#!/usr/bin/env python3
"""Apply Fred's fail-closed event metadata patch to the pinned Game Center source."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


PATCH_VERSION = "fred-gamecenter-events-v1"
TYPE_LINE = '\t\tret["type"] = "post_score";\n'
METADATA_LINES = (
    TYPE_LINE
    + '\t\tret["category"] = category;\n'
    + '\t\tret["score"] = score;\n'
)


def patch_source(path: Path) -> dict[str, object]:
    source = path.read_text(encoding="utf-8")
    if "static UIViewController *godot_game_center_get_root_view_controller()" not in source:
        raise ValueError("scene-based Game Center presentation patch is missing")
    if "[GKLeaderboard submitScore:score" not in source:
        raise ValueError("modern Game Center score API patch is missing")
    if "ERR_FAIL_COND_V([GKScore respondsToSelector" in source:
        raise ValueError("known inverted Game Center score capability guard remains")
    if METADATA_LINES in source:
        changed = False
    else:
        occurrences = source.count(TYPE_LINE)
        if occurrences != 1:
            raise ValueError(f"expected one post_score event preimage, found {occurrences}")
        source = source.replace(TYPE_LINE, METADATA_LINES, 1)
        with path.open("w", encoding="utf-8", newline="\n") as handle:
            handle.write(source)
        changed = True
    validated = path.read_text(encoding="utf-8")
    for required in (
        'ret["type"] = "post_score";',
        'ret["category"] = category;',
        'ret["score"] = score;',
        "[GKLeaderboard submitScore:score",
        "godot_game_center_get_root_view_controller()",
    ):
        if required not in validated:
            raise ValueError(f"patched Game Center source is missing: {required}")
    return {
        "status": "PASS",
        "patch_version": PATCH_VERSION,
        "changed": changed,
        "source": str(path),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    try:
        report = patch_source(args.source)
    except (OSError, ValueError) as exc:
        print(f"IOS_GAMECENTER_SOURCE_PATCH_FAIL {exc}")
        return 1
    print("IOS_GAMECENTER_SOURCE_PATCH " + json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
