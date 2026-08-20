# Fred iOS Game Center release gate

Date: 2026-08-19 (America/Denver)

## Exact candidate

- Repository branch: `codex/app-build-1`
- Runtime/source commit: `c8fcf859e4aa7a9c419e88f1bde7f1ecabbdb943`
- Runtime/source tree: `5f0b6dd1895e68a8e0208e4d98714a510e5cbfe3`
- Starting commit: `caf5d1274b62a0aaaaadb61f9c483aa977625408`
- Godot: `4.7.1-stable`
- Core tree: `288d87420c5694f80c071f00aa71a0b581f9f60c`
- Bundle identifier: `com.flinsvault.fredmyers`
- App Store Connect app: `Fred Myers: Moonpetal Marsh`, Apple ID `6803295872`

The configured GitHub remote is public. This local branch and the patched iOS
source remain unpushed.

## Defects found and fixed

The pinned official `godot-ios-plugins` Game Center source contained an inverted
`respondsToSelector` guard that returned `ERR_UNAVAILABLE` on supported score
submission. The native presentation path also depended on a legacy app-delegate
window, and Fred treated the synchronous `post_score` return as final delivery
even though GameKit completes score delivery asynchronously.

The local development build now fail-closed pins and compiles:

- official plugin base `fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb`;
- official scene-safe presentation change
  `58c7b86054d9fe2eb7c7a0095153df8db64096aa`;
- official modern `GKLeaderboard.submitScore` change
  `2824fadd0e20a3cdcc12650d01c3c5934f7fd4ca`;
- Fred event metadata patch `fred-gamecenter-events-v1`.

The patcher rejects an absent scene fix, absent modern score API, the known
inverted capability guard, an ambiguous callback, or unexpected upstream SHA.
Generated frameworks are accepted only when their provenance records the exact
base, both reviewed changes, Fred patch version, Godot tag, device/simulator
libraries and file manifest.

Fred's adapter now:

- queues personal records before authentication instead of dropping them;
- posts the adventure score and highest level sequentially;
- waits for matching asynchronous category-and-score acknowledgements;
- ignores stale or mismatched callbacks;
- retries bounded failures and timeouts without claiming delivery;
- continuously polls native events after authentication;
- exposes the native Game Center leaderboard while preserving the local,
  offline-first leaderboard.

## Automated evidence

- Windows Godot matrix: 24 suites, 5,220 checks passed, 0 failed.
- Focused Game Center adapter: 31 passed, 0 failed on Windows and macOS.
- Native source patch fixtures: 8 passed, 0 failed.
- Generated plugin validator fixtures: 7 passed, 0 failed.
- Readiness: 122 artifacts and eight save fixtures passed before this report was
  added to the required inventory.
- Godot project import/parse: passed with Godot 4.7.1.
- Patched framework validator: `PASS`; manifest SHA-256
  `c0c1c3064faba6338d400e19c04e78be0318098e188870f4871c145286b1a027`.
- Simulator Xcode build: passed as part of the guarded iOS validation handoff.
- Signed device archive: `ARCHIVE SUCCEEDED` at
  `builds/ios/FredMyers-AppBuild1.xcarchive`.
- Signed application verification: strict `codesign` passed and the archive
  contains `com.apple.developer.game-center = true`.

The plugin compilation emitted one availability warning from Godot's app
delegate headers about `UIWindowSceneDelegate` and a 12.0 compilation target;
the plugin and both frameworks completed successfully. Fred's declared minimum
iOS version remains 15.0.

## Apple configuration evidence

- Registered App ID `com.flinsvault.fredmyers`: Game Center checked.
- iOS version 1.0: Game Center checked and saved during this gate.
- `com.flinsvault.fredmyers.adventure_score`: integer, best score, high-to-low,
  visible, default leaderboard, status `Prepare for Submission`.
- `com.flinsvault.fredmyers.highest_level`: integer range 1-100, best score,
  high-to-low, visible, status `Prepare for Submission`.
- The app version remains `Prepare for Submission`, manual release remains
  selected, and no Game Center component or app version was added for review.

## Integrity

- Owner primary save: 592 bytes,
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save: 592 bytes,
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Both timestamps and bytes remained unchanged.
- Exactly one `Fred Myers Owner Test.lnk` remains; it was not modified.
- Save schema remains `fred_save` v1 and no credentials, player identifiers, or
  Game Center tokens are persisted.

## Remaining protected proof

