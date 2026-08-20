#!/usr/bin/env python3
"""Add and verify the Game Center entitlement on a generated Xcode project."""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import sys
from pathlib import Path


SETTING = "CODE_SIGN_ENTITLEMENTS"
ENTITLEMENT_KEY = "com.apple.developer.game-center"


def prepare_project(project: Path) -> dict[str, object]:
    project = project.resolve()
    pbxproj = project / "project.pbxproj"
    if project.suffix != ".xcodeproj" or not pbxproj.is_file():
        raise ValueError(f"Xcode project is missing project.pbxproj: {project}")
    entitlement_name = f"{project.stem}.entitlements"
    source = pbxproj.read_text(encoding="utf-8")
    bundle_lines = list(re.finditer(r"(?m)^(?P<indent>\s*)PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;\s*$", source))
    if not bundle_lines:
        raise ValueError("Generated Xcode target has no PRODUCT_BUNDLE_IDENTIFIER setting")
    existing = re.findall(rf"(?m)^\s*{SETTING}\s*=\s*([^;]+);\s*$", source)
    normalized = [value.strip().strip('"') for value in existing]
    allowed = {entitlement_name, f"{project.stem}/{entitlement_name}"}
    unexpected = [value for value in normalized if value not in allowed]
    if unexpected:
        raise ValueError(f"Unexpected existing {SETTING} value(s): {sorted(set(unexpected))}")
    if len(set(normalized)) > 1:
        raise ValueError(f"Conflicting existing {SETTING} value(s): {sorted(set(normalized))}")
    if not existing:
        source, inserted = re.subn(
            r"(?m)^(?P<indent>\s*)(?P<bundle>PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;\s*)$",
            rf"\g<indent>{SETTING} = {entitlement_name};\n\g<indent>\g<bundle>",
            source,
        )
        if inserted != len(bundle_lines):
            raise ValueError(f"Expected to patch {len(bundle_lines)} configurations; patched {inserted}")
        pbxproj.write_text(source, encoding="utf-8")
    elif len(existing) != len(bundle_lines):
        raise ValueError(f"Expected {len(bundle_lines)} {SETTING} settings; found {len(existing)}")
    entitlement_reference = normalized[0] if normalized else entitlement_name
    entitlement_path = project.parent / entitlement_reference
    entitlement_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {ENTITLEMENT_KEY: True}
    entitlement_path.write_bytes(plistlib.dumps(payload, fmt=plistlib.FMT_XML, sort_keys=True))
    if plistlib.loads(entitlement_path.read_bytes()) != payload:
        raise ValueError("Game Center entitlement failed round-trip validation")
    return {
        "status": "PASS",
        "project": str(project),
        "entitlements": str(entitlement_path),
        "configuration_count": len(bundle_lines),
        "game_center": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xcode-project", required=True, type=Path)
    args = parser.parse_args()
    try:
        report = prepare_project(args.xcode_project)
    except (OSError, UnicodeError, ValueError, plistlib.InvalidFileException) as exc:
        print(f"IOS_GAMECENTER_ENTITLEMENTS_FAIL {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
