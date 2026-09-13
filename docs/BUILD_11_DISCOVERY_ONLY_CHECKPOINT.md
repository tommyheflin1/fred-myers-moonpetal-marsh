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

## Privacy approval and website delivery checkpoint

Owner explicitly approved the revised September 12 three-choice/no-normal-gameplay
website policy: "YES, THATS WHAT IT IS SUPPOSED TO DO!" App privacy approval is recorded
in 8203579. Do not ask for this approval again. Registry sync succeeded through the
existing tool. Website source 0ae3fa72eba74024650414f39e30d2fb6f61ea2d is pushed to the
existing Sites main branch; its production build and all 155 Node tests passed.

The validated package SHA256 is
b5857b1fa54056a4b140fd8303493ed04089631473c39d4e57fc979e4ee773c8.
Two native save_site_version attempts failed in blob upload after 60 seconds each
(request IDs 5e807070-21a7-4a9a-8f2c-a4d76b186705 and
c722452c-701e-4991-ae5a-c8d0729e0c5f). Latest saved version was still 83 when checked.
No new version/deployment succeeded. Resume archive-backed saving of the unchanged
package and exact source after upload service recovery, then deploy and verify live.
Do not remove the archive argument to conceal an upload transport failure. Do not
mark production endpoint, physical-device behavior, or Apple delivery verified.

## Campaign achievement implementation and Apple checkpoint

The next isolated full Godot run completed with `TOTAL=49 FAILED=0`, including
164 campaign-achievement assertions. App-owned milestones use actual completion
of levels 4, 8, ... 100; existing saved completion records support replay. Dispatch
is paced, uses the pinned shared gaming adapter, and does not add another native
event poller. Achievement capability remains disabled pending complete Apple
record/artwork reconciliation and device verification. These are local checks,
not Apple award acknowledgements or device tests.

Apple now contains the first newly created record:
`com.flinsvault.fredmyers.campaign_004` / First Lily Trail,
record `903c1325-40bb-4e4e-bd34-03eaf6946ab8`. Its 40 points were saved and verified
in the UI (960 of 1000 remaining). Localization/artwork are incomplete and it
has NOT been added for review. No other proposed campaign ID is registered yet.
The localization modal was cancelled without losing the saved base record.

Original built-in image-generation draft is preserved at
`docs/artwork-drafts/first-lily-trail-v1.png` outside production assets. It is
1254x1254 RGB, not the required 1024x1024 production artwork, and is not uploaded.
Prompt: original polished storybook gold medal, luminous lily-pad trail across
midnight teal marsh water, moon-white flower, fireflies and crescent moon; no
text, numbers, logos, watermark or borrowed characters. Generation source:
`exec-d02e97af-7767-4df4-9287-7eb81e426c51.png`. No change to superhero egg art.

A third unchanged website-package save failed with the same 60000ms blob-upload
timeout, request `a26ec554-9f6a-42f3-9bcd-ed6ad39ce544`. Latest saved version remains
83, source c0807276b62185c0988655886fc39ca92c99d30e. Do not deploy this older
version as the new Golden Egg fix. The canonical process audit still reports
MIGRATION_REQUIRED (14 differences), disabled achievements and missing backbone
evidence. No release gate has been marked passed to bypass these failures.

Existing Mac session became responsive without reconnecting. A bounded
`caffeinate -di -t 3600` was started, PID 22477. No logout, reboot, account,
certificate or provisioning changes. No Build 11 archive/upload/submission yet.

## Candidate 30 migration verified

Reviewed and adopted the canonical candidate-30 shared tools, documentation,
contract and Core helper differences. Canonical audit now reports MATCH with
zero file differences. This supersedes the earlier 14-difference checkpoint;
it does not clear backbone, website, Apple or device gates. Fred's app-owned
transport, Core version pin, gameplay, saves and release-ios lane are unchanged.
The added shared discovery/secure-store helper is not a replacement of Fred's
existing authenticated transport. Existing app integration tests still run.

Validation after migration: all 49 app Godot suites passed, shared persistence
22 checks passed, shared event-driven contract reported zero failures and zero
pre-discovery requests, and 39 Python tests passed. Two initial imported template
test failures were fixture assumptions (template placeholders and default icon/
disabled Golden Egg settings); app-specific test fixtures were corrected without
changing production review flags. Diff whitespace validation passed.

