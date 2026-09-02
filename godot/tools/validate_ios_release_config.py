#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    game = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
    config = json.loads((root / "tools/ios_release_config.json").read_text(encoding="utf-8"))
    if config.get("bundle_id") != game.get("bundle_id"):
        errors.append("release config bundle ID differs from game definition")
    patterns = {
        "app_store_app_id": r"[0-9]{6,20}",
        "team_id": r"[A-Z0-9]{10}",
        "api_key_id": r"[A-Z0-9]{10}",
        "api_issuer_id": r"[0-9a-fA-F-]{36}",
    }
    for field, pattern in patterns.items():
        if not re.fullmatch(pattern, str(config.get(field, ""))):
            errors.append(f"release config {field} is unset or invalid")
    key_path = str(config.get("api_key_path", ""))
    if not key_path.startswith("~/") or not key_path.endswith(".p8"):
        errors.append("API private key path must reference a .p8 outside the repository")
    if game.get("capabilities", {}).get("game_center"):
        gc = config.get("game_center", {})
        if not re.fullmatch(r"[0-9a-f]{40}", str(gc.get("plugin_commit", ""))):
            errors.append("Game Center plugin commit is not pinned")
        if not re.fullmatch(r"[0-9a-f]{64}", str(gc.get("patch_sha256", ""))):
            errors.append("Game Center compatibility patch hash is not pinned")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    root = parser.parse_args().root.resolve()
    errors = validate(root)
    if errors:
        for error in errors: print(f"IOS_RELEASE_CONFIG_FAIL {error}")
        return 1
    print("IOS_RELEASE_CONFIG_PASS identity=exact credentials=external")
    return 0


if __name__ == "__main__": raise SystemExit(main())
