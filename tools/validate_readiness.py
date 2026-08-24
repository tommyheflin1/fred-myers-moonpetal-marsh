from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "README.md",
    "docs/ARCHITECTURE_ASSESSMENT.md",
    "docs/FEATURE_INVENTORY.md",
    "docs/CORE_MIGRATION_MATRIX.md",
    "docs/SAVE_CONTRACT.md",
    "docs/TEST_BUILD_PLAN.md",
    "docs/MIGRATION_ROADMAP.md",
    "docs/EVIDENCE_REPORT.md",
    "godot/CORE_VERSION",
    "godot/project.godot",
    "godot/export_presets.cfg",
    "godot/scenes/main.tscn",
    "godot/scenes/fred_rig.tscn",
    "godot/scripts/adventure_session.gd",
    "godot/scripts/input_intent.gd",
    "godot/scripts/fred_save_adapter.gd",
    "godot/scripts/fred_save_feedback.gd",
    "godot/scripts/fred_visual_state.gd",
    "godot/scripts/level_intensity.gd",
    "godot/scripts/player_identity.gd",
    "godot/scripts/camera_follow.gd",
    "godot/scripts/fred_animation_coordinator.gd",
    "godot/scripts/fred_rig.gd",
    "godot/scripts/marsh_route_layout.gd",
    "godot/scripts/frog_customization.gd",
    "godot/scripts/apple_game_scoring.gd",
    "godot/scripts/game_center_adapter.gd",
    "godot/scripts/predator_depth.gd",
    "godot/scripts/wildlife_animation_rig.gd",
    "godot/scripts/golden_egg_run_state.gd",
    "godot/scripts/golden_egg_discovery_store.gd",
    "godot/scripts/golden_egg_client.gd",
    "godot/tests/run_tests.gd",
    "godot/tests/run_keyboard_regression.gd",
    "godot/tests/run_save_stress.gd",
    "godot/tests/run_save_feedback.gd",
    "godot/tests/run_visual_clarity.gd",
    "godot/tests/run_m2_foundation.gd",
    "godot/tests/run_campaign_one.gd",
    "godot/tests/run_chapter_difficulty.gd",
    "godot/tests/run_camera_follow.gd",
    "godot/tests/run_animation_coordinator.gd",
    "godot/tests/run_fred_rig.gd",
    "godot/tests/run_marsh_visual_uplift.gd",
    "godot/tests/run_android_readiness.gd",
    "godot/tests/run_lives_routes_phone_layout.gd",
    "godot/tests/run_product_uplift.gd",
    "godot/tests/run_customization_expansion.gd",
    "godot/tests/run_game_center_adapter.gd",
    "godot/tests/run_touch_first_controls.gd",
    "godot/tests/run_app_build_2_phone_fixes.gd",
    "godot/tests/run_story_instructions.gd",
    "godot/tests/run_predator_depth.gd",
    "godot/tests/run_water_current_visual.gd",
    "godot/tests/run_golden_egg_level10.gd",
    "godot/docs/evidence/golden-egg-reveal-normal-1280x720.png",
    "godot/docs/evidence/golden-egg-reveal-reduced-960x540.png",
    "docs/M2_PROGRESSION_IDENTITY_FOUNDATION.md",
    "docs/M2_CAMERA_FOLLOW_REPORT.md",
    "docs/M2_LOCOMOTION_ANIMATION_REPORT.md",
    "docs/M2_AUTHORED_FRED_RIG_REPORT.md",
    "docs/M2_MARSH_VISUAL_UPLIFT_REPORT.md",
    "docs/M2_ANDROID_DEVELOPMENT_EXPORT_REPORT.md",
    "docs/M2_LIVES_ROUTES_PHONE_LAYOUT_REPORT.md",
    "docs/M2_PHYSICAL_ANDROID_OWNER_HANDOFF.md",
    "docs/DESKTOP_OWNER_TEST.md",
    "docs/M2_DESKTOP_OWNER_HANDOFF.md",
    "docs/M2_TITLE_ART_UPLIFT.md",
    "docs/M2_APP_ICON_UPLIFT.md",
    "docs/APP_BUILD_1_TEST_REPORT.md",
    "docs/APP_GENERATION_ENGINE_APPLE_READINESS_STATUS.md",
    "docs/IOS_HANDOFF_PLAN.md",
    "docs/APP_STORE_CONNECT_BUILD_1_PACKAGE.md",
    "docs/FRED_PRIVACY_POLICY_DRAFT.md",
    "docs/FRED_SUPPORT_DRAFT.md",
    "docs/IOS_APP_BUILD_1_HANDOFF_REPORT.md",
    "docs/IOS_APP_BUILD_2_HANDOFF_REPORT.md",
    "docs/IOS_APP_BUILD_3_HANDOFF_REPORT.md",
    "docs/IOS_GAME_CENTER_RELEASE_GATE_REPORT.md",
    "docs/M2_PRODUCT_UPLIFT_REPORT.md",
    "docs/M2_TOUCH_FIRST_PHONE_TABLET_CONTROLS.md",
    "docs/M2_HERO_STORY_INSTRUCTIONS.md",
    "docs/M2_CAMPAIGN_ONE_TOUCH_PG.md",
    "docs/M2_FRED_ATTIRE_VISUAL_UPLIFT.md",
    "docs/M2_FRED_RIG_GRAPHICS_REV21_REPORT.md",
    "docs/M2_PREDATOR_DEPTH_TRAVERSAL.md",
    "docs/M2_WATER_CURRENT_VISUAL_REPORT.md",
    "docs/M2_CHARACTER_RIG_REALISM_REPORT.md",
    "docs/M2_ALL_CHARACTER_ARTICULATION_REPORT.md",
    "docs/M2_CHARACTER_VOLUME_RIG_REPORT.md",
    "docs/APP_BUILD_2_PHONE_FIXES_REPORT.md",
    "docs/APP_BUILD_2_GAME_CENTER_ACCESS_REPORT.md",
    "docs/APP_BUILD_2_CUSTOMIZATION_EXPANSION_REPORT.md",
    "docs/FRED_LEVEL10_GOLDEN_EGG_REPORT.md",
    "godot/assets/art/fred-moonpetal-crest-v3.png",
    "godot/assets/art/fred-moonpetal-crest-v3.png.import",
    "godot/assets/art/fred-app-icon-v3-platform.png",
    "godot/assets/art/fred-app-icon-v3-platform.png.import",
    "godot/assets/art/fred-app-icon-v3.ico",
    "godot/assets/art/moonpetal-title-fred-v3.png",
    "godot/assets/art/moonpetal-title-fred-v3.png.import",
    "godot/assets/art/moonpetal-title-fred-v4-sport.png",
    "godot/assets/art/moonpetal-title-fred-v4-sport.png.import",
    "godot/scripts/water_current_visual.gd",
    "godot/tools/capture_attire_fit_evidence.gd",
    "godot/tools/capture_app_store_build_1.gd",
    "godot/tools/review_customization_expansion.gd",
    "godot/docs/evidence/app-build-1-r8-attire-marsh_runner.png",
    "godot/docs/evidence/app-build-1-r8-attire-trail_scout.png",
    "godot/docs/evidence/app-build-1-r8-attire-moon_champion.png",
    "godot/docs/evidence/app-build-1-r8-attire-firefly_hero.png",
    "godot/docs/evidence/app-build-1-r21-attire-marsh_runner.png",
    "godot/docs/evidence/app-build-1-r21-attire-trail_scout.png",
    "godot/docs/evidence/app-build-1-r21-attire-moon_champion.png",
    "godot/docs/evidence/app-build-1-r21-attire-firefly_hero.png",
    "tools/validate_android_export.py",
    "tools/inspect_android_apk.py",
    "tools/validate_physical_android_device.ps1",
    "tools/tests/test_physical_android_preflight.ps1",
    "tools/validate_physical_android_preflight.py",
    "tools/launch_desktop_owner_test.ps1",
    "tools/install_desktop_owner_shortcut.ps1",
    "tools/validate_desktop_owner_handoff.py",
    "tools/audit_apple_readiness.py",
    "tools/tests/test_apple_readiness_audit.py",
    "tools/validate_ios_preparation.py",
    "tools/tests/test_ios_preparation.py",
    "tools/prepare_ios_gamecenter_entitlements.py",
    "tools/prepare_ios_export_compliance.py",
    "tools/tests/test_ios_export_helpers.py",
    "tools/validate_ios_gamecenter_plugin.py",
    "tools/tests/test_ios_gamecenter_plugin.py",
    "tools/patch_ios_gamecenter_events.py",
    "tools/tests/test_patch_ios_gamecenter_events.py",
    "tools/build_ios_gamecenter_plugin.sh",
    "tools/ios_validation_handoff.sh",
    "tools/run_fred_app_build_1_macos.sh",
    "tools/run_fred_app_build_2_macos.sh",
    "tools/run_fred_app_build_3_macos.sh",
    "tools/prepare_ios_handoff.py",
    "tools/validate_app_store_screenshots.py",
]

