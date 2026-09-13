"""Read-only, offline release-tool drift audit. A match is not device/store evidence."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from backbone_contract import validate as validate_backbone


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
    result = subprocess.run(
        ["git", "-c", f"safe.directory={root.as_posix()}", "-C", str(root), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
    )
    return {"app": root.name, "path": str(root), "process_version": lock["process_version"],
            "source_commit": result.stdout.strip() if result.returncode == 0 else None,
            "status": "MATCH" if not failures else "MIGRATION_REQUIRED", "differences": failures,
            "backbone_errors": validate_backbone(root, reference),
            "runtime_verified": False, "apple_verified": False}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--reference", type=Path, default=ROOT)
    parser.add_argument("--fleet", type=Path, help="Workspace containing registered independent app repositories")
    parser.add_argument("--backbone", action="store_true", help="Also fail for missing universal capability/integration evidence")
    parser.add_argument("--discover", action="store_true", help="Include unregistered game/game.json candidates in fleet; does not select a release candidate")
    parser.add_argument("--summary", action="store_true", help="Print compact counts while retaining nonzero failure status")
    args = parser.parse_args()
    roots = [args.root]
    if args.fleet:
        registry = json.loads((args.reference / "PROCESS_APPS.json").read_text(encoding="utf-8"))
        roots = [args.fleet / item["path"] for item in registry["apps"]]
        if args.discover:
            roots = sorted(set(roots) | {p.parent.parent for p in args.fleet.glob("*/game/game.json")}
                           | {p.parent.parent for p in args.fleet.glob("worktrees/*/game/game.json")}
                           | {p.parent.parent for p in args.fleet.glob("worktrees/*/godot/game/game.json")})
    try:
        reports = [audit(root.resolve(), args.reference.resolve()) for root in roots]
        display = [{"path": r["path"], "status": r["status"], "process_differences": len(r["differences"]),
                    "backbone_errors": len(r["backbone_errors"])} for r in reports] if args.summary else reports
        print(json.dumps(display, indent=2))
        return 0 if all(r["status"] == "MATCH" and (not args.backbone or not r["backbone_errors"]) for r in reports) else 1
    except (OSError, ValueError, KeyError) as exc:
        print("PROCESS_AUDIT_FAIL", exc)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
