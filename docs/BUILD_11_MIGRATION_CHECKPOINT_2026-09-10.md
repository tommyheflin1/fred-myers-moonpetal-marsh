# Fred Build 11 migration checkpoint

## Latest continuation: website verified; Apple Build 11 still absent

- Sites version 81 deployment appgdep_6aa317316cac8191b0dde3c5e0239da8 succeeded
  from c4eb2deb08d9ac502f0df2b37361c98fe1b23905 through another release operation.
  Fred's exact approved 2026-09-10 privacy marker passed live verification. Do not
  overwrite that newer release with the older locally packaged source.
- Apple TestFlight was checked live again: newest is 1.1 (10), uploaded September
  5. Build 11 is absent. No substitute build was submitted.
- Recorded published Apple privacy answers in the store package; no other
  compliance/device review fields were marked true without evidence.
- Reran all 39 Godot suites with isolated APPDATA/LOCALAPPDATA using the installed
  4.7.1 console engine: 39 passed, zero failed. Initial sandbox/GUI-runner attempts
  failed to launch and are not game-test failures or test evidence. The successful
  console run follows the final service-version and privacy-metadata edits.
- Five privacy regressions and 14 static Fred release-lane guards passed.
- iOS release configuration validation passes. Store release readiness still fails:
  missing exact-build screenshot inventory/capture commit, icon package path,
  Game Center record/device acceptance, Golden Egg identity/production/device
  evidence, custom-track package, reviewed store/compliance fields and update
  contract. The validator also rejects the owner-approved automatic release mode;
  do not silently change Apple's selected release mode to get a pass.
- Canonical process advanced to candidate.23 independently; current comparison
  reports five reviewed-migration differences, including the intentionally
  preserved Fred uploader. Do not claim canonical adoption or rewrite hashes merely
  to suppress drift. No signing/account reset, Mac reconnect, archive or upload ran.

The privacy deployment blocker is resolved. The next milestone is completion of
the actual candidate/store/native preflight, not another website upload retry.

Target: 1.1 (11), com.flinsvault.fredmyers, team W6WBR6N6S8.
Base commit: 59f681e669ec186469198e83c68aeea4133cf80d.
The working migration is not a frozen or uploaded candidate.

## Verified this session

- Apple TestFlight still lists 1.1 (10) as the newest upload. Build 11 is absent.
- 39 Godot suites passed using isolated APPDATA/LOCALAPPDATA, including Pause,
  Golden Egg return to Level 5, website integration fixtures and 14 new secure-storage checks.
- Five existing Python script suites passed, 76 checks. Fixed legacy validators
  still expecting Build 8 and a non-worktree workspace location; no gate was waived.
- The live update-policy check returned HTTP 200, app-bound, current, signature present.
  This is not device enforcement or cryptographic verification evidence.
- iOS Golden Egg storage now uses the native app-scoped Keychain bridge, fails closed
  without it, and preserves legacy credentials until migration readback succeeds.
- Current shared native-plugin patches were copied; native compilation/device proof is pending.

## Preserve the proven lane

The canonical shared-tool copy would have replaced Fred's explicit manual profile,
exported-IPA Game Center check and existing altool API-key upload with a different
upload configuration. Those Fred steps were restored before execution. Added shared
Release-export, bundle scans, icon checks and compliance staging remain.

Consequently apple_delivery.sh intentionally differs from canonical candidate.21.
The canonical digest is NOT rewritten to disguise this difference. Shared-tool
migration is pending tested reconciliation; a copy-only MATCH was not readiness.
Do not execute archive/upload against this dirty partial migration.
Do not reset signing, remove profiles, change accounts or overwrite previous archives.

## Outstanding release gates

- App-owned store/app_store_package.json and screenshot, audio and Game Center
  draft manifests now exist. Their outstanding evidence fields remain false;
  screenshot captures and rights records are not fabricated. Draft validation
  exposes missing Golden Egg identity-contract declarations, mandatory-update
  configuration and a release-mode validator that does not handle the already
  owner-authorized automatic release. Release validation remains failing.
- governance/asset_registry.json is missing. Existing reports explicitly leave
  commercial rights to the two owner-supplied music tracks unconfirmed at the time.
  This was superseded by the owner's explicit music approval on 2026-09-10, now
  recorded with exact file hashes in store/audio_package.json. Preserve assets.
