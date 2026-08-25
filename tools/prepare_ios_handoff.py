#!/usr/bin/env python3
"""Create a clean, hash-guarded Fred App Build 4 macOS handoff bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run(*args: str) -> str:
    result = subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", "-C", str(ROOT), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-commit", required=True)
    parser.add_argument("--output", type=Path, default=ROOT / "builds/ios-handoff-build-4")
    args = parser.parse_args()
    expected = args.expected_commit.strip()
    if run("rev-parse", "HEAD") != expected:
        raise SystemExit("Expected commit does not match HEAD.")
    if run("status", "--porcelain"):
        raise SystemExit("Worktree must be clean before creating the iOS handoff.")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    bundle = output / "fred-myers-app-build-4.bundle"
    wrapper = output / "RUN-FRED-APP-BUILD-4.command"
    manifest_path = output / "handoff-manifest.json"
    for path in (bundle, wrapper, manifest_path):
        if path.exists():
            raise SystemExit(f"Refusing to overwrite an existing handoff artifact: {path}")
    subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", "-C", str(ROOT), "bundle", "create", str(bundle), "HEAD"],
        check=True,
    )
    subprocess.run(["git", "bundle", "verify", str(bundle)], check=True, capture_output=True, text=True)
    bundle_sha = sha256(bundle)
    wrapper.write_text(
        """#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
EXPECTED="%s"
EXPECTED_BUNDLE_SHA="%s"
WORK="$ROOT/run-$(date -u +%%Y%%m%%dT%%H%%M%%SZ)"
SOURCE="$WORK/source"
mkdir -p "$WORK/bin"
BUNDLE_SHA="$(shasum -a 256 "$ROOT/fred-myers-app-build-4.bundle" | awk '{print toupper($1)}')"
[[ "$BUNDLE_SHA" == "$EXPECTED_BUNDLE_SHA" ]] || { echo "Source bundle SHA-256 mismatch." >&2; exit 1; }
echo "Source bundle SHA-256 verified: $BUNDLE_SHA"
GODOT="$(command -v godot || true)"
if [[ -z "$GODOT" && -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then GODOT=/Applications/Godot.app/Contents/MacOS/Godot; fi
[[ -n "$GODOT" ]] || { echo "Godot 4.7.1 is required." >&2; exit 1; }
ln -sf "$GODOT" "$WORK/bin/godot"
export PATH="$WORK/bin:$PATH"
git clone "$ROOT/fred-myers-app-build-4.bundle" "$SOURCE"
cd "$SOURCE"
git checkout --detach "$EXPECTED"
[[ "$(git rev-parse HEAD)" == "$EXPECTED" ]]
[[ -z "$(git status --porcelain)" ]]
export FRED_TESTFLIGHT_UPLOAD_ACK=UPLOAD_BUILD_4
bash tools/run_fred_app_build_4_macos.sh "$EXPECTED" | tee "$ROOT/FRED-APP-BUILD-4-RESULT.txt"
""" % (expected, bundle_sha),
        encoding="utf-8",
        newline="\n",
    )
    os.chmod(wrapper, os.stat(wrapper).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    manifest = {
        "schema": "fred-ios-handoff-v1",
        "commit": expected,
        "tree": run("rev-parse", "HEAD^{tree}"),
        "branch": run("branch", "--show-current"),
        "bundle": bundle.name,
        "bundle_bytes": bundle.stat().st_size,
        "bundle_sha256": bundle_sha,
        "runner": wrapper.name,
        "runner_sha256": sha256(wrapper),
        "bundle_identifier": "com.flinsvault.fredmyers",
        "marketing_version": "1.0",
        "build_number": "4",
        "testflight_upload_authorized": True,
        "public_app_store_release_authorized": False,
        "credentials_included": False,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        print(f"IOS_HANDOFF_FAIL {exc}", file=sys.stderr)
        raise SystemExit(1)
