# Versioned development-to-Apple process

Process 1.8 candidate 32, reviewed 2026-09-14. This is a shared operating contract,
not a production monorepo or permission to change released apps.

## Development and reuse

Read `docs/OWNER_WEBSITE_CONTACT_DECISION.md` before website integration work or an
owner approval question. It records the latest discovery-only contact instruction
and supersedes older optional company-website polling defaults for app runtime.

1. Inventory the actual branch, dirty files, commit/tree, game/store/save identities,
   pinned Core/Godot/plugins and enabled features. Preserve dirty work and owner saves.
2. Start new apps with `tools/new_game.py`. Run `tools/audit_process.py` on the result.
   Existing apps need reviewed migrations, not regeneration over an existing folder.
3. Keep rules/content/assets app-owned. Promote only tested provider-neutral behavior
   to Core, then explicitly migrate consumers. Never infer compatibility from version labels.
4. Run isolated deterministic rules, save migration/corruption/backup recovery,
   input arbitration, touch release/cancellation, pause/home/background/resume,
   audio/haptics and restart tests. Use temporary user-data locations, never owner saves.
5. Test real scene input in addition to pure rules. Review phone and tablet safe areas,
   HUD overlap, readable prompts, reduced-motion/accessibility, frame time and memory.
   Desktop pointer simulation is not real multi-touch or physical-device evidence.
6. Inventory third-party asset licenses, runtime exports and dependencies. Export no
   tests, private reports, keys, screenshots of accounts, local saves or build caches.
   Register material production assets and dependencies in
   `governance/asset_registry.json`; generate exact required notices and run the IP
   provenance audit. Unknowns remain unknown. Do not silently source external content
   or remediate retrospective findings before owner review. Development audit findings
   are advisory and do not stop research, prototypes, or original creation. Validate an
   external item before production adoption; if evidence is unavailable, pause only that
   adoption for an item-specific owner decision. Release remains fail-closed.
7. Reconcile feature/data inventory with the dedicated website privacy policy and
   App Store answers. Golden Egg website submission is separate from a local solve;
   pending/rejected transport never becomes verified. Golden Egg finder names must
   follow the bundled Game Center identity skill: no website-entered names, fresh
   server-verified Apple identity, consent-gated provider-reported display name, and
   Anonymous fallback. Classify the transmitted identifier, display name, and discovery
   record as linked user data used for app functionality, not tracking, while forbidding
   advertising, broker sharing, and cross-company ad linkage. Do not embed shared signing keys.
   GOLDEN EGG WEBSITE INTEGRATION IS DISCOVERY-TRIGGERED, NOT STARTUP-TRIGGERED.
   Launch, menu, gameplay, Game Center, native leaderboards and achievements must make
   zero Golden Egg requests. Only local discovery verification, reveal, fresh identity
   resolution and the explicit YES/NO public-name choice may activate submission.
   Failures remain nonblocking, durable and idempotent; server success is never invented.
8. Freeze the tested candidate and preserve sanitized, exact-SHA evidence in CI.
9. Complete the app-owned creative contract and versioned App Store package. Game
   Center titles must reconcile runtime IDs with `store/game_center.json`; each declared
   achievement needs unique 1024x1024 artwork, localized before/after text, behavior
   flags and points within Apple's per-item and app-total limits. Golden Egg titles must
   additionally clear all five website/identity/privacy/production/device gates.
   Every game must ship custom game-specific music recorded in `store/audio_package.json`
   with file hashes, provenance, rights review, runtime mix and loop/transition proof.
   Draft metadata does not prove story, icon or screenshots are approved. Run
   `tools/store_readiness.py release --verify-live` before Apple preflight.
   Public app, website, policy, support, achievement and marketing copy must be
   vendor-neutral and contain no discretionary external company or website names.
   Record narrowly required attribution, privacy, platform labels and first-party URLs
   separately with their exact legal or contractual basis.
   Any exception must be explicitly owner-approved for one named gate and the exact
   version/build. Never infer a blanket waiver from approval to finish or release.
