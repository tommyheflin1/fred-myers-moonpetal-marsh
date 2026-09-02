# Build and Upload Runbook

Use a clean checkout at one exact commit. Keep the version/build immutable throughout the lane.

## Before the Mac

1. Run the project's local tests and record what actually passed.
2. Confirm `game/game.json`, `export_presets.cfg`, App Store Connect, and the intended release record agree on bundle ID, marketing version, build number, orientation, and capabilities.
3. Create and hash the source handoff with `tools/prepare_source_handoff.py`; verify the hash again on the Mac.

## Live App Store Connect readiness

The owner verifies these live—not from an old report:

- active agreements, tax, and banking requirements;
- app record and bundle ID;
- unused build number for the intended marketing version;
- pricing, availability, and territories;
- privacy answers, age rating, content rights, and encryption/export-compliance answers;
- Game Center identifiers and leaderboards/achievements when enabled;
- support URL, privacy URL, screenshots, review contact, review notes, and demo access where applicable;
- manual release remains selected unless public release was separately authorized.

## Deterministic command lane

Set the exact commit once:

```bash
ROOT="$PWD"
COMMIT="$(git rev-parse HEAD)"
tools/release-ios preflight "$COMMIT"
```

Preparation is unsigned. It imports and exports with Godot, builds the iOS simulator target without signing, and writes a checkpoint.

After the owner authorizes signing, find the 10-character Apple team ID in Xcode and run:

```bash
export APPLE_TEAM_ID="YOURTEAMID"
export APPLE_ARCHIVE_ACK="ARCHIVE_BUILD_$(python3 -c 'import json; print(json.load(open("game/game.json"))["build_number"])')"
tools/release-ios archive "$COMMIT"
```

The archive phase verifies the signed application, bundle ID, version, build, and Game Center entitlement when declared.

After the owner separately authorizes upload:

```bash
export APPLE_UPLOAD_ACK="UPLOAD_BUILD_$(python3 -c 'import json; print(json.load(open("game/game.json"))["build_number"])')"
tools/release-ios upload "$COMMIT"
tools/release-ios status "$COMMIT"
```

An upload command returning success proves only command acceptance. Open App Store Connect and confirm the exact version/build becomes visible and finishes processing. Record the Apple-visible state or delivery identifier.

## Xcode-account failure recovery

If upload fails with account/authentication error `-501`, preserve the archive and
checkpoint. Check Apple status for the exact build before retrying; reauthenticate
the existing Xcode account once with the owner. Resume the same upload command.
Do not create keys or switch uploaders automatically. The legacy API helper is only
for a separately reviewed and owner-authorized recovery plan with existing key
references and expected IPA hash; its existence does not make it an alternate normal
lane. Record the recovery decision and proven Apple outcome in the candidate handoff.

## TestFlight and device gate

After Apple processing, assign only the approved internal TestFlight group. Install that exact build on the target iPhone/iPad and record launch, lifecycle, orientation, audio/haptics, save migration, network-offline behavior, and live Game Center behavior when enabled. External testing, App Review submission, phased release, and public release are later owner-controlled gates.
