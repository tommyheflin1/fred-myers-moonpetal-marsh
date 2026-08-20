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