10. If explicitly enabled, configure the separate signed mandatory-update policy and App Store product URL. The
    client must check before gameplay and on foreground, fail closed without a valid
    policy, and provide no continue/offline bypass. Keep the live minimum compatible
    with the currently public build throughout development and Apple review.
    Apple preflight must receive an HTTP 200 policy bound to the exact app and iOS,
    with a current bounded validity window and nonempty signature/key identifier.

## Apple: one lane, separately proven gates

Read the Apple skill's remote-mac-setup, standard-release-process and build-and-upload
references. The standard remains `tools/release-ios preflight → archive → upload → status`.
Each invocation takes the exact candidate SHA. This is our supported lane, not a claim
that Apple forbids its other official upload methods.

- Remote Mac: approved remote desktop; no credentials in chat, bundles or source;
  initialized Xcode, selected developer directory, supported SDK, matching Godot/export
  templates, SCons for the pinned native plugin, adequate space and caffeinate.
- Preflight: process lock matches; local regression evidence reviewed; exact clean
  commit/tree; approved store package and dedicated policy/support pages live;
  IP provenance release gate passes; correct ASC app/auth; doctor/import/unsigned build.
- Native Game Center builds apply and record both the scene-presentation patch and
  the signed-identity patch. Provenance must include both patch hashes; the latter
  exposes team- and game-scoped player IDs in authentication and signature events.
- Archive: separate owner authorization; signed bundle/version/build and true Game Center
  entitlement verified; record source identity plus archive content hash atomically.
- Upload: separate authorization; refuse stale checkpoints or altered archives. Preserve
  logs. On an ambiguous network outcome query Apple before attempting another upload.
- Status: only exact version/build with `processingState=VALID` and not expired exits 0.
  Pending/absent/unknown exits 3; failed/invalid/expired exits 2. Neither proves tester
  assignment, installed-device success, review submission or public release.
- TestFlight: explicitly authorized group, then actual iPhone/iPad install and fresh/upgrade
  save test; offline guest, Game Center login cancellation/relogin/native leaderboard,
  achievement replay, pause on native overlays, Golden Egg privacy/website flow.
  Also prove the supported build enters gameplay, a lower fictional build is blocked,
  invalid/expired/wrong-app policy is blocked, and the App Store button opens the exact app.
- Review: reconcile privacy manifest/required-reason APIs, privacy answers, age ratings,
  screenshots, support URL, export compliance, agreements and Game Center records.
  Submit only when authorized. Public release is a separate decision; do not silently
  change an existing app's owner-selected release setting.

## Mandatory-update activation after release

Apple automatic downloads are a user-controlled convenience, not a force-install
mechanism. The game enforces the requirement with a signed server minimum build.
Read `.agents/skills/mandatory-app-update/SKILL.md` and its activation reference.

Do not raise the production minimum during archive, upload, processing, TestFlight,
or review. After separately authorized public release, verify the exact replacement
version/build is downloadable from the public product page in every supported
storefront and on each supported device class. Prefer release-to-all for mandatory
migrations; phased release is not evidence that every automatic-update user has the
replacement. A separate owner-approved policy activation raises the minimum. Then
verify an old production build is blocked and the replacement plays. Record the signed
policy digest and previous/new minimum so the same authenticated channel can lower it
for recovery. Because the requested behavior fails closed, a policy outage can block
all players; monitoring and rollback readiness are release requirements.

Never overwrite an existing version/build lane with a different commit. Old checkpoints
without source-tree/archive hashes need a reviewed migration or a new candidate; do not
fabricate missing provenance. Never rerun preflight over a preserved signed archive.

## Stable change processing

Candidate 32 distinguishes tracked review evidence from production assets. Files under
`docs/evidence/` remain documentation and are excluded from the production provenance
scan because the release process separately forbids exporting that directory. Material
selected for an app or store package still belongs in a production path and must be
registered normally; moving a file under `docs/evidence/` is never a clearance mechanism.

Candidate 30 adds the tested shared publication-v2 wire adapter and identity-exchange
protocol header. Read `docs/GOLDEN_EGG_PUBLICATION_V2.md`. It does not replace each
app's authenticated transport, or certify website deployment and native-device behavior.

