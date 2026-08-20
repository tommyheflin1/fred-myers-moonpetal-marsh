# App Generation Engine adoption and Apple readiness status

Date: 2026-08-19

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

Fred now has a processed Apple test candidate. The current Apple execution
status is truthfully `APPLE_TESTFLIGHT_OWNER_ACCEPTANCE_REQUIRED`: exact-source
macOS transfer, Godot 4.7.1 export, Xcode simulator build, pinned native Game
Center framework compilation, privacy/entitlement inspection, signed device
archive, Apple validation and upload have run. Exact Build `1.0 (1)` is attached
to App Store version `1.0` and assigned to the manually controlled internal
`Fred Owner Testing` group. The approved tester is invited but has not yet
installed the build. Physical iPhone/iPad and live Game Center service
acceptance therefore remain unverified.

Apple's processed metadata reports Build SDK `23F73`. Apple validated this
upload on 2026-08-19, after its 2026-04-28 requirement for Xcode 26 or later and
an iOS/iPadOS 26 SDK took effect. The engine audit therefore records the SDK
gate as externally validated while retaining the exact Apple metadata value and
the official-requirement inference basis.

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

## Remaining Apple acceptance

1. The invited owner accepts Build `1.0 (1)` in TestFlight and completes
   representative physical iPhone/iPad touch, safe-area, lifecycle, audio,
   save, performance, battery and thermal testing.
2. Prove Game Center authentication, both permanent leaderboard submissions,
   native leaderboard display, offline queue and one-time reconnect delivery
   on that physical Apple device.
3. Obtain the owner's commercial-rights answer to Apple's exact third-party
   content question. No repository evidence establishes the rights to the two
   owner-supplied music files, so the answer must not be inferred.
4. Approve and publish the prepared Fred-specific privacy policy, verify its
   dedicated URL and then enter that URL in App Store Connect. The complete
   App Review contact record is already saved.
5. Review physical-device findings and Game Center component readiness, then
   stop again before App Review submission or public release.

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

The owner authorized a $2.99 paid app and the first TestFlight build upload.
Apple team/signing custody stays on the authenticated Mac. The exact enabled
territory set matches Snake Reactor, the internal group is configured and the
review contact is saved. App Review submission, public release, physical-device
acceptance and legal/media-rights acceptance remain separate owner gates.

No Apple credential was stored or exposed. A signed archive, validated
TestFlight Build `1.0 (1)` and App Store Connect metadata now exist, but no App
Review submission or public release exists. The static Windows audit does not
convert external Apple processing or an invitation into passing physical-device
or production evidence.
