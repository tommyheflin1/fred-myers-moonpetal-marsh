#!/usr/bin/env python3
"""Validate app-owned App Store metadata/media without submitting anything."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import urllib.request

ORIGIN = "https://theflinsappvaultllc.com"
IPHONE = {(1260,2736),(1290,2796),(1320,2868),(2736,1260),(2796,1290),(2868,1320)}
IPAD = {(2064,2752),(2048,2732),(2752,2064),(2732,2048)}

def load(root: Path) -> tuple[dict,dict,dict,dict,dict]:
    return tuple(json.loads((root/p).read_text(encoding="utf-8")) for p in
                 ("game/game.json","store/app_store_package.json","store/screenshots.json","store/game_center.json","store/audio_package.json"))

def approved_exception(package: dict, game: dict, gate: str) -> bool:
    for item in package.get("release_exceptions",[]):
        if not isinstance(item,dict): continue
        if (item.get("gate")==gate and item.get("owner_approved") is True
                and item.get("exact_version")==game.get("marketing_version")
                and item.get("exact_build")==game.get("build_number")
                and isinstance(item.get("reason"),str) and item["reason"].strip()):
            return True
    return False

def placeholder(value: object) -> bool:
    if isinstance(value,str): return "REPLACE" in value
    if isinstance(value,list): return any(placeholder(item) for item in value)
    if isinstance(value,dict): return any(placeholder(item) for item in value.values())
    return False

def release_mode_authorized(package: dict, game: dict) -> bool:
    mode = package.get("version", {}).get("release_mode")
    if mode == "manual":
        return True
    approval = package.get("release_authorization", {})
    return (mode == "automatic" and isinstance(approval, dict)
            and approval.get("mode") == mode
            and approval.get("owner_approved") is True
            and approval.get("exact_version") == game.get("marketing_version")
            and approval.get("exact_build") == game.get("build_number")
            and isinstance(approval.get("reason"), str)
            and bool(approval["reason"].strip()))

def png_info(data: bytes) -> tuple[int,int,bool]:
    if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 26:
        raise ValueError("invalid PNG")
    width,height = struct.unpack(">II", data[16:24]); color_type=data[25]
    return width,height,color_type in {4,6}

def jpeg_info(data: bytes) -> tuple[int,int,bool]:
    if data[:2] != b"\xff\xd8": raise ValueError("invalid JPEG")
    i=2
    while i+9 < len(data):
        if data[i] != 0xff: i+=1; continue
        marker=data[i+1]; i+=2
        if marker in {0xd8,0xd9} or 0xd0 <= marker <= 0xd7: continue
        if i+2 > len(data): break
        length=int.from_bytes(data[i:i+2],"big")
        if marker in {0xc0,0xc1,0xc2,0xc3,0xc5,0xc6,0xc7,0xc9,0xca,0xcb,0xcd,0xce,0xcf}:
            if length < 7: break
            return int.from_bytes(data[i+3:i+5],"big"),int.from_bytes(data[i+5:i+7],"big"),False
        i += length
    raise ValueError("JPEG dimensions missing")

def image_info(path: Path) -> tuple[int,int,bool,str]:
    data=path.read_bytes()
    lowered=data.lower()
    if any(marker in lowered for marker in (b"users/",b"users\\",b"appdata",b"onedrive",b"gpslatitude",b"gpslongitude")):
        raise ValueError("private path or location metadata detected")
    width,height,alpha = png_info(data) if path.suffix.lower()==".png" else jpeg_info(data)
    return width,height,alpha,hashlib.sha256(data).hexdigest()

DEVICE_DEFERRABLE_GATES = {"game_center.on_device_authentication_tested", "game_center.on_device_replay_tested", "golden_egg.physical_device_flow_reviewed"}

def device_check_deferred(package: dict, game: dict, gate: str, purpose: str) -> bool:
    # Never convert pending device evidence into a pass for App Review.
    if purpose != "internal-testflight" or gate not in DEVICE_DEFERRABLE_GATES:
        return False
    return any(approved_exception({"release_exceptions": [item]}, game, gate)
               and item.get("deferred_until") == "app-review"
               for item in package.get("release_exceptions", []) if isinstance(item, dict))

def validate(root: Path, release: bool=False, verify_live: bool=False, purpose: str="app-review") -> list[str]:
    errors=[]
    if purpose not in {"app-review", "internal-testflight"}: return ["invalid release purpose"]
    try: game,package,shots,game_center,audio=load(root)
    except (OSError,ValueError) as exc: return [f"package load failed: {exc}"]
    identity=package.get("identity",{}); creative=package.get("creative_contract",{}); version=package.get("version",{})
    distribution=package.get("distribution",{}); compliance=package.get("compliance",{}); media=package.get("media",{})
    public_copy=package.get("public_copy_review",{})
    if package.get("schema")!="flins-app-store-package-v1": errors.append("store package schema mismatch")
    if package.get("review_status") not in {"draft","approved"}: errors.append("store package review status invalid")
    if shots.get("schema")!="flins-app-store-screenshots-v1": errors.append("screenshot schema mismatch")
    if game_center.get("schema")!="flins-game-center-package-v1": errors.append("Game Center package schema mismatch")
    if audio.get("schema")!="flins-custom-music-package-v1": errors.append("custom music package schema mismatch")
    if identity.get("name") != game.get("display_name"): errors.append("App Store name differs from game display name")
    if not 2 <= len(str(identity.get("name",""))) <= 30: errors.append("app name must be 2-30 characters")
    if len(str(identity.get("subtitle",""))) > 30: errors.append("subtitle exceeds 30 characters")
    if len(str(version.get("promotional_text",""))) > 170: errors.append("promotional text exceeds 170 characters")
    if not 1 <= len(str(version.get("description",""))) <= 4000: errors.append("description must be 1-4000 characters")
    keywords=version.get("keywords",[])
    if not isinstance(keywords,list) or not keywords or any(not isinstance(x,str) or len(x)<=2 or ',' in x for x in keywords): errors.append("keywords must be a nonempty string list without commas and each exceed two characters")
    elif len(','.join(keywords).encode()) > 100: errors.append("keywords exceed 100 UTF-8 bytes")
    expected_privacy=f"{ORIGIN}/{game.get('game_id')}/privacy"
    expected_support=f"{ORIGIN}/{game.get('game_id')}/support"
    if version.get("privacy_url") != expected_privacy or version.get("privacy_url") != game.get("privacy",{}).get("policy_url"): errors.append("privacy URL identity mismatch")
    if version.get("support_url") != expected_support: errors.append("dedicated support URL identity mismatch")
    if not release_mode_authorized(package, game): errors.append("release mode must remain manual unless separately approved")
    if media.get("exact_version") != game.get("marketing_version") or media.get("exact_build") != game.get("build_number"): errors.append("media version/build differs from candidate")
    if media.get("screenshots_manifest") != "store/screenshots.json": errors.append("screenshot manifest path must be store/screenshots.json")
    for field in ("story_premise","player_role","main_objective","visual_direction"):
        if not isinstance(creative.get(field),str) or not creative[field].strip(): errors.append(f"creative contract missing {field}")
    truths=creative.get("gameplay_truths")
    if not isinstance(truths,list) or not truths or any(not isinstance(x,str) or not x.strip() for x in truths): errors.append("gameplay truths missing")
    if bool(distribution.get("paid_download")) != bool(game.get("privacy",{}).get("paid_download")): errors.append("paid-download privacy mismatch")
    platforms=distribution.get("platforms",{})
    ios_enabled="ios" in game.get("platforms",[])
    if ios_enabled and not platforms.get("iphone"): errors.append("iPhone media support must be declared")
    if release and not ios_enabled: errors.append("App Store release package requires iOS platform")
    if release and public_copy.get("vendor_neutral_reviewed") is not True: errors.append("public copy vendor-neutral review missing")
    for field in ("external_company_names","external_website_names"):
        value=public_copy.get(field)
        if release and (not isinstance(value,list) or value): errors.append(f"public copy {field} must be an empty reviewed list")
    disclosures=public_copy.get("required_disclosures",[])
    if release and (not isinstance(disclosures,list) or any(not isinstance(x,dict) or not str(x.get("text","")).strip() or not str(x.get("basis","")).strip() for x in disclosures)):
        errors.append("required public disclosures must include exact text and legal or contractual basis")
    if game.get("capabilities",{}).get("game_center") and not compliance.get("game_center_records_reviewed") and release: errors.append("Game Center records are not reviewed")
    gc_enabled=bool(game.get("capabilities",{}).get("game_center"))
    achievements_enabled=bool(game.get("capabilities",{}).get("achievements"))
    if bool(game_center.get("enabled")) != gc_enabled: errors.append("Game Center package capability mismatch")
    achievements=game_center.get("achievements",[])
    if not isinstance(achievements,list): errors.append("Game Center achievements must be a list"); achievements=[]
    ids=set(); refs=set(); icon_hashes=set(); points=0
    for index,item in enumerate(achievements):
        if not isinstance(item,dict): errors.append(f"Game Center achievement {index} invalid"); continue
        achievement_id=str(item.get("id","")); reference_name=str(item.get("reference_name",""))
        if not achievement_id or len(achievement_id)>100 or achievement_id in ids: errors.append(f"Game Center achievement {index} ID invalid or duplicate")
        if not reference_name or reference_name in refs: errors.append(f"Game Center achievement {index} reference name invalid or duplicate")
        ids.add(achievement_id); refs.add(reference_name)
        value=item.get("points")
        if not isinstance(value,int) or not 1 <= value <= 100: errors.append(f"Game Center achievement {index} points must be 1-100")
        else: points += value
        for field in ("title","unearned_description","earned_description"):
            if not isinstance(item.get(field),str) or not item[field].strip() or placeholder(item[field]): errors.append(f"Game Center achievement {index} {field} missing")
        if not isinstance(item.get("hidden"),bool) or not isinstance(item.get("repeatable"),bool): errors.append(f"Game Center achievement {index} behavior flags invalid")
        relative=str(item.get("image","")); path=(root/relative).resolve()
        try:
            if not path.is_relative_to((root/"assets/store/game-center").resolve()): raise ValueError("must stay under assets/store/game-center")
            if path.suffix.lower() not in {".png",".jpg",".jpeg"}: raise ValueError("must be PNG or JPEG")
            width,height,_alpha,digest=image_info(path)
            if (width,height)!=(1024,1024): raise ValueError("must be 1024x1024 pixels")
            if digest in icon_hashes: raise ValueError("must be unique for every achievement")
            icon_hashes.add(digest)
            if item.get("sha256") != digest: raise ValueError("manifest SHA-256 mismatch")
        except (OSError,ValueError) as exc:
            if release or relative: errors.append(f"Game Center achievement {index} image: {exc}")
    if points>1000: errors.append("Game Center achievement points exceed 1000 total")
    if release and achievements_enabled and not achievements: errors.append("Game Center achievements are enabled but none are declared")
    if release and not achievements_enabled and achievements: errors.append("Game Center achievements exist while capability is disabled")
    if release and gc_enabled:
        for field in ("app_store_records_reviewed","identifiers_match_runtime","on_device_authentication_tested","on_device_replay_tested"):
            if game_center.get(field) is not True and not device_check_deferred(package,game,f"game_center.{field}",purpose): errors.append(f"Game Center {field} missing")
    golden=package.get("golden_egg",{})
    if game.get("capabilities",{}).get("golden_eggs"):
        contract=game.get("integrations",{}).get("golden_eggs",{})
        expected={"origin":ORIGIN,"hunt_path":"/golden-eggs","public_identity_source":"verified_game_center_session","provider_display_name_source":"game_center_reported","private_cross_game_identity":"verified_team_player_id","private_game_audit_identity":"provider_reported_game_player_id","offline_linking":"explicit_server_verified_only","activation_trigger":"verified_local_discovery","startup_network_requests":False,"core_gameplay_requires_backend":False,"game_center_independent":True,"failure_mode":"pending_nonblocking_idempotent_retry","anonymous_public_name":"Anonymous","version_enforcement_independent":True}
        for field,value in expected.items():
            if contract.get(field)!=value: errors.append(f"Golden Egg {field} contract mismatch")
        if contract.get("website_name_entry_allowed") is not False or contract.get("public_name_consent_required") is not True: errors.append("Golden Egg public identity privacy contract mismatch")
        if release and contract.get("auth_protocol") in {None,"","unconfigured"}: errors.append("Golden Egg authentication protocol is not configured")
        if release:
            for field in ("website_contract_reviewed","game_center_identity_reviewed","privacy_consent_reviewed","production_endpoint_verified","physical_device_flow_reviewed"):
                if golden.get(field) is not True and not device_check_deferred(package,game,f"golden_egg.{field}",purpose): errors.append(f"Golden Egg {field} missing")
    updates=game.get("updates",{})
    if not isinstance(updates.get("enabled"),bool): errors.append("version enforcement enabled flag must be explicit")
    elif updates.get("enabled") and (updates.get("mode")!="mandatory_minimum_build" or updates.get("fail_closed") is not True): errors.append("mandatory update policy contract mismatch")
    tracks=audio.get("tracks",[])
    if not isinstance(tracks,list): errors.append("custom music tracks must be a list"); tracks=[]
    track_ids=set(); track_hashes=set()
    for index,item in enumerate(tracks):
        if not isinstance(item,dict): errors.append(f"custom music track {index} invalid"); continue
        track_id=str(item.get("id",""))
        if not track_id or track_id in track_ids: errors.append(f"custom music track {index} ID invalid or duplicate")
        track_ids.add(track_id)
        for field in ("title","gameplay_role","composer_or_source"):
            if not isinstance(item.get(field),str) or not item[field].strip() or placeholder(item[field]): errors.append(f"custom music track {index} {field} missing")
        if item.get("custom_for_this_game") is not True: errors.append(f"custom music track {index} is not game-specific")
        relative=str(item.get("file","")); path=(root/relative).resolve()
        try:
            if not path.is_relative_to((root/"assets/audio/custom").resolve()): raise ValueError("must stay under assets/audio/custom")
            if path.suffix.lower() not in {".ogg",".mp3",".wav"}: raise ValueError("must be OGG, MP3, or WAV")
            digest=hashlib.sha256(path.read_bytes()).hexdigest()
            if not path.stat().st_size: raise ValueError("must not be empty")
            if digest in track_hashes: raise ValueError("must be unique")
            track_hashes.add(digest)
            if item.get("sha256")!=digest: raise ValueError("manifest SHA-256 mismatch")
        except (OSError,ValueError) as exc:
            if release or relative: errors.append(f"custom music track {index}: {exc}")
    music_exception=approved_exception(package,game,"custom_music")
    if release and not tracks and not music_exception: errors.append("custom game music is required unless exact-build owner exception is approved")
    if release and tracks:
        for field in ("rights_reviewed","runtime_mix_reviewed","loop_and_transition_tested","owner_approved"):
            if audio.get(field) is not True: errors.append(f"custom music {field} missing")
    exceptions=package.get("release_exceptions",[])
    if not isinstance(exceptions,list): errors.append("release exceptions must be a list")
    elif release:
        for index,item in enumerate(exceptions):
            if not isinstance(item,dict) or not item.get("gate") or not item.get("reason") or item.get("owner_approved") is not True or item.get("exact_version")!=game.get("marketing_version") or item.get("exact_build")!=game.get("build_number"):
                errors.append(f"release exception {index} is not a narrow exact-build owner approval")
    sets=shots.get("sets",{})
    seen_hashes=set()
    required={"iphone-6.9":IPHONE}; required.update({"ipad-13":IPAD} if platforms.get("ipad") else {})
    for set_name,sizes in required.items():
        items=sets.get(set_name,[])
        if not isinstance(items,list): errors.append(f"{set_name} screenshot set invalid"); continue
        if release and not 1 <= len(items) <= 10: errors.append(f"{set_name} requires 1-10 screenshots")
        if len(items)>10: errors.append(f"{set_name} exceeds 10 screenshots")
        for index,item in enumerate(items):
            if not isinstance(item,dict): errors.append(f"{set_name} item {index} invalid"); continue
            relative=str(item.get("file","")); path=(root/relative).resolve()
            try:
                if not path.is_relative_to((root/"assets/store").resolve()): raise ValueError("must stay under assets/store")
                if path.suffix.lower() not in {".png",".jpg",".jpeg"}: raise ValueError("must be PNG or JPEG")
                width,height,alpha,digest=image_info(path)
                if (width,height) not in sizes: raise ValueError(f"unsupported dimensions {width}x{height}")
                if alpha: raise ValueError("alpha channel is not allowed")
                if digest in seen_hashes: raise ValueError("duplicate screenshot content")
                seen_hashes.add(digest)
                if item.get("sha256") != digest: raise ValueError("manifest SHA-256 mismatch")
                if placeholder(item.get("caption")): raise ValueError("caption is missing")
            except (OSError,ValueError) as exc: errors.append(f"{set_name} item {index}: {exc}")
    if release:
        if package.get("review_status") != "approved": errors.append("store package owner approval missing")
        for value in (identity,creative,version):
            if placeholder(value): errors.append("store package contains placeholder content"); break
        for field in ("description","whats_new","review_notes","beta_description"):
            if not isinstance(version.get(field),str) or not version[field].strip(): errors.append(f"version {field} missing")
        what=version.get("what_to_test")
        if not isinstance(what,list) or not what or any(not isinstance(x,str) or not x.strip() for x in what): errors.append("observable TestFlight checks missing")
        for field in ("content_rights_attested",):
            if not identity.get(field): errors.append("content and media rights are not attested")
        if not creative.get("owner_approved"): errors.append("creative contract owner review missing")
        if not media.get("visual_owner_reviewed"): errors.append("store media owner review missing")
        for field in ("price_reviewed","availability_reviewed","agreements_tax_banking_reviewed"):
            if not distribution.get(field): errors.append(f"distribution {field} missing")
        if updates.get("enabled") and not str(updates.get("app_store_url","")).startswith("https://apps.apple.com/"): errors.append("mandatory update App Store product URL missing")
        for field in ("age_rating_reviewed","privacy_answers_reviewed","export_compliance_reviewed","accessibility_reviewed","third_party_sdk_inventory_reviewed"):
            if not compliance.get(field): errors.append(f"compliance {field} missing")
        if updates.get("enabled") and not compliance.get("mandatory_update_policy_reviewed"): errors.append("compliance mandatory_update_policy_reviewed missing")
        capture=str(shots.get("capture_commit",""))
        if not re.fullmatch(r"[0-9a-f]{40}",capture): errors.append("screenshot capture commit is invalid")
        elif subprocess.run(["git","-c",f"safe.directory={root.as_posix()}","-C",str(root),"merge-base","--is-ancestor",capture,"HEAD"],capture_output=True).returncode != 0: errors.append("screenshot capture commit is not in candidate history")
        try:
            icon=(root/str(media.get("app_icon",""))).resolve(); w,h,alpha,_=image_info(icon)
            if icon.suffix.lower() != ".png" or not icon.is_relative_to((root/"assets/store").resolve()) or (w,h)!=(1024,1024) or alpha: errors.append("app icon must be a 1024x1024 PNG without alpha under assets/store")
        except (OSError,ValueError): errors.append("valid 1024x1024 app icon missing")
    if verify_live and not errors:
        for label,url in (("privacy",expected_privacy),("support",expected_support)):
            try:
                request=urllib.request.Request(url,headers={"User-Agent":"FlinsStoreGate/1.0"})
                with urllib.request.urlopen(request,timeout=30) as response:
                    body=response.read(262144).decode("utf-8",errors="replace")
                    if response.status != 200: raise ValueError(f"HTTP {response.status}")
                    if label == "support" and f'data-support-id="{game["game_id"]}"' not in body: raise ValueError("app-specific support marker missing")
            except Exception as exc: errors.append(f"live {label} URL failed: {exc}")
    return errors

def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("mode",choices=["draft","release"]); parser.add_argument("--root",type=Path,default=Path.cwd()); parser.add_argument("--verify-live",action="store_true"); parser.add_argument("--purpose",choices=["app-review","internal-testflight"],default="app-review"); args=parser.parse_args()
    errors=validate(args.root.resolve(),args.mode=="release",args.verify_live,args.purpose)
    if errors:
        for error in sorted(set(errors)): print("STORE_READINESS_FAIL",error)
        return 1
    print(f"STORE_READINESS_OK mode={args.mode} purpose={args.purpose} submission=false release=false")
    return 0
if __name__=="__main__": raise SystemExit(main())
