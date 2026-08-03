# Fred App Build 1 test report

Date: 2026-08-03

## Scope and authorization

The owner's explicit next-phase instruction starts App Build 1 as a local
testing phase. The exact gameplay and presentation source is commit
`9e4091fa9c8822395d27c0ebe689c7da50552d31` on local branch
`codex/app-build-1`, descended from the validated desktop/icon candidate
`7c64c360f70068685a65ca1f5f0a73339d20f0bf`.

This build is not a production build, release, deployment, store submission,
or physical-device acceptance result. It remains local and unpushed because
the configured GitHub repository is public.

## Artifact identity

- Local artifact: `builds/android/fred-myers-app-build-1-debug.apk`
- SHA-256: `E57242793EED3FBF83570299346EB6236BC37BCF3C40EBA2742136D747C73316`
- Size: 81,973,530 bytes
- Package: `com.flinsappvault.fredmyers.dev`
- Label: `Fred Myers App Build 1`
- Version: `0.2.1-app-build-1` (`20101`)
- Minimum/target/compile SDK: 24/36/36
- Architectures: `arm64-v8a` and `x86_64`
- Orientation: landscape
- Requested Android permissions: zero
- Signing: Godot development/debug certificate, RSA 2048, APK Signature
  Schemes v2 and v3; no production keystore or release signing
- ZIP alignment: passed with 16 KiB page alignment validation

The newer version code preserves the existing development package identity so
an authorized owner phone can test an update without a downgrade or a second
Fred application identity. The corrected v2 game icon is the active Godot
application icon in this exact source.

## Toolchain and package inspection

- Godot: `4.7.1.stable.official.a13da4feb`
- JDK: Eclipse Temurin/OpenJDK `17.0.19`
- Android build tools: `36.0.0`; `aapt2` 2.20-13193326
- ADB: 1.0.41, platform tools 37.0.0-14910828
- APK entries: 188
- Content scan: 63 text entries; no tests, tools, evidence, source-control
  metadata, signing material, credentials, private Windows paths, or secret-like
  content
- Debug signer certificate SHA-256:
  `3846f003df913682a497d7bf726439df432ed9d4f83cf99f46647079be8f6a87`

## Validation

- Godot headless import: passed.
- Complete deterministic matrix: 17 suites, 2,190 passed, 0 failed.
- App Build 1 export contract: passed.
- Physical-device safety fixtures: 60 passed, 0 failed.
- Physical-device static safety contract: passed.
- Live read-only preflight: `DEVICE_NOT_CONNECTED / UNVERIFIED`, zero devices,
  no selected serial, and `mutation_performed=false`.
- Mobile Game Core remains version 0.5.1 at tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- `fred_save` remains schema v1.

No phone was installed to, controlled, or captured. Emulator shader limits
from the earlier M2 run are not relabeled as App Build 1 phone acceptance.

## Owner gate

The next owner action is to connect one authorized Android phone with USB
debugging, run the read-only preflight with its explicit serial, review the
result, and separately approve install/launch. The guarded workflow forbids
implicit target selection, uninstall, clear-data, downgrade, root, permission
grant, bootloader, or broad log capture.

Milestone percentages do not increase for packaging alone. M3 story work,
production signing, store preparation, iOS export, publication, and release
remain separate future gates.
