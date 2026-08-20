from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "patch_ios_gamecenter_events", ROOT / "tools/patch_ios_gamecenter_events.py"
)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    if not condition:
        raise SystemExit(f"Game Center source patch test failed: {message}")
    checks += 1


def fixture(*, scene_fix: bool = True, modern_score: bool = True, inverted_guard: bool = False) -> str:
    return (
        ("static UIViewController *godot_game_center_get_root_view_controller() {}\n" if scene_fix else "")
        + ("[GKLeaderboard submitScore:score context:0 player:player completionHandler:nil];\n" if modern_score else "")
        + ("ERR_FAIL_COND_V([GKScore respondsToSelector:@selector(reportScores)], ERR_UNAVAILABLE);\n" if inverted_guard else "")
        + "void completion() {\n\t\tret[\"type\"] = \"post_score\";\n}\n"
    )


with tempfile.TemporaryDirectory() as temporary:
    source_path = Path(temporary) / "game_center.mm"
    source_path.write_text(fixture(), encoding="utf-8")
    result = MODULE.patch_source(source_path)
    check(result["status"] == "PASS" and result["changed"] is True, "valid source was not patched")
    patched = source_path.read_text(encoding="utf-8")
    check('ret["category"] = category;' in patched, "leaderboard category metadata missing")
    check('ret["score"] = score;' in patched, "score metadata missing")
    result = MODULE.patch_source(source_path)
    check(result["changed"] is False, "patch is not idempotent")

    for label, payload in (
        ("scene", fixture(scene_fix=False)),
        ("modern score", fixture(modern_score=False)),
        ("inverted guard", fixture(inverted_guard=True)),
        ("ambiguous callback", fixture() + '\t\tret["type"] = "post_score";\n'),
    ):
        source_path.write_text(payload, encoding="utf-8")
        try:
            MODULE.patch_source(source_path)
        except ValueError:
            checks += 1
        else:
            raise SystemExit(f"Game Center source patch test failed: {label} source did not fail closed")

print(f"Game Center source patch tests passed: {checks} checks")
