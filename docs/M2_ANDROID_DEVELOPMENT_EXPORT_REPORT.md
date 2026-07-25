# M2 Android development export evidence

Date: 2026-07-24

## Scope and boundary

This Fred-only slice starts from local uplift commit
`eb55ceb9a79c79dc9b6f61fec66d17e5b2d46213`. It adds a reproducible
development-only Android APK preset and lifecycle safety without changing
Core 0.5.1, `fred_save` schema v1, progression, rewards, level rules, or the
owner desktop shortcut. The configured GitHub repository is public, so this
branch and its proprietary M2 work remain local and unpushed.

This is Android engineering evidence, not a release, store, signing,
physical-device, or owner-acceptance claim. M012 remains 99.3%, M013 remains
0%, and TASK-002 remains 19.9%.

## Development export contract

`Android Development` uses Godot's built-in debug export path:

- package: `com.flinsappvault.fredmyers.dev`
- label: `Fred Myers Development`
- version: `0.2.0-m2-dev` (`20001`)
- orientation: landscape on a portrait phone profile
- architectures: `arm64-v8a` and `x86_64`
- built-in template SDK contract: minimum 24, target/compile 36
- renderer declaration: GL Compatibility with Android ETC2/ASTC import
- requested Android permissions: none
- user-data backup: disabled
- production/release keystore fields: absent
- output: ignored `builds/android/fred-myers-debug.apk`

The project title artwork is reused as a development launcher icon. This is
not a final store-icon claim. Tests, review tools, evidence screenshots, and
source-control material are excluded from the APK.

The validation export at evidence capture was 76,676,402 bytes with SHA-256
`2E9D4757233371AE1672986F4180206BEFD01AA382C5CA904210C219EC95A1FB`.
Debug APK generation is timestamped; the final local handoff records the
post-commit re-export hash separately.

Android build inspection passed:

- ZIP alignment verified;
- APK Signature Scheme v2 and v3 verified;
- one 2,048-bit RSA Godot debug signer with certificate SHA-256
  `3846f003df913682a497d7bf726439df432ed9d4f83cf99f46647079be8f6a87`;
- exact package/version/SDK/ABI identity verified by `aapt2`;
- no `uses-permission` entries;
- 178 ZIP entries and both required native libraries;
- no tests, tools, evidence captures, `.git`, signing material, secret files,
  private Windows paths, or credential-like text in scanned APK entries.

## Lifecycle and touch safety

Active play now responds to Android pause/resume and Back notifications:

- backgrounding clears every touch contact and fixed-step remainder;
- active play enters a paused state and flushes one stable save;
- duplicate pause/resume notifications cannot rotate another save or resume
  play;
- foreground recovery remains paused until explicit input;
- the first Back press pauses and saves, the second returns home, and Back
  from the title requests a normal app exit;
- no touch, animation, energy, life, or simulation state advances while
  backgrounded.

The focused Android suite passed 21/21. It includes simultaneous movement and
boost contacts, stale-contact clearing, duplicate lifecycle notifications,
off-screen invariance, Back behavior, schema-v1 reload with four lives,
deterministic canonical reload hashes, and a 10,000-decision touch-zone loop.

## Automated regression and performance

Godot `4.7.1.stable.official.a13da4feb` imported the project. The complete
16-suite matrix passed **2,143 checks with zero failures**. The previously
reported 15-suite headline was 2,090; the executed suite rows now total 2,122,
plus 21 Android checks. This report uses executed counts rather than the stale
headline.

Two additional clean repetitions produced:

- marsh geometry: 10,000 updates in 90 and 106 ms, identical hash
  `1493484083`, and 264 bytes measured static-memory movement;
- Android touch decisions: 10,000 updates in 17 and 16 ms, identical hash
  `609708773`, and zero measured static-memory growth.

Readiness passed with 42 required artifacts, the same eight fictional save
fixtures, Core 0.5.1, and Godot 4.7. The new Android runner exits without an
ObjectDB/resource warning. Existing standalone SceneTree shutdown-only
diagnostics remain limited to their pre-existing suites; no new parser,
GDScript, save, or gameplay failure was introduced.

## Emulator result and blocker

