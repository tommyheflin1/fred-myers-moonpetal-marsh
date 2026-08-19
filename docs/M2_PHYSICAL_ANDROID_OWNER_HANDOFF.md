# M2 physical Android owner-acceptance handoff

Updated: 2026-08-18

## Current App Build 1 revision 19

The current guarded phone candidate supersedes the older artifact identities
retained below for append-only history. Revision 19 is built from exact source
`2b0931ba9a848c51e3820f8d361fccce6dbd9228` with the complete 100-level
Campaign 1 profile set, touch-only player routing, age-five recovery floors,
PG copy, the Moonpetal hero story, the bottom action row, mouth-clear aligned
Fred gear, continuous touch leap traversal over predators without a round reset, deterministic
surface/underwater routes for aquatic predators, upgraded Fred/wildlife
anatomy, connected deterministic articulation, layered character volume,
garment-specific anatomical Fred attire with soft fitted materials and no floating
locomotion/location text above Fred or nameplates above predators.

- artifact: `builds/android/fred-myers-app-build-1-debug.apk`;
- SHA-256: `799B883E0EAB2A66B8BE336E66AD39E1EABF9D7515FE9EA31051D6C116037D2C`;
- size: 84,907,755 bytes;
- version: `0.2.1-app-build-1-r19` (`20119`);
- package: `com.flinsappvault.fredmyers.dev`;
- ABI: arm64-v8a and x86_64;
- permissions: zero requested;
- signing: Godot development/debug certificate only.

The same explicit serial and owner/save acknowledgement boundary applies. A
zero-device result remains `DEVICE_NOT_CONNECTED / UNVERIFIED` and is not
physical phone or tablet acceptance. Revision 19's 60/60 fictional safety
fixtures pass. No install, launch, selected serial, diagnostics, or phone
control is performed by this packaging refresh, so physical testing remains
`UNVERIFIED`.

## Scope and result

This Fred-only handoff begins from exact gameplay/APK source commit
`1ae3b28fc89a38de616af126c0e08fdbb8f624a8`, tree
`f3fe0af1d5077998a24de02fe6ca69999715c1a0`. It adds a hash-guarded,
read-only-by-default Windows preflight for a future owner-authorized physical
Android session. It does not change gameplay, rendering, Core 0.5.1,
`fred_save` v1, the APK, the desktop shortcut, or owner saves.

The executed default command found no connected device and returned exit code
zero with this truthful machine-readable state:

- `result`: `DEVICE_NOT_CONNECTED`
- `status`: `UNVERIFIED`
- `device_classification`: `ZERO_DEVICES`
- `mutation_performed`: `false`
- candidate source:
  `1ae3b28fc89a38de616af126c0e08fdbb8f624a8`
- APK SHA-256:
  `2DCE71E33B321784AD2AEFBBE3E92D5E6B1582F34F1731266CF65A54EBAEC10A`
- package: `com.flinsappvault.fredmyers.dev`

No device was selected, installed to, launched, controlled, or captured.
Physical-phone acceptance remains unverified.

## Tool modes and safety invariants

`tools/validate_physical_android_device.ps1` provides three explicit modes:

1. `Preflight` is the default and read-only.
2. `InstallLaunch` is unavailable without an exact physical-device serial,
   `-AcknowledgeOwnerDevice`, and `-AcknowledgeSaveRisk`.
3. `CaptureDiagnostics` additionally requires
   `-AcknowledgeDiagnosticCapture` and writes only redacted, app-scoped
   diagnostics under ignored `builds/physical-android/`.

Every invocation verifies the exact APK hash and byte count before device
classification. Non-fixture preflight also reuses the existing APK content and
export validators, then verifies package/version, SDK 24/36, arm64-v8a plus
x86_64, zero requested permissions, ZIP alignment, and the Godot debug
signature.

Device discovery fails closed:

- zero devices returns `DEVICE_NOT_CONNECTED / UNVERIFIED` cleanly;
- unauthorized and offline targets are rejected;
- emulator-only evidence cannot become physical acceptance;
- multiple devices are ambiguous unless the owner explicitly supplies one
  exact physical serial;
