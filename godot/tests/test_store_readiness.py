from __future__ import annotations
import copy, hashlib, json, struct, subprocess, sys, tempfile, unittest, zlib
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tools"))
import store_readiness as STORE

def png(path: Path, width: int, height: int) -> str:
    def chunk(kind,data):
        return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data)&0xffffffff)
    row=b"\0"+b"\x20\x60\xa0"*width
    data=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",width,height,8,2,0,0,0))+chunk(b"IDAT",zlib.compress(row*height,9))+chunk(b"IEND",b"")
    path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(data)
    return hashlib.sha256(data).hexdigest()

class StoreReadinessTests(unittest.TestCase):
    def test_website_deferral_is_exact_and_never_security(self):
        game = {"marketing_version":"1.1", "build_number":11}
        package = {"golden_egg":{"safe_nonblocking_fallback_reviewed":True},
                   "release_exceptions":[{"gate":"golden_egg.production_endpoint_verified",
                       "owner_approved":True, "reason":"Fictional endpoint unavailable",
                       "exact_version":"1.1", "exact_build":11}]}
        self.assertTrue(STORE.website_check_deferred(package,game,"golden_egg.production_endpoint_verified"))
        self.assertFalse(STORE.website_check_deferred(package,game,"golden_egg.privacy_consent_reviewed"))
        game["build_number"] = 12
        self.assertFalse(STORE.website_check_deferred(package,game,"golden_egg.production_endpoint_verified"))
        game["build_number"] = 11
        package["golden_egg"]["safe_nonblocking_fallback_reviewed"] = False
        self.assertFalse(STORE.website_check_deferred(package,game,"golden_egg.production_endpoint_verified"))

    def test_golden_egg_is_discovery_triggered_and_version_enforcement_is_independent(self):
        game=json.loads((ROOT/"game/game.json").read_text())
        game["capabilities"].update(game_center=True,golden_eggs=True)
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"game").mkdir(); (root/"store").mkdir()
            for relative in ("game/game.json","store/app_store_package.json","store/screenshots.json","store/game_center.json","store/audio_package.json"):
                (root/relative).write_bytes((ROOT/relative).read_bytes())
            (root/"game/game.json").write_text(json.dumps(game))
            errors=STORE.validate(root)
            self.assertFalse(any("Golden Egg" in e for e in errors), errors)
            game["integrations"]["golden_eggs"]["startup_network_requests"]=True
            (root/"game/game.json").write_text(json.dumps(game))
            self.assertIn("Golden Egg startup_network_requests contract mismatch",STORE.validate(root))

    def test_automatic_release_requires_exact_owner_authorization(self):
        game = {"marketing_version": "1.1", "build_number": 11}
        package = {"version": {"release_mode": "manual"}}
        self.assertTrue(STORE.release_mode_authorized(package, game))
        package["version"]["release_mode"] = "automatic"
        self.assertFalse(STORE.release_mode_authorized(package, game))
        package["release_authorization"] = {"mode": "automatic", "owner_approved": True,
            "exact_version": "1.1", "exact_build": 11, "reason": "Fictional exact-build release approval"}
        self.assertTrue(STORE.release_mode_authorized(package, game))
        for field, value in (("mode", "scheduled"), ("owner_approved", False),
                             ("exact_version", "1.2"), ("exact_build", 12), ("reason", "")):
            changed = copy.deepcopy(package)
            changed["release_authorization"][field] = value
            self.assertFalse(STORE.release_mode_authorized(changed, game))
        package["release_authorization"] = True
        self.assertFalse(STORE.release_mode_authorized(package, game))

    def test_unsigned_game_player_id_cannot_be_labelled_verified(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "game").mkdir(); (root / "store").mkdir()
            for relative in ("game/game.json", "store/app_store_package.json", "store/screenshots.json", "store/game_center.json", "store/audio_package.json"):
                (root / relative).write_bytes((ROOT / relative).read_bytes())
            game = json.loads((root / "game/game.json").read_text())
            game["capabilities"]["golden_eggs"] = True
            for label, rejected in (("verified_game_player_id", True), ("provider_reported_game_player_id", False)):
                game["integrations"]["golden_eggs"]["private_game_audit_identity"] = label
                (root / "game/game.json").write_text(json.dumps(game))
                self.assertEqual(rejected, any("private_game_audit_identity" in error for error in STORE.validate(root)))

    def test_device_deferral_is_exact_build_and_never_waives_review(self):
        game={"marketing_version":"1.0","build_number":2}
        gate="game_center.on_device_authentication_tested"
        item={"gate":gate,"reason":"Device testing follows first internal upload", "owner_approved":True,
              "exact_version":"1.0","exact_build":2,"deferred_until":"app-review"}
        package={"release_exceptions":[item]}
        self.assertTrue(STORE.device_check_deferred(package,game,gate,"internal-testflight"))
        self.assertFalse(STORE.device_check_deferred(package,game,gate,"app-review"))
        for field,value in (("exact_build",3),("exact_version","1.1"),("owner_approved",False),("reason",""),("deferred_until","never")):
            changed=copy.deepcopy(package); changed["release_exceptions"][0][field]=value
            self.assertFalse(STORE.device_check_deferred(changed,game,gate,"internal-testflight"))
        for other in ("custom_music","game_center.app_store_records_reviewed","golden_egg.production_endpoint_verified"):
            changed=copy.deepcopy(package); changed["release_exceptions"][0]["gate"]=other
            self.assertFalse(STORE.device_check_deferred(changed,game,other,"internal-testflight"))

    def test_device_deferral_does_not_hide_unrelated_release_failures(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"game").mkdir(); (root/"store").mkdir()
            for relative in ("game/game.json","store/app_store_package.json","store/screenshots.json","store/game_center.json","store/audio_package.json"):
                (root/relative).write_bytes((ROOT/relative).read_bytes())
            game=json.loads((root/"game/game.json").read_text())
            game["capabilities"].update(game_center=True,golden_eggs=True)
            (root/"game/game.json").write_text(json.dumps(game))
            package=json.loads((root/"store/app_store_package.json").read_text())
            package["release_exceptions"]=[{"gate":gate,"reason":"Fictional approved deferral","owner_approved":True,
                "exact_version":game["marketing_version"],"exact_build":game["build_number"],"deferred_until":"app-review"} for gate in STORE.DEVICE_DEFERRABLE_GATES]
            (root/"store/app_store_package.json").write_text(json.dumps(package))
            review=set(STORE.validate(root,release=True))
            internal=set(STORE.validate(root,release=True,purpose="internal-testflight"))
            self.assertEqual({"Game Center on_device_authentication_tested missing", "Game Center on_device_replay_tested missing", "Golden Egg physical_device_flow_reviewed missing"},review-internal)
            self.assertIn("store package owner approval missing",internal)
            self.assertIn("Golden Egg production_endpoint_verified missing",internal)

    def test_fred_draft_is_structurally_valid_and_not_releasable(self):
        self.assertEqual([],STORE.validate(ROOT))
        errors=STORE.validate(ROOT,release=True)
        self.assertTrue(any("owner approval" in x for x in errors))
        self.assertIn("creative contract owner review missing",errors)
        self.assertIn("Golden Egg production_endpoint_verified missing",errors)

    def test_field_limits_and_privacy_identity_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"game").mkdir(); (root/"store").mkdir()
            game=json.loads((ROOT/"game/game.json").read_text()); package=json.loads((ROOT/"store/app_store_package.json").read_text()); shots=json.loads((ROOT/"store/screenshots.json").read_text()); gc=json.loads((ROOT/"store/game_center.json").read_text()); audio=json.loads((ROOT/"store/audio_package.json").read_text())
            game["capabilities"].update(game_center=False,achievements=False)
            gc["enabled"]=False
            package["identity"]["subtitle"]="x"*31; package["version"]["privacy_url"]="https://example.invalid"
            (root/"game/game.json").write_text(json.dumps(game)); (root/"store/app_store_package.json").write_text(json.dumps(package)); (root/"store/screenshots.json").write_text(json.dumps(shots)); (root/"store/game_center.json").write_text(json.dumps(gc)); (root/"store/audio_package.json").write_text(json.dumps(audio))
            errors=STORE.validate(root)
            self.assertTrue(any("subtitle" in x for x in errors)); self.assertTrue(any("privacy URL" in x for x in errors))

    def test_approved_exact_build_media_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"game").mkdir(); (root/"store").mkdir()
            game=json.loads((ROOT/"game/game.json").read_text()); package=json.loads((ROOT/"store/app_store_package.json").read_text()); shots=json.loads((ROOT/"store/screenshots.json").read_text()); gc=json.loads((ROOT/"store/game_center.json").read_text()); audio=json.loads((ROOT/"store/audio_package.json").read_text())
            # This fictional media-only fixture is independent of Fred's live services.
            game["capabilities"].update(game_center=False,achievements=False,golden_eggs=False)
            gc["enabled"]=False
            game["updates"]["app_store_url"]="https://apps.apple.com/app/id1234567890"
            package["review_status"]="approved"; package["identity"].update(subtitle="A Real Game",copyright="2026 Fictional Studio",secondary_category="Family",content_rights_attested=True)
            package["creative_contract"]={"story_premise":"Restore a fictional garden.","player_role":"Garden keeper","main_objective":"Repair every path.","gameplay_truths":["Play 10 deterministic levels"],"visual_direction":"Original colorful shapes","owner_approved":True}
            package["version"].update(description="A truthful fictional game.",promotional_text="",keywords=["garden","puzzle"],whats_new="First release.",review_notes="Use labeled controls and finish level one.",beta_description="Test the full campaign.",what_to_test=["Complete level one"],release_mode="manual")
            package["distribution"].update(price_reviewed=True,availability_reviewed=True,agreements_tax_banking_reviewed=True)
            package["compliance"]={key:True for key in package["compliance"]}; package["media"]["visual_owner_reviewed"]=True
            package["public_copy_review"]["vendor_neutral_reviewed"]=True
            music=root/"assets/audio/custom/theme.ogg"; music.parent.mkdir(parents=True); music.write_bytes(b"fictional custom music fixture")
            audio.update(rights_reviewed=True,runtime_mix_reviewed=True,loop_and_transition_tested=True,owner_approved=True)
            audio["tracks"]=[{"id":"main_theme","title":"Garden Theme","gameplay_role":"Main gameplay","composer_or_source":"Fictional test composer","custom_for_this_game":True,"file":"assets/audio/custom/theme.ogg","sha256":hashlib.sha256(music.read_bytes()).hexdigest()}]
            icon_hash=png(root/"assets/store/app-icon-1024.png",1024,1024)
            package["media"]["app_icon"]="assets/store/app-icon-1024.png"
            phone=root/"assets/store/iphone.png"; tablet=root/"assets/store/ipad.png"; ph=png(phone,1320,2868); th=png(tablet,2064,2752)
            shots["sets"]={"iphone-6.9":[{"file":"assets/store/iphone.png","sha256":ph,"caption":"Real title screen"}],"ipad-13":[{"file":"assets/store/ipad.png","sha256":th,"caption":"Real gameplay"}]}
            for path,data in ((root/"game/game.json",game),(root/"store/app_store_package.json",package),(root/"store/screenshots.json",shots),(root/"store/game_center.json",gc),(root/"store/audio_package.json",audio)): path.write_text(json.dumps(data))
            subprocess.run(["git","init",str(root)],check=True,capture_output=True); subprocess.run(["git","-C",str(root),"add","."],check=True); subprocess.run(["git","-C",str(root),"-c","user.name=Fixture","-c","user.email=fixture@example.invalid","commit","-m","capture"],check=True,capture_output=True)
            capture=subprocess.check_output(["git","-C",str(root),"rev-parse","HEAD"],text=True).strip(); shots["capture_commit"]=capture; (root/"store/screenshots.json").write_text(json.dumps(shots)); subprocess.run(["git","-C",str(root),"add","store/screenshots.json"],check=True); subprocess.run(["git","-C",str(root),"-c","user.name=Fixture","-c","user.email=fixture@example.invalid","commit","-m","manifest"],check=True,capture_output=True)
            # Media approval alone no longer waives the universal service backbone.
            release_errors = STORE.validate(root,release=True)
            self.assertTrue(any(x.startswith("backbone:") for x in release_errors))
            self.assertEqual([], [x for x in release_errors if not x.startswith("backbone:")])
            shots["sets"]["ipad-13"][0]["sha256"]=icon_hash; (root/"store/screenshots.json").write_text(json.dumps(shots))
            self.assertTrue(any("SHA-256" in x for x in STORE.validate(root,release=True)))

    def test_release_rejects_discretionary_external_names(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"game").mkdir(); (root/"store").mkdir()
            for relative in ("game/game.json","store/app_store_package.json","store/screenshots.json","store/game_center.json","store/audio_package.json"):
                (root/relative).write_bytes((ROOT/relative).read_bytes())
            package=json.loads((root/"store/app_store_package.json").read_text())
            package["public_copy_review"].update(vendor_neutral_reviewed=True,external_company_names=["Example Vendor"])
            (root/"store/app_store_package.json").write_text(json.dumps(package))
            self.assertIn("public copy external_company_names must be an empty reviewed list",STORE.validate(root,release=True))

    def test_game_center_achievement_art_and_limits_are_enforced(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/"game").mkdir(); (root/"store").mkdir()
            game=json.loads((ROOT/"game/game.json").read_text()); package=json.loads((ROOT/"store/app_store_package.json").read_text()); shots=json.loads((ROOT/"store/screenshots.json").read_text()); gc=json.loads((ROOT/"store/game_center.json").read_text()); audio=json.loads((ROOT/"store/audio_package.json").read_text())
            game["capabilities"].update(game_center=True,achievements=True)
            gc["enabled"]=True
            icon=root/"assets/store/game-center/first.png"; digest=png(icon,1024,1024)
            gc["achievements"]=[{"id":"first_win","reference_name":"First Win","title":"First Win","unearned_description":"Win one race.","earned_description":"You won one race.","points":100,"hidden":False,"repeatable":False,"image":"assets/store/game-center/first.png","sha256":digest}]
            for path,data in ((root/"game/game.json",game),(root/"store/app_store_package.json",package),(root/"store/screenshots.json",shots),(root/"store/game_center.json",gc),(root/"store/audio_package.json",audio)): path.write_text(json.dumps(data))
            self.assertFalse(any("achievement 0" in x.lower() for x in STORE.validate(root)))
            gc["achievements"][0]["points"]=101; (root/"store/game_center.json").write_text(json.dumps(gc))
            self.assertIn("Game Center achievement 0 points must be 1-100",STORE.validate(root))

    def test_custom_music_exception_is_exact_build_and_owner_scoped(self):
        game=json.loads((ROOT/"game/game.json").read_text()); package=json.loads((ROOT/"store/app_store_package.json").read_text())
        self.assertFalse(STORE.approved_exception(package,game,"custom_music"))
        package["release_exceptions"]=[{"gate":"custom_music","reason":"Owner-approved silent accessibility prototype","owner_approved":True,"exact_version":game["marketing_version"],"exact_build":game["build_number"]}]
        self.assertTrue(STORE.approved_exception(package,game,"custom_music"))
        package["release_exceptions"][0]["exact_build"] += 1
        self.assertFalse(STORE.approved_exception(package,game,"custom_music"))

if __name__=="__main__": unittest.main()
