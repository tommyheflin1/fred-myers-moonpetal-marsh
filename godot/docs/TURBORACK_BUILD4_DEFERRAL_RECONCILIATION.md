# TurboRack 1.2 (4): standing defect-deferral reconciliation

The owner's September 20 direction in the shared harness task is that all apps
follow Fred's open / owner-accepted / repair-deferred status for Golden Egg website
and related leaderboard defects, so those defects do not stop submission/rollout.
This records that standing direction for TurboRack's already-local-only next
candidate, not a new approval to disable another app's online functionality.

Only apex-rush-circuit / com.theflinsappvault.turborack / 1.2 / integer build 4
uses decision ID `FLEET-DEFECT-DEFERRAL-2026-09-20-TR-1.2-4`. Use the same scoped
website-publishing exception fields as the preserved build3 decision, with these
exact identity and decision values. Do not change or reuse build3 records/results.
Keep deferred scenarios deferred, never passed. No native-device waiver is added.

In addition to the existing eight local-hunt scenario records and current hashes,
the app must run current tests and provide `local_hunt_run` in backbone evidence,
pointing to a hash-bound JSON receipt containing:

- schema: `flins-local-hunt-run-v1`; exact game_id, bundle_id, marketing_version,
  build_number, decision_id and a nonempty actual executed_at timestamp;
- source_files: LF-normalized SHA256 of game/game.json, actual scripts/*.gd runtime
  inputs and tests/* inputs used by the run, all also bound in backbone evidence;
- scenarios: all eight LOCAL_HUNT_SCENARIOS mapped to passed from actual results.

The runner/engineering reviewer must generate this from an actual build4 run;
editing identity fields on old output is not execution. Static receipt checks are
not cryptographic execution attestation or device proof. Refresh all hash-bound
evidence after configuration/package changes. Preserve the hunt, pending/history,
native Game Center, security/backend checks, truthful privacy/media and Apple gates.
GC authentication/replay deferrals remain independently exact-build authorized;
this reconciliation does not supply them. No runtime, website or release-setting
change is part of this harness patch. App owner performs any later adoption.