The fourth unchanged Sites upload failed after 60004ms, request
5bc37270-f3f0-4b58-b795-e178e3c964dd. New publication is still not verified.
Internal-TestFlight readiness remains blocked by achievement enablement/evidence,
Game Center identity and privacy flow review, production website/contract,
third-party inventory, creative review, audible runtime mix and package review.
No signing, uploading or App Review submission occurred during this migration.

## Achievement retry correction

Found and fixed two session-level dispatch problems: repeated progress enqueues
previously reset failed-attempt counts, and later completions could resend all
previously started achievements. A session-only started set now suppresses repeats;
failed-attempt counts survive enqueue calls. Fresh authentication clears both so
saved completion can replay without pretending any request was confirmed by Apple.
Enqueue is also blocked while identity refresh is in progress.

Actual targeted tests after this correction: campaign achievements 167 passed,
Game Center adapter 56 passed, discovery-only network 48 passed, Pause input 36
passed. All four commands exited zero. These are fictional/native-adapter local
checks, not physical-device results. The prior 49-suite result predates this small
correction and is not relabeled as an exact-final full-suite result.

Live Apple inspection still shows First Lily Trail / campaign_004, 40 points,
Prepare for Submission with no localization. No account/session/signing changes.
Source SDK review is in BUILD_11_SDK_SOURCE_REVIEW.md; native artifact inspection
is still missing, so the corresponding release gate remains false.

## Apple metadata authorization checkpoint

Created Reed Runner base record campaign_008, Apple record
1bf2c625-8fc0-4c71-bdd2-e5760e743eb1. Creation was verified in Apple; its point
value remains 0, and localization/artwork remain absent. The attempted 40-point
save was rejected by the action safety reviewer because the exact allocation had
not been verified against an explicit owner-approved specification. No workaround
was attempted. Follow-up read showed no change. Request the narrow approval for
25 campaign milestones at completed levels 4,8,...100, 40 points each, 1000 total;
this is separate from broad release approval and does not waive release evidence.

Harness task received exact immutable website archive path, byte count, digest,
native save arguments, last saved version and request IDs. It is investigating
the upload transport while Fred remains sole deployment owner. Blind retries are
paused; source and archive remain unchanged. No Apple build submitted.

## Exact-runtime regression and stale validator repair (2026-09-12)

All 49 Godot run_*.gd suites completed on runtime commit fad7534 with
TOTAL=49 FAILED=0, using isolated temporary APPDATA/LOCALAPPDATA and Dummy audio.
An initial restricted process launch was denied; the approved elevated runtime
execution completed. Existing ObjectDB/resource warnings on test shutdown remain;
these results do not certify native devices, live Apple callbacks or audible mix.
All 39 shared Python tests also passed.

The two app-owned legacy preparation validators still expected Core tree
ce7821a6431681adca8bd5997fab8fe24b82ec23 after the reviewed candidate-30 migration
4f3c0db. Reviewed the complete four-file diff: discovery service persistence,
secure-store helper plus UID, and identity-exchange protocol header. Canonical
audit verifies MATCH with zero differences. Updated only the two validation pins
to fd3a585946e4fa4a78e7a32eb05be66aac9b31c7; Core base version, gameplay, signing,
and source helpers remain unchanged. Six standalone Python scripts passed 115
checks; the preparation script then passed 36 rather than 34 checks after adding
two negative assertions that an unknown Core tree still fails explicitly.

Internal-TestFlight store validation still fails the four Golden Egg integration
reviews, achievements capability/backbone evidence, third-party SDK review,
creative review, audible mix review, and store package approval. No review flags
or exceptions were changed to conceal these gaps.

Website packaging inspection found required outputs and active images, no
accidental source/node_modules payload. The helper already uses gzip and exposes
no compression setting; the native upload exposes no timeout setting or inner
failure detail. The original archive is unchanged. With no Sites calls running,
sole website lifecycle ownership was explicitly transferred to harness task
019fc591-9c35-79e2-a59d-cef0f0158890 for product-context transport investigation.
Fred must not concurrently save, deploy, package or modify that website.
Apple points remain blocked pending exact allocation approval. No Build 11
archive, upload, TestFlight device installation, or App Review submission verified.

