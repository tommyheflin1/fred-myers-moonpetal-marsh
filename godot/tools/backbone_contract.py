"""Offline universal release-contract gate; never implies device or live-backend proof."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SNAKE_COPY_GATE = "privacy.pending_public_copy"
SNAKE_COPY_DECISION = "SR-1.4-11-INTERNAL-PRIVACY-COPY-2026-09-20"


def snake_copy_deferred(root: Path, game: dict, evidence: dict, purpose: str) -> bool:
    """Only the accepted wording defect, never the actual collection inventory."""
    try:
        keys = ("game_id", "bundle_id", "marketing_version", "build_number")
        if (purpose != "internal-testflight" or type(game.get("build_number")) is not int
                or tuple(game.get(k) for k in keys) != ("snake-reactor", "com.flinsvault.snakereactor", "1.4", 11)):
            return False
        package = json.loads((root / "store/app_store_package.json").read_text(encoding="utf-8"))
        items = [x for x in package.get("release_exceptions", []) if isinstance(x, dict) and x.get("gate") == SNAKE_COPY_GATE]
        if len(items) != 1:
            return False
        item = items[0]
        expected = {"gate": SNAKE_COPY_GATE, "decision_id": SNAKE_COPY_DECISION,
                    "owner_approved": True, "game_id": game["game_id"], "bundle_id": game["bundle_id"],
                    "exact_version": "1.4", "exact_build": 11, "purpose": "internal-testflight",
                    "deferred_until": "app-review", "defect": "pending_discovery_incorrectly_described_as_public"}
        if (any(type(item.get(k)) is not type(v) or item.get(k) != v for k, v in expected.items())
                or not isinstance(item.get("reason"), str) or not item["reason"].strip()):
            return False
        record = evidence.get("runtime", {}).get("privacy_inventory_matches", {})
        if record.get("status") != "deferred_owner_approved" or record.get("decision_id") != SNAKE_COPY_DECISION:
            return False
        inventory = evidence.get("privacy_inventory_except_pending_public_copy", {})
        if inventory.get("status") != "passed":
            return False
        files = evidence.get("source_files", {})
        names = ["game/game.json", "store/app_store_package.json", item.get("owner_decision"),
                 inventory.get("test"), inventory.get("result"), record.get("test"), record.get("result")]
        for name in names:
            if (not isinstance(name, str) or name not in files or "\\" in name or ":" in name
                    or Path(name).is_absolute() or ".." in Path(name).parts):
                return False
            path = root / name
            if not path.resolve().is_relative_to(root.resolve()) or not path.is_file() or digest(path) != files[name]:
                return False
        decision = json.loads((root / item["owner_decision"]).read_text(encoding="utf-8"))
        return (all(type(decision.get(k)) is type(v) and decision.get(k) == v for k, v in expected.items())
                and decision.get("owner_answer") == "YES"
                and isinstance(decision.get("source_turn"), str) and bool(decision["source_turn"].strip()))
    except (OSError, ValueError, TypeError, AttributeError, KeyError):
        return False

# Recorded owner scope, not a general publication bypass or a game-rule dependency.
LOCAL_ONLY_APPROVAL = ("apex-rush-circuit", "com.theflinsappvault.turborack", "1.1", 3)
LOCAL_ONLY_DECISION = "TR-LOCAL-ONLY-2026-09-14"
BUILD4_APPROVAL = ("apex-rush-circuit", "com.theflinsappvault.turborack", "1.2", 4)
BUILD4_DECISION = "FLEET-DEFECT-DEFERRAL-2026-09-20-TR-1.2-4"
LOCAL_ONLY_DECISIONS = {LOCAL_ONLY_APPROVAL: LOCAL_ONLY_DECISION, BUILD4_APPROVAL: BUILD4_DECISION}
LOCAL_HUNT_SCENARIOS = (
    "hidden_normal_navigation", "verified_local_discovery", "home_return",
    "restart_persistence", "zero_requests_and_retries", "pending_history_preserved",
    "offline_findability", "native_game_center_preserved",
)
LOCAL_ONLY_DEFERRED_RUNTIME = frozenset({
    "discovery_before_consent_before_network", "public_provider_name_only",
    "anonymous_no_name", "pending_restart_fresh_identity", "duplicate_idempotency",
    "server_authoritative_rank",
})


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def local_only_release_approved(root: Path, game: dict) -> bool:
    """Exact recorded exception with hash-bound local tests; never device proof."""
    try:
        identity = tuple(game.get(key) for key in ("game_id", "bundle_id", "marketing_version", "build_number"))
        decision = LOCAL_ONLY_DECISIONS.get(identity)
        if decision is None or type(game.get("build_number")) is not int:
            return False
        if game.get("capabilities", {}).get("golden_eggs") is not True:
            return False
        if game.get("integrations", {}).get("golden_eggs", {}).get("publishing_enabled") is not False:
            return False
        package = json.loads((root / "store/app_store_package.json").read_text(encoding="utf-8"))
        golden = package.get("golden_egg", {})
        if golden.get("local_hunt_enabled") is not True or golden.get("website_publishing_enabled") is not False:
            return False
        matches = [item for item in package.get("release_exceptions", []) if isinstance(item, dict)
                   and item.get("gate") == "golden_egg.website_publishing"]
        if len(matches) != 1:
            return False
        item = matches[0]
        if (item.get("decision_id") != decision or item.get("owner_approved") is not True
                or item.get("game_id") != identity[0] or item.get("bundle_id") != identity[1]
                or item.get("exact_version") != identity[2] or type(item.get("exact_build")) is not int
                or item.get("exact_build") != identity[3] or item.get("deferred_until") != "all-apps-live"
                or not isinstance(item.get("reason"), str) or not item["reason"].strip()):
            return False
        evidence = json.loads((root / "store/backbone_evidence.json").read_text(encoding="utf-8"))
        if evidence.get("review_status") != "approved" or any(evidence.get(key) != game.get(key)
                for key in ("game_id", "bundle_id", "marketing_version", "build_number")):
            return False
        files = evidence.get("source_files", {})
        # Bind the decision and actual configuration as well as local runtime/test artifacts.
        needed = {"game/game.json", "store/app_store_package.json"}
        if identity == BUILD4_APPROVAL:
            # A renamed build3 approval/result is insufficient. Require an exact-run
            # receipt bound to this configuration and actual runtime/test inputs.
            receipt_name = evidence.get("local_hunt_run")
            if not isinstance(receipt_name, str):
                return False
            receipt_path = root / receipt_name
            if ("\\" in receipt_name or ":" in receipt_name or ".." in Path(receipt_name).parts
                    or Path(receipt_name).is_absolute()
                    or not receipt_path.resolve().is_relative_to(root.resolve())):
                return False
            receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
            if (receipt.get("schema") != "flins-local-hunt-run-v1"
                    or any(receipt.get(k) != game.get(k) for k in
                           ("game_id", "bundle_id", "marketing_version", "build_number"))
                    or receipt.get("decision_id") != decision
                    or not isinstance(receipt.get("executed_at"), str) or not receipt["executed_at"].strip()):
                return False
            inputs = receipt.get("source_files", {})
            if (not isinstance(inputs, dict) or "game/game.json" not in inputs
                    or not any(p.startswith("scripts/") and p.endswith(".gd") for p in inputs)
                    or not any(p.startswith("tests/") for p in inputs)):
                return False
            if any(files.get(p) != sha for p, sha in inputs.items()):
                return False
            if any(receipt.get("scenarios", {}).get(s) != "passed" for s in LOCAL_HUNT_SCENARIOS):
                return False
            needed.update(inputs)
            needed.add(receipt_name)
        for scenario in LOCAL_HUNT_SCENARIOS:
            record = evidence.get("local_hunt", {}).get(scenario, {})
            if record.get("status") != "passed":
                return False
            for field in ("test", "result"):
                name = record.get(field)
                if not isinstance(name, str):
                    return False
                needed.add(name)
        for name in needed:
            path = root / name
            if (name not in files or "\\" in name or ":" in name or Path(name).is_absolute()
                    or ".." in Path(name).parts or not path.resolve().is_relative_to(root.resolve())
                    or not path.is_file() or digest(path) != files[name]):
                return False
        return True
    except (OSError, ValueError, TypeError, AttributeError):
        return False


def validate(root: Path, reference: Path = ROOT, *, purpose: str = "app-review") -> list[str]:
    errors: list[str] = []
    if purpose not in {"app-review", "internal-testflight"}:
        return ["invalid backbone validation purpose"]
    try:
        contract = json.loads((reference / "BACKBONE_CONTRACT.json").read_text(encoding="utf-8"))
        game = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
        local_only = local_only_release_approved(root, game)
        for name in contract["required_capabilities"]:
            if game.get("capabilities", {}).get(name) is not True:
                errors.append(f"required capability disabled or missing: {name}")
        egg = game.get("integrations", {}).get("golden_eggs", {})
        for name, expected in contract["golden_eggs"].items():
            actual = egg.get(name)
            if type(actual) is not type(expected) or actual != expected:
                errors.append(f"Golden Egg contract mismatch: {name}")
        if egg.get("publishing_enabled") is False and not local_only:
            errors.append("Golden Egg publication disabled")
        if not isinstance(game.get("updates", {}).get("enabled"), bool):
            errors.append("updates.enabled requires an explicit independent decision")
        evidence = json.loads((root / "store/backbone_evidence.json").read_text(encoding="utf-8"))
        copy_deferred = snake_copy_deferred(root, game, evidence, purpose)
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
                if copy_deferred and group == "runtime" and scenario == "privacy_inventory_matches":
                    continue
                if (local_only and group == "runtime" and scenario in LOCAL_ONLY_DEFERRED_RUNTIME
                        and isinstance(record, dict) and record.get("status") == "deferred_owner_approved"
                        and record.get("decision_id") == LOCAL_ONLY_DECISIONS.get(tuple(game.get(k) for k in
                            ("game_id", "bundle_id", "marketing_version", "build_number")))):
                    continue
                if not isinstance(record, dict) or record.get("status") != "passed":
                    errors.append(f"missing {group} evidence: {scenario}")
                    continue
                # Test code and output must be committed local artifacts, not unchecked prose.
                for field in ("test", "result"):
                    name = record.get(field)
                    if not isinstance(name, str) or name not in files:
                        errors.append(f"unbound {group} {scenario} {field}")
        if evidence.get("review_status") != "approved" and not (copy_deferred and evidence.get("review_status") == "approved_for_internal_testflight"):
            errors.append("app/backend integration evidence requires review")
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
        errors.append(f"backbone inventory incomplete: {exc}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--reference", type=Path, default=ROOT)
    parser.add_argument("--purpose", choices=("app-review", "internal-testflight"), default="app-review")
    args = parser.parse_args()
    errors = validate(args.root.resolve(), args.reference.resolve(), purpose=args.purpose)
    print(json.dumps({"status": "BACKBONE_MIGRATION_REQUIRED" if errors else "BACKBONE_EVIDENCE_CURRENT",
                      "errors": errors, "device_verified": False, "live_backend_verified": False}, indent=2))
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
