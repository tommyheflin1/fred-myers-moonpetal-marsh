# Fred Build 11 privacy verification

## Latest status after explicit owner approval

### Website publication independently verified

Sites version 81 appeared during the next continuation, from source
c4eb2deb08d9ac502f0df2b37361c98fe1b23905, saved version
appgprj_6a6fc76b33b481919e331f55b7b87299~appgver_d47470182cf08191b1b386baca4f3a6d.
Native status for deployment appgdep_6aa317316cac8191b0dde3c5e0239da8 returned
succeeded, updated 2026-09-10T20:50:03.673167+00:00. This was another release
operation, not the failed local upload retries. The exact Fred policy verifier
then passed against the custom domain: PRIVACY_POLICY_LIVE_OK,
app_specific=true, version_exact=true. Do not redeploy the older local package
over this newer website. Website publication is no longer a Fred privacy blocker.

Reconfirmed Apple's published User ID and Gameplay Content/App Functionality/
linked-to-user labels in the existing session. Recorded this actual evidence in
store/app_store_package.json compliance.privacy_answers_reviewed=true. This does
not mark native manifest inclusion, device tests, or other compliance gates passed.

### Website publication attempt after combined-release approval

Follow-up retry after "THEN GET IT DONE": same immutable archive again failed in
the native file-upload operation after 60002 ms, request
5e1ac532-537d-4c29-8827-c3be38e77e1d, host
sdmntprwestus2.oaiusercontent.com. A credential-free HEAD connectivity diagnostic
to the previous upload host completed in 1.8 seconds with HTTP 400 (expected for
an unauthenticated storage root), proving basic HTTPS reachability but NOT upload
success. Reconciled history again: still version 80, no new saved deployment.
Do not bypass native Sites upload with shell HTTP or claim the retry succeeded.

The owner subsequently approved publishing the pending TurboRack website/API
changes alongside Fred's policy. That scope blocker is resolved. The exact tested
source was committed and pushed to the existing Sites origin/main:
967eb1e11863aedd089256b81c5593d182a2a272. The checkout is clean. Reused the successful
142-test production build and packaged it with the existing Sites packager using
Git Bash/native paths (the wrapper selected WSL Bash and failed Windows paths).
Archive includes the hosting manifest, Worker, client assets and migration 0012.

Native Sites save/upload failed twice, both before version creation, with blob
upload timeouts at approximately 60 seconds. Request IDs:
ce6238ce-1b4a-48d5-91ce-2f442e59ba0b and
5d957736-6af0-4e08-a3c7-4726f4e81e19. Version history was reconciled after each
failure: latest remains 80, source df2849440ddfdbaea63284a454689e8a9d18296f.
No deploy was issued because no new saved version exists; public site unchanged.
Resume by saving the same exact source and existing archive
`C:/Users/tommy/.codex/visualizations/2026/09/03/01a067fa-0c0a-7531-a321-11e86e9e5325/fred-privacy-approved.tar`,
then deploy the returned saved-version ID and verify the live policy. Do not
repeat approvals, reset signing, rebuild unchanged source or claim publication.
The current blocker is the Sites file-upload service, not missing owner authority.

The owner replied "APPROVED" to the exact User ID / Gameplay Content,
linked-to-player, App Functionality only, no-tracking disclosures and matching
policy. The previous publication-approval blocker below is resolved.

Verified the existing App Store Connect app 6803295872 privacy page live:
Gameplay Content was already published when reopened. Completed User ID with
only App Functionality selected, linkage Yes and tracking No, then clicked
Publish. Apple returned "Published a few seconds ago by Tommy Heflin" with both
categories and no incomplete-category warning. Product Page Preview Details shows
Identifiers > User ID and User Content > Gameplay Content under Data Linked to You.
Closed the preview dialog, preserving the existing Apple and remote desktop tabs.
This is published privacy metadata, NOT a new binary or App Review submission.

Marked the exact 2026-09-10 local inventory approved and ran the existing prepare
and sync workflow into the website registry. Rebuilt using the existing `pnpm test`:
142 tests passed; five app privacy tests and manifest structure validation also
passed. The Sites helper still exits before building with a path error; no
dependency or pipeline redesign was made.