- an explicit serial must resolve to one authorized physical target;
- API below 24, unsupported ABI, less than 512 MB free storage, mismatched APK,
  or a downgrade attempt is rejected.

The future install path distinguishes first install from a data-preserving
update. It never exposes uninstall, clear-data, downgrade, permission-grant,
root, remount, reboot, bootloader, or developer-setting operations. It does not
claim that Android app data can be backed up without platform/owner authority;
the required save-risk acknowledgement makes that limitation explicit.

The bounded diagnostic mode uses only Fred's package/PID for memory, frame, and
the last 400 app-process log lines. It redacts the device serial, Windows/macOS
user paths, and email-like text. It does not collect accounts, contacts,
location, unrelated logs, or broad device state.

## Deterministic tooling evidence

The fictional fixture suite passed **60/60** checks. It covers:

- no device;
- unauthorized device;
- offline device;
- emulator-only;
- ambiguous multiple physical devices;
- wrong APK hash;
- wrong package;
- unsupported device API;
- unsupported device ABI;
- an installed Fred version that cannot be proven;
- downgrade rejection; and
- explicit physical-serial selection while another emulator is present.

Every fixture remained `UNVERIFIED`, reported the observed APK hash, and
performed no mutation. The portable static validator separately proves the
hash/package guard, explicit serial selection, acknowledgement gates,
app-scoped diagnostics, and absence of prohibited destructive ADB paths.

The unchanged Fred product also revalidated:

- 17 Godot suites: **2,188 passed, 0 failed**;
- Godot 4.7.1 headless import: passed;
- readiness: 49 required artifacts, eight fictional save fixtures, Core
  0.5.1, Godot 4.7;
- Android export contract: package/version/orientation, SDK policy,
  arm64-v8a plus x86_64, and zero requested permissions passed;
- APK inspection: 180 entries, aligned, v2/v3 Godot debug signature, and no
  tests, tools, evidence, source-control, secret-like, or private-path content;
  and
- physical preflight static safety validation: passed.

## Owner commands

Run the read-only command first from the Fred worktree:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_physical_android_device.ps1
```

After connecting exactly one owner-authorized physical phone, copy its exact
serial locally and run read-only selection:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_physical_android_device.ps1 -Mode Preflight -Serial "<OWNER-APPROVED-SERIAL>"
```

Stop unless the result is `DEVICE_PREFLIGHT_READY`. The serial must not be
placed in documentation, chat, screenshots, or committed files.

Only after a separate explicit owner authorization for that connected device,
the guarded install/launch command is:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_physical_android_device.ps1 -Mode InstallLaunch -Serial "<OWNER-APPROVED-SERIAL>" -AcknowledgeOwnerDevice -AcknowledgeSaveRisk
```

The optional bounded capture also requires separate approval:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_physical_android_device.ps1 -Mode CaptureDiagnostics -Serial "<OWNER-APPROVED-SERIAL>" -AcknowledgeOwnerDevice -AcknowledgeSaveRisk -AcknowledgeDiagnosticCapture
```

## Ordered two-run physical-phone matrix

Use fictional/local play only. Do not sign in, enable analytics, or enter real
player information.

### Run one

1. Verify Fred's development label/package, landscape orientation, offline
   launch, title art, music, and no permission prompt.
2. Inspect the top cutout/safe area and confirm objective, lives, Pause,
   energy, status, touch-and-drag steering guide, MUNCH, LEAP, DIVE/SURFACE,
   and BOOST do not clip
   or overlap.
3. Exercise real touch movement, reversal, leap/landing, tongue hit/miss,
   boost/exhaustion/recovery, dive/underwater/surface, and pause/resume. Confirm
   one contact creates one action and releases cleanly.
4. Lose the first and second lives separately. Confirm the current level stays
   active, collected progress remains, and the reached midpoint restores when
   available. Lose the final current life and confirm only then that
   `OH NO FRED!!!` appears with working Retry and Home choices.
