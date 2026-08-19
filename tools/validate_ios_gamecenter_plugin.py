#!/usr/bin/env python3
"""Fail-closed validation of Fred's locally built official Game Center plugin."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN_COMMIT = "fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"
GODOT_TAG = "4.7.1-stable"
REQUIRED_TARGETS = ("release", "debug")


def validate_project(root: Path = ROOT) -> dict[str, object]:
    root = root.resolve()
    plugin_root = root / "godot/ios/plugins/gamecenter"
    errors: list[str] = []
    descriptor = plugin_root / "gamecenter.gdip"
    provenance = plugin_root / "PROVENANCE.txt"
    license_path = plugin_root / "LICENSE.godot-ios-plugins.txt"
    for required in (descriptor, provenance, license_path):
        if not required.is_file():
            errors.append(f"required file missing: {required.relative_to(root).as_posix()}")
    descriptor_text = descriptor.read_text(encoding="utf-8") if descriptor.is_file() else ""
    for fragment in (
        'name="GameCenter"',
        'binary="gamecenter.xcframework"',
        'initialization="register_gamecenter_types"',
        'system=["GameKit.framework"]',
        'capabilities=["gamekit"]',
    ):
        if fragment not in descriptor_text:
            errors.append(f"Game Center descriptor missing: {fragment}")
    provenance_text = provenance.read_text(encoding="utf-8") if provenance.is_file() else ""
    if f"source_commit={PLUGIN_COMMIT}" not in provenance_text:
        errors.append("Game Center source commit provenance mismatch")
    if f"godot_tag={GODOT_TAG}" not in provenance_text:
        errors.append("Game Center Godot tag provenance mismatch")
    for target in REQUIRED_TARGETS:
        framework = plugin_root / f"gamecenter.{target}.xcframework"
        if not framework.is_dir():
            errors.append(f"required xcframework missing: {framework.name}")
            continue
        if not (framework / "Info.plist").is_file():
            errors.append(f"xcframework Info.plist missing: {framework.name}")
        if len(list(framework.rglob("*.a"))) < 2:
            errors.append(f"xcframework lacks device/simulator libraries: {framework.name}")
    files: list[dict[str, object]] = []
    if plugin_root.is_dir():
        for path in sorted(plugin_root.rglob("*")):
            if path.is_symlink():
                errors.append(f"symbolic link is not allowed: {path.relative_to(plugin_root).as_posix()}")
            elif path.is_file():
                payload = path.read_bytes()
                files.append({
                    "path": path.relative_to(plugin_root).as_posix(),
                    "size": len(payload),
                    "sha256": hashlib.sha256(payload).hexdigest(),
                })
    normalized = {"files": files, "godot_tag": GODOT_TAG, "plugin_commit": PLUGIN_COMMIT}
    return {
        "status": "PASS" if not errors else "FAIL",
        **normalized,
        "manifest_sha256": hashlib.sha256(json.dumps(normalized, separators=(",", ":"), sort_keys=True).encode()).hexdigest(),
        "errors": sorted(set(errors)),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        report = validate_project(args.project_root)
    except (OSError, UnicodeError) as exc:
        print(f"IOS_GAMECENTER_PLUGIN_FAIL {exc}", file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