- Release config lacks the reviewed uses_non_exempt_encryption declaration required
  by the migrated script. Check the existing Apple answer and actual dependency inventory.
- Native Keychain compile/device tests, signed archive and exported entitlement
  verification, upload acceptance and Build 11 processing remain unproven.
- The copied lifecycle modules alone do not integrate mandatory-update behavior into Fred.
  Review actual runtime wiring and signed-policy verification before claiming enforcement.

Windows Godot emitted root-certificate-store warnings during headless tests. Local
fixture success does not certify production TLS, native Game Center, live website
identity/consent, physical-device gameplay, TestFlight or App Review.

No Mac login, signing asset, existing Apple submission, production policy minimum,
or public release setting was changed during this checkpoint.

## Continued integration review

The active Build 11 GoldenEggService still declared BUILD_VERSION = "10" and its
website fixture expected that obsolete value. Corrected the service to "11" and
added independent assertions against game/game.json for both build and marketing
version. The updated website fixture suite passed 17 checks with isolated data.
The full 39-suite result above predates this final service/metadata edit.

game/game.json display_name now matches the live Apple product name
"Fred Myers: Moonpetal Marsh" (within Apple's 30-character limit); bundle, game,
version/build, SKU and save identities are unchanged.

Requested a factual owner confirmation for The Marshland March and Marshland
Chase. The owner subsequently replied "MUSIC IS APPROVED"; the approval is now
recorded in store/audio_package.json. Do not repeat this approval request.

## Privacy gate follow-up

Added privacy.persistent_local_data=true, reflecting the existing save/inventory
contract rather than a new data flow. The repository's privacy-policy verifier
passed against the existing public policy: exact app and policy-version markers.
Its first sandboxed request failed with WinError 10013; the same read-only check
passed with approved network access. No website or policy-content deployment ran.

The live minimum-build endpoint check again passed its HTTP/app-binding/freshness/
signature-presence checks, not native enforcement or signature verification.

The first pass found no godot/ios/PrivacyInfo.xcprivacy. The subsequent privacy
reconciliation added it with explicit linked User ID/Gameplay Content declarations,
App Functionality purpose, no tracking, and pinned-engine required-reason API
declarations. Structure validation and five local privacy regressions pass.
Actual native export/signature inclusion remains unverified; earlier Build 1
privacy evidence is not the new candidate's shipped-manifest evidence.

See BUILD_11_PRIVACY_VERIFICATION_2026-09-10.md for the subsequent content review:
the updated website policy/inventory is staged locally and all 142 website tests
pass. After explicit owner approval, Apple publication completed: User ID and
Gameplay Content, linked to the player, App Functionality only, no tracking.
Apple's published preview no longer says Data Not Collected and has no incomplete
category warning. The inventory is approved and synchronized to the local website
registry. Website publication was subsequently verified live in version 81,
including the Fred policy update; newer version 82 retains it. Native signed-manifest inclusion also
remains unverified. Do not mark those remaining gates complete.

## Packaging and integration follow-up

- Preserved the exact two owner-approved music files and hashes; moved them into
  assets/audio/custom and updated preload paths and audio_package track inventory.
- Re-ran all 39 local Godot suites after that change. All 38 RESULT summaries report
  zero failed assertions; secure-storage reports 14 checks, zero failures.
  Logs: C:/Users/tommy/AppData/Local/Temp/fred-build11-regressions-f3eb41e22bd640168970df486dbc22b9.
  The ad-hoc runner initially misclassified `_failed=0` as failure; log review
  corrected the classification, not any game code. ObjectDB/resource shutdown
  warnings remain; these results are not native device acceptance.
- Generated fresh iPhone and iPad format images in builds/store-build11 with the
  existing capture tool and real OpenGL renderer. They are current dirty-source
  captures, not frozen-commit or physical-device screenshots.
- Copied the existing 1024x1024 opaque approved icon into assets/store/app-icon.png;
  the native export icon path and artwork remain unchanged.
- Reviewed both live Apple Game Center leaderboard records: exact runtime IDs,
  integer best score, high-to-low, visible. Both still Prepare for Submission.
- Apple still has Build 10 selected for version 1.1. Build 11 is not submitted.
- Found and reproduced a website integration defect: Fred's identity exchange
  returned 403 because its bundle was missing from the allowed game map. Added
  its exact bundle and reused the hardened certificate/signed-team binding lane.
  Two real-handler Fred regressions fail before the fix and pass after it;
  all 146 website tests and the production build pass. Source pushed:
  f4fd3485c1c2217c8d557a76639d8f4fc461e4c5. Deployment confirmation pending.

### Subsequent verified fixes and remaining boundary

- Website package transfer failed twice at the native Sites file-upload service,
  each after 60 seconds. No new saved/deployed version was returned. Version 82
  remains the last observed live version; the Fred endpoint fix is NOT claimed live.
- Reviewed Apple age-rating questionnaire (no edits): 9+ with regional exceptions,
  infrequent fantasy violence and contests; other sensitive categories absent.
- Migrated the four reviewed candidate-23 privacy/documentation differences.
  Current live policy passes the strict consent-marker check; exact data inventory
  now includes linked functionality data and explicit no-ad/broker/cross-company
  advertising declarations. This reflects already-approved behavior, not new collection.
- Fixed shared automatic-release approval validation as harness candidate 24,
  commit 0d5442cb935e209167d7e33786f4cf764cddcb0d. Ten store-package tests,
  two generated-game smoke tests and canonical self-audit pass. Fleet audit ran;
  other apps remain unmigrated. Fred now differs only in apple_delivery.sh,
  intentionally preserving its proven manual-profile/export/altool lane. That
  outstanding difference still fails the migration gate; no digest was fabricated.
- Fixed cold-start Game Center metadata refresh for an already authenticated device;
  48 adapter checks pass. Golden Egg registration requests fresh identity, does not
  auto-link offline discoveries at launch, and retains the original account binding.
  Added explicit saved-discovery review from the title for later retry; no hidden
  gameplay solution or existing leaderboard ID was changed. Service fixtures pass
  25 checks; the Level 5 return remains tested separately.
- The existing Apple version 1.1 still has Build 10 selected, not Build 11.
  Native compile, signed manifest, device acceptance, Build 11 upload and Apple
  review are not yet proven. No Mac session, account or signing asset was reset.

### Restart recovery verification

- Fixed accepted-discovery recovery: the bounded public snapshot is stored through
  the existing private store and restored on launch without any network request or
  automatic consent change. The saved-egg review remains available after acceptance.
  A failed snapshot write keeps the pending idempotent operation recoverable.
- Added six restart/privacy regressions: accepted identity/link and last confirmed
  privacy survive restart; Anonymous can be selected after restart and persists.
  Website integration now passes 31 checks. All 39 Godot suites were rerun after
  this change and completed with zero failed suites (2026-09-10).
- Rendered the saved-review title button at 2868x1320 using the real OpenGL renderer.
  It is readable, within the playfield and separate from existing controls. Evidence
  is under godot/builds/recovery-layout. This is desktop rendering, not iOS proof.
- A third native Sites package-save attempt timed out after 60004 ms. Reconciliation
  still returns version 82, not the Fred fix. No production success is claimed.
- Live Apple pricing/availability summary shows 143 available and 32 unavailable
  territories. No price, availability, account or release setting was changed.
  Detailed price inspection was blocked by the UI action safety check; that review
  remains incomplete. Release readiness still fails; Build 11 is not submitted.

### Proven-lane migration completed

- Harness candidate 25, c3e0791e0fa3bbd67c1e891336c9d10db91d73e7,
  carries Fred's established manual export/validate/altool sequence as explicit
  app configuration. Default Xcode delivery is unchanged for other apps.
- Fred selects its existing exact profile name, manual signing and altool. On the
  Mac, that name must resolve uniquely to an installed, validated distribution
  profile; the verified UUID is used without regenerating signing assets.
- All 99 canonical harness tests pass, including generated-game smoke checks.
  Bash syntax validation, 15 Fred release guards and exact configuration validation
  pass. Fred's canonical process audit now reports MATCH with no differences.
- Fleet audit ran; other independently released apps remain unmigrated and were
  not modified. The harness commit is local; no unapproved shared-source push occurred.
- No Mac build or upload ran during this migration. Live browser inspection found
  App Store Connect at sign-in and the existing remote view showing wallpaper only.
  The safety check rejected a wake click on the unverified remote surface; no
  reconnect, reboot, account reset or signing mutation was performed.

### Existing session and source exposure follow-up

- The next read-only remote screenshot showed the Mac awake, with TurboRack's
  idle Python terminal in front. No wake, logout or restart was needed. Opening
  the visible Shell menu for a separate Fred tab was rejected by the action safety
  checker; exact-action approval was requested without touching TurboRack.
- GitHub repository metadata now independently confirms the configured Fred origin
  is PUBLIC (repository 1299883593). New candidate work remains local; no private
  branch is assumed private within that public repository. Use the already-approved
  private source handoff instead of silently publishing candidate source.
- Added an initial 14-asset provenance registry with exact file hashes and existing
  project evidence. Recorded the owner's two music-rights confirmations without
  inferring raw-source redistribution rights. Unknown license/notice decisions
  remain explicit YELLOW findings; no asset was removed, replaced or relicensed.
- Advisory provenance audit ran, and the standard notice generator ran with zero
  verified attribution-bearing entries. This is not provenance release clearance.
  Documentation captures and internal/native dependencies remain to reconcile.
- Website status reconciliation still reports version 82, not the staged Fred
  identity fix. No additional unsuccessful transfer was repeated in this follow-up.

### Remote control recovered; external delivery still incomplete

- Opened one separate Terminal tab in the existing RDP session. TurboRack's
  existing tabs and Python prompt were preserved. Keyboard events work; browser
  text insertion/clipboard did not deliver shell text, so short read-only commands
  were entered with verified key events instead. No reconnect or account reset.
- Located `/Users/admin/downloads/fred-build10-81814f7` and entered it only for
  inspection. `git status --short` completed with no output. Its old release
  artifacts were not modified. This is not the newer local Build 11 candidate.
- `git show -s` completed at the Mac prompt: commit begins `c1911a4`, subject
  `Restore proven API-key Apple upload lane`, dated September 5. The folder name
  is therefore not authoritative source provenance. Preserve this historical lane.
- Canonical process audit reran: candidate 25 MATCH, no differences; runtime and
  Apple verification remain false. Store readiness reran and reported 25 missing
  gates, including native/device, production integration, media and store reviews.
- Apple now displays the signed-in owner, but Apps navigation repeatedly shows
  an empty app list and an unrelated News Request error. No current Fred build or
  submission state could be verified from that page. No Apple settings changed.
- Retried the unchanged validated website archive using native Sites saving.
  File upload timed out after 60002 ms, request
  `d66cf0dc-25ca-4470-8c5f-13314ffdcf15`. Reconciliation still shows version 82 at
  `b5290d95f00b8bb25d2fb0aced71ef211c0eeeec`; the Fred identity fix at
  `f4fd3485c1c2217c8d557a76639d8f4fc461e4c5` is not saved/deployed.
- No new archive, signing, upload, TestFlight assignment or App Review submission
  ran in this follow-up. Existing sessions and signing assets remain intact.

### Dedicated support requirement implemented

- Created a separate writable website worktree at
  `worktrees/fred-website-release` from the preserved website candidate. The
  original checkout remains unchanged. Its ignored dependency junction reuses
  the existing installed packages; no dependency versions changed.
- Added `/fred-myers/support` with the exact support marker, established contact,
  save-preservation advice, Pause guidance, provider-name consent/Anonymous rules,
  Level 5 return and honest unreleased Build 11 labeling. Added only this support
  route to the existing public page allowlist; no authentication reset or broader
  public access change.
- Production website build passed. All 147 website tests passed; the support
  regression was rerun after adding its public-route assertion and passed.
- Committed and pushed website source
  `3aa9d3df33bba143570bd364363b9df7f150acff` to its existing approved Sites origin.
  This includes the preceding Fred identity fix; no private game source was pushed.
- Standard package helper succeeded, but native saving failed again at the file
  transport: 60001 ms timeout, request `3861ec64-d45c-4ecb-9b82-df82136bbcb7`.
  The package is retained at
  `worktrees/fred-website-release/outputs/fred-support-3aa9d3d.tar.gz`.
  Neither the support page nor identity fix is proven live.
- Rechecked local Fred privacy reconciliation: five tests passed. Static release
  lane guards executed and reported 15 passing checks (not native Mac tests).
  App Store Connect still returns an empty app list. No archive or upload ran.

### Apple command-line status verified

- Inspected the actual Mac `tools/release-ios` entry point, then ran its status
  mode for exact preserved commit `c1911a422cc33cbd317a5144fbf4a35858f26a09` in
  `/Users/admin/downloads/fred-build10-81814f7/godot`.
- The historical process audit returned candidate 1.6.0-candidate.8 MATCH;
  checkpoint and iOS release configuration checks passed. This is the old
  preserved lane, not proof that Build 11 was transferred or compiled.
- The existing external credential successfully reached Apple. Response:
  version `1.1`, build `10`, processing_state `VALID`, processing_verified true,
  status `APPLE_PROCESSED`, Apple build ID
  `67b04dfd-7c1b-4160-83ee-eae9cf829fd6`. The response's release_authorized was
  false; status does not prove App Review submission or public release.
- This resolves command-line Apple connectivity as a suspected blocker. The
  browser app list remains unavailable, but account resets are unnecessary.
- Added source-level dependency/encryption review in
  `BUILD_11_RUNTIME_DEPENDENCY_REVIEW_2026-09-10.md`. No unsupported encryption
  declaration or native SDK clearance was entered. Build 11 is still unarchived
  and unsubmitted, with production website publishing and native/device gates open.

### Publishing failure isolated without production changes

- Reverified the website checkout is clean at
  `3aa9d3df33bba143570bd364363b9df7f150acff`; retained package SHA-256 is
  `b67fed7a865601012c72c70e942989792c4b67bd39bde907391aa34557720971`.
- Native version save again failed after 60006 ms at the external file-blob
  upload, request `5b571586-8c84-40aa-9df4-1ea689e6b7ca`. No new saved version
  or deployment resulted. Do not repeatedly rebuild identical validated source.
- A credential-free HEAD request to that upload host returned HTTP 400 promptly,
  proving local DNS/TLS reachability only, not upload capability. The failure is
  not evidence that the remote Mac or its signing assets need repair.
- Sites metadata confirms active, not disabled, public audience and version 82.
  Anonymous CLI checks of the Fred support/privacy routes returned a Cloudflare
  `Just a moment...` challenge (403); they do not establish actual page content,
  policy failure or successful live integration. No challenge was bypassed, no
  real player records accessed and no access/security settings changed.

### First-TestFlight sequencing and focused reruns

- Re-ran iOS preparation (10 checks) and static release-lane guards (15 checks):
  passed. Re-ran Pause regression (36 checks) and Golden Egg integration/restart
  recovery (31 checks) using separate temporary user-data directories: passed.
  Integration transport is fictional; test labels do not certify live requests,
  Apple signing, physical multitouch or device acceptance.
- Requested the mandatory exact-version/build authorization to defer only
  `game_center.on_device_authentication_tested`,
  `game_center.on_device_replay_tested` and
  `golden_egg.physical_device_flow_reviewed` for first internal TestFlight of
  version 1.1 Build 11, with all three required again before App Review.
  No response has been recorded and no exception was inserted. General release
  approval is not silently converted into this narrowly defined deferral.
- Production website, media, rights and all other readiness gates remain unchanged.

### Owner response recorded for the specific TestFlight deferral

- Following the explicit three-check question, the owner again directed
  "MOVE FORWARD". This response was interpreted and announced as approval of
  that specific first-internal-TestFlight deferral, not a blanket gate waiver.
- Added precisely those three `release_exceptions`, bound to version 1.1,
  build 11 and `deferred_until: app-review`. Device evidence fields remain false.
- Four new regression tests passed: exact gate set, internal-only scope,
  non-transferability to another build/version, no production/music waiver and
  preservation of unverified device evidence.
- Ran both readiness purposes. Internal TestFlight now reports 22 remaining
  failures; App Review still reports all 25, including the three device gates.
  This is intended separation, not a passing preflight or upload authorization
  beyond the existing owner request. No signing, archive or upload was run.

### Live Apple review and complete local regression rerun

- Live TestFlight lists version 1.1 Builds 10, 9, 7 and 6. Build 10 is Ready
  to Submit; Build 11 is absent. Build 8 has a failed upload. No older binary
  was substituted for the requested Build 11.
- Reviewed current USD 2.99 base price, 143 available / 32 unavailable
  territories, public App Store availability, and active agreements, tax and
  banking. Recorded three completed review gates in the store package without
  changing prices, territories, financial information or Apple settings.
- The normal browser successfully rendered the dedicated September 10 Fred
  privacy policy: linked Game Center identity, provider-reported name,
  affirmative public consent, Anonymous fallback, retention and contact
  disclosures are present. This visual check does not replace the harness HTTP
  marker verifier or an authenticated production discovery test.
- Added `run_soundtrack_lifecycle.gd` using actual packaged MP3 streams with
  the dummy audio driver. Reproduced a missing background suspension for the
  Golden Egg chime. Added chime pause/resume handling alongside the existing
  two music players. No soundtrack files, gameplay rules or save schema changed.
- Ran all 40 `tests/run_*.gd` suites after the fix with separate temporary
  APPDATA/LOCALAPPDATA directories. All 40 exited 0, including Pause, Golden
  Egg integration, secure storage and the new soundtrack lifecycle suite.
  The new suite has 26 assertions. Dummy-driver tests do not assess audible
  loop seams, device mixing, native Game Center or physical-device behavior.
  Godot resource/ObjectDB exit warnings occurred in the focused test; no
  warning-free native build is claimed.
- Canonical process audit remains candidate 25 MATCH. Internal TestFlight
  store readiness still fails 19 gates, including live integration, music
  listening review, exact-build screenshots/owner visual review, compliance
  and the unconfigured mandatory-update contract. Do not mark these true
  merely because automated regression passed.
- Reconciled Sites saved versions: latest remains 82, source
  `b5290d95f00b8bb25d2fb0aced71ef211c0eeeec`, not the requested fix. Retried
  the unchanged, previously built and pushed website package for source
  `3aa9d3df33bba143570bd364363b9df7f150acff` through the native save operation.
  File upload again timed out after 60001 ms; request
  `1fa2fcb3-231e-47d0-8d7d-cbf4e935b3f2`. No saved version or deployment was
  returned. The existing release is untouched; no alternative uploader or
  security bypass was introduced.
- Build 11 remains uncommitted/unfrozen, unarchived and unsubmitted. Existing
  Mac session, Apple authentication, certificates and provisioning retained.

### Follow-up: upload-path isolation and actual soundtrack loop verification

- The unchanged website package is locally readable, is not an offline-only
  OneDrive placeholder, and its SHA-256 still matches the recorded value.
  Copied it into a new local temporary directory and verified the same hash
  and readable tar contents. The native Sites save failed there too after
  60001 ms, request `14b69dc6-d070-4cb9-a081-836de639cbd8`. This rules out
  the OneDrive folder path as the cause of this observed upload failure;
  it does not identify the infrastructure fault inside the file service.
  Reconciled saved versions first: version 82 still lacked the requested fix.
- Expanded the real-stream soundtrack regression to seek both packaged tracks
  to 50 ms before their end and verify playback wraps without stopping.
  All 28 assertions passed, including screen transitions, pause, background,
  foreground, mute and home. A verbose rerun also passed with no resource
  warnings in that run; earlier intermittent exit warnings are not erased.
- Recorded the automated loop/transition evidence in `audio_package.json`.
  Physical-device listening, audible-seam and mix review remain unverified;
  `runtime_mix_reviewed` stays false. Internal TestFlight readiness now has
  18 failures, not 18 demonstrated gameplay defects. Many are uncompleted
  release evidence/approval requirements. Build 11 is not submitted.

### Explicit Build 11 photos and testing approval

- Owner explicitly approved the existing Build 11 photos and proceeding to
  testing. Recorded `media.visual_owner_reviewed: true` with the exact scope.
  This does not invent screenshot capture commits or hashes. Internal
  TestFlight readiness now reports 17 failures; broad testing approval was
  not recorded as completed tests or used to alter the shared release gate.
- Checked saved website versions before retrying: no version for the required
  source exists. The unchanged validated package again failed in the native
  save operation after 60001 ms, request
  `692dd9ac-1d17-473b-9145-c4b0e5858266`, at OpenAI file-blob upload to
  `sdmntprwestcentralus.oaiusercontent.com`. No deployment was started.
  Local tests, archive readability and the outside-OneDrive retry do not
  expose an actionable project defect that would repair this service failure.
  Further identical retries should wait for a service-state change; do not
  reset Mac/Xcode, change credentials, remove site assets or bypass the
  required archive to disguise the failed transfer.

### Continued combined Build 11 fixes and live delivery checks

- Added the existing TurboRack/Core signed mandatory-update integration for Fred,
  including the exact public verification key, fail-closed launch/foreground/expiry,
  bounded requests, input/simulation/audio blocking, Retry and the exact App Store
  product link. Fictional policy tests passed 53 checks. This is not live service
  or iOS execution proof.
- Added runtime-derived offline license notices and the pinned native plugin's
  verified license. A review found that its first title-button position overlapped
  REVIEW SAVED GOLDEN EGG; moved it to the upper right and added a regression for
  the formerly overlapping point. Removed the now-misleading PLAY INSTANTLY footer.
- Combined desktop run before that rectangle correction: 43 suites, 146850 checks,
  zero failed. Eighteen suites reported shutdown ObjectDB/resource warnings, not
  hidden as clean exits. 91 app release/preparation checks, 12 Fred Python cases
  and 99 canonical shared-harness cases passed. Logs are retained under
  `builds/validation/combined-20260910-184901`. Final changed scenes are rerun
  separately; this total must not be presented as native or final-commit proof.
- Process audit remains candidate25 MATCH. Existing diff-check warnings within
  the signed-identity unified-patch context are not trimmed because doing so would
  change the actual patch and its recorded hash.
- Live Apple inspection still lists 1.1 Build 10 as the newest uploaded binary,
  Validated / Ready to Submit; Build 11 is absent. Neither TestFlight upload nor
  App Review submission occurred. The existing remote session and signing state
  were preserved; no Mac reset, logout or competing session was used.
- Added Fred to the existing website signed-policy route, using minimum build 1
  and the exact product URL. Production environment revision 8 stages only those
  two non-secret Fred settings for a future deployment. The existing secret and
  key ID were not replaced and no live minimum was raised.
- Website c0807276b62185c0988655886fc39ca92c99d30e was tested (148 tests and a
  production build), committed and pushed to its existing Sites origin. The
  standard archive was 22678116 bytes, SHA-256
  f22f8c5c094093a79b519feb7da8a425fb9d30dff4b8f1cb33ce5202de4d5404.
  Native version-save failed again after 60006 ms at the service's blob uploader,
  request 79dd340f-ea62-4b63-b729-4d862027e85c. No new version ID was returned.
- A read-only diagnostic established that the upload hostname resolves and HTTPS
  responds (HTTP 400 at its unparameterized root); no network/security settings
  were changed. This does not establish that the signed file-upload operation works.
- The repository's live update-policy gate actually ran and returned HTTP 404.
  The unshipped client is intentionally blocked until the production service works.
  Apple launch readiness cannot be asserted or bypassed while this is unresolved.
- Further source review found a real Golden Egg consent gap beyond the previous
  tests: a saved identity was not sufficiently fresh and the exact public name
  was not shown before consent. App correction is in progress. Website correction
  adds authenticated stored-name preview, bounded fresh verification and matching
  reviewed-name confirmation for new Build 11 discoveries, while preserving
  Anonymous revocation and old Build 10 records. The actual route/SQL fixture suite
  and all website tests now pass (152); these latest changes are not deployed.
- Revised privacy wording for required online version checks is prepared as
  fred-myers-2026-09-10-v2, draft pending the specific owner review. Earlier
  policy and broad testing approvals are not fabricated as approval of new text.

This checkpoint is not release clearance. Local source is still uncommitted on
59f681e669ec186469198e83c68aeea4133cf80d. Final source/scene tests, frozen screenshot
registration, rights/SDK and audio acceptance, live website verification and the
native release chain remain distinct. The three previously approved device
deferrals remain limited to first internal TestFlight; no additional waiver was added.

### September 12 continuation

See `godot/docs/BUILD_11_GOLDEN_EGG_REVIEW_2026-09-12.md` for the newer evidence.
The original frog-medallion Golden Egg is implemented and rendered; the gameplay-HUD
boundary and fresh public-name review corrections are now tested. Export exclusions
are tightened and an actual unsigned pack inspection passes. All 47 game suites pass;
nine shutdown audio-resource warning logs remain explicitly recorded. Website upload
still fails in the connector's file transport, the public update policy returns 404,
the revised privacy policy remains draft, and the Apple browser is signed out.
No archive/upload/submission is claimed and no released baseline was changed.
