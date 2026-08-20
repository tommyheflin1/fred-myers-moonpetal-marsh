# Fred Myers App Build 2 Game Center access report

Date: 2026-08-20
Branch: `codex/app-build-2`
Starting revision: `0401d5154399cddb4f9b3618223d20fdef76a173`

## Owner-reported defect

The owner could not access Game Center from Fred TestFlight Build 1. The report
is accepted as a physical-device failure, not dismissed by the earlier static,
signed-entitlement, simulator, or App Store Connect evidence.

The Fred runtime authenticated automatically once at startup. If Apple sign-in
was cancelled, failed, or timed out, the leaderboard fell back to its local
offline state and exposed no button to authenticate again. A player therefore
could not recover without relaunching the app. The App Store version has Game
Center enabled, but both Fred leaderboard components remain in `Prepare for
Submission`; neither Apple component was changed during this local correction.

## Build 2 correction

- The leaderboard now shows `CONNECT GAME CENTER` whenever the native bridge is
  available but unauthenticated.
- Failed or timed-out authentication returns to a retryable state instead of a
  terminal offline-only state.
- A player can retry sign-in from the leaderboard without relaunching Fred.
- An authenticated player receives the distinct `OPEN GAME CENTER` action.
- A native dashboard presentation failure remains visible and retryable.
- Local scores and gameplay remain available whether Apple sign-in succeeds or
  not.
- Diagnostics retain only bounded state and numeric error data; they exclude
  the player's display name, player identifier, credentials, and tokens.

This follows the App Generation Engine provider-neutral pattern: authentication
is an explicit retryable state, local play remains offline-first, and platform
diagnostics are bounded. Mobile Game Core 0.5.1 was not modified.

## Validation

- Focused Game Center adapter: **38 passed, 0 failed**.
- Menu/lives/leaderboard integration: **35 passed, 0 failed**.
- Product-uplift regression: **96 passed, 0 failed**.
- Native plugin validator fixtures: **7 passed, 0 failed**.
- Native source-patch fixtures: **8 passed, 0 failed**.
- Complete Godot matrix: **26 suites, 6,947 passed, 0 failed**.
- Godot 4.7.1 import: passed.
- Readiness: **127 artifacts, eight fixtures**, Core 0.5.1/Godot 4.7.
- iOS preparation: version 1.0/build 2, iPhone+iPad, iOS 15 minimum,
  Game Center enabled, and both permanent Fred leaderboard identifiers.
- Computer Use inspected the real Godot leaderboard at 960 by 540 and 640 by
  360. Connect and Home remained readable, separated, and non-overlapping.

Some pre-existing standalone SceneTree suites continue to emit their known
shutdown-only ObjectDB/resource diagnostics. All assertions and suite exit
codes passed; the changed Game Center adapter suite emits no such diagnostic.

## Rebuilt local Android companion artifact

The current source was also rebuilt into the development-only Android companion
at `builds/android/fred-myers-app-build-2-debug.apk`:

- size: `84,928,583` bytes;
- SHA-256:
  `E89B60D4003C85D4D3C1EAD2034EE69201B85DE74CD58CBB722DF9902B44E8C3`;
- package/version: `com.flinsappvault.fredmyers.dev`,
  `0.2.2-app-build-2-r1` (`20201`);
- Android SDK 24/36, arm64-v8a plus x86_64, zero requested permissions;
- debug certificate, APK signature schemes v2/v3 and ZIP alignment verified;
- 207 entries and no test/tool/evidence, source-control, secret, credential, or
  private-path content in the package scan.

Android does not validate Apple's Game Center service. It is retained only as
the exact current-source mobile companion artifact.

## Apple configuration and remaining proof

Read-only App Store Connect inspection confirmed:

- Fred app Apple ID `6803295872`;
- Game Center enabled on iOS version 1.0;
- leaderboard `com.flinsvault.fredmyers.adventure_score` exists;
- leaderboard `com.flinsvault.fredmyers.highest_level` exists;
- both leaderboards remain `Prepare for Submission`.

Apple's testing guidance requires the app version to be enabled for Game Center
and its leaderboard components to be added to the tested version. Adding either
component for review changes App Store Connect state, so no such action was
taken during this local implementation. References:

- https://developer.apple.com/help/app-store-connect/configure-game-center/overview-of-testing-game-center/
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-game-center-components
- https://developer.apple.com/documentation/gamekit/authenticating-a-player

Build 1 cannot receive this source correction. The corrected Build 2 must be
signed on the authorized Mac, uploaded, processed, and assigned to the existing
internal group. A physical iPhone signed into Game Center must then prove:
authentication and retry, native leaderboard opening, both score submissions,
best-score behavior, offline queueing, foreground recovery, and one-time
reconnect delivery. Until that exact sequence passes, live Game Center remains
`UNVERIFIED`.

No Game Center component was added for review, no App Review submission was
made, and no release, publication, remote push, account, credential, or player
data change occurred.
