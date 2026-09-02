#!/usr/bin/env python3
"""Create a clean, exact-commit source bundle without signing or upload authority."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def run(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-c", f"safe.directory={root}", "-C", str(root), *args],
        check=True, capture_output=True, text=True,
    )
    return result.stdout.strip()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--expected-commit", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    output = args.output.resolve()
    expected = args.expected_commit.strip()
    if run(root, "rev-parse", "HEAD") != expected:
        raise SystemExit("Expected commit does not match HEAD")
    if run(root, "status", "--porcelain"):
        raise SystemExit("Worktree must be clean")
    if output.exists():
        raise SystemExit("Refusing to overwrite handoff output")
    output.mkdir(parents=True)
    bundle = output / "game-source.bundle"
    subprocess.run(["git", "-C", str(root), "bundle", "create", str(bundle), "HEAD"], check=True)
    subprocess.run(["git", "bundle", "verify", str(bundle)], check=True, capture_output=True, text=True)
    definition = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
    manifest = {
        "schema": "fresh-game-source-handoff-v1",
        "commit": expected,
        "tree": run(root, "rev-parse", "HEAD^{tree}"),
        "bundle": bundle.name,
        "bundle_sha256": sha256(bundle),
        "game_id": definition["game_id"],
        "bundle_identifier": definition["bundle_id"],
        "marketing_version": definition["marketing_version"],
        "build_number": definition["build_number"],
        "credentials_included": False,
        "signing_authorized": False,
        "upload_authorized": False,
        "public_release_authorized": False,
    }
    (output / "handoff-manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        print(f"HANDOFF_FAIL {error}")
        raise SystemExit(1)
