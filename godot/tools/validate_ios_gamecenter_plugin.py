#!/usr/bin/env python3
"""Fail-closed validation of the locally built official Game Center plugin."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


PLUGIN_COMMIT = "fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"
GODOT_TAG = "4.7.1-stable"
PLUGIN_PATCH_ID = "gamecenter-uiwindow-scene-v1"
PLUGIN_PATCH_SHA256 = "bdcc0f6dbdb199c62867c2a7aefc0397cac858113a6f893e047838b188c99ee2"
IDENTITY_PATCH_ID = "gamecenter-signed-identity-v1"
IDENTITY_PATCH_SHA256 = "6b4a33596a4719538ffef8747d5f84e0f0fcde1156fbb358256974c116f3690c"
KEYCHAIN_PATCH_ID = "gamecenter-keychain-v1"
KEYCHAIN_PATCH_SHA256 = "15866e5e26ab29a83299411efe5a126a47782a95f0a04f9e873dc969b08b3fc0"
KEYCHAIN_PATCH_RELATIVE_PATH = Path("tools/patches/gamecenter-keychain-v1.patch")
PATCH_RELATIVE_PATH = Path("tools/patches/gamecenter-uiwindow-scene-v1.patch")
IDENTITY_PATCH_RELATIVE_PATH = Path("tools/patches/gamecenter-signed-identity-v1.patch")
REQUIRED_TARGETS = ("release", "debug")
COMMIT = PLUGIN_COMMIT
TAG = GODOT_TAG
PATCH_ID = PLUGIN_PATCH_ID
PATCH_SHA = PLUGIN_PATCH_SHA256
IDENTITY_PATCH_SHA = IDENTITY_PATCH_SHA256
DESCRIPTOR_LINES = (
    '[config]',
    'name="GameCenter"',
    'binary="gamecenter.xcframework"',
    'initialization="register_gamecenter_types"',
    'deinitialization="unregister_gamecenter_types"',
    'system=["GameKit.framework", "Security.framework"]',
    'capabilities=["gamekit"]',
)


def _tree_manifest(path: Path) -> tuple[list[dict[str, object]], list[str]]:
    files: list[dict[str, object]] = []
    errors: list[str] = []
    for item in sorted(path.rglob("*")):
        if ".symbols" in item.relative_to(path).parts:
            errors.append("Game Center plugin contains Apple-forbidden .symbols paths")
            continue
        if item.is_symlink():
            errors.append(f"symbolic link is not allowed: {item.relative_to(path).as_posix()}")
            continue
        if not item.is_file():
            continue
        relative = item.relative_to(path).as_posix()
        payload = item.read_bytes()
        files.append(
            {
                "path": relative,
                "size": len(payload),
                "sha256": hashlib.sha256(payload).hexdigest(),
            }
        )
    return files, errors


def validate_project(root: Path) -> dict[str, object]:
    root = root.resolve()
    plugin_root = root / "ios" / "plugins" / "gamecenter"
    errors: list[str] = []
    descriptor = plugin_root / "gamecenter.gdip"
    provenance = plugin_root / "PROVENANCE.txt"
    license_path = plugin_root / "LICENSE.godot-ios-plugins.txt"
    preset_path = root / "export_presets.cfg"
    patch_path = root / PATCH_RELATIVE_PATH
    identity_patch_path = root / IDENTITY_PATCH_RELATIVE_PATH
    keychain_patch_path = root / KEYCHAIN_PATCH_RELATIVE_PATH

    for required in (descriptor, provenance, license_path, preset_path, patch_path, identity_patch_path, keychain_patch_path):
        if not required.is_file():
            errors.append(f"required file missing: {required.relative_to(root).as_posix()}")

    if patch_path.is_file():
        patch_sha256 = hashlib.sha256(patch_path.read_bytes()).hexdigest()
        if patch_sha256 != PLUGIN_PATCH_SHA256:
            errors.append("Game Center compatibility patch file hash mismatch")
    if identity_patch_path.is_file():
        identity_patch_sha256 = hashlib.sha256(identity_patch_path.read_bytes()).hexdigest()
        if identity_patch_sha256 != IDENTITY_PATCH_SHA256:
            errors.append("Game Center identity patch hash mismatch")
    if keychain_patch_path.is_file() and hashlib.sha256(keychain_patch_path.read_bytes()).hexdigest() != KEYCHAIN_PATCH_SHA256:
        errors.append("Game Center Keychain patch hash mismatch")

    descriptor_text = descriptor.read_text(encoding="utf-8") if descriptor.is_file() else ""
    required_descriptor_fragments = DESCRIPTOR_LINES[1:]
    for fragment in required_descriptor_fragments:
        if fragment not in descriptor_text:
            errors.append(f"Game Center descriptor missing {fragment}")

    provenance_text = provenance.read_text(encoding="utf-8") if provenance.is_file() else ""
    if f"source_commit={PLUGIN_COMMIT}" not in provenance_text:
        errors.append("Game Center source commit provenance mismatch")
    if f"godot_tag={GODOT_TAG}" not in provenance_text:
        errors.append("Game Center Godot tag provenance mismatch")
    if f"patch_id={PLUGIN_PATCH_ID}" not in provenance_text:
        errors.append("Game Center compatibility patch provenance mismatch")
    if f"patch_sha256={PLUGIN_PATCH_SHA256}" not in provenance_text:
        errors.append("Game Center compatibility patch hash provenance mismatch")
    if f"identity_patch_id={IDENTITY_PATCH_ID}" not in provenance_text:
        errors.append("Game Center provenance identity patch mismatch")
    if f"identity_patch_sha256={IDENTITY_PATCH_SHA256}" not in provenance_text:
        errors.append("Game Center signed-identity patch hash provenance mismatch")
    if f"keychain_patch_id={KEYCHAIN_PATCH_ID}" not in provenance_text or f"keychain_patch_sha256={KEYCHAIN_PATCH_SHA256}" not in provenance_text:
        errors.append("Game Center Keychain patch provenance mismatch")

    for target in REQUIRED_TARGETS:
        framework = plugin_root / f"gamecenter.{target}.xcframework"
        if not framework.is_dir():
            errors.append(f"required xcframework missing: {framework.name}")
            continue
        info = framework / "Info.plist"
        if not info.is_file():
            errors.append(f"xcframework Info.plist missing: {framework.name}")
        libraries = list(framework.rglob("*.a"))
        if len(libraries) < 2:
            errors.append(f"Game Center {target} framework lacks device/simulator contract")

    preset_text = preset_path.read_text(encoding="utf-8") if preset_path.is_file() else ""
    if not re.search(r"(?m)^plugins/GameCenter=true$", preset_text):
        errors.append("iOS export preset must enable plugins/GameCenter=true")
    if not re.search(r"(?m)^capabilities/game_center=true$", preset_text):
        errors.append("iOS export preset must enable Game Center capability")

    files, tree_errors = _tree_manifest(plugin_root) if plugin_root.is_dir() else ([], [])
    errors.extend(tree_errors)
    normalized = {
        "file_count": len(files),
        "files": files,
        "godot_tag": GODOT_TAG,
        "plugin_commit": PLUGIN_COMMIT,
        "plugin_patch_id": PLUGIN_PATCH_ID,
        "plugin_patch_sha256": PLUGIN_PATCH_SHA256,
        "identity_patch_id": IDENTITY_PATCH_ID,
        "identity_patch_sha256": IDENTITY_PATCH_SHA256,
        "keychain_patch_id": KEYCHAIN_PATCH_ID,
        "keychain_patch_sha256": KEYCHAIN_PATCH_SHA256,
    }
    return {
        "status": "PASS" if not errors else "FAIL",
        **normalized,
        "manifest_sha256": hashlib.sha256(
            json.dumps(normalized, separators=(",", ":"), sort_keys=True).encode("utf-8")
        ).hexdigest(),
        "errors": sorted(set(errors)),
    }


def validate(root: Path) -> list[str]:
    return list(validate_project(root)["errors"])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path.cwd())
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()
    try:
        report = validate_project(args.project_root)
    except (OSError, UnicodeError) as exc:
        print(f"IOS_GAMECENTER_PLUGIN_FAIL {exc}", file=sys.stderr)
        return 2
    rendered = json.dumps(report, indent=2, sort_keys=True)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
