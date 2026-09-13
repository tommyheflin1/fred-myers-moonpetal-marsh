#!/usr/bin/env python3
"""Validate the app-owned privacy declaration and stage it into an existing export.

This checks structure, not legal accuracy. Never infer an empty collection inventory
or copy another game's declarations. Store-package privacy review remains required.
"""
from __future__ import annotations

import argparse
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate_manifest(path: Path) -> dict:
    if path.is_symlink():
        raise ValueError("privacy manifest must not be a symbolic link")
    data = plistlib.loads(path.read_bytes())
    if not isinstance(data, dict) or data.get("NSPrivacyTracking") is not False:
        raise ValueError("this no-tracking lane requires NSPrivacyTracking=false")
    if data.get("NSPrivacyTrackingDomains") != []:
        raise ValueError("tracking domains must be an empty array")
    for field in ("NSPrivacyCollectedDataTypes", "NSPrivacyAccessedAPITypes"):
        if not isinstance(data.get(field), list):
            raise ValueError(f"{field} must be an array")
    seen = set()
    for item in data["NSPrivacyCollectedDataTypes"]:
        if not isinstance(item, dict):
            raise ValueError("collected-data entries must be dictionaries")
        name = item.get("NSPrivacyCollectedDataType")
        purposes = item.get("NSPrivacyCollectedDataTypePurposes")
        if not isinstance(name, str) or not name.startswith("NSPrivacyCollectedDataType") or name in seen:
            raise ValueError("collected-data categories must be named and unique")
        seen.add(name)
        if type(item.get("NSPrivacyCollectedDataTypeLinked")) is not bool or item.get("NSPrivacyCollectedDataTypeTracking") is not False:
            raise ValueError("collected-data linkage must be boolean and tracking false")
        if not isinstance(purposes, list) or not purposes or any(not isinstance(p, str) or not p.startswith("NSPrivacyCollectedDataTypePurpose") for p in purposes):
            raise ValueError("collected-data purposes must be explicit")
    seen = set()
    for item in data["NSPrivacyAccessedAPITypes"]:
        if not isinstance(item, dict):
            raise ValueError("accessed-API entries must be dictionaries")
        name = item.get("NSPrivacyAccessedAPIType")
        reasons = item.get("NSPrivacyAccessedAPITypeReasons")
        if not isinstance(name, str) or not name.startswith("NSPrivacyAccessedAPICategory") or name in seen:
            raise ValueError("accessed-API categories must be named and unique")
        seen.add(name)
        if not isinstance(reasons, list) or not reasons or any(not isinstance(r, str) or not re.fullmatch(r"[A-Z0-9]{4}\.[0-9]+", r) for r in reasons):
            raise ValueError("required-reason API declarations must be explicit")
    return data


def stage(root: Path, destination: Path) -> Path:
    source = root / "ios/PrivacyInfo.xcprivacy"
    validate_manifest(source)
    destination = destination.resolve()
    projects = list(destination.glob("*.xcodeproj/project.pbxproj"))
    if len(projects) != 1:
        raise ValueError("expected exactly one exported Xcode project")
    if "PrivacyInfo.xcprivacy" not in projects[0].read_text(encoding="utf-8"):
        raise ValueError("Xcode project does not reference a privacy manifest")
    targets = [p for p in destination.rglob("PrivacyInfo.xcprivacy")
               if not any(part.endswith((".framework", ".xcframework")) for part in p.relative_to(destination).parts)]
    if len(targets) != 1 or targets[0].is_symlink() or not targets[0].resolve().is_relative_to(destination):
        raise ValueError("expected one existing, non-symlink app privacy manifest in export")
    # Replace only the already-referenced generated app manifest, not plugin ones.
    target = targets[0]
    target.write_bytes(source.read_bytes())
    if target.read_bytes() != source.read_bytes():
        raise ValueError("staged privacy manifest does not match app-owned source")
    return target


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--stage", type=Path)
    args = parser.parse_args()
    try:
        validate_manifest(args.root / "ios/PrivacyInfo.xcprivacy")
        if args.stage:
            stage(args.root, args.stage)
    except (OSError, ValueError, TypeError, plistlib.InvalidFileException) as exc:
        print("IOS_PRIVACY_MANIFEST_FAIL", exc)
        return 1
    print("IOS_PRIVACY_MANIFEST_PASS structure_only=true signed_bundle_check_required=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