FIXTURES = {
    "new_game.json", "mid_level_checkpoint.json", "completed_lily_leap.json",
    "interrupted_write_recovery.json", "stale_checkpoint.json", "invalid_save.json",
    "unsupported_save_version.json", "core_version_incompatibility.json",
}

missing = [name for name in REQUIRED if not (ROOT / name).is_file()]
if missing:
    raise SystemExit(f"Missing readiness artifacts: {', '.join(missing)}")

core_version = (ROOT / "godot/CORE_VERSION").read_text(encoding="utf-8").strip()
project = (ROOT / "godot/project.godot").read_text(encoding="utf-8")
if core_version != "0.5.1":
    raise SystemExit(f"Unexpected Core pin: {core_version}")
if 'PackedStringArray("4.7", "GL Compatibility")' not in project:
    raise SystemExit("Godot 4.7 GL Compatibility declaration is missing")
if 'run/main_scene="res://scenes/main.tscn"' not in project:
    raise SystemExit("M1 main scene is not configured")

fixture_dir = ROOT / "godot" / "tests" / "fixtures"
actual_fixtures = {path.name for path in fixture_dir.glob("*.json")}
if actual_fixtures != FIXTURES:
    raise SystemExit(f"Unexpected save fixtures: {sorted(actual_fixtures ^ FIXTURES)}")
for fixture in fixture_dir.glob("*.json"):
    import json
    json.loads(fixture.read_text(encoding="utf-8"))

core_root = ROOT / "godot" / "addons" / "mobile_game_core"
core_files = sorted(path for path in core_root.rglob("*") if path.is_file())
if len(core_files) != 29:
    raise SystemExit(f"Vendored Core inventory changed: {len(core_files)} files")

readme = (ROOT / "README.md").read_text(encoding="utf-8")
for link in re.findall(r"\[[^]]+\]\(([^)]+)\)", readme):
    if "://" not in link and not (ROOT / link).is_file():
        raise SystemExit(f"Broken README link: {link}")

print(f"Readiness validation passed: {len(REQUIRED)} artifacts, {len(FIXTURES)} fixtures, Core {core_version}, Godot 4.7")
