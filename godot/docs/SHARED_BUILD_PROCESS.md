# Versioned development-to-Apple process

Process 1.6 candidate, reviewed 2026-08-30. This is a shared operating contract,
not a production monorepo or permission to change released apps.

## Development and reuse

1. Inventory the actual branch, dirty files, commit/tree, game/store/save identities,
   pinned Core/Godot/plugins and enabled features. Preserve dirty work and owner saves.
2. Start new apps with `tools/new_game.py`. Run `tools/audit_process.py` on the result.
   Existing apps need reviewed migrations, not regeneration over an existing folder.
3. Keep rules/content/assets app-owned. Promote only tested provider-neutral behavior
   to Core, then explicitly migrate consumers. Never infer compatibility from version labels.
4. Run isolated deterministic rules, save migration/corruption/backup recovery,
   input arbitration, touch release/cancellation, pause/home/background/resume,
   audio/haptics and restart tests. Use temporary user-data locations, never owner saves.
5. Test real scene input in addition to pure rules. Review phone and tablet safe areas,
   HUD overlap, readable prompts, reduced-motion/accessibility, frame time and memory.
   Desktop pointer simulation is not real multi-touch or physical-device evidence.
6. Inventory third-party asset licenses, runtime exports and dependencies. Export no
   tests, private reports, keys, screenshots of accounts, local saves or build caches.
7. Reconcile feature/data inventory with the dedicated website privacy policy and
   App Store answers. Golden Egg website submission is separate from a local solve;
   pending/rejected transport never becomes verified. Do not embed shared signing keys.
8. Freeze the tested candidate and preserve sanitized, exact-SHA evidence in CI.

## Apple: one lane, separately proven gates

Read the Apple skill's remote-mac-setup, standard-release-process and build-and-upload
references. The standard remains `tools/release-ios preflight → archive → upload → status`.
Each invocation takes the exact candidate SHA. This is our supported lane, not a claim
that Apple forbids its other official upload methods.

- Remote Mac: approved remote desktop; no credentials in chat, bundles or source;
  initialized Xcode, selected developer directory, supported SDK, matching Godot/export
  templates, SCons for the pinned native plugin, adequate space and caffeinate.
- Preflight: process lock matches; local regression evidence reviewed; exact clean
  commit/tree; dedicated policy live; correct ASC app/auth; doctor/import/unsigned build.
- Archive: separate owner authorization; signed bundle/version/build and true Game Center
  entitlement verified; record source identity plus archive content hash atomically.
- Upload: separate authorization; refuse stale checkpoints or altered archives. Preserve
  logs. On an ambiguous network outcome query Apple before attempting another upload.
- Status: only exact version/build with `processingState=VALID` and not expired exits 0.
  Pending/absent/unknown exits 3; failed/invalid/expired exits 2. Neither proves tester
  assignment, installed-device success, review submission or public release.
- TestFlight: explicitly authorized group, then actual iPhone/iPad install and fresh/upgrade
  save test; offline guest, Game Center login cancellation/relogin/native leaderboard,
  achievement replay, pause on native overlays, Golden Egg privacy/website flow.
- Review: reconcile privacy manifest/required-reason APIs, privacy answers, age ratings,
  screenshots, support URL, export compliance, agreements and Game Center records.
  Submit only when authorized. Public release is a separate decision; do not silently
  change an existing app's owner-selected release setting.

Never overwrite an existing version/build lane with a different commit. Old checkpoints
without source-tree/archive hashes need a reviewed migration or a new candidate; do not
fabricate missing provenance. Never rerun preflight over a preserved signed archive.

## Stable change processing

`PROCESS_LOCK.json` records LF-normalized hashes of shared release implementation files.
CI runs the self-audit. Changing a locked file requires updating its digest in the same
reviewed change after tests; a digest match alone does not prove behavior or security.
Run `python tools/audit_process.py --fleet <workspace>` against `PROCESS_APPS.json` to
find missing/different implementations. The command is offline, read-only and exits
nonzero for any drift. It never copies credentials, changes branches or upgrades games.

For each migration: choose the active candidate; compare against the last known working
app lane; adapt identity/config without replacing save/Core versions; run app regressions
and fictional release-state tests; review the diff; commit; run the canonical audit again.
Keep the old working lane until the replacement passes local and Mac/device gates.
Xcode Cloud remains supplemental with no PR distribution, manually started archive,
owner-approved TestFlight and no implicit public release.

## Official requirements checked 2026-08-30

- Apple requires iOS/iPadOS 26 SDK or later for uploads from April 28, 2026:
  https://developer.apple.com/news/?id=ueeok6yw
- Upload and Apple processing are separate:
  https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds
- Processing statuses and failure investigation:
  https://developer.apple.com/help/app-store-connect/reference/app-uploads/build-upload-statuses/
- Privacy inventory must include actual third-party behavior:
  https://developer.apple.com/app-store/app-privacy-details/

Recheck primary requirements when preparing each release or changing toolchain/plugins.
Do not auto-upgrade Godot/Xcode/Core to a newly announced version without compatibility
testing. These references are verification inputs, not legal-compliance certification.
