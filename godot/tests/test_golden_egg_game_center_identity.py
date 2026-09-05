from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FredGameCenterIdentityContractTests(unittest.TestCase):
    def test_fred_scope_and_signed_identity_fields(self):
        service = (ROOT / "scripts/golden_egg_service.gd").read_text(encoding="utf-8")
        adapter = (ROOT / "scripts/game_center_adapter.gd").read_text(encoding="utf-8")
        self.assertIn('const GAME_ID := "fred-myers"', service)
        self.assertIn('const EXPECTED_BUNDLE_ID := "com.flinsvault.fredmyers"', service)
        for field in ("team_player_id", "game_player_id", "bundle_id", "timestamp", "salt", "signature", "public_key_url"):
            self.assertIn(field, service)
            self.assertIn(field, adapter)

    def test_no_editable_name_is_transmitted(self):
        service = (ROOT / "scripts/golden_egg_service.gd").read_text(encoding="utf-8")
        bridge = (ROOT / "scripts/golden_egg_network_bridge.gd").read_text(encoding="utf-8")
        main = (ROOT / "scripts/main.gd").read_text(encoding="utf-8")
        self.assertIn("func submit_privacy_choice(make_public: bool)", service)
        self.assertNotIn('payload := {"privacy_status": "PUBLIC", "display_name"', service)
        self.assertIn("service.submit_privacy_choice(true)", bridge)
        self.assertNotIn("start_privacy(golden_service, true, identity.profile_label)", main)
        self.assertNotIn('"display_name": identity.profile_label', main)

    def test_native_patch_and_build_number(self):
        patch = (ROOT / "tools/patches/gamecenter-signed-identity-v1.patch").read_text(encoding="utf-8")
        game = (ROOT / "game/game.json").read_text(encoding="utf-8")
        self.assertIn('ret["team_player_id"]', patch)
        self.assertIn('ret["game_player_id"]', patch)
        self.assertIn('"build_number": 10', game)


if __name__ == "__main__":
    unittest.main()
