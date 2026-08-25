#!/usr/bin/env python3
"""Fail-closed static validation for Fred's unsigned iOS preparation boundary."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot"
EXPECTED_CORE_TREE = "288d87420c5694f80c071f00aa71a0b581f9f60c"
DEVELOPMENT_BUNDLE_ID = "com.flinsvault.fredmyers.dev"
PRODUCTION_BUNDLE_ID = "com.flinsvault.fredmyers"
MARKETING_VERSION = "1.0"
BUILD_NUMBER = "4"


def _git(*args: str) -> str:
    result = subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", "-C", str(ROOT), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def _png_size(path: Path) -> tuple[int, int]:
    payload = path.read_bytes()
    if payload[:8] != b"\x89PNG\r\n\x1a\n":
        return (0, 0)
    return struct.unpack(">II", payload[16:24])


def _setting(text: str, key: str) -> str:
    match = re.search(rf'(?m)^{re.escape(key)}="([^"]*)"$', text)
    return match.group(1) if match else ""


def validate(root: Path = ROOT) -> dict[str, object]:
    root = root.resolve()
    project = root / "godot"
    preset = (project / "export_presets.cfg").read_text(encoding="utf-8")
    adapter = (project / "scripts/game_center_adapter.gd").read_text(encoding="utf-8")
    main = (project / "scripts/main.gd").read_text(encoding="utf-8")
    errors: list[str] = []

    required_counts = {
        'name="iOS Unsigned Preparation"': 1,
        'platform="iOS"': 1,
        'export_filter="all_resources"': 2,
        'exclude_filter="tests/**,tools/**,docs/evidence/**"': 2,
        f'application/bundle_identifier="{DEVELOPMENT_BUNDLE_ID}"': 1,
        f'application/short_version="{MARKETING_VERSION}"': 1,
        f'application/version="{BUILD_NUMBER}"': 1,
        'application/app_store_team_id=""': 1,
        "application/targeted_device_family=2": 1,
        'application/min_ios_version="15.0"': 1,
        "application/export_project_only=true": 1,
        "capabilities/game_center=true": 1,
        "plugins/GameCenter=true": 1,
    }
    for fragment, expected_count in required_counts.items():
        if preset.count(fragment) != expected_count:
            errors.append(f"expected {expected_count} preset value(s): {fragment}")

    prohibited = (
        "DEVELOPMENT_TEAM=",
        "PROVISIONING_PROFILE",
        "CODE_SIGN_IDENTITY",
        ".p12",
        ".mobileprovision",
    )
    combined = preset + "\n" + adapter + "\n" + main
    for value in prohibited:
        if value in combined:
            errors.append(f"protected signing material must not appear in source: {value}")

    for leaderboard in (
        "com.flinsvault.fredmyers.adventure_score",
        "com.flinsvault.fredmyers.highest_level",
    ):
        if adapter.count(leaderboard) != 1:
            errors.append(f"permanent Game Center ID missing or duplicated: {leaderboard}")
    if 'Engine.has_singleton("GameCenter")' not in adapter:
        errors.append("native Game Center singleton discovery is missing")
    if "submit_personal_records" not in main:
        errors.append("gameplay completion is not connected to the Game Center adapter")
    if "OFFLINE MARSH BOARD" not in main:
        errors.append("offline leaderboard fallback is missing")

    icon = project / "assets/art/fred-app-icon-v3-platform.png"
    if not icon.is_file() or _png_size(icon) != (1024, 1024):
        errors.append("the 1024x1024 Fred platform icon master is missing")
    core_tree = _git("rev-parse", "HEAD:godot/addons/mobile_game_core")
    if core_tree != EXPECTED_CORE_TREE:
        errors.append(f"Mobile Game Core tree changed: {core_tree}")

    normalized = {
        "build_number": BUILD_NUMBER,
        "core_tree": core_tree,
        "development_bundle_id": DEVELOPMENT_BUNDLE_ID,
        "game_center_leaderboards": [
            "com.flinsvault.fredmyers.adventure_score",
            "com.flinsvault.fredmyers.highest_level",
        ],
        "marketing_version": MARKETING_VERSION,
        "minimum_ios": "15.0",
        "production_bundle_id": PRODUCTION_BUNDLE_ID,
        "targeted_device_family": "iPhone+iPad",
    }
    return {
        "schema": "fred-ios-preparation-v1",
        "status": "PASS" if not errors else "FAIL",
        **normalized,
        "contract_sha256": hashlib.sha256(
            json.dumps(normalized, separators=(",", ":"), sort_keys=True).encode("utf-8")
        ).hexdigest(),
        "errors": sorted(set(errors)),
        "protected_runtime_gates": [
            "macOS Xcode 26 and iOS 26 SDK",
            "bundle identifier availability",
            "Apple team and automatic signing",
            "Game Center records and sandbox authentication",
            "signed archive upload and TestFlight processing",
        ],
    }


def main() -> int:
    try:
        report = validate()
    except (OSError, UnicodeError, subprocess.CalledProcessError) as exc:
        print(f"IOS_PREPARATION_FAIL {exc}", file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
