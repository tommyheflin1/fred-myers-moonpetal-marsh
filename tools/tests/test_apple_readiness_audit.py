from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
result = subprocess.run(
    [sys.executable, str(ROOT / "tools" / "audit_apple_readiness.py")],
    cwd=ROOT,
    check=True,
    capture_output=True,
    text=True,
)
payload = json.loads(result.stdout)
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    if not condition:
        raise SystemExit(f"Apple readiness audit test failed: {message}")
    checks += 1


check(payload["schema"] == "fred-apple-readiness-audit-v1", "unexpected schema")
check(payload["foundation_status"] == "STRONG_REUSE", "engine reuse is not complete")
check(payload["foundation_controls_passed"] == 10, "foundation pass count changed")
check(payload["foundation_controls_total"] == 10, "foundation denominator changed")
for name, passed in payload["engine_reuse"].items():
    check(passed is True, f"foundation control failed: {name}")

check(
    payload["apple_execution_status"] == "APPLE_PREPARATION_REQUIRED",
    "audit must not imply Apple readiness before protected gates run",
)
check(payload["apple_items_prepared"] >= 4, "local iOS identity and Game Center preparation should be present")
check(payload["apple_items_total"] == 11, "Apple gate denominator changed")
check(payload["apple_readiness"]["platform_icon_master_1024"] is True, "icon master missing")
check(payload["apple_readiness"]["ios_export_preset"] is True, "iOS preset missing")
check(payload["apple_readiness"]["ios_bundle_and_build_identity"] is True, "iOS identity missing")
check(payload["apple_readiness"]["game_center_adapter_and_ids"] is True, "Game Center adapter missing")
for required_gap in (
    "privacy_manifest_audited",
    "xcode_26_ios_26_sdk_validation",
    "simulator_runtime_evidence",
    "physical_iphone_ipad_evidence",
    "signed_archive_uploaded_to_testflight",
):
    check(required_gap in payload["missing_apple_gates"], f"missing gap: {required_gap}")

check("do not submit App Review" in payload["protected_next_action"], "public-release boundary is unclear")
print(f"Apple readiness audit tests passed: {checks} checks")
