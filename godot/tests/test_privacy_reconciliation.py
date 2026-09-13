"""Fred privacy regressions. Export fixtures are fictional, not signed evidence."""
import importlib.util
import json
import plistlib
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("privacy_validator", ROOT / "tools/validate_ios_privacy_manifest.py")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class PrivacyReconciliationTests(unittest.TestCase):
    def test_manifest_matches_identity_and_discovery_collection(self):
        data = validator.validate_manifest(ROOT / "ios/PrivacyInfo.xcprivacy")
        entries = data["NSPrivacyCollectedDataTypes"]
        self.assertEqual({e["NSPrivacyCollectedDataType"] for e in entries}, {
            "NSPrivacyCollectedDataTypeUserID", "NSPrivacyCollectedDataTypeGameplayContent"})
        for entry in entries:
            self.assertIs(entry["NSPrivacyCollectedDataTypeLinked"], True)
            self.assertIs(entry["NSPrivacyCollectedDataTypeTracking"], False)
            self.assertEqual(entry["NSPrivacyCollectedDataTypePurposes"],
                             ["NSPrivacyCollectedDataTypePurposeAppFunctionality"])

    def test_required_reasons_are_explicit_and_minimal(self):
        data = validator.validate_manifest(ROOT / "ios/PrivacyInfo.xcprivacy")
        self.assertEqual({e["NSPrivacyAccessedAPIType"]: e["NSPrivacyAccessedAPITypeReasons"]
                          for e in data["NSPrivacyAccessedAPITypes"]}, {
            "NSPrivacyAccessedAPICategoryFileTimestamp": ["C617.1"],
            "NSPrivacyAccessedAPICategorySystemBootTime": ["35F9.1"],
            "NSPrivacyAccessedAPICategoryDiskSpace": ["E174.1"]})

    def test_inventory_records_server_identity_and_keychain_retention(self):
        privacy = json.loads((ROOT / "game/game.json").read_text(encoding="utf-8"))["privacy"]
        self.assertEqual(privacy["policy_version"], "fred-myers-2026-09-12-v3")
        self.assertTrue(privacy["persistent_local_data"])
        self.assertIn("provider-reported", " ".join(privacy["server_data"]))
        self.assertIn("may survive app deletion", " ".join(privacy["local_data"]))
        self.assertIn("No company website request", " ".join(privacy["server_data"]))
        self.assertIn("local-only finds are never automatically submitted", " ".join(privacy["local_data"]))

    def test_stage_preserves_plugin_manifest(self):
        with tempfile.TemporaryDirectory(prefix="fred-privacy-test-") as tmp:
            export = Path(tmp)
            project = export / "FictionalFred.xcodeproj/project.pbxproj"
            project.parent.mkdir()
            project.write_text("/* fictional reference PrivacyInfo.xcprivacy */", encoding="utf-8")
            app_manifest = export / "FictionalFred/PrivacyInfo.xcprivacy"
            app_manifest.parent.mkdir()
            app_manifest.write_bytes(plistlib.dumps({}))
            plugin = export / "Fictional.framework/PrivacyInfo.xcprivacy"
            plugin.parent.mkdir()
            original = plistlib.dumps({"fixture": "plugin-owned"})
            plugin.write_bytes(original)
            self.assertEqual(validator.stage(ROOT, export), app_manifest)
            self.assertEqual(app_manifest.read_bytes(), (ROOT / "ios/PrivacyInfo.xcprivacy").read_bytes())
            self.assertEqual(plugin.read_bytes(), original)

    def test_ambiguous_export_fails_without_changes(self):
        with tempfile.TemporaryDirectory(prefix="fred-privacy-test-") as tmp:
            export = Path(tmp)
            project = export / "FictionalFred.xcodeproj/project.pbxproj"
            project.parent.mkdir()
            project.write_text("PrivacyInfo.xcprivacy", encoding="utf-8")
            for folder in ("First", "Second"):
                path = export / folder / "PrivacyInfo.xcprivacy"
                path.parent.mkdir()
                path.write_bytes(plistlib.dumps({}))
            with self.assertRaisesRegex(ValueError, "expected one existing"):
                validator.stage(ROOT, export)
            self.assertEqual(plistlib.loads((export / "First/PrivacyInfo.xcprivacy").read_bytes()), {})


if __name__ == "__main__":
    unittest.main()