5. Confirm an odd level runs left-to-right, an even level runs right-to-left,
   lily pads/bugs/predators mirror correctly, and the first four marsh
   background treatments are visibly distinct.
6. Exercise Android Home/background during countdown, play, pause, and an
   active touch. Resume and confirm no stale input, off-screen life loss,
   duplicated reward, or unexpected unpause.
7. Relaunch offline and confirm save-v1 progress, checkpoint, current lives,
   energy, and stacked fairy life behavior remain correct.
8. Observe touch comfort, camera comfort, Fred/prey/predator readability,
   audio balance, frame pacing, memory pressure, battery warmth, and thermal
   throttling without presenting subjective observations as automated proof.

### Run two

1. Close and relaunch the existing installed app without uninstalling,
   clearing data, or changing permissions.
2. Repeat movement, MUNCH, leap, boost, depth, pause/Home/resume, life one/two/
   final, checkpoint recovery, route direction, and save/relaunch.
3. Confirm the same saved state returns, no fairy/life/reward duplicates, no
   stale touch survives lifecycle transitions, and no new crash, ANR, shader,
   resource, or rendering warning appears.
4. Compare the two runs' human notes and the bounded app-scoped diagnostics.
   Record automated facts separately from owner control-feel, visuals, audio,
   heat, and overall acceptance.

## Integrity and scoring

The APK remains 76,684,765 bytes with the guarded SHA-256 above. Core remains
tree `288d87420c5694f80c071f00aa71a0b581f9f60c`. Owner saves remained
byte- and timestamp-identical:

- primary: 592 bytes, modified `2026-07-22T03:53:46.7782318Z`, SHA-256
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`;
- backup: 592 bytes, modified `2026-07-22T03:53:32.9493944Z`, SHA-256
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.

Exactly one desktop shortcut remains:
`%OneDrive%\Desktop\Fred Myers Owner Test.lnk`, targeting this worktree's
exact-candidate desktop launcher. The configured GitHub
repository remains public; no push or PR is permitted.

M012 remains 99.3%, M013 remains 0%, and TASK-002 remains 19.9%. Tooling and a
no-device result do not earn physical-device, platform-hardening, or milestone
credit.

## App Build 1 replacement artifact

For the 2026-08-03 owner-authorized App Build 1 phase, the guarded workflow now
targets `builds/android/fred-myers-app-build-1-debug.apk` from exact source
`9e4091fa9c8822395d27c0ebe689c7da50552d31`. Its SHA-256 is
`E57242793EED3FBF83570299346EB6236BC37BCF3C40EBA2742136D747C73316`,
size is 81,973,530 bytes, package remains
`com.flinsappvault.fredmyers.dev`, and version is
`0.2.1-app-build-1` (`20101`). The executed default preflight again returned
`DEVICE_NOT_CONNECTED / UNVERIFIED` and performed no mutation.

## Mobile-first App Build 1 revision 3

The current guarded successor was rebuilt from exact source
`c0495dcc4c67afc3f0818230e8d2b63c33a15fd4` after the mobile-first product,
visual, cosmetics and scoring-adapter uplift was committed. The only accepted
phone target is now:

- artifact: `builds/android/fred-myers-app-build-1-debug.apk`;
- SHA-256: `C9FB181368524592918600235F1AE7B8083F5850CA5511BA61E6B0999F7CEB1B`;
- size: 84,841,877 bytes;
- package: `com.flinsappvault.fredmyers.dev`;
- version: `0.2.1-app-build-1-r3` (`20103`);
- SDK: minimum 24, target/compile 36;
- ABI: arm64-v8a and x86_64;
- permissions: zero requested;
- signing: local Godot debug certificate only, APK Signature Schemes v2/v3.

The same fail-closed command and owner acknowledgement boundary apply. No real
device install, control, diagnostic capture, signing change, store action, or
physical acceptance is claimed by this refresh.
The executed default revision-2 preflight returned
`DEVICE_NOT_CONNECTED / UNVERIFIED`, selected no device, and performed no
mutation.