Rechecked Sites: latest saved version remains 80 at
df2849440ddfdbaea63284a454689e8a9d18296f. The pending site branch also contains
unpublished TurboRack backend/schema and support changes. The approval covered
Fred privacy, not that separate app deployment. No website deployment, rollback,
or deletion of another app's changes was performed. Website publication and live
policy-version verification remain pending a scoped/coordinated release; native
signed-manifest verification remains a separate build gate.

Earlier findings below are historical; this latest status supersedes their
draft/unpublished-Apple status.

Candidate: dirty continuation of 59f681e669ec186469198e83c68aeea4133cf80d,
version 1.1 (11), bundle com.flinsvault.fredmyers. This is not signed-build evidence.

## Earlier baseline results (superseded by reconciliation below)

- Public page: https://theflinsappvaultllc.com/fred-myers/privacy, HTTP 200.
- Harness verifies the exact fred-myers app marker and fred-myers-2026-08-25 policy marker.
- Live text describes local saves, optional Game Center, Golden Egg verification,
  server ranks, Public/Anonymous choice, network security logs, retention and a
  privacy/deletion contact. It says there are no in-app ads or developer analytics.
- Local inventory correctly declares persistent local data. Ordinary saves and
  cosmetic progress are local; Golden Egg credentials use the new iOS Keychain
  bridge, whose actual native build and device behavior are not yet verified.

## Original findings (historical, not current completion status)

1. The current golden_egg_service.gd sends a provider-reported Game Center display
   name and Apple identity-verification fields to the backend. Its local secure
   store retains identity and service credentials. The live policy's generic
   pseudonymous-binding and marsh-profile-label wording does not clearly explain
   this current flow or the cross-game team-identity purpose required by the
   bundled identity contract. Do not describe the display name as Apple-signed.
   Update the inventory/policy with a new effective version after content review;
   do not silently reuse old approval for materially expanded disclosures.
2. The App Store privacy answers have not been independently verified in this
   pass. Do not apply historical Data Not Collected answers to the backend-linked
   identity/discovery flow. Reconcile user identifiers and gameplay records,
   linkage and app-functionality purpose against actual server retention.
3. godot/ios/PrivacyInfo.xcprivacy is missing. The migrated validator fails on that
   exact missing path. Reconcile collected-data declarations and required-reason
   APIs against the pinned engine/plugin and exported app, then stage and validate
   the actual bundle. An old archive's manifest is not proof for Build 11.
4. The webpage includes a separate optional website-analytics consent banner.
   This is not evidence of analytics inside Fred. Review website consent and
   handling separately; this pass did not exercise analytics or inspect cookies.

Apple's current disclosure guidance requires data used only for app functionality
to be considered for disclosure and distinguishes optional disclosure criteria:
https://developer.apple.com/app-store/app-privacy-details/

## Earlier review boundaries

This is an engineering consistency review, not legal certification. Website marker
verification alone is not a semantic privacy approval. No website content, Apple
privacy answers, real-player record, live policy minimum or signing asset was changed.
No full privacy-release pass, upload or App Review submission is claimed.

The owner explicitly approved the two existing music tracks in this conversation.
That exact statement and both file hashes are recorded in store/audio_package.json;
no new music-rights approval request is outstanding. Native audio/runtime and
remaining provenance-package checks are separate.

## Reconciliation implemented on 2026-09-10

- Added app-owned `godot/ios/PrivacyInfo.xcprivacy`: User ID and Gameplay Content,
  linked to the user, App Functionality only, no tracking or tracking domains.
- Required reasons: FileTimestamp C617.1 (private app filesystem), SystemBootTime
  35F9.1 (elapsed timing), DiskSpace E174.1 (space needed for writes). Compared
  against the pinned Godot 4.7.1 Apple export source and installed iOS template.
  No UserDefaults, display-space or display-timestamp purpose is asserted.
- Updated game/game.json inventory to policy fred-myers-2026-09-10. It now
  explicitly covers server identity/proofs, discovery records, privacy choice and
  app-scoped Keychain credentials that may survive app deletion. Review status
  remains draft until publication/semantic review are complete.
