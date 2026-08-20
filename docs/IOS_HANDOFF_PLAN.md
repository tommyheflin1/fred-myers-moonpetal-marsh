# Fred iOS unsigned handoff plan

Status: executed through signed archive; TestFlight upload and physical-device
acceptance remain open. This plan inherits the App Generation Engine release
sequence without copying another game's identifiers or claiming live Fred iOS
service readiness.

## Fixed Fred defaults

- Product: Fred Myers and the Moonpetal Marsh.
- Source: one clean exact Fred commit; no working-tree builds.
- Engine: Godot 4.7.1 with matching export templates.
- Shared client: Mobile Game Core 0.5.1 at exact tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Save: `fred_save` v1, offline-first with atomic backup recovery.
- Orientation: landscape, preserving the current 1280 by 720 design and
  safe-area/touch layout contract.
- Identity: guest play remains available. `FredAppleGameScoring` defines the
  platform-neutral `fred_marsh_adventure_progress` event and bounded offline
  queue. `FredGameCenterAdapter` uses the official native plugin only on iOS;
  unavailable authentication falls back to the local board.
- Production bundle: `com.flinsvault.fredmyers`; source preparation bundle:
  `com.flinsvault.fredmyers.dev`.
- Version/build: `1.0` (`1`).
- Minimum OS and family: iOS/iPadOS 15.0; iPhone and iPad.
- Game Center records: `com.flinsvault.fredmyers.adventure_score` and
  `com.flinsvault.fredmyers.highest_level`.
- Icon inputs: `fred-app-icon-v3-platform.png` is the 1024-pixel full-bleed
  platform master; `fred-moonpetal-crest-v3.png` is the transparent foreground
  source for later Icon Composer layering.
- Release: manual. TestFlight and App Store release require separate approval.

The fixed values above are now the local Build 1 contract. App Store Connect
must still confirm availability and that build 1 is unused. No team ID,
certificate, profile, key or Apple credential is stored in source. Build 1
enables Game Center personal records only; Sign in with Apple, achievements,
cloud save and haptics remain off.

## Windows freeze and transfer

1. Require a clean source tree and record full Fred SHA/tree, Core version/tree,
   Godot version, save schema, bundle/version/build settings, and known issues.
2. Run readiness, all deterministic suites, save recovery/security, icon audit,
   and exact Android/desktop regression gates relevant to shared source.
3. Produce an unsigned iOS export configuration only. Do not sign on Windows.
4. Generate a tracked-file manifest and hashes. Prefer a clean authenticated
   exact-SHA Git clone on macOS; otherwise use a Git bundle plus SHA-256.
5. Exclude `.godot`, build caches, owner saves, logs, credentials, `.p12`,
   provisioning profiles, keys, team IDs, and production environment files.

## macOS, Xcode, and Simulator

1. Recheck the transfer hash, exact Git SHA, clean tree, Godot version, macOS,
   Xcode, command-line tools, and installed iOS SDK.
2. Export/open with signing disabled and no team. Inspect bundle ID,
   version/build, minimum OS, families, orientation, safe areas, icon catalog,
   capabilities, linked frameworks, and `PrivacyInfo.xcprivacy`.
3. Audit required-reason API use and create the Xcode privacy report. Privacy
   declarations must match the exact code and providers in the build.
4. Build supported iPhone, small iPhone, and iPad Simulator targets. Exercise
   title/start/countdown, touch movement, leap, tongue, boost, depth,
   pause/home, lives/failure/retry, alternating routes, tenth-level fairy,
   background/foreground, termination/relaunch, offline saves, recovery,
   audio, accessibility, memory, and frame pacing.
5. Record results in the release-readiness matrix. Simulator evidence remains
   separate from physical-device and provider evidence.

## Protected follow-on gates

- Owner has authorized the first signed TestFlight upload and $2.99 U.S. base
  price. The authenticated Mac must still prove team/signing custody, App ID,
  capability and build-number availability.
- Test representative physical iPhone and iPad before release-candidate credit.
- Query App Store Connect before upload to prevent a build-number collision.
- Upload once, then query processing state before any retry.
- App Review submission and manual public release remain approval-bound. Price,
  territories, agreements, privacy answers and tester access must still be
  verified in App Store Connect.

## Stop conditions

Stop on any commit/hash mismatch, invalid privacy manifest, unsupported SDK,
bundle/build collision, unintended entitlement, missing signing authority,
unclear Apple account state, missing physical-device evidence, or request for
credentials in chat/source. Preserve the unsigned handoff and report the exact
next owner action.
