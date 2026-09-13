from __future__ import annotations

import importlib.util
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
import subprocess

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from release_checkpoint import archive_hash, validate_checkpoint
from audit_process import audit, digest

spec = importlib.util.spec_from_file_location("receipt", ROOT / ".agents/skills/apple-remote-delivery/scripts/apple_receipt_status.py")
receipt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipt)


class ProcessConsistencyTests(unittest.TestCase):
    def payload(self, state="VALID", version="1.0", build="4", expired=False):
        return {"included": [{"type": "preReleaseVersions", "id": "pv", "attributes": {"version": version}}],
                "data": [{"id": "fictional", "attributes": {"version": build, "processingState": state, "expired": expired},
                          "relationships": {"preReleaseVersion": {"data": {"id": "pv"}}}}]}

    def test_processing_is_not_receipt_or_release(self):
        game = {"marketing_version": "1.0", "build_number": 4}
        for state, code in [("VALID", 0), ("PROCESSING", 3), ("FAILED", 2), ("INVALID", 2), (None, 3)]:
            with self.subTest(state=state):
                result, actual = receipt.classify_build(self.payload(state), game)
                self.assertEqual(code, actual)
                self.assertFalse(result["release_authorized"])
                self.assertEqual(state == "VALID", result["processing_verified"])
        for payload in (self.payload(version="2.0"), self.payload(build="5")):
            self.assertEqual(3, receipt.classify_build(payload, game)[1])
        self.assertEqual(2, receipt.classify_build(self.payload(expired=True), game)[1])
        self.assertEqual(3, receipt.classify_build(self.payload(expired=None), game)[1])

    def test_checkpoint_rejects_stale_and_reordered_gates(self):
        expected = {"commit": "a" * 40, "tree": "b" * 40, "game_id": "fictional", "bundle_id": "com.example.game", "version": "1.0", "build": 4}
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp)
            (archive / "binary").write_bytes(b"fictional archive")
            data = dict(expected, gate="archived", archive_sha256=archive_hash(archive))
            validate_checkpoint(data, expected, "upload", archive)
            for field in expected:
                stale = dict(data, **{field: "wrong"})
                with self.subTest(field=field), self.assertRaises(ValueError):
                    validate_checkpoint(stale, expected, "upload", archive)
            with self.assertRaises(ValueError):
                validate_checkpoint(dict(data, gate="upload-command-succeeded"), expected, "upload", archive)
            (archive / "binary").write_bytes(b"changed")
            with self.assertRaises(ValueError):
                validate_checkpoint(data, expected, "upload", archive)

    def test_process_audit_reports_missing_modified_and_bad_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "game").mkdir()
            (root / "game/game.json").write_text(json.dumps(dict.fromkeys(["game_id", "bundle_id", "marketing_version", "build_number", "capabilities", "privacy"])))
            (root / "tool").write_text("one\n")
            (root / "PROCESS_LOCK.json").write_text(json.dumps({"process_version": "test", "files": {"tool": digest(root / "tool")}}))
            self.assertEqual("MATCH", audit(root, root)["status"])
            (root / "tool").write_text("two\n")
            self.assertEqual("reference-lock-stale", audit(root, root)["differences"][0]["reason"])
            (root / "tool").unlink()
            self.assertEqual("MIGRATION_REQUIRED", audit(root, root)["status"])

    def test_canonical_process_lock(self):
        self.assertEqual("MATCH", audit(ROOT)["status"])

    def test_native_game_center_identity_patch_is_mandatory(self):
        builder = (ROOT / "tools/build_ios_gamecenter_plugin.sh").read_text(encoding="utf-8")
        validator = (ROOT / "tools/validate_ios_gamecenter_plugin.py").read_text(encoding="utf-8")
        patch = ROOT / "tools/patches/gamecenter-signed-identity-v1.patch"
        self.assertEqual("6b4a33596a4719538ffef8747d5f84e0f0fcde1156fbb358256974c116f3690c", hashlib.sha256(patch.read_bytes()).hexdigest())
        for marker in ("identity_patch_id=gamecenter-signed-identity-v1", "identity_patch_sha256"):
            self.assertIn(marker, builder)
        for marker in ("IDENTITY_PATCH_ID", "IDENTITY_PATCH_SHA"):
            self.assertIn(marker, validator)

    def test_keychain_patch_is_app_scoped_and_fail_closed(self):
        builder = (ROOT / "tools/build_ios_gamecenter_plugin.sh").read_text(encoding="utf-8")
        patch = (ROOT / "tools/patches/gamecenter-keychain-v1.patch").read_text(encoding="utf-8")
        for marker in ("keychain_patch_id=gamecenter-keychain-v1", "keychain_patch_sha256", 'apply --check "$keychain_patch_file"', "FLINS_IOS_PLUGIN_CACHE"):
            self.assertIn(marker, builder)
        self.assertNotIn("reset --hard", builder)
        for marker in ("bundleIdentifier", "kSecAttrService", "kSecAttrAccount", "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly", "kSecAttrSynchronizable: @NO", "Security.framework", "SecItemCopyMatching", "SecItemUpdate", "SecItemAdd", "SecItemDelete", 'result["found"]', "CFRelease(item)"):
            self.assertIn(marker, patch)
        self.assertNotIn("kSecAttrAccessGroup", patch)
        self.assertNotIn("NSLog", patch)

    def test_checkpoint_cli_sequence_and_source_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "game").mkdir()
            (root / "game/game.json").write_text(json.dumps({"game_id": "fictional", "bundle_id": "com.example.game", "marketing_version": "1.0", "build_number": 1}))
            (root / ".gitignore").write_text("builds/\n")
            def git(*args):
                return subprocess.check_output(["git", "-C", str(root), *args], text=True, stderr=subprocess.STDOUT).strip()
            git("init")
            git("add", ".")
            git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "fixture")
            commit = git("rev-parse", "HEAD")
            def run(action, mode):
                return subprocess.run([sys.executable, str(ROOT / "tools/release_checkpoint.py"), action, "--root", str(root), "--commit", commit, "--mode", mode], capture_output=True, text=True)
            self.assertEqual(0, run("check", "preflight").returncode)
            self.assertNotEqual(0, run("check", "upload").returncode)
            self.assertEqual(0, run("record", "prepared").returncode)
            self.assertEqual(0, run("check", "archive").returncode)
            archive = root / "builds/ios/apple-delivery/1.0-1/fictional.xcarchive"
            archive.mkdir()
            (archive / "binary").write_text("fictional")
            self.assertEqual(0, run("record", "archived").returncode)
            self.assertNotEqual(0, run("check", "preflight").returncode)
            self.assertEqual(0, run("check", "upload").returncode)
            self.assertEqual(0, run("record", "upload-command-succeeded").returncode)
            self.assertNotEqual(0, run("check", "upload").returncode)
            self.assertEqual(0, run("check", "status").returncode)
            (root / "uncommitted").write_text("dirty")
            self.assertNotEqual(0, run("check", "status").returncode)


if __name__ == "__main__":
    unittest.main()

