from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("validate_ios_gamecenter_plugin", ROOT / "tools/validate_ios_gamecenter_plugin.py")
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    if not condition:
        raise SystemExit(f"Game Center plugin validator test failed: {message}")
    checks += 1


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    plugin = root / "godot/ios/plugins/gamecenter"
    plugin.mkdir(parents=True)
    (plugin / "gamecenter.gdip").write_text(
        '[config]\nname="GameCenter"\nbinary="gamecenter.xcframework"\ninitialization="register_gamecenter_types"\n'
        '[dependencies]\nsystem=["GameKit.framework"]\ncapabilities=["gamekit"]\n', encoding="utf-8"
    )
    (plugin / "PROVENANCE.txt").write_text(
        f"source_commit={MODULE.PLUGIN_COMMIT}\n"
        f"presentation_patch_commit={MODULE.PRESENTATION_PATCH_COMMIT}\n"
        f"score_patch_commit={MODULE.SCORE_PATCH_COMMIT}\n"
        f"fred_event_patch_version={MODULE.FRED_EVENT_PATCH_VERSION}\n"
        f"godot_tag={MODULE.GODOT_TAG}\n",
        encoding="utf-8",
    )
    (plugin / "LICENSE.godot-ios-plugins.txt").write_text("fixture", encoding="utf-8")
    for target in MODULE.REQUIRED_TARGETS:
        framework = plugin / f"gamecenter.{target}.xcframework"
        (framework / "ios-arm64").mkdir(parents=True)
        (framework / "ios-simulator").mkdir()
        (framework / "Info.plist").write_text("fixture", encoding="utf-8")
        (framework / "ios-arm64/libgamecenter.a").write_bytes(b"device")
        (framework / "ios-simulator/libgamecenter.a").write_bytes(b"simulator")
    report = MODULE.validate_project(root)
    check(report["status"] == "PASS", str(report["errors"]))
    check(len(report["files"]) >= 9, "complete fixture inventory was not hashed")
    check(report["score_patch_commit"] == MODULE.SCORE_PATCH_COMMIT, "score patch provenance was not normalized")
    original_provenance = (plugin / "PROVENANCE.txt").read_text(encoding="utf-8")
    (plugin / "PROVENANCE.txt").write_text(
        original_provenance.replace(MODULE.SCORE_PATCH_COMMIT, "0" * 40), encoding="utf-8"
    )
    report = MODULE.validate_project(root)
    check(report["status"] == "FAIL", "wrong score patch provenance did not fail closed")
    check(any("score patch provenance mismatch" in error for error in report["errors"]), "wrong patch reason missing")
    (plugin / "PROVENANCE.txt").write_text(original_provenance, encoding="utf-8")
    (plugin / "gamecenter.debug.xcframework/ios-simulator/libgamecenter.a").unlink()
    report = MODULE.validate_project(root)
    check(report["status"] == "FAIL", "missing simulator library did not fail closed")
    check(any("lacks device/simulator" in error for error in report["errors"]), "missing library reason was not reported")

print(f"Game Center plugin validator tests passed: {checks} checks")
