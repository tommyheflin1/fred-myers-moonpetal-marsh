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

Fred now has the local source needed for an Apple test candidate. The current
Apple execution status remains truthfully `APPLE_PREPARATION_REQUIRED`: the
1024-pixel icon master, unsigned iPhone+iPad preset, bundle/version/build
identity, offline-safe Game Center adapter and permanent leaderboard IDs are
prepared. The exact macOS handoff is frozen locally after the clean commit.
Privacy-manifest,
Xcode 26, Simulator, physical-device, sandbox Game Center, signed archive,
upload and TestFlight processing gates have not run.

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

1. Freeze the clean exact source into the hash-guarded macOS Git bundle and
   handoff manifest.
2. Create the separate Fred App Store Connect record, verify
   `com.flinsvault.fredmyers`, create both leaderboard records and confirm that
   version 1.0 build 1 is unused.
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
7. Build the pinned official Game Center plugin and map the two checked-in
   leaderboard identifiers to the owner-created Apple records; preserve
   guest/offline play.
8. Upload the exact signed Build 1 under the owner's current TestFlight
   authorization, wait for processing and attach it only to approved internal
   testers.
9. Stop again before App Review submission or public release.

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

The owner has authorized a $2.99 paid app and the first TestFlight build upload.
Apple team/signing custody stays on the authenticated Mac. App Review
submission, public release, final storefront/regulatory choices, tester groups
and legal/media-rights acceptance remain separate owner gates.

No Apple credential, certificate, provisioning profile, App Store Connect
record, signed archive, upload, TestFlight build, submission, or release was
created or changed by this local preparation.
