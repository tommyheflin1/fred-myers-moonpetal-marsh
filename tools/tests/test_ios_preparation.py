from __future__ import annotations

import importlib.util
import configparser
import fnmatch
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "validate_ios_preparation", ROOT / "tools/validate_ios_preparation.py"
)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

report = MODULE.validate(ROOT)
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    if not condition:
        raise SystemExit(f"iOS preparation test failed: {message}")
    checks += 1


check(report["schema"] == "fred-ios-preparation-v1", "unexpected schema")
check(report["status"] == "PASS", str(report["errors"]))
with patch.object(MODULE, "_git", return_value="0" * 40):
    drifted = MODULE.validate(ROOT)
check(drifted["status"] == "FAIL", "unreviewed Core drift must remain blocked")
check(any("Mobile Game Core tree changed" in error for error in drifted["errors"]),
      "Core drift must retain its explicit diagnostic")
check(report["development_bundle_id"] == "com.flinsvault.fredmyers", "active bundle changed")
check(report["production_bundle_id"] == "com.flinsvault.fredmyers", "production bundle changed")
check(report["marketing_version"] == "1.1", "marketing version changed")
check(report["build_number"] == "11", "Build 11 number is not prepared")
check(report["minimum_ios"] == "15.0", "minimum iOS changed")
check(report["targeted_device_family"] == "iPhone+iPad", "device family changed")
check(len(report["game_center_leaderboards"]) == 2, "leaderboard contract changed")
check(len(report["protected_runtime_gates"]) == 5, "runtime gates must remain explicit")
presets = configparser.ConfigParser(interpolation=None)
presets.read(ROOT / "godot/export_presets.cfg", encoding="utf-8")
for section in ("preset.0", "preset.1"):
    exclusions = presets[section]["exclude_filter"].strip('"').split(",")
    for internal_file in (
        "tests/test_scene.gd", "tools/private_report.json", "docs/evidence/account.png",
        "builds/reveal-boundary-review/egg-reveal.png", "store/screenshots.json",
        "governance/asset_registry.json", ".agents/skills/release/SKILL.md",
        "assets/store/screenshots/iphone.png",
    ):
        check(any(fnmatch.fnmatchcase(internal_file, pattern) for pattern in exclusions),
              f"{section} leaks {internal_file}")
    for required_file in (
        "assets/security/update-policy-public.pub", "game/game.json",
        "scripts/golden_egg_art.gd", "assets/art/fred-app-icon-v3-platform.png",
    ):
        check(not any(fnmatch.fnmatchcase(required_file, pattern) for pattern in exclusions),
              f"{section} excludes runtime resource {required_file}")
print(f"iOS preparation tests passed: {checks} checks")