A Fred-only Pixel 7 API 35 x86_64 AVD was created inside the ignored worktree
and assigned unique ADB serial `emulator-5600`. The existing
`snake_reactor_r1_api35` emulator at `emulator-5580` was identified and never
used, installed to, or terminated.

The exact APK installed and cold-launched successfully while offline. Android
confirmed the expected package, version, ABI, debug flag, and landscape
orientation at:

- the 1080 by 2400, 420-dpi phone profile, presented to the app as
  2400 by 1080 landscape; and
- a 720 by 1600, 280-dpi constrained profile, presented as 1600 by 720
  landscape with a simulated 91-pixel cutout inset.

The emulator's SwiftShader OpenGL ES 3 renderer then failed to link Godot
4.7.1's built-in scene/canvas shaders:

`Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`

Godot remained alive, but the retained screenshots are grey and therefore do
not validate Fred, the HUD, touch targets, safe-area layout, level play,
failure/retry, fairy/life stacking, or recovery visuals. Both bounded emulator
starts were consumed. A Windows Computer Use inspection attempt also timed out
before control, and no third emulator start or renderer/architecture rewrite
was attempted.

There was no Fred ANR, fatal exception, GDScript/parse error, or observed
network request. The blocked title process reported 173,683 KiB total PSS and
271,772 KiB total RSS. Its 18-frame, 44.44% jank sample is an emulator shader
failure diagnostic, not phone-performance evidence.

Accordingly, actual phone-emulator presentation, touch-to-game-state
transitions, background save/relaunch, stacked-life recovery, failure/retry,
fairy consumption, and two-run state hashes remain **UNVERIFIED /
EMULATOR_RENDERER_UNAVAILABLE**. The deterministic Godot suites prove those
contracts in isolated fictional storage, but are not relabeled as emulator or
physical-device acceptance.

## Integrity and open gates

- Core tree remains
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- `fred_save` remains schema v1.
- Owner primary and backup saves remain outside every test runtime and must
  retain their recorded byte hashes in the final handoff.
- The desktop owner shortcut remains unchanged and continues to target the
  uplift review candidate.
- No account, PII, analytics, network permission, provider, production
  signing, store asset, release, deployment, publication, push, or PR was
  added.

The next safe Android action is a fresh isolated API 35 emulator run with a
verified host/ANGLE renderer that meets Godot 4.7.1's GLES3 uniform limits, or
an owner-approved physical Android debug-device session. That run must repeat
the complete touch, lifecycle, safe-area, fairy/life, recovery, performance,
and screenshot matrix before Android visual/device acceptance.

## Post-review correction rebuild

The later lives/routes/phone-layout correction was rebuilt through the same
development-only preset. The current ignored APK is 76,684,765 bytes with
SHA-256
`2DCE71E33B321784AD2AEFBBE3E92D5E6B1582F34F1731266CF65A54EBAEC10A`.
Package `com.flinsappvault.fredmyers.dev`, version `0.2.0-m2-dev` (`20001`),
minimum SDK 24, target SDK 36, arm64-v8a plus x86_64, ZIP alignment, and v2/v3
Godot debug signatures all revalidated. The 180-entry privacy scan found no
tests, tools, evidence, source-control metadata, secret-like content, or
private Windows paths, and `aapt2` reported no requested Android permissions.
This refresh does not change the emulator-renderer blocker or create a release,
store, signing, publication, or physical-device claim.

## Physical-phone owner handoff

The later handoff adds a read-only-by-default, hash-guarded physical-device
preflight without changing the APK. The executed command found zero devices
and returned `DEVICE_NOT_CONNECTED / UNVERIFIED`, with the expected APK hash,
package, candidate source SHA, explicit owner next action, and
`mutation_performed=false`. Fictional safety fixtures passed 60/60 for absent,
unauthorized, offline, emulator-only, ambiguous, wrong-hash, wrong-package,
unsupported API/ABI, unprovable installed-version, downgrade, and
explicit-serial cases.

Install, launch, and redacted app-scoped diagnostics are coded behind explicit
serial and acknowledgement gates but were not executed. See
`M2_PHYSICAL_ANDROID_OWNER_HANDOFF.md` for the exact commands and two-run owner
matrix. Physical-device acceptance remains unverified and scores remain
unchanged.
