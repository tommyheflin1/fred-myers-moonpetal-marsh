# App Generation Engine adoption and Apple readiness status

Date: 2026-08-18

## Decision

Fred has used the App Generation Engine reference efficiently for the reusable
parts of the product. The independent repository, immutable Core pin,
deterministic gameplay, offline-first atomic save/recovery, provider-neutral
identity boundary, device-neutral input path, platform-separated evidence, and
hash-guarded owner handoffs are all present. The new Fred-owned scoring adapter
also uses the Engine's platform-neutral event boundary, bounded offline queue,
and server-verification requirement without pretending Windows can activate
Game Center. The executable audit reports
`STRONG_REUSE` for all ten foundation controls.

Fred is not yet an Apple test candidate. The current Apple execution status is
truthfully `APPLE_PREPARATION_REQUIRED`: one of ten platform items is prepared
(the 1024-pixel platform icon master), while the iOS export, privacy, macOS,
Simulator, physical-device, provider, signing, and TestFlight gates have not
run. This is a short operational gap rather than an architecture rewrite.

Run the current local audit with:

```powershell
python tools/audit_apple_readiness.py
```

## Engine-to-Fred mapping

| Engine reference control | Fred evidence | Status |
| --- | --- | --- |
| Independent game repository | Fred has its own Git history, Godot project, exports, and rollback boundary | PASS |
| Immutable Mobile Game Core | Core 0.5.1; exact vendored tree `288d87420c5694f80c071f00aa71a0b581f9f60c` | PASS |
| Pinned toolchain | Godot 4.7.1 project/import/test contract | PASS |
| Offline-first durable progress | `fred_save` v1, atomic writes, backup recovery, corrupt/future-schema fixtures | PASS |
| Deterministic product rules | 18 Godot suites and fixed-tick traversal/session contracts | PASS |
| Portable controls | Desktop, pointer, real screen-touch events, and synthetic adapter tests share intent contracts; the player UI is device-neutral | PASS |
| Optional platform identity | Guest-first interface includes Apple Game Center and Sign in with Apple provider slots | PASS, adapter only |
| Evidence-gate separation | Desktop, Android artifact, emulator, physical device, human review, signing, and release are not conflated | PASS |
| Exact owner handoffs | One SHA/manifest-guarded desktop shortcut and a hash-guarded Android preflight | PASS |
| Shared online architecture | Core/player identity/local leaderboard plus `FredAppleGameScoring` emit a platform-neutral verified-score envelope; no production provider or backend is activated | PARTIAL, intentionally deferred |

This is the right form of reuse: Fred inherits infrastructure and release
discipline while retaining Fred-specific traversal, lives, fairies, predators,
levels, story, audio, and art.

## Apple path already inherited from the engine

- Freeze one clean Fred commit and record the game SHA, Core tree, Godot
  version, bundle/version/build identity, and artifact hashes.
- Produce only an unsigned Xcode handoff on Windows; keep Apple credentials,
  team IDs, certificates, profiles, and keys out of source and evidence.
- Verify the exact source again on macOS before import/export.
- Validate Xcode project identity, current SDK, icons, privacy manifest,
  capabilities, safe areas, touch, lifecycle, offline play, and saves.
- Treat Simulator, physical iPhone/iPad, Game Center sandbox, signing, upload,
  TestFlight, App Review, and manual public release as separate gates.
- Keep guest/offline play available when identity or network services fail.

## Remaining Apple preparation

1. Add a Fred-owned local `iOS Unsigned Preparation` preset with an
   owner-confirmed bundle ID, monotonic build number, minimum OS, device
   families, landscape policy, and no team/signing identity.
2. Create the exact source/handoff manifest and transfer validation script.
3. Export on a supported Mac with Xcode 26 and the iOS/iPadOS 26 SDK or later,
   then record the generated Xcode project and toolchain hashes.
4. Audit Godot and included code for required-reason APIs; add and validate
   `PrivacyInfo.xcprivacy` from the generated Xcode target evidence rather than
   guessing values on Windows.
5. Convert the Moonpetal Crest into Apple Icon Composer layers/appearances and
   inspect default, dark, and tinted results on macOS. The square 1024-pixel
   platform master is ready; Apple applies the final platform mask.
6. Run iPhone and iPad Simulator matrices, then representative physical
   iPhone/iPad touch, safe-area, lifecycle, audio, save, performance, battery,
   and thermal testing.
7. Map `fred_marsh_adventure_progress` to an owner-created Game Center
   leaderboard identifier on macOS, inject the native bridge, and activate Game
   Center or Sign in with Apple only after the owner approves the entitlement,
   App ID, and provider effects; preserve guest/offline play.
8. Prepare App Store Connect privacy answers, privacy-policy/support URLs,
   metadata, screenshots, age rating, test information, and release notes from
   the exact build.
9. Stop again for owner approval before signing, archive/upload, TestFlight,
   submission, or release.

Apple currently requires iOS/iPadOS uploads to use the iOS/iPadOS 26 SDK or
later, documents a 1024 by 1024 layered app-icon layout whose final mask is
applied by the system, and requires accurate privacy-manifest and App Store
privacy information. Recheck these official requirements at execution time:

- https://developer.apple.com/app-store/submitting/
- https://developer.apple.com/design/human-interface-guidelines/app-icons/
- https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- https://developer.apple.com/help/app-store-connect/reference/app-privacy/
- https://developer.apple.com/testflight/

## Questions intentionally deferred to the protected owner gate

Only choices that affect Apple records or release authority should need owner
input: final production bundle/App ID, Apple team and signing custody,
minimum-supported device/OS policy, Game Center/Sign in with Apple enablement,
tester groups, and the exact upload/submission/release action. Everything else
should follow the checked-in plan and generated evidence.

No Apple account, credential, certificate, provisioning profile, entitlement,
App Store Connect record, upload, TestFlight build, signing, submission, or
release was created or changed by this audit.
