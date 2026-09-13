#!/usr/bin/env python3
"""Apply an explicitly reviewed encryption declaration to an iOS export."""

from __future__ import annotations

import argparse
import json
import plistlib
import sys
from pathlib import Path


EXPORT_KEY = "ITSAppUsesNonExemptEncryption"
FORBIDDEN_USAGE_KEYS = (
    "NSCameraUsageDescription",
    "NSMicrophoneUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSPhotoLibraryAddUsageDescription",
)


def _application_plists(export_root: Path) -> list[tuple[Path, dict]]:
    candidates: list[tuple[Path, dict]] = []
    for path in sorted(export_root.rglob("*.plist")):
        if path.is_symlink() or not path.is_file():
            continue
        try:
            payload = plistlib.loads(path.read_bytes())
        except (OSError, ValueError, plistlib.InvalidFileException):
            continue
        if isinstance(payload, dict) and payload.get("CFBundlePackageType") == "APPL":
            candidates.append((path, payload))
    return candidates


def prepare_export(export_root: Path, uses_non_exempt_encryption: bool) -> dict[str, object]:
    export_root = export_root.resolve()
    if not export_root.is_dir():
        raise ValueError(f"iOS export root is missing: {export_root}")

    candidates = _application_plists(export_root)
    if len(candidates) != 1:
        paths = [str(path.relative_to(export_root)) for path, _ in candidates]
        raise ValueError(
            f"Expected exactly one application Info.plist; found {len(candidates)}: {paths}"
        )

    path, payload = candidates[0]
    existing = payload.get(EXPORT_KEY)
    if existing is not None and existing is not uses_non_exempt_encryption:
        raise ValueError(
            f"Existing {EXPORT_KEY} conflicts with reviewed value "
            f"{uses_non_exempt_encryption!r}: found {existing!r}"
        )

    removed_usage_keys = [key for key in FORBIDDEN_USAGE_KEYS if key in payload]
    for key in removed_usage_keys:
        payload.pop(key)
    payload[EXPORT_KEY] = uses_non_exempt_encryption
    path.write_bytes(plistlib.dumps(payload, fmt=plistlib.FMT_XML, sort_keys=False))
    verified = plistlib.loads(path.read_bytes())
    if verified.get(EXPORT_KEY) is not uses_non_exempt_encryption:
        raise ValueError(f"Generated app plist failed {EXPORT_KEY} verification")
    remaining_usage_keys = [key for key in FORBIDDEN_USAGE_KEYS if key in verified]
    if remaining_usage_keys:
        raise ValueError(
            "Generated app plist retained prohibited privacy usage keys: "
            + ", ".join(remaining_usage_keys)
        )

    return {
        "status": "PASS",
        "export_root": str(export_root),
        "info_plist": str(path),
        "uses_non_exempt_encryption": uses_non_exempt_encryption,
        "removed_privacy_usage_keys": removed_usage_keys,
        "application_plist_count": 1,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--export-root", required=True, type=Path)
    parser.add_argument(
        "--uses-non-exempt-encryption",
        required=True,
        choices=("true", "false"),
        help="Reviewed App Store export-compliance declaration; never inferred by this tool.",
    )
    args = parser.parse_args()
    try:
        report = prepare_export(
            args.export_root,
            args.uses_non_exempt_encryption == "true",
        )
    except (OSError, UnicodeError, ValueError, plistlib.InvalidFileException) as exc:
        print(f"IOS_EXPORT_COMPLIANCE_FAIL {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
