from __future__ import annotations

import importlib.util
from pathlib import Path


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
check(report["development_bundle_id"] == "com.flinsvault.fredmyers", "active bundle changed")
check(report["production_bundle_id"] == "com.flinsvault.fredmyers", "production bundle changed")
check(report["marketing_version"] == "1.1", "marketing version changed")
check(report["build_number"] == "8", "Build 8 number is not prepared")
check(report["minimum_ios"] == "15.0", "minimum iOS changed")
check(report["targeted_device_family"] == "iPhone+iPad", "device family changed")
check(len(report["game_center_leaderboards"]) == 2, "leaderboard contract changed")
check(len(report["protected_runtime_gates"]) == 5, "runtime gates must remain explicit")
print(f"iOS preparation tests passed: {checks} checks")
