from __future__ import annotations
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import backbone_contract as gate


class BackboneTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "game").mkdir()
        (self.root / "store").mkdir()
        self.contract = json.loads((ROOT / "BACKBONE_CONTRACT.json").read_text())
        self.game = {"game_id": "fictional", "bundle_id": "com.example.fictional",
                     "marketing_version": "1.0", "build_number": 1,
                     "capabilities": dict.fromkeys(self.contract["required_capabilities"], True),
                     "integrations": {"golden_eggs": self.contract["golden_eggs"].copy()},
                     "updates": {"enabled": False}}
        self.write_game()
        (self.root / "fixture.txt").write_text("Fictional test artifact only; not app/device proof.")
        self.evidence = {"schema": "flins-backbone-evidence-v1", "review_status": "approved",
                         **{k: self.game[k] for k in ("game_id", "bundle_id", "marketing_version", "build_number")},
                         "contract_sha256": gate.digest(ROOT / "BACKBONE_CONTRACT.json"),
                         "source_files": {p: gate.digest(self.root / p) for p in ("game/game.json", "fixture.txt")}}
        for group in ("runtime", "backend"):
            self.evidence[group] = {s: {"status": "passed", "test": "fixture.txt", "result": "fixture.txt"}
                                    for s in self.contract[f"required_{group}_scenarios"]}
        self.write_evidence()

    def write_game(self):
        (self.root / "game/game.json").write_text(json.dumps(self.game))

    def write_evidence(self):
        (self.root / "store/backbone_evidence.json").write_text(json.dumps(self.evidence))

    def test_current_fixture_inventory(self):
        self.assertEqual(gate.validate(self.root), [])

    def test_disabling_capability_cannot_bypass_release(self):
        self.game["capabilities"]["golden_eggs"] = False
        self.write_game()
        self.assertIn("required capability disabled or missing: golden_eggs", gate.validate(self.root))

    def test_changed_source_invalidates_evidence(self):
        (self.root / "fixture.txt").write_text("Changed source")
        self.assertIn("backbone evidence stale source: fixture.txt", gate.validate(self.root))

    def test_prior_build_not_current(self):
        self.evidence["build_number"] = 99
        self.write_evidence()
        self.assertIn("backbone evidence stale identity: build_number", gate.validate(self.root))

    def test_missing_scenario_and_unbound_test(self):
        del self.evidence["runtime"]["startup_zero_egg_requests"]
        self.evidence["backend"]["rate_limit"]["test"] = "not-reviewed.txt"
        self.write_evidence()
        errors = gate.validate(self.root)
        self.assertIn("missing runtime evidence: startup_zero_egg_requests", errors)
        self.assertIn("unbound backend rate_limit test", errors)

    def test_no_path_escape(self):
        self.evidence["source_files"]["../outside"] = "0" * 64
        self.write_evidence()
        self.assertIn("unsafe evidence source path", gate.validate(self.root))

    def test_startup_and_unsigned_identity_regressions(self):
        self.game["integrations"]["golden_eggs"].update(startup_network_requests=True,
            private_game_audit_identity="verified_game_player_id")
        self.write_game()
        errors = gate.validate(self.root)
        self.assertIn("Golden Egg contract mismatch: startup_network_requests", errors)
        self.assertIn("Golden Egg contract mismatch: private_game_audit_identity", errors)

    def test_new_revision_invalidates_old_review(self):
        self.evidence["contract_sha256"] = "0" * 64
        self.write_evidence()
        self.assertIn("backbone evidence requires current contract review", gate.validate(self.root))


if __name__ == "__main__":
    unittest.main()

