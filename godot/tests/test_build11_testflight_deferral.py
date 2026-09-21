"""Keep the owner's first-TestFlight deferral narrow and separate from proof."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("fred_store_readiness", ROOT / "tools/store_readiness.py")
READINESS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(READINESS)


class TestBuild13Deferral(unittest.TestCase):
    def setUp(self):
        self.game = json.loads((ROOT / "game/game.json").read_text())
        self.package = json.loads((ROOT / "store/app_store_package.json").read_text())

    def test_only_three_named_device_checks_are_deferred(self):
        self.assertEqual({item["gate"] for item in self.package["release_exceptions"]}, READINESS.DEVICE_DEFERRABLE_GATES)
        for gate in READINESS.DEVICE_DEFERRABLE_GATES:
            self.assertTrue(READINESS.device_check_deferred(self.package, self.game, gate, "internal-testflight"))
            self.assertFalse(READINESS.device_check_deferred(self.package, self.game, gate, "app-review"))

    def test_approval_cannot_transfer_to_another_build_or_version(self):
        for change in ({"build_number": 14}, {"marketing_version": "1.2"}):
            for gate in READINESS.DEVICE_DEFERRABLE_GATES:
                self.assertFalse(READINESS.device_check_deferred(self.package, self.game | change, gate, "internal-testflight"))

    def test_production_checks_are_not_waived(self):
        for gate in ("golden_egg.production_endpoint_verified", "golden_egg.privacy_consent_reviewed", "custom_music"):
            self.assertFalse(READINESS.approved_exception(self.package, self.game, gate))

    def test_device_evidence_stays_unverified(self):
        game_center = json.loads((ROOT / "store/game_center.json").read_text())
        self.assertFalse(game_center["on_device_authentication_tested"])
        self.assertFalse(game_center["on_device_replay_tested"])
        self.assertFalse(self.package["golden_egg"]["physical_device_flow_reviewed"])


if __name__ == "__main__":
    unittest.main()