- Updated the dedicated website privacy page with scoped Game Center identity,
  cross-game private binding, unsigned provider-reported display name, opt-in
  public name, Anonymous/private-retention distinction and Keychain retention.
- Apple privacy page was inspected live. Its published label says Data Not
  Collected. Began category setup for Gameplay Content and User ID; entered
  gameplay App Functionality and linked-to-user answers. The publish action was
  rejected by the approval safeguard. No revised Apple declaration is confirmed
  published or completely saved. The browser remains on the existing privacy
  setup, and its incomplete-category warning must not be mistaken for completion.

### Exact proposed Apple disclosure for owner approval

| Category | Purpose | Linked to user | Tracking |
| --- | --- | --- | --- |
| User ID (Game Center identifiers/display name and service binding) | App Functionality | Yes | No |
| Gameplay Content (scores/discovery evidence and records) | App Functionality | Yes | No |

These are engineering-derived answers, not an attestation that Apple has approved
them. Published Build 1 source c8fcf859e4aa7a9c419e88f1bde7f1ecabbdb943 already
contains Game Center authentication and score/highest-level submission; the new
candidate adds the service-backed identity/discovery flow. Current public-version
scope and infrastructure logging must remain part of final disclosure review.

### Validation actually run

- Manifest validator: PASS, structure_only=true; signed_bundle_check_required=true.
- Five Python privacy regressions: PASS. Includes exact collection/reason inventory,
  fictional export staging, preservation of plugin manifests and ambiguous-export
  fail-closed behavior. These are NOT native Xcode/archive evidence.
- Website production `pnpm run build`: PASS. The standard Sites helper failed
  before building with "The system cannot find the path specified"; the existing
  package build command succeeded with permitted access and unchanged lockfile.
- Website regression suite: 142 PASS, zero failed; includes three new Fred privacy
  tests. Updated the existing policy-marker assertion to the new effective version.
- Shared-process audit still reports MIGRATION_REQUIRED solely for the preserved
  app-specific apple_delivery.sh. No signing/upload migration was improvised.

### Publication boundaries / safe resume

Website edits are local, not committed, pushed, version-saved or deployed. Existing
site main 33abea8 includes two TurboRack commits beyond live version 80 source
df2849440ddfdbaea63284a454689e8a9d18296f, including backend/schema changes.
Do not publish those unrelated pending changes under this Fred-only correction.
Resolve the other app's deployment ownership/approval or use an approved scoped
release before deploying the policy. Preserve all existing code and migrations.

Obtain explicit approval of the exact public Apple answers above and the revised
policy. Do not bypass the safeguard. Then complete BOTH category wizards, verify
Apple's persisted preview/published state, deploy the reviewed website through
Sites, and verify the live policy marker. Finally verify manifest inclusion and
required reasons against the exact native exported/signed Build 11 artifact.

No RDP reconnection, Mac/Xcode logout, signing-asset change, Apple upload or App
Review submission occurred in this privacy reconciliation. Other Build 11 gates
remain independent; this report does not certify the entire release ready.

## Later required-version-check reconciliation

The earlier sections are historical checkpoints, not the current publication state.
The new iOS supported-build check reuses the existing signed Flins policy lane.
It runs before play, on foreground and after policy expiry. It sends only the
public app identifier and platform, not player identity, a save or an authorization
token. Ordinary hosting/network-security information is still processed.

The existing dedicated privacy page's "offline-first" claim was therefore no
longer accurate. Prepared revision `fred-myers-2026-09-10-v2`, keeping the same
date's existing identity, consent, retention and business-contact disclosures.
Added the required connection/verification behavior and the separate public
policy-request inventory. The new revision is **draft** pending the specific
asynchronous owner review presented in this task. A previous policy approval is
not silently carried forward. No new linked-player collection is invented for
the policy request. Five app privacy tests and the website disclosure tests pass.

The dedicated Fred route is separate from the generic registry renderer; updating
the registry alone cannot correct its copy. Publication must use the reviewed
dedicated page and matching registry marker together. The website's existing
Game Center data declarations and the shipped native manifest still require
their separate exact-artifact checks.
