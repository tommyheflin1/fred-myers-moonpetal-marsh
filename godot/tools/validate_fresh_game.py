#!/usr/bin/env python3
"""Fail-closed static readiness checks for a generated game."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


REQUIRED = {
    "CORE_VERSION", "ENGINE_PROVENANCE.json", "GENERATION_MANIFEST.json",
    "project.godot", "export_presets.cfg", "game/game.json",
    "docs/EVIDENCE_GATES.md", "docs/SAVE_CONTRACT.md",
    "tools/ci_evidence.py",
    "tools/prepare_source_handoff.py",
    "tools/release-ios", "tools/validate_ios_release_config.py", "tools/verify_live_update_policy.py",
    "tools/prepare_ios_export_compliance.py",
    "tools/ios_release_config.json", "tools/build_ios_gamecenter_plugin.sh",
    "tools/validate_ios_gamecenter_plugin.py",
    "tools/patches/gamecenter-uiwindow-scene-v1.patch",
    ".agents/skills/apple-remote-delivery/SKILL.md",
    ".agents/skills/apple-remote-delivery/scripts/apple_remote_doctor.sh",
    ".agents/skills/apple-remote-delivery/scripts/apple_delivery.sh",
    ".agents/skills/apple-remote-delivery/scripts/apple_api_upload.sh",
    ".agents/skills/apple-remote-delivery/scripts/apple_receipt_status.py",
    ".agents/skills/apple-remote-delivery/references/remote-mac-setup.md",
    ".agents/skills/apple-remote-delivery/references/build-and-upload.md",
    ".agents/skills/apple-remote-delivery/references/troubleshooting.md",
    ".agents/skills/apple-remote-delivery/references/standard-release-process.md",
    "docs/GAME_SERVICES_STANDARD.md",
    ".agents/skills/app-privacy-policy/SKILL.md",
    "tools/privacy_policy.py",
    "tools/audit_process.py", "tools/release_checkpoint.py", "PROCESS_LOCK.json",
    ".agents/skills/shared-build-process/SKILL.md", "docs/SHARED_BUILD_PROCESS.md",
    ".agents/skills/app-store-package/SKILL.md", "tools/store_readiness.py",
    ".agents/skills/golden-egg-game-center-identity/SKILL.md",
    ".agents/skills/golden-egg-game-center-identity/references/identity-contract.md",
    ".agents/skills/mandatory-app-update/SKILL.md",
    ".agents/skills/mandatory-app-update/references/activation-and-recovery.md",
    "addons/mobile_game_core/lifecycle/update_policy_service.gd",
    "addons/mobile_game_core/online/golden_egg_discovery_service.gd",
    "addons/mobile_game_core/online/golden_egg_secure_store.gd",
    "addons/mobile_game_core/online/golden_egg_publication_contract.gd",
    "store/app_store_package.json", "store/screenshots.json",
}
PROHIBITED_SUFFIXES = {".p12", ".mobileprovision", ".jks", ".keystore", ".pem", ".key"}


def validate_definition(value: dict) -> list[str]:
    errors: list[str] = []
    if not re.fullmatch(r"[a-z][a-z0-9-]{2,63}", str(value.get("game_id", ""))):
        errors.append("invalid game_id")
    for key in ("bundle_id", "android_package"):
        if not re.fullmatch(r"[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*){2,}", str(value.get(key, ""))):
            errors.append(f"invalid {key}")
    if value.get("orientation") not in {"portrait", "landscape"}:
        errors.append("invalid orientation")
    if value.get("audience") not in {"general", "family", "children"}:
        errors.append("invalid audience")
    if not isinstance(value.get("build_number"), int) or value.get("build_number", 0) < 1:
        errors.append("invalid build_number")
    return errors


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(root: Path) -> list[str]:
    errors: list[str] = []
    for relative in sorted(REQUIRED):
        if not (root / relative).is_file():
            errors.append(f"missing {relative}")
    if errors:
        return errors
    definition = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
    errors.extend(validate_definition(definition))
    golden = definition.get("integrations", {}).get("golden_eggs", {})
    if golden.get("origin") != "https://theflinsappvaultllc.com" or golden.get("hunt_path") != "/golden-eggs":
        errors.append("Golden Egg authoritative website contract mismatch")
    if definition.get("capabilities", {}).get("golden_eggs") and golden.get("auth_protocol") == "unconfigured":
        errors.append("enabled Golden Eggs require an approved secure auth protocol")
    if definition.get("capabilities", {}).get("golden_eggs") and "ios" in definition.get("platforms", []) and not definition.get("capabilities", {}).get("game_center"):
        errors.append("iOS Golden Eggs require Game Center identity")
    identity_contract = {
        "public_identity_source": "verified_game_center_session",
        "provider_display_name_source": "game_center_reported",
        "private_cross_game_identity": "verified_team_player_id",
        "private_game_audit_identity": "provider_reported_game_player_id",
        "identical_name_distinction": "server_generated_non_sensitive_suffix",
        "offline_linking": "explicit_server_verified_only",
        "public_name_consent_required": True,
        "website_name_entry_allowed": False,
        "activation_trigger": "verified_local_discovery",
        "startup_network_requests": False,
        "core_gameplay_requires_backend": False,
        "game_center_independent": True,
        "failure_mode": "pending_nonblocking_idempotent_retry",
        "anonymous_public_name": "Anonymous",
        "version_enforcement_independent": True,
    }
    for key, expected_value in identity_contract.items():
        if golden.get(key) != expected_value:
            errors.append(f"Golden Egg identity contract mismatch: {key}")
    if golden.get("presentation") != "hidden_in_game_discovery":
        errors.append("Golden Egg presentation must default to hidden in-game discovery")
    if golden.get("normal_navigation_visible") is not False:
        errors.append("Golden Egg normal navigation requires explicit per-app owner review; never generate it by default")
    updates = definition.get("updates", {})
    update_contract = {
        "enabled": False,
        "mode": "mandatory_minimum_build",
        "policy_origin": "https://theflinsappvaultllc.com",
        "policy_path": "/api/app-updates/policy",
        "fail_closed": True,
        "activation_gate": "replacement_build_storefront_verified",
    }
    for key, expected_value in update_contract.items():
        if updates.get(key) != expected_value:
            errors.append(f"mandatory update contract mismatch: {key}")
    if definition.get("content_state") != "placeholder":
        errors.append("fresh game content state must remain placeholder")
    privacy = definition.get("privacy", {})
    if privacy.get("policy_url") != f'https://theflinsappvaultllc.com/{definition["game_id"]}/privacy':
        errors.append("app-specific privacy policy URL mismatch")
    if privacy.get("review_status") != "draft":
        errors.append("fresh game privacy policy must remain owner-review draft")
    core = (root / "CORE_VERSION").read_text(encoding="utf-8").strip()
    provenance = json.loads((root / "ENGINE_PROVENANCE.json").read_text(encoding="utf-8"))
    if core != provenance.get("core_version"):
        errors.append("Core provenance mismatch")
    presets = (root / "export_presets.cfg").read_text(encoding="utf-8")
    expected = [
        f'package/unique_name="{definition["android_package"]}"',
        f'application/bundle_identifier="{definition["bundle_id"]}"',
        f'application/short_version="{definition["marketing_version"]}"',
        f'application/version="{definition["build_number"]}"',
        'application/app_store_team_id=""',
        'package/signed=false',
    ]
    for entry in expected:
        if entry not in presets:
            errors.append(f"export boundary missing {entry}")
    manifest = json.loads((root / "GENERATION_MANIFEST.json").read_text(encoding="utf-8"))
    for relative, expected_hash in manifest.get("files", {}).items():
        path = root / relative
        if not path.is_file() or digest(path) != expected_hash:
            errors.append(f"generation manifest mismatch: {relative}")
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in PROHIBITED_SUFFIXES:
            errors.append(f"credential or signing file prohibited: {path.relative_to(root).as_posix()}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    errors = check(args.root.resolve())
    if errors:
        for error in errors:
            print(f"FRESH_GAME_FAIL {error}")
        return 1
    print("FRESH_GAME_OK static=true signing=false device=false store=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