The signed archive upload stopped with Apple's reauthentication error 501. App
Store Connect therefore still truthfully shows `No Builds`. Static tests,
simulator compilation, native framework compilation, signed entitlements and
App Store configuration do not prove live Game Center service behavior.

Before the first rollout is called ready, the owner must:

1. reauthenticate the Apple account in Xcode directly, including 2FA;
2. upload this exact signed candidate and wait for TestFlight processing;
3. on a physical iPhone or iPad signed into Game Center, confirm authentication;
4. complete one level and verify both exact personal records are accepted;
5. open the native Game Center board and verify the submitted score and level;
6. relaunch, repeat with a higher score/level, and verify best-score behavior;
7. repeat once offline to confirm gameplay/local scores remain available and
   queued Game Center records do not masquerade as delivered;
8. reconnect and verify the queued records sync once, with no duplicate reward
   or progress change.

Until that physical TestFlight sequence passes, live Game Center status is
`UNVERIFIED`; Fred is build/configuration ready, not service-acceptance complete.

## App Store Connect follow-through - 2026-08-19

- Fred's `Data Not Collected` privacy response is published for this inspected
  build; no developer analytics, ads, account backend or Flins-operated score
  service is active.
- iPhone and iPad accessibility drafts now list only the verified non-color and
  contrast support. Release is required before Apple permits publishing those
  product-page labels.
- The $2.99 U.S. price, eight iPhone screenshots, eight iPad screenshots,
  Game Center version checkbox, manual release selection and TestFlight
  feedback email are verified.
- Fred's release availability is verified against Snake Reactor at 143
  identical available countries, with zero missing or extra storefronts.
  Fred's two Apple-blocked storefronts are explicitly unavailable, so its
  summary reads `32 Not Available` instead of Snake's `30 Not Available` plus
  `2 Cannot Sell`; the customer-facing available set is identical.
- The currently published studio `/privacy` page is Pokemon Field
  Academy-specific. Fred requires the separately approved and published
  `/fred-myers/privacy` page before its privacy URL is entered.
- Content-rights attestation, the dedicated Fred privacy-policy URL and
  physical-device Game Center proof remain protected owner gates. No App
  Review submission or public release occurred.
- The TestFlight feedback email is saved. Fred's complete App Review contact
  now reuses the established Snake Reactor contact record without repeating
  its private values in project documentation.

## TestFlight Build 1 delivery - 2026-08-19

The Xcode account session continued to fail export reauthentication with Apple
error `-501`, so the signed archive was packaged and delivered using the same
App Store Connect API-key upload path proven for Snake Reactor. No Apple
password, two-factor code or private key was printed, copied into the project,
or committed.

- Signed archive app: strict `codesign` verification passed.
- Bundle identity: `com.flinsvault.fredmyers`, version `1.0`, build `1`.
- Local signed IPA: 53,919,341 bytes; SHA-256
  `f5bfb51d8fcad4ab6e8a2320f91d885d541ef2b44296546feb38e36a19e32620`.
- IPA archive integrity: `unzip -t` passed with no errors.
- Apple API validation: `VERIFY SUCCEEDED with no errors`.
- Apple API upload: `UPLOAD SUCCEEDED with no errors`.
- Delivery UUID: `e3ec31b7-beff-41fb-ae93-e5d077d706c5`.
- App Store Connect processing completed; binary state is `Validated`. The iOS
  Builds table reports `Ready to Submit` for external beta review and an
  expiration in 90 days; exact Build `1.0 (1)` is assigned to the approved
  internal owner-testing group.
- Processed metadata confirms iPhone and iPad, `arm64`, minimum iOS `15.0`,
  non-exempt encryption `No`, required capability `gamekit`, and
  `com.apple.developer.game-center = true`.
- A manually controlled internal group named `Fred Owner Testing` contains
  exact Build `1.0 (1)` and one approved owner tester. Automatic distribution
  is disabled.
- Build-specific touch, campaign, life/fairy, save, layout and Game Center
  test instructions are saved in TestFlight.
- Exact Build `1.0 (1)` is attached and saved on App Store version `1.0`.
  Manual release remains selected and the Game Center checkbox remains enabled.
- Both permanent leaderboards remain correctly configured in App Store Connect
  with status `Prepare for Submission`; no Game Center component or app version
  was submitted for App Review.

This closes the upload and processing gates. Live Game Center authentication,
score submission, native leaderboard display, offline queue and reconnect
delivery remain `UNVERIFIED` until the owner runs the documented sequence on a
physical iPhone or iPad from this exact TestFlight build.
