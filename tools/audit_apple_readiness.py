from __future__ import annotations

import json
from pathlib import Path
import struct
import subprocess


ROOT = Path(__file__).resolve().parents[1]
APP_VAULT = ROOT.parent
EXPECTED_CORE_TREE = "288d87420c5694f80c071f00aa71a0b581f9f60c"
BUILD_1_RUNTIME_COMMIT = "c8fcf859e4aa7a9c419e88f1bde7f1ecabbdb943"
EXPECTED_BUNDLE_ID = "com.flinsvault.fredmyers"
EXPECTED_IPA_SHA256 = "f5bfb51d8fcad4ab6e8a2320f91d885d541ef2b44296546feb38e36a19e32620"
EXTERNAL_EVIDENCE_PATH = ROOT / "docs" / "APPLE_BUILD_1_EXTERNAL_EVIDENCE.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def read_json(path: Path) -> dict[str, object]:
    if not path.is_file():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", "-C", str(ROOT), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def png_size(path: Path) -> tuple[int, int]:
    payload = path.read_bytes()
    if payload[:8] != b"\x89PNG\r\n\x1a\n":
        return (0, 0)
    return struct.unpack(">II", payload[16:24])


def main() -> None:
    project = read(ROOT / "godot" / "project.godot")
    preset = read(ROOT / "godot" / "export_presets.cfg")
    save_contract = read(ROOT / "docs" / "SAVE_CONTRACT.md")
    identity = read(ROOT / "godot" / "scripts" / "player_identity.gd")
    test_plan = read(ROOT / "docs" / "TEST_BUILD_PLAN.md")
    input_sources = "\n".join(
        read(path)
        for path in (
            ROOT / "godot" / "scripts" / "main.gd",
            ROOT / "godot" / "scripts" / "input_intent.gd",
        )
    )
    engine_documents = (
        APP_VAULT / "FLINS_MOBILE_GAME_ENGINE_ARCHITECTURE.md",
        APP_VAULT / "WINDOWS_TO_IOS_CLOUD_BUILD_AND_RELEASE_GUIDE.md",
        APP_VAULT / "MOBILE_GAME_RELEASE_READINESS_TEMPLATE.md",
    )
    icon_path = ROOT / "godot" / "assets" / "art" / "fred-app-icon-v3-platform.png"
    privacy_manifests = list(ROOT.rglob("PrivacyInfo.xcprivacy"))
    external = read_json(EXTERNAL_EVIDENCE_PATH)
    external_evidence_valid = (
        external.get("schema") == "fred-apple-external-evidence-v1"
        and external.get("runtime_source_commit") == BUILD_1_RUNTIME_COMMIT
        and external.get("bundle_identifier") == EXPECTED_BUNDLE_ID
        and external.get("version") == "1.0"
        and external.get("build") == "1"
        and external.get("ipa_sha256") == EXPECTED_IPA_SHA256
        and external.get("binary_state") == "Validated"
        and external.get("apple_validation_succeeded") is True
        and external.get("apple_upload_succeeded") is True
        and external.get("app_store_version_build_attached") is True
        and external.get("app_review_submitted") is False
        and external.get("public_release_performed") is False
    )
    ios_evidence = [
        path
        for path in (ROOT / "docs").glob("*IOS*EVIDENCE*.md")
        if "PLAN" not in path.name.upper()
    ]
    current_build_number = "2" if 'application/version="2"' in preset else ""
    current_candidate_external_evidence = (
        external_evidence_valid
        and external.get("build") == current_build_number
        and external.get("runtime_source_commit") == git("rev-parse", "HEAD")
    )

    reuse = {
        "independent_game_repository": (ROOT / ".git").exists(),
        "central_engine_documents_available": all(path.is_file() for path in engine_documents),
        "godot_4_7_contract": 'PackedStringArray("4.7", "GL Compatibility")' in project,
        "core_0_5_1_exact_tree": (
            read(ROOT / "godot" / "CORE_VERSION").strip() == "0.5.1"
            and git("rev-parse", "HEAD:godot/addons/mobile_game_core") == EXPECTED_CORE_TREE
        ),
        "deterministic_test_matrix": len(list((ROOT / "godot" / "tests").glob("run_*.gd"))) >= 17,
        "offline_atomic_save_contract": (
            '"schema_version": 1' in save_contract
            and "atomic" in save_contract.lower()
            and "local load" in save_contract.lower()
        ),
        "provider_neutral_apple_identity_boundary": (
            "APPLE_GAME_CENTER" in identity and "SIGN_IN_WITH_APPLE" in identity
        ),
        "device_neutral_input_and_touch_path": (
            "InputEventScreenTouch" in input_sources and "FredInputIntent" in input_sources
        ),
        "separate_platform_and_human_gates": (
            "Platform checks" in test_plan and "Human acceptance" in test_plan
        ),
        "hash_guarded_android_and_desktop_handoffs": (
            (ROOT / "tools" / "validate_physical_android_device.ps1").is_file()
            and (ROOT / "tools" / "launch_desktop_owner_test.ps1").is_file()
        ),
    }

    apple = {
        "platform_icon_master_1024": icon_path.is_file() and png_size(icon_path) == (1024, 1024),
        "ios_export_preset": 'platform="iOS"' in preset,
        "ios_bundle_and_build_identity": (
            "application/bundle_identifier" in preset
            and "application/short_version" in preset
            and "application/version" in preset
        ),
        "game_center_adapter_and_ids": (
            (ROOT / "godot/scripts/game_center_adapter.gd").is_file()
            and "com.flinsvault.fredmyers.adventure_score" in read(
                ROOT / "godot/scripts/game_center_adapter.gd"
            )
            and "com.flinsvault.fredmyers.highest_level" in read(
                ROOT / "godot/scripts/game_center_adapter.gd"
            )
        ),
        "privacy_manifest_audited": bool(privacy_manifests) or (
            external_evidence_valid and external.get("privacy_manifest_audited") is True
        ),
        "unsigned_xcode_handoff_manifest": (
            ROOT / "builds" / "ios-handoff-build-2" / "handoff-manifest.json"
        ).is_file(),
        "xcode_26_ios_26_sdk_validation": bool(ios_evidence) or (
            external_evidence_valid
            and external.get("xcode_26_ios_26_sdk_validation") is True
        ),
        "simulator_runtime_evidence": (
            current_candidate_external_evidence
            and external.get("simulator_runtime_evidence") is True
        ),
        "physical_iphone_ipad_evidence": (
            current_candidate_external_evidence
            and external.get("physical_iphone_ipad_evidence") is True
        ),
        "live_game_center_or_sign_in_with_apple": (
            current_candidate_external_evidence
            and external.get("live_game_center_or_sign_in_with_apple") is True
        ),
        "signed_archive_uploaded_to_testflight": current_candidate_external_evidence,
    }

    missing = [name for name, ready in apple.items() if not ready]
    reuse_passed = sum(reuse.values())
    apple_prepared = sum(apple.values())
    output = {
        "schema": "fred-apple-readiness-audit-v1",
        "candidate_commit": git("rev-parse", "HEAD"),
        "branch": git("branch", "--show-current"),
        "foundation_status": "STRONG_REUSE" if all(reuse.values()) else "REUSE_GAPS",
        "foundation_controls_passed": reuse_passed,
        "foundation_controls_total": len(reuse),
        "apple_execution_status": (
            "READY_FOR_APP_REVIEW_GATE"
            if all(apple.values())
            else (
                "APPLE_TESTFLIGHT_OWNER_ACCEPTANCE_REQUIRED"
                if apple["signed_archive_uploaded_to_testflight"]
                else "APPLE_PREPARATION_REQUIRED"
            )
        ),
        "apple_items_prepared": apple_prepared,
        "apple_items_total": len(apple),
        "engine_reuse": reuse,
        "apple_readiness": apple,
        "external_apple_evidence": {
            "path": str(EXTERNAL_EVIDENCE_PATH.relative_to(ROOT)),
            "valid": external_evidence_valid,
            "runtime_source_commit": external.get("runtime_source_commit"),
            "binary_state": external.get("binary_state"),
            "owner_tester_status": external.get("owner_tester_status"),
            "applies_to_current_candidate": current_candidate_external_evidence,
        },
        "missing_apple_gates": missing,
        "protected_next_action": (
            "Create a clean hash-guarded iOS Build 2 handoff from the committed candidate, then use "
            "the authorized Mac to sign and upload Build 2 without releasing publicly. After Apple "
            "processing, attach only Build 2 to the internal group and repeat physical iPhone audio, "
            "touch, lifecycle, save and live Game Center acceptance."
        ),
    }
    print(json.dumps(output, sort_keys=True))


if __name__ == "__main__":
    main()