## Apple achievement allocation completed (2026-09-13)

Harness task relayed the owner's explicit answer, "Approve this achievement
allocation", to the exact 25-milestone/every-four-levels/40-points question.
The previously blocked Save operation then succeeded through the normal Apple UI.
All 25 campaign records now exist and have 40 points saved, verified in the full
Apple inventory. The final record shows 0 of 1000 total points remaining.
Exact Apple IDs, titles, thresholds and prepared English text are preserved in
BUILD_11_APPLE_ACHIEVEMENT_RECORDS.json. This supersedes the earlier allocation
authorization blocker. Do not ask for that approval again or recreate the records.

None of the achievement records has been added for review. Localization Save
remained disabled after entering valid English text without an image; cancelled
only that unfinished modal, preserving every saved record. Unique compliant art,
localization, runtime capability enablement and native award/replay verification
remain incomplete. The Hero of Moonpetal draft was generated separately from the
unchanged superhero Golden Egg; its provenance and dimensions are recorded beside it.

The harness website owner reports fresh-context and lossless-TAR attempts also
failed at the native 60-second upload boundary. Latest reported request is
d74cea13-21ba-4b70-8118-53771482c2f1. Existing version 83 is preserved. This is
not evidence of broken website source or successful publication. No additional
website operations were performed by the Fred task after ownership transfer.

## Complete achievement original artwork set (2026-09-13)

All 25 distinct original badges are now preserved in docs/artwork-drafts,
including separate Hero of Moonpetal and First Lily Trail originals. The new
ACHIEVEMENT_ORIGINALS.json maps every milestone ID to its original, SHA-256,
dimensions, generation source, and prompt (or existing prompt provenance).
All 25 are opaque RGB PNGs, 1254x1254. They are not yet Apple-compliant 1024x1024
copies, production assets, uploaded localizations, or owner-approved visuals.
One shared permission question for non-generative dimension-only resizing remains
pending; do not duplicate it. The superhero Golden Egg artwork is unchanged.

Direct Apple DOM and screenshot inspection found a visibility mismatch in the
new records' defaults: showBeforeEarned=false displays Hidden=Yes, whereas the
app catalog specifies hidden=false. For Hero of Moonpetal (campaign_100), selected
showBeforeEarned=true and clicked Save; the current form then showed true and
repeatable=false. Subsequent breadcrumb navigation timed out at the CDP transport
and read-only snapshots timed out. Persistence must be reverified before claiming
the visibility correction complete. Inspect and reconcile the other 24 records
against the same runtime definition; do not recreate IDs or change point values.
No logout, remote reconnection, browser reset, or alternate Apple session was used.

No runtime files changed in this artwork checkpoint. Earlier exact-runtime test
results retain their stated boundaries; no new native or Apple submission claim.

## Apple visibility reconciliation and session expiration (2026-09-13)

The same Apple tab recovered without any logout, browser/session reset or Mac work.
Reopened Hero of Moonpetal and First Lily Trail from the catalog and independently
verified each persisted showBeforeEarned=true, points=40 and repeatable=false.
Save was then issued after field/identity checks for campaign_008 through
campaign_080 (inclusive, steps of four), changing only showBeforeEarned to true.
Those 19 records still require independent reopen/readback before considering the
visibility audit complete. Existing IDs, point values and repeatability were retained.

When opening campaign_084, the expected heading was absent. A fresh DOM snapshot
showed Apple's sign-in screen with empty Email or Phone Number and Password fields.
No sign-out action was performed. campaign_084,088,092,096 were not changed.
Resume with the same authenticated tab after owner sign-in, first rereading saves;
do not recreate records or repeat already-persisted mutations blindly.

Canonical process audit remains MATCH, zero file differences at ca7a9ba. Internal
TestFlight release-readiness was actually rerun and still reports ten failures:
the four non-device Golden Egg reviews, missing backbone evidence, disabled
achievements, third-party SDK review, creative review, audible mix review and
store-package approval. No failed gate was relabeled or waived. The harness task
confirmed no explicit sizing answer and no successful website publication; it
remains sole website lifecycle owner. Original artwork, runtime and signing assets
are unchanged. No new build/archive/upload or App Review submission occurred.
