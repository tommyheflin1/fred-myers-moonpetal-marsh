"""Offline universal release-contract gate; never implies device or live-backend proof."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def validate(root: Path, reference: Path = ROOT) -> list[str]:
    errors: list[str] = []
    try:
        contract = json.loads((reference / "BACKBONE_CONTRACT.json").read_text(encoding="utf-8"))
        game = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
        for name in contract["required_capabilities"]:
            if game.get("capabilities", {}).get(name) is not True:
                errors.append(f"required capability disabled or missing: {name}")
        egg = game.get("integrations", {}).get("golden_eggs", {})
        for name, expected in contract["golden_eggs"].items():
            actual = egg.get(name)
            if type(actual) is not type(expected) or actual != expected:
                errors.append(f"Golden Egg contract mismatch: {name}")
        if egg.get("publishing_enabled") is False:
            errors.append("Golden Egg publication disabled")
        if not isinstance(game.get("updates", {}).get("enabled"), bool):
            errors.append("updates.enabled requires an explicit independent decision")
        evidence = json.loads((root / "store/backbone_evidence.json").read_text(encoding="utf-8"))
        if evidence.get("schema") != "flins-backbone-evidence-v1":
            errors.append("backbone evidence schema mismatch")
        if evidence.get("contract_sha256") != digest(reference / "BACKBONE_CONTRACT.json"):
            errors.append("backbone evidence requires current contract review")
        for name in ("game_id", "bundle_id", "marketing_version", "build_number"):
            if evidence.get(name) != game.get(name):
                errors.append(f"backbone evidence stale identity: {name}")
        files = evidence.get("source_files", {})
        if not isinstance(files, dict) or "game/game.json" not in files or len(files) < 2:
            errors.append("backbone evidence requires configuration and runtime source hashes")
            files = {}
        for relative, expected in files.items():
            path = root / relative
            if (not isinstance(relative, str) or "\\" in relative or ":" in relative
                    or Path(relative).is_absolute() or ".." in Path(relative).parts
                    or not path.resolve().is_relative_to(root.resolve())):
                errors.append("unsafe evidence source path")
            elif not path.is_file() or digest(path) != expected:
                errors.append(f"backbone evidence stale source: {relative}")
        for group in ("runtime", "backend"):
            records = evidence.get(group, {})
            for scenario in contract[f"required_{group}_scenarios"]:
                record = records.get(scenario, {}) if isinstance(records, dict) else {}
                if not isinstance(record, dict) or record.get("status") != "passed":
                    errors.append(f"missing {group} evidence: {scenario}")
                    continue
                # Test code and output must be committed local artifacts, not unchecked prose.
                for field in ("test", "result"):
                    name = record.get(field)
                    if not isinstance(name, str) or name not in files:
                        errors.append(f"unbound {group} {scenario} {field}")
        if evidence.get("review_status") != "approved":
            errors.append("app/backend integration evidence requires review")
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
        errors.append(f"backbone inventory incomplete: {exc}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--reference", type=Path, default=ROOT)
    args = parser.parse_args()
    errors = validate(args.root.resolve(), args.reference.resolve())
    print(json.dumps({"status": "BACKBONE_MIGRATION_REQUIRED" if errors else "BACKBONE_EVIDENCE_CURRENT",
                      "errors": errors, "device_verified": False, "live_backend_verified": False}, indent=2))
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
