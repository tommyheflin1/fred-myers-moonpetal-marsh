#!/usr/bin/env python3
"""Declare and verify the generated iOS app's exempt encryption status."""

from __future__ import annotations

import argparse
import json
import plistlib
import sys
from pathlib import Path


EXPORT_KEY = "ITSAppUsesNonExemptEncryption"


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


def prepare_export(export_root: Path) -> dict[str, object]:
    export_root = export_root.resolve()
    if not export_root.is_dir():
        raise ValueError(f"iOS export root is missing: {export_root}")
    candidates = _application_plists(export_root)
    if len(candidates) != 1:
        paths = [str(path.relative_to(export_root)) for path, _ in candidates]
        raise ValueError(f"Expected exactly one application Info.plist; found {len(candidates)}: {paths}")
    path, payload = candidates[0]
    existing = payload.get(EXPORT_KEY)
    if existing is not None and existing is not False:
        raise ValueError(f"Existing {EXPORT_KEY} must be false, found {existing!r}")
    payload[EXPORT_KEY] = False
    path.write_bytes(plistlib.dumps(payload, fmt=plistlib.FMT_XML, sort_keys=False))
    verified = plistlib.loads(path.read_bytes())
    if verified.get(EXPORT_KEY) is not False:
        raise ValueError(f"Generated app plist failed {EXPORT_KEY}=false verification")
    return {
        "status": "PASS",
        "info_plist": str(path),
        "uses_non_exempt_encryption": False,
        "application_plist_count": 1,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--export-root", required=True, type=Path)
    args = parser.parse_args()
    try:
        report = prepare_export(args.export_root)
    except (OSError, UnicodeError, ValueError, plistlib.InvalidFileException) as exc:
        print(f"IOS_EXPORT_COMPLIANCE_FAIL {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
