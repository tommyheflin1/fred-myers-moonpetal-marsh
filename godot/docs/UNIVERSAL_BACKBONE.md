# Universal app backbone

Every Flins game release requires Game Center, native leaderboards, achievements,
Golden Egg discovery/publication, custom game-specific audio and lifecycle handling.
`BACKBONE_CONTRACT.json` is the machine-readable common contract. Prototype generation
may retain disabled services while work proceeds; a disabled capability cannot silently
waive the release requirement. Do not enable a configuration flag without implementing
and testing the underlying behavior. Preserve old released binaries and save formats.

GOLDEN EGG WEBSITE INTEGRATION IS DISCOVERY-TRIGGERED, NOT STARTUP-TRIGGERED.
Native leaderboards and achievements are Game Center services, not website availability
checks. Normal launch, menus, gameplay and Game Center must make zero Golden Egg requests.
Only locally verified discovery followed by an explicit publishing choice starts transport.
The website must revalidate discovery; never trust a client boolean as server proof.
Never put solutions or signing credentials in public metadata.

The website verifies fresh app-bound signed team-player identity. Game-player ID and
display name are provider-reported, not Apple-signed identity. No typed substitute names.
Public-name consent is affirmative; Anonymous must redact identity from public DTOs.
Expose Public, Anonymous and Local-only as distinct actions. Local-only sends no Hunt
requests and schedules no retries; dismissing the flow is not consent. Keep pending
records out of public leaderboards. Legacy typed-name fallbacks must be removed server-side.
Local discovery survives failure, dismissal, restart and account changes. Retry uses the
original idempotency key and freshly resolved identity for the originally bound account.
Server transactions assign rank/time and enforce duplicates, replay limits and isolation.
Never fabricate confirmation, ranks or a successful HTTP response. Store credentials in
the existing per-app secure adapter, not ordinary save JSON. Public output contains no
private player IDs, proof material or secrets. General app-update enforcement is separate
and explicitly enabled or disabled; Golden Egg configuration cannot turn it on.

## Evidence and propagation

Run `python tools/audit_process.py --fleet <workspace> --discover --backbone` from the
canonical template. Discovery includes unregistered candidates but does not select which
candidate is released. Process MATCH is only a file comparison; backbone evidence and
physical-device/Apple gates remain separate. Store release validation runs the backbone
gate automatically. Existing apps with older release tools remain MIGRATION_REQUIRED.

Each app owns `store/backbone_evidence.json` (schema `flins-backbone-evidence-v1`): exact
game_id, bundle_id, marketing_version, build_number; current LF-normalized contract SHA256;
review_status; and source_files mapping repository-relative files to LF-normalized SHA256.
Include configuration, all integration runtime/native sources, test code and sanitized
results. For each required runtime/backend scenario include status, test and result paths
bound by that mapping. Backend test/results must identify the reviewed backend source SHA
and app registration. Do not copy another app's passing evidence or manufacture records.
This is reviewable evidence integrity, not a security attestation: reviewers must ensure
test coverage exercises actual app transport and deployed backend, not just a helper.
Existing store gates still require approved media, 25 achievement assets where specified,
custom music/rights, policy parity, physical-device behavior and Apple delivery proof.

Promote a common fix with regression tests, versioned lock, generated-app smoke and fleet
audit. Every consumer becomes migration-required until its reviewed adapter and evidence
are updated. Do not blindly overwrite concurrent app work, native bindings, IDs, Core pins,
save versions or signed checkpoints. A fleet-wide update is not complete while any active
candidate remains migration-required. No audit or source change signs/uploads/releases.
