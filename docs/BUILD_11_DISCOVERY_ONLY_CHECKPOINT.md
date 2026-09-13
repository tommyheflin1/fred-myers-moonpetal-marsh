# Fred 1.1 (11): discovery-only website checkpoint

September 12, 2026 owner-directed architecture correction. This supersedes earlier
notes that described a mandatory website policy check as a Fred release prerequisite.
This is a tested development checkpoint, not Apple upload or device acceptance.

## Exact behavior

- `updates.enabled=false`: the update gate creates no HTTPRequest, no overlay and no
  startup/foreground dependency. Earlier mandatory enforcement came from the optional
  shared update service wired into this uncommitted Build 11 pass, not the egg puzzle.
- Normal launch, menus, gameplay, save loading, Game Center sign-in and native
  leaderboard access make zero Golden Egg requests. Game Center stays independent.
- A locally verified find stages private evidence. Review Game Center Name performs
  identity exchange only. A separate Share action posts the reviewed provider name.
  Apple signs identity, not the display name itself.
- Post as Anonymous is an explicit posting choice. Don't post / Return keeps an
  unsubmitted find local and durably prevents automatic posting after restart.
- Return restores the beginning of Level 5 with unpaused controls. A late name lookup
  cannot reopen consent or publish the declined find. Website failure cannot block play.
- The established app-bound bearer bootstrap, Keychain, nonce and idempotency paths
  are retained. No embedded service key, new uploader, signing migration or account reset.
- Shared publication-v2 body/acknowledgement validation rejects pending or mismatched
  acceptance and non-2xx responses. Existing server ranks and records survive retries.
  A failed requested privacy change remains distinct from the earlier confirmed choice
  and is saved for explicit retry, never reported as completed.

## Shared provenance

Fred keeps the existing Core 0.5.1 files and version label. The exact original tree
`288d87420c5694f80c071f00aa71a0b581f9f60c` is unchanged underneath additive helpers.
The bundled overlay tree is explicitly pinned as
`ce7821a6431681adca8bd5997fab8fe24b82ec23` in the iOS validators.
Additions: optional lifecycle/update verification, Golden Egg web/discovery helpers,
bounded native event pump and platform gaming service, plus the publication-v2 helper.
The latter is copied verbatim from Core
`3ae274a1503c564b90d0dca5d680eace483aafac`; associated template checkpoint is
`6f5bff324cd3396ecf0d8899f1e74d526cf64896` (candidate 30).
Fred consumes that pure helper inside its original authenticated transport.
Its existing candidate-28 release lock remains intact; this narrow code adoption is
NOT full candidate-30 migration. The canonical audit correctly remains MIGRATION_REQUIRED.

## Actually executed

- All 48 Godot suites exit 0 after final wire-adapter changes. Logs:
  `godot/builds/validation/shared-wire-final`. Shutdown resource warnings remain in
  some suites; this is not a warning-free or physical-device run.
- Included: 48 discovery-only network checks, 50 public-name/consent/recovery checks,
  35 website integration checks. Fictional transport, identities and isolated saves only.
- Earlier actual OpenGL review: 18 reveal/HUD/return checks and read-only name screen.
  The superhero frog egg and all three choices were visually inspected.
- Website handlers: 155 Node tests pass with real RSA verification fixtures and SQLite
  transaction fixtures. These do not constitute live Game Center or independent
  server proof of gameplay; the current evidence token is a local attestation.
- Apple browser: version 1.1 still Prepare for Submission, selected Build 10. No
  Build 11 archive, upload, TestFlight install, review submission or live release proved.
- Existing remote tab preserved. Wallpaper remained visible after one non-destructive
  Spotlight attempt. No reconnect, logout, reboot, Xcode/account/signing cleanup.

## Website and compatibility

Website contract commits in `worktrees/fred-website-release`:
`844634150c18bcd05c2c0112b5c886b95b31a464`,
`afe3e141ab8e6de9ab799b5463335f78d907219a`, and
`9512a886fb255cb9940fb9ae1dacc2dfb190131a`.
These changes are local, NOT production-deployed. Last known production version 83
is separate. V2 requires explicit PUBLIC/ANONYMOUS, authenticated identity even when
the claimed version is downgraded, and exact reviewed provider name for Public.
Pending records are omitted from leaderboard, direct public lookup and hero race;
existing records/ranks are not deleted or renumbered. Legacy public PATCH compatibility
is retained for unupgraded Snake clients; do not claim all old clients already enforce
v2 freshness. TurboRack confirms publication is OFF in its live Build 2 configuration.

## Remaining release gates, not waived

- September 12 privacy text is draft, awaiting the one owner review request already
  sent. Earlier privacy categories, retention, contact and Apple answers are retained;
  only startup/three-choice behavior changes. No draft policy has been published.
- Current canonical backbone audit additionally requires achievements/evidence and
  integration evidence. The follow-up below removes normal-navigation recovery UI.
  Fred's released baseline has two leaderboards
  and no achievements. Adding game features or overriding that newer requirement needs
  an explicit scope decision; no fake capability or forged MATCH is recorded.
- Store media has approved pictures but no frozen capture provenance; source SDK/music
  reviews are not native binary/device proof. Existing rights/provenance questions and
  separate Game Center/Golden Egg device gates remain open. No evidence flags were
  silently promoted to true, and the public GitHub origin was not pushed.

Resume `tools/release-ios preflight -> archive -> upload -> status` only after its
actual gates pass. Keep preserved Build 10 Mac artifacts and signing assets unchanged.

## Hidden-event navigation follow-up

Following the canonical Golden Egg skill, normal title navigation no longer draws
or handles the saved-discovery entry point. Pending/canonical discovery storage is
preserved, but closing the event does not unlock a permanent menu category. Existing
publication choices, native leaderboard identifiers, puzzle and Level 5 return are
unchanged. App inventory now declares hidden presentation and no normal navigation.

Targeted headless regression: 140 checks passed across discovery return, public-name
review, notices, render-source boundaries and discovery-only networking. Actual
OpenGL title/reveal/gameplay/return boundary test: 15 checks passed. These are local
tests, not physical-device or Apple proof.

The first broad regression attempt encountered one soundtrack end-wrap timing failure.
Three unchanged isolated soundtrack reruns then passed 28 checks each. Do not erase
this intermittent result or claim audible/device loop acceptance from these tests.
The subsequent complete run passed all 48 Godot suites, including soundtrack.
Canonical audit still reports MIGRATION_REQUIRED: shared-tool migration, achievements
and backbone evidence remain open; the two hidden-navigation inventory errors are
resolved. Website f3a66d4 remains unpublished; no Apple upload was performed here.

## Exact-capture provenance follow-up

The existing capture tool ran against clean a4639fc3a94cae284c10f2f100a67f60f1637bda
with isolated user data. All sixteen iPhone/iPad renders passed the screenshot
dimension, RGB and metadata validator. The two touch-control captures are byte-for-byte
identical to their corresponding owner-approved store-build11 files and were visually
inspected. They are now registered in store/screenshots.json with that capture commit
and exact hashes. Other changed captures are not silently owner-approved, and the
existing eight-per-device Apple screenshot selections were not modified.

Internal-TestFlight store readiness now clears screenshot sets and capture provenance;
eight other review/evidence failures remain. Underlying artwork provenance is still
unresolved independently of screenshot approval and is not marked cleared here.
Live Apple Game Center inventory was inspected: two existing leaderboards, no achievement
records. The harness confirmed that the owner-requested update requires 25 app-specific
achievements. These must be implemented and registered, not represented by capability
flags alone. No proposed achievement ID is claimed to exist in Apple.