Universal backbone enforcement is defined by `BACKBONE_CONTRACT.json` and
`docs/UNIVERSAL_BACKBONE.md`. Release validation rejects disabled common services
and missing/stale per-app integration evidence. Run the canonical fleet audit with
`--discover --backbone` to include unregistered candidates. A common contract change
invalidates old reviews by its hash; never equate matching tools with working features.

Candidate 28 makes Golden Egg networking event-driven. Shared configuration and release
validation require zero startup requests, gameplay/backend independence, independent
Game Center, post-discovery consent, nonblocking durable retry and idempotency. New apps
default version enforcement to disabled; an existing app may retain it only through
explicit `updates.enabled: true`. This candidate does not migrate existing games merely
because their files differ: Fred, TurboRack and every registered participant require
an active-candidate audit and app-owned regression before adoption.

Candidate 27 bounds native callback draining to 32 events per frame and continues
polling after authentication, preserving callback order and timeout/UI progress.
See `docs/NATIVE_EVENT_PUMP.md`. Fred explicitly adopts the helper and refreshes
identity fields before reconnecting. This does not certify native-device behavior,
alter leaderboard IDs, or migrate TurboRack or other released apps automatically.

Candidate 26 fixes the privacy-registry serialization mismatch reproduced by Fred
Build 11. App inventories retain nested snake_case audit records; website registry
entries receive the established camelCase booleans, linkage, purpose and consent
fields. Translation rejects inconsistent inventories, and direct sync rejects drafts
before modifying the website. Dedicated policy pages still require their own exact
marker/content review and publication. This does not approve privacy text, fix a
hosting transport outage, change any player data, or replace the Apple release lane.
Existing apps adopt the three changed shared files and reviewed lock explicitly;
future generated apps inherit them. Preserve previous signed release checkpoints.

Candidate 25 preserves an existing manual export/altool delivery configuration
inside the same guarded release-ios commands. Apps explicitly select
`upload_method: altool` and manual signing; the default Xcode upload is unchanged.
An existing profile can be selected by exact `app_store_profile_name` instead of
UUID, never both. The installed profile must resolve unambiguously and pass the
same app/team/expiry/distribution/private-key checks; its verified UUID is then
used for archive/export. The exported IPA is checked before validation/upload.
No key is copied, no certificate/profile is recreated and no app is auto-migrated.
This is configuration support for the proven Fred lane, not new Apple/device proof.

Candidate 24 corrects validation of an already owner-approved automatic Apple
release. Manual remains the default. Automatic mode requires a separate
`release_authorization` record naming the mode, exact version/build, affirmative
owner approval and nonempty reason. Stale, missing or unrelated approvals fail.
This does not change Apple settings, perform publication, or waive any test gate.

Candidate 23 binds each live Golden Egg app policy to the website's machine-readable
`game-center-consent-v1` public-name contract. Live verification now fails when an exact
policy page lacks that marker, preventing a generic privacy page from satisfying release.
The corresponding Hunt and app policy text must say that names come only from a fresh
verified Game Center session, typed substitutes are forbidden, consent is affirmative
and revocable with Anonymous fallback, and consent is not advertising tracking.

Candidate 22 makes the Golden Egg privacy classification machine-verifiable. When the
feature is enabled, its player identifier, provider-reported display name, and discovery
record are declared as linked user data used for app functionality. Public-name consent
controls website publication and is not an advertising-tracking permission. Advertising,
data-broker sharing, and cross-company advertising linkage are prohibited. This does not
claim an unmigrated app or deployed backend already satisfies the contract.

Candidate 21 restores the proven explicit App Store distribution-profile option
inside the same archive/upload/status lane. Automatic signing remains the default.
An app may select `signing_style: manual` and its exact `app_store_profile_uuid` in
its own release configuration. The Mac must independently verify that installed
profile's exact app/team, UUID, expiration, distribution type, required Game Center
entitlement and matching installed Apple Distribution private-key identity. Profile
envelopes, certificates and keys remain outside source and logs. Export uses that
same profile and preserves the exact version/build rather than allowing an automatic
build-number increment. Existing prepared/signed checkpoints must be preserved in
their original checkout when a source migration requires a fresh candidate checkout.
No replacement uploader, certificate reset, new account or development-device
registration is introduced. This does not migrate other apps automatically.

