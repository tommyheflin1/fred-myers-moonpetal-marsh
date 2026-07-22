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
]

missing = [name for name in REQUIRED if not (ROOT / name).is_file()]
if missing:
    raise SystemExit(f"Missing readiness artifacts: {', '.join(missing)}")

core_version = (ROOT / "godot/CORE_VERSION").read_text(encoding="utf-8").strip()
project = (ROOT / "godot/project.godot").read_text(encoding="utf-8")
if core_version != "0.5.1":
    raise SystemExit(f"Unexpected Core pin: {core_version}")
if 'PackedStringArray("4.7", "GL Compatibility")' not in project:
    raise SystemExit("Godot 4.7 GL Compatibility declaration is missing")

readme = (ROOT / "README.md").read_text(encoding="utf-8")
for link in re.findall(r"\[[^]]+\]\(([^)]+)\)", readme):
    if "://" not in link and not (ROOT / link).is_file():
        raise SystemExit(f"Broken README link: {link}")

print(f"Readiness validation passed: {len(REQUIRED)} artifacts, Core {core_version}, Godot 4.7")

