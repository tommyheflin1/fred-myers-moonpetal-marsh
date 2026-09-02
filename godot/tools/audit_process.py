"""Read-only, offline release-tool drift audit. A match is not device/store evidence."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]


def digest(path: Path) -> str:
    # Git's checkout newline conversion must not look like semantic drift.
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def audit(root: Path, reference: Path = ROOT) -> dict:
    lock = json.loads((reference / "PROCESS_LOCK.json").read_text(encoding="utf-8"))
    failures = []
    for relative, expected in lock["files"].items():
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts or ":" in relative or "\\" in relative:
            raise ValueError("unsafe process-lock path")
        source = reference / path
        target = root / path
        if not source.is_file() or digest(source) != expected:
            failures.append({"file": relative, "reason": "reference-lock-stale"})
        elif not target.is_file():
            failures.append({"file": relative, "reason": "missing"})
        elif digest(target) != expected:
            failures.append({"file": relative, "reason": "different-review-required"})
    try:
        game = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
        for key in ("game_id", "bundle_id", "marketing_version", "build_number", "capabilities", "privacy"):
            if key not in game:
                failures.append({"file": "game/game.json", "reason": f"missing-{key}"})
    except (OSError, ValueError):
        failures.append({"file": "game/game.json", "reason": "identity-adapter-required"})
    result = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True, text=True)
    return {"app": root.name, "process_version": lock["process_version"],
            "source_commit": result.stdout.strip() if result.returncode == 0 else None,
            "status": "MATCH" if not failures else "MIGRATION_REQUIRED", "differences": failures,
            "runtime_verified": False, "apple_verified": False}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--reference", type=Path, default=ROOT)
    parser.add_argument("--fleet", type=Path, help="Workspace containing registered independent app repositories")
    args = parser.parse_args()
    roots = [args.root]
    if args.fleet:
        registry = json.loads((args.reference / "PROCESS_APPS.json").read_text(encoding="utf-8"))
        roots = [args.fleet / item["path"] for item in registry["apps"]]
    try:
        reports = [audit(root.resolve(), args.reference.resolve()) for root in roots]
        print(json.dumps(reports, indent=2))
        return 0 if all(r["status"] == "MATCH" for r in reports) else 1
    except (OSError, ValueError, KeyError) as exc:
        print("PROCESS_AUDIT_FAIL", exc)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