Candidate 20 adds a public-copy review gate. Every release package must attest that
discretionary public copy contains no external company or website names, with empty
reviewed detection lists. Only necessary first-party URLs, platform labels, and legally
or contractually required disclosures remain, each recorded with its exact basis.

Candidate 19 clarifies the IP workflow as validation-first rather than development-
blocking. Untracked experiments remain outside the production scan and must stay out of
exports. Tracked production assets are registered and release-gated. Unresolved external
material pauses only its production adoption for validation or a focused owner decision;
it does not freeze unrelated app development.

Candidate 17 corrects the non-Arcade Game Center audit contract: `teamPlayerID` is
signed; the accompanying `gamePlayerID` is provider-reported audit metadata, not a
verified identity. Bind signed team/game/local-account relationships atomically
and never use the unsigned field to transfer or deduplicate an account. This
clarification changes no release exceptions, app IDs, save/Core pins or uploader.

Candidate 16 adds an app-bundle-scoped Keychain bridge to the pinned Game Center
plugin. Its patch and provenance hashes are mandatory; the descriptor links Apple's
Security framework. Items use a device-only accessibility class, never iCloud sync
or another game's access group. Adopters must migrate existing Hunt credentials with
verified readback before removing the old plaintext file and fail closed if native
storage is unavailable. Simulator/device compilation and signed-device tests remain
required; local fixtures do not certify native behavior. The plugin cache is separate
from old app caches and never uses a destructive hard reset to erase unknown work.

Candidate 15 repairs privacy-manifest staging and the signed-bundle profile check.
The app owns `ios/PrivacyInfo.xcprivacy`; the harness validates its structure and
stages it into the existing referenced export. It never invents collection claims.
Only a signed app's root `embedded.mobileprovision` is allowed; arbitrary profile
files and signing secrets remain prohibited. Preparation exports a Release PCK,
so the same source later archived cannot retain debug-export behavior.

For first internal TestFlight uploads, `FLINS_RELEASE_PURPOSE=internal-testflight`
selects the same lane with an explicitly scoped readiness purpose. Only a named,
reasoned exact-version/build owner exception with `deferred_until: app-review`
can defer `game_center.on_device_authentication_tested`,
`game_center.on_device_replay_tested`, or `golden_egg.physical_device_flow_reviewed`.
Those evidence fields stay false. Default/App Review validation still requires
them. This does not waive screenshots, rights, policy, production endpoints or
other release gates. Run default release readiness again before submission.

`PROCESS_LOCK.json` records LF-normalized hashes of shared release implementation files.
CI runs the self-audit. Changing a locked file requires updating its digest in the same
reviewed change after tests; a digest match alone does not prove behavior or security.
Run `python tools/audit_process.py --fleet <workspace>` against `PROCESS_APPS.json` to
find missing/different implementations. The command is offline, read-only and exits
nonzero for any drift. It never copies credentials, changes branches or upgrades games.

For each migration: choose the active candidate; compare against the last known working
app lane; adapt identity/config without replacing save/Core versions; run app regressions
and fictional release-state tests; review the diff; commit; run the canonical audit again.
Keep the old working lane until the replacement passes local and Mac/device gates.
Xcode Cloud remains supplemental with no PR distribution, manually started archive,
owner-approved TestFlight and no implicit public release.

## Official requirements checked 2026-08-30

- Apple requires iOS/iPadOS 26 SDK or later for uploads from April 28, 2026:
  https://developer.apple.com/news/?id=ueeok6yw
- Upload and Apple processing are separate:
  https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds
- Processing statuses and failure investigation:
  https://developer.apple.com/help/app-store-connect/reference/app-uploads/build-upload-statuses/
- Privacy inventory must include actual third-party behavior:
  https://developer.apple.com/app-store/app-privacy-details/
- Automatic app downloads can be disabled by the device owner:
  https://support.apple.com/guide/iphone/update-apps-iph98709f167/ios
- Phased release gradually reaches automatic-update users while manual download remains available:
  https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases

Recheck primary requirements when preparing each release or changing toolchain/plugins.
Do not auto-upgrade Godot/Xcode/Core to a newly announced version without compatibility
testing. These references are verification inputs, not legal-compliance certification.
