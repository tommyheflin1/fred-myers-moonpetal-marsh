# One practical process for every Flins app

Use this alongside SHARED_BUILD_PROCESS.md and the app's existing release record.
The goal is a repeatable working build, not a new workflow on every attempt.

## Harness authority: procedural and nonvisual only

The harness owns common backend contracts, integration validation, recordkeeping,
and build/delivery procedures. It does not own game design. Harness adoption must
not change gameplay, hidden solutions, visuals, music, menu options, or add any
player-facing buttons/screens. In-game policy/license/credit UI is prohibited.
Report a presentation issue to the app owner without implementing it as harness work.
Existing authorized discovery consent is preserved, not redesigned or expanded.
Asset validation records existing materials; it does not generate or replace them.

## Work and reporting

- Separate engineering work, genuinely unanswered owner decisions, external access,
  and the next Apple gate. A raw file-difference count is not a gameplay defect count.
- Review each applicable implementation difference; preserve game rules, accepted
  visuals, menu behavior, save identity, Core pins and working native adapters.
- App-specific exceptions stay in the exact app/build decision record. They are not
  shared procedure or requirements for other apps. No exception transfers builds.
- Reuse unchanged source-bound tests and settled approvals. Fix the specific failure;
  do not repeat a full build because a document or downstream Apple state changed.
- An unresolved artwork decision must not stop unrelated migration or testing.
  Real applicable security/signing/release failures still require correction.

## Standard Apple delivery procedure

1. Inspect the app's latest successful delivery receipt and configured signing/upload
   method before planning. Preserve that method, identity and remote Mac session.
2. Reconcile candidate version/build with Apple. Freeze the tested source and verify
   the source-transfer hash. Reuse the approved internal testing group.
3. Use release-ios preflight, archive, upload, status with the exact source commit.
   Resume at the first unfinished stage; never rebuild a valid archive to retry upload.
4. Read tools/ios_release_config.json. Keep its configured signing style and upload
   method: Xcode export/upload or the supported manual export/altool configuration.
   This is one wrapper procedure with explicit configuration, not operator choice.
   Validate the installed app-specific profile/team and external key location before
   building. Never substitute another app's profile or choose a method by trial.
5. For Xcode -501, inspect exact status/logs first. Repeated account login attempts are
   not progress. Check the installed Xcode export authentication options and the
   configured existing API-key ID, issuer and external private-key location. Where
   the approved recovery supports Xcode API authentication, use those existing
   references with the same export/upload command and archive. Do not create keys,
   switch uploader, sign out, or copy credentials. If configured authentication
   cannot work, record that exact access failure instead of repeating attempts.
6. Export can alter archive metadata. Preserve the original hash checkpoint; inspect
   the exact change and query Apple's receipt. Never rewrite hashes to hide drift,
   blindly reupload, or equate export success with processing success.
7. Prove separately: processed build, tester assignment, exact device results or
   scoped approved deferrals, App Review submission, and public release. Preserve the
   owner's existing manual/automatic release setting. Internal testing is not review.

### Command and resume checklist

Use the exact clean source SHA as COMMIT in the candidate checkout on the authorized
Mac. Run `tools/release-ios preflight "$COMMIT"` only before an archive exists.
Set the verified APPLE_TEAM_ID and documented APPLE_ARCHIVE_ACK for this build;
run `tools/release-ios archive "$COMMIT"`. Set the documented APPLE_UPLOAD_ACK;
run `tools/release-ios upload "$COMMIT"`, then `tools/release-ios status "$COMMIT"`.
The wrapper validates the acknowledgements; do not invent or bypass them.

- Preflight failed: repair only its named prerequisite and rerun preflight.
- Archive passed, upload not received: preserve archive; repair the upload cause.
- Upload outcome unknown: inspect log and exact Apple status before any retry.
- Apple processing pending: wait/query; do not upload again.
- Apple processing VALID: assign the approved tester group and record build ID.
- Internal testing complete: review applicable exact-build checks/approvals, attach
  that processed build to the intended version, submit once, and record Apple's
  submission identifier/state. Public release is separate.

At each checkpoint record source SHA/tree, app/version/build, command exit result,
artifact hash/path, Apple identifier/state and next unfinished step. A remote
disconnect resumes this record; it never restarts the entire process.

## Independent functions and truthful privacy

- Native Game Center authentication, native leaderboards and achievements are not
  Golden Egg website services. They must not depend on company-website availability.
- The website is contacted only during the verified-discovery publication flow and
  explicit player choice. Don't Post sends nothing; errors never prevent normal play.
- Store materials mean listing text, screenshots, icons and achievement artwork.
  They do not mean storage of player information.
- Record separately: device-local saves/settings, platform Game Center processing,
  and optional website identity/discovery processing. Do not add data collection.
  Do not claim no data is stored or transmitted when code actually saves progress,
  uses platform identifiers, or sends a consented website discovery.
- Use the same policy structure and inventory rules across all apps, with truthful
  app-specific differences. Existing dedicated website policy URLs belong in App
  Store links; do not introduce in-game policy/license/credit buttons.

## Systematic asset records

Use governance/asset_registry.json and the existing provenance tools for every app:
exact asset path/hash, origin, recorded rights decision, use and validation evidence.
Reuse the standing music commercial-use decision; only uncovered conflicting evidence
needs a new question. Preserve required bundled notices without new player-facing UI.
App-specific music, art and screenshots remain app-specific; common recordkeeping
does not authorize replacing accepted assets or inventing approvals.

## Adoption

When a common procedure changes, change the canonical instructions, implementation
and regression tests together, version the revision, and publish one migration note
describing exactly what changed and which stage it affects. App owners apply that
revision once to their next candidate and record evidence. Do not maintain competing
per-app procedural recipes. Per-app configuration and exact approvals remain local.

Every existing/future app records the exact harness revision, applicable changes,
tests, genuine pending decisions and next delivery stage in NEXT_BUILD_ADOPTION.md.
Do not mutate already-submitted binaries just to update process documentation.
Promote reusable fixes centrally with regression evidence, then migrate each owning
app deliberately. Matching files alone never proves native or Apple success.
