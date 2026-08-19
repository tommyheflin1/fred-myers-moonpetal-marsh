# Testing and build/export plan

## Automated test pyramid

1. **Static contracts**: exact Godot/Core pins; no edits under vendored Core; level/story/save JSON schemas; forbidden secret files; formatting and typed GDScript warnings.
2. **Headless unit tests**: fixed-tick movement, jump/landing, boost drain/recovery, tongue target selection, surface/dive transitions, hole safety, predator state machines, damage/respawn, objective transitions, save validation/migration, analytics allowlist.
3. **Deterministic scenario tests**: each of five levels has a seeded completion path and representative failure/escape paths; checkpoint restore reproduces stable state.
4. **Headless integration**: import, launch, Core compatibility smoke, full adventure autoplay, corrupt-save recovery, offline startup, pause/quit flush.
5. **Rendering/input checks**: screenshot candidates at desktop, phone portrait, phone landscape (if supported), high contrast, larger text, reduced motion; native touch plus desktop pointer emulation. Platform adapters remain a separate gate.
6. **Platform checks**: Web artifact launch/storage; Windows x86-64 package; Android debug export/install/launch/lifecycle; iOS unsigned preparation and Mac/Xcode handoff.
7. **Human acceptance**: frog readability, controls, telegraphs/fairness, camera comfort, story comprehension, five-level completion, audio/haptics, accessibility, representative physical devices.

CI should mirror Snake Reactor's split content/Godot jobs: checkout, pinned Godot 4.7.1 download, import, compatibility smoke, behavioral suite, deterministic adventure autoplay, secret scan, generated-data clean diff. Export artifacts should be a later opt-in workflow; no signing secrets in repository.

## Build matrix

| Target | Development artifact | Gate |
| --- | --- | --- |
| Web | Godot Web export | Loads over HTTPS, pointer/touch, save survives reload where browser permits, clear fallback on restricted storage |
| Windows PC | x86-64 `.exe` + `.pck`/package | Fresh-machine launch, mouse-as-touch, save path/recovery |
| Android | arm64 + x86_64 debug APK first; AAB later | Export, hash, install, launch, lifecycle, safe areas, touch, performance, physical QA |
| iPhone/iPad | Unsigned Xcode project preparation | Supported Mac/Xcode export, signing owned by user, simulator then physical device; App Store submission is separate approval |

Windows Phone has no current Microsoft mobile store target in this toolchain. Treat small Windows devices as responsive web clients, not a promised native Windows Phone package.

## Version pinning

- Godot: `4.7.1.stable.official.a13da4feb` and matching export templates.
- Mobile Game Core: `0.5.1` exact vendored snapshot.
- Backend tooling if used: Supabase CLI `2.109.1`, pnpm `10.13.1`, Node 22 in CI.
- Record product version/build number and export hashes in each evidence report.

## Current reproducibility

The live browser prototype remains a historical playable reference. The Godot
owner candidate is now reproducible from its exact clean local commit with a
pinned Core 0.5.1 tree, deterministic suites, save fixtures, readiness
inventory, exact-candidate desktop launcher, and development-only Android debug
artifact. Human desktop acceptance, compatible physical-phone acceptance,
signing, store preparation, and release remain separate gates.

Owner direction dated 2026-08-03 unlocks App Build 1 as a local testing
artifact. Its Android version code must be newer than the earlier M2 debug APK,
retain the development package identity for safe update testing, remain debug
signed with zero requested permissions, and be guarded by its exact source and
artifact hashes. This authorization does not include a store or release build.

The local M2 candidate now has a reproducible development-only Android debug
APK preset for arm64 and x86_64, static export checks, APK identity/security
inspection, and lifecycle/touch regression coverage. The exact APK installs
and launches on the isolated API 35 AVD, but the tested SwiftShader GLES3
renderer cannot link Godot 4.7.1's built-in canvas shader. Treat Android
presentation, actual touch gameplay, safe areas, performance, and lifecycle
relaunch as unverified until repeated on a compatible emulator renderer or
physical Android device. This does not change the physical-QA or release gate.

The latest phone-layout contract preserves the 1280 by 720 landscape canvas,
keeps objective/lives/Pause/energy/status regions separate, and shares exact
geometry between touch rendering and hit tests. Desktop runtime review passed
at 960 by 540 and constrained 640 by 360, and synthetic screen-touch checks
cover every action. Repeat the same matrix on a compatible emulator or
physical phone before awarding mobile presentation or touch acceptance.

Use `tools/validate_physical_android_device.ps1` for the physical Android
handoff. Its default mode is read-only and returns machine-readable
`UNVERIFIED` results. A future install/launch requires the exact guarded APK,
one explicit physical serial, an API/ABI/storage preflight, and separate
owner-device/save-risk acknowledgements. Never uninstall, clear data,
downgrade, grant permissions, root, or collect broad device logs for this
test.
