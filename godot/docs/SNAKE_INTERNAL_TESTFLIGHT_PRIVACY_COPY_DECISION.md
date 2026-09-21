# Snake 1.4 (11): internal-TestFlight-only copy exception

Owner answered YES in the Snake task to the proposed exact internal-TestFlight-only
exception on September 20, 2026. Website work remains prohibited. This decision
does not authorize App Review or public release while the mismatch remains.

Only snake-reactor / com.flinsvault.snakereactor / 1.4 / integer build 11 can defer
the existing policy sentence incorrectly describing pending discoveries as public.
It does not defer collection inventory, identity, consent, secret handling, native
security, device checks, live endpoint checks, artwork or any other requirement.
The previously approved three device deferrals remain separate records and gates.

## App-owned evidence (no fabricated results)

Add exactly one store package release_exceptions item with:

```json
{
  "gate": "privacy.pending_public_copy",
  "decision_id": "SR-1.4-11-INTERNAL-PRIVACY-COPY-2026-09-20",
  "owner_approved": true,
  "game_id": "snake-reactor",
  "bundle_id": "com.flinsvault.snakereactor",
  "exact_version": "1.4",
  "exact_build": 11,
  "purpose": "internal-testflight",
  "deferred_until": "app-review",
  "defect": "pending_discovery_incorrectly_described_as_public",
  "reason": "Owner accepts only the recorded pending-public wording mismatch for internal testing; App Review remains blocked.",
  "owner_decision": "docs/evidence/internal-testflight-copy-owner-decision.json"
}
```

The owner_decision JSON repeats those scope fields and records owner_answer YES
and source_turn pointing to the actual approval turn (never an invented reference).
Bind that file, game/game.json and store/app_store_package.json in backbone source_files.

Keep runtime.privacy_inventory_matches status deferred_owner_approved, decision_id
as above, and hash-bound test/result documenting the exact mismatch. Add top-level
privacy_inventory_except_pending_public_copy with status passed and hash-bound
test/result proving all remaining inventory/manifest/Apple/consent/data-flow parity.
This is real engineering review, not an owner-approved blanket privacy assertion.
Use overall review_status approved_for_internal_testflight after that review.
All ordinary scenario/source/contract checks remain mandatory.

Run backbone_contract.py --purpose internal-testflight and store_readiness.py
release --purpose internal-testflight; default app-review MUST still fail on the
deferred scenario and limited overall review. release-ios already routes purpose
through FLINS_RELEASE_PURPOSE=internal-testflight. Do not alter the uploader.
Plain audit_process.py --backbone remains the default App Review assessment and
may truthfully report this pending scenario; process MATCH is separate from it.

Before App Review replace deferred evidence with actual parity proof and full
review approval. Do not auto-remove the known defect or reinterpret this approval
as permission to edit the website. Preserve previous source/archive checkpoints;
app owner alone adopts tooling and creates the updated exact source handoff.
