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
    "godot/scenes/main.tscn",
    "godot/scripts/adventure_session.gd",
    "godot/scripts/input_intent.gd",
    "godot/scripts/fred_save_adapter.gd",
    "godot/tests/run_tests.gd",
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
