#!/usr/bin/env python3
"""Validate an exact generated iOS .app bundle without exposing its contents."""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
from pathlib import Path


FORBIDDEN_PARTS = {".symbols", "tests", "tools", "docs", "store", "art-source", "release-evidence"}
SECRET_SUFFIXES = {".p8", ".p12", ".pem", ".key", ".mobileprovision", ".jks", ".keystore"}
SECRET_NAMES = {".env", "credentials.json", "secrets.json"}


def _tree_digest(app: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    count = 0
    for path in sorted(item for item in app.rglob("*") if item.is_file() and not item.is_symlink()):
        relative = path.relative_to(app).as_posix()
        digest.update(relative.encode("utf-8") + b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
        count += 1
    return digest.hexdigest(), count


def scan(project_root: Path, app: Path, stage: str) -> dict[str, object]:
    project_root = project_root.resolve()
    app = app.resolve()
    errors: list[str] = []
    game = json.loads((project_root / "game/game.json").read_text(encoding="utf-8"))
    config = json.loads((project_root / "tools/ios_release_config.json").read_text(encoding="utf-8"))
    if not app.is_dir() or app.suffix != ".app":
        raise ValueError(f"iOS application bundle is missing or invalid: {app}")

    plist_path = app / "Info.plist"
    try:
        info = plistlib.loads(plist_path.read_bytes())
    except (OSError, ValueError, plistlib.InvalidFileException) as exc:
        raise ValueError(f"invalid application Info.plist: {exc}") from exc
    expected = {
        "CFBundleIdentifier": game["bundle_id"],
        "CFBundleShortVersionString": game["marketing_version"],
        "CFBundleVersion": str(game["build_number"]),
    }
    for key, value in expected.items():
        if str(info.get(key, "")) != str(value):
            errors.append(f"{key} mismatch")
    declaration = config.get("uses_non_exempt_encryption")
    if not isinstance(declaration, bool):
        errors.append("export encryption declaration is not owner-reviewed")
    elif info.get("ITSAppUsesNonExemptEncryption") is not declaration:
        errors.append("ITSAppUsesNonExemptEncryption mismatch")

    privacy = app / "PrivacyInfo.xcprivacy"
    try:
        privacy_data = plistlib.loads(privacy.read_bytes())
        if privacy_data.get("NSPrivacyTracking") is not False:
            errors.append("privacy manifest tracking must be false")
    except (OSError, ValueError, plistlib.InvalidFileException) as exc:
        errors.append(f"invalid or missing PrivacyInfo.xcprivacy: {exc}")

    prohibited: list[str] = []
    symlinks: list[str] = []
    for path in app.rglob("*"):
        relative = path.relative_to(app).as_posix()
        lower_parts = {part.lower() for part in path.relative_to(app).parts}
        if path.is_symlink():
            symlinks.append(relative)
        # Xcode embeds this public provisioning envelope in a signed app.
        # Do not allow arbitrary profile files, nested profiles or unsigned copies.
        signed_profile = stage == "signed" and relative == "embedded.mobileprovision" and not path.is_symlink()
        if path.is_file() and (lower_parts & FORBIDDEN_PARTS or (path.suffix.lower() in SECRET_SUFFIXES and not signed_profile) or path.name.lower() in SECRET_NAMES):
            prohibited.append(relative)
    if prohibited:
        errors.append("prohibited bundle paths found")
    if symlinks:
        errors.append("symbolic links found in application bundle")

    signature_exists = (app / "_CodeSignature/CodeResources").is_file()
    if stage == "unsigned" and signature_exists:
        errors.append("unsigned bundle unexpectedly contains a code signature")
    if stage == "signed" and not signature_exists:
        errors.append("signed bundle is missing _CodeSignature/CodeResources")
    tree_sha256, file_count = _tree_digest(app)
    return {
        "status": "PASS" if not errors else "FAIL",
        "stage": stage,
        "errors": errors,
        "bundle_id": info.get("CFBundleIdentifier"),
        "marketing_version": info.get("CFBundleShortVersionString"),
        "build_number": str(info.get("CFBundleVersion", "")),
        "uses_non_exempt_encryption": info.get("ITSAppUsesNonExemptEncryption"),
        "privacy_manifest_present": privacy.is_file(),
        "signature_marker_present": signature_exists,
        "prohibited_paths": sorted(prohibited),
        "symbolic_links": sorted(symlinks),
        "file_count": file_count,
        "tree_sha256": tree_sha256,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True, type=Path)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--stage", required=True, choices=("unsigned", "signed"))
    args = parser.parse_args()
    try:
        report = scan(args.project_root, args.app, args.stage)
    except (OSError, UnicodeError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print("IOS_APP_BUNDLE_SCAN_FAIL", exc)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
