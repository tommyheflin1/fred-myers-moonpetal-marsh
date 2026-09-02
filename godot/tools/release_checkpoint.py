"""Bind resumable Apple gates to source and artifact identity; never authorize release."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def identity(root: Path, commit: str) -> dict:
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("exact commit required")
    if git(root, "rev-parse", "HEAD") != commit or git(root, "status", "--porcelain"):
        raise ValueError("candidate commit mismatch or dirty checkout")
    game = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
    if not re.fullmatch(r"[a-z][a-z0-9-]{2,63}", str(game.get("game_id", ""))):
        raise ValueError("unsafe game identity")
    if not re.fullmatch(r"[0-9]+\.[0-9]+(?:\.[0-9]+)?", str(game.get("marketing_version", ""))):
        raise ValueError("invalid marketing version")
    if type(game.get("build_number")) is not int or game["build_number"] < 1:
        raise ValueError("invalid build number")
    return {"commit": commit, "tree": git(root, "rev-parse", "HEAD^{tree}"),
            "game_id": game["game_id"], "bundle_id": game["bundle_id"],
            "version": game["marketing_version"], "build": int(game["build_number"])}


def archive_hash(path: Path) -> str:
    if not path.is_dir() or path.is_symlink():
        raise ValueError("archive missing or linked")
    digest = hashlib.sha256()
    files = 0
    for item in sorted(path.rglob("*")):
        if item.is_symlink():
            content = b"link:" + os.readlink(item).encode()
        elif item.is_file():
            content = b"file:" + hashlib.sha256(item.read_bytes()).digest()
        else:
            continue
        digest.update(item.relative_to(path).as_posix().encode() + b"\0" + content + b"\0")
        files += 1
    if not files:
        raise ValueError("empty archive")
    return digest.hexdigest()


def validate_checkpoint(data: dict, expected: dict, mode: str, archive: Path) -> None:
    if any(data.get(key) != value for key, value in expected.items()):
        raise ValueError("checkpoint belongs to another candidate; preserve it and use a new lane")
    allowed = {"archive": {"prepared"}, "upload": {"archived"},
               "status": {"archived", "upload-command-succeeded"}}
    if data.get("gate") not in allowed[mode]:
        raise ValueError("gate out of order; resume status instead of repeating a completed operation")
    if mode in {"upload", "status"} and data.get("archive_sha256") != archive_hash(archive):
        raise ValueError("archive changed since verification")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["check", "record"])
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--mode", choices=["preflight", "archive", "upload", "status", "prepared", "archived", "upload-command-succeeded"], required=True)
    args = parser.parse_args()
    try:
        root = args.root.resolve()
        expected = identity(root, args.commit)
        lane = root / "builds/ios/apple-delivery" / f"{expected['version']}-{expected['build']}"
        path = lane / "checkpoint.json"
        archive = lane / f"{expected['game_id']}.xcarchive"
        data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
        if args.action == "check":
            if args.mode == "preflight":
                if data and (data.get("gate") != "prepared" or any(data.get(k) != v for k, v in expected.items())):
                    raise ValueError("existing lane must be resumed, not overwritten")
            elif args.mode in {"archive", "upload", "status"}:
                validate_checkpoint(data, expected, args.mode, archive)
            else:
                raise ValueError("invalid check mode")
        else:
            previous = {"prepared": "preflight", "archived": "archive", "upload-command-succeeded": "upload"}
            if args.mode not in previous:
                raise ValueError("invalid record gate")
            if args.mode != "prepared":
                validate_checkpoint(data, expected, previous[args.mode], archive)
            elif data and (data.get("gate") != "prepared" or any(data.get(k) != v for k, v in expected.items())):
                raise ValueError("cannot overwrite prior lane")
            data.update(expected, gate=args.mode, processing_verified=False, release_authorized=False)
            if args.mode == "archived":
                data["archive_sha256"] = archive_hash(archive)
            lane.mkdir(parents=True, exist_ok=True)
            temp = path.with_suffix(".tmp")
            temp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
            temp.replace(path)
        print("RELEASE_CHECKPOINT_OK", args.action, args.mode)
        return 0
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as exc:
        print("RELEASE_CHECKPOINT_STOP", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
