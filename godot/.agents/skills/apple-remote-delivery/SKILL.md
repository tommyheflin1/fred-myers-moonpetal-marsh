---
name: apple-remote-delivery
description: Prepare, diagnose, archive, upload, and verify a Godot iOS build from a remote Mac. Use for Apple, Xcode, TestFlight, App Store Connect, remote-desktop Mac, provisioning, signing, archive, or upload work on a generated game.
---

# Apple Remote Delivery

Use one versioned release lane from the exact clean candidate through Apple processing. Never improvise a new uploader merely because a step failed.

Before release work, use the bundled `shared-build-process` skill and run the canonical
`tools/audit_process.py` against this candidate. A mismatch requires reviewed migration.
Checkpoints are bound to commit/tree and archive content, not just version/build names.
Status exits 0 only for a valid, unexpired processed build; 3 is pending/absent/unknown,
2 is failed/invalid/expired. Preserve the archive and investigate, without changing lanes.

## Non-negotiable boundaries

- Record game ID, bundle ID, version, build, branch, commit, tree, Core version, Godot version, and clean status before any Mac work.
- A Windows test, unsigned export, simulator build, signed archive, uploaded binary, processed TestFlight build, physical-device result, App Review state, and public release are separate gates.
- Do not store Apple passwords, two-factor codes, API private keys, certificates, provisioning profiles, or private player data in the repository, logs, clipboard instructions, or evidence bundles.
- Signing, upload, tester distribution, App Review submission, and public release each require explicit owner authorization. Automatic public release stays disabled.
- A build number is immutable after Apple accepts an upload. Stop on a duplicate rather than silently changing it.
- Preserve the last successful checkpoint and logs. Resume from the failed gate instead of rebuilding everything.

## Route the task

1. Read [remote-mac-setup.md](references/remote-mac-setup.md) when provisioning or repairing the remote Mac.
2. Run `scripts/apple_remote_doctor.sh <project-root>` before building. Resolve every failure before continuing.
3. Read [standard-release-process.md](references/standard-release-process.md) before any release work. It defines the single supported command lane and stopping rules.
4. Read [build-and-upload.md](references/build-and-upload.md) for candidate transfer, unsigned validation, archive, upload, processing, and TestFlight assignment.
5. Use only `tools/release-ios <preflight|archive|upload|status> <exact-commit>` for normal releases. The lower-level scripts are implementation details, not alternative release methods.
5. Read [troubleshooting.md](references/troubleshooting.md) only for the reported failure code or checkpoint.

## Required operating sequence

1. Preflight locally and create a hash-guarded, exact-commit source bundle.
2. Transfer the bundle plus its manifest to the remote Mac; verify SHA-256 before opening it.
3. Run the doctor. Install or repair only the missing prerequisite, then rerun the doctor.
4. Run `tools/release-ios preflight`: authenticate the exact App Store Connect app before lengthy work, check the clean exact commit, validate Game Center provenance, perform Godot import/export, and compile unsigned for the simulator.
5. Confirm Apple identifiers and capabilities in both the candidate and live App Store Connect record.
6. After archive authorization, run `tools/release-ios archive`: sign, archive, verify code signature, distribution entitlements, bundle ID, version, and build.
7. After upload authorization, run `tools/release-ios upload`; do not treat command completion as Apple processing.
8. Run `tools/release-ios status`. It must authenticate through the App Store Connect API and match both marketing version and build before reporting Apple receipt.
9. Assign only the approved internal TestFlight group, then perform physical iPhone/iPad and live Game Center checks where applicable.
10. Stop before external beta, App Review, or public release unless each is explicitly authorized.

## Success condition

Report the furthest proven gate and its exact evidence. “Done” requires the requested gate—not merely an archive or upload command—to be visibly confirmed in Apple’s system.
