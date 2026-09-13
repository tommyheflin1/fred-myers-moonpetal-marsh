# Build 11 runtime dependency and encryption review

Scope: local candidate based on `59f681e669ec186469198e83c68aeea4133cf80d`
with uncommitted Build 11 changes. This is source evidence, not a signed-binary
inventory or completed export-compliance declaration.

| Component | Observed source/configuration | Remaining verification |
| --- | --- | --- |
| Godot runtime | `project.godot` targets 4.7 GL Compatibility; native plugin tooling pins `4.7.1-stable` | Exact exported engine binary, compiled third-party libraries and license notices |
| Mobile Game Core | Bundled `addons/mobile_game_core/plugin.cfg` declares 0.5.1 | Inventory exact bundled code, not a presumed upstream version match |
| Game Center plugin | Sole enabled iOS plugin in `export_presets.cfg`; pinned commit `fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb` | Compile device/simulator, preserve all three patch hashes, validate exported descriptor and binary |
| Native platform services | Patch imports GameKit and Security; Keychain namespace uses the app bundle and disables synchronization | Physical-device secure storage and identity/lifecycle checks |
| Golden Egg transport | `golden_egg_network_bridge.gd` uses Godot HTTPClient with `TLSOptions.client()` on HTTPS port 443 | Do not describe this as exclusively Apple URLSession/system-provided encryption without checking the engine build |
| Randomness and request authentication | Godot Crypto random bytes; legacy `golden_egg_client.gd` contains SHA-256 HMAC support | Confirm actual export contents and runtime reachability; do not claim absence merely because a newer transport exists |
| Pack encryption | Both configured exports disable PCK/directory encryption | Verify the generated export retains those settings |

No additional `.gdextension`/`.gdip` files were found in the local addons scan.
The local `ios` directory currently contains the privacy manifest, not compiled
Game Center frameworks. This prevents certifying a complete native SDK inventory.
No advertising or analytics SDK was identified in the examined app scripts and
export configuration; absence from the eventual native binary is not yet proven.

## Declaration boundary

Apple's guidance includes third-party linked libraries when deciding the
`ITSAppUsesNonExemptEncryption` value. An HTTPS URL alone does not establish that
all encryption is limited to the operating system. The existing release helper
requires an explicitly reviewed value and refuses conflicting exported values.
No value was invented, no compliance flag was set true and no existing native
configuration was changed during this review.

Sources inspected September 10, 2026:

- https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/
- https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption
- https://docs.godotengine.org/en/stable/about/complying_with_licenses.html

The exact engine/plugin notices must accompany the actual distributed components;
the earlier empty generated attribution list does not prove that no notices are
required. Preserve the current provenance uncertainties until those components
and notices are verified.

## Subsequent verification in the same release task

- App Store Connect's actual accepted 1.1 Build 10 metadata was inspected again:
  Binary State Validated; bundle com.flinsvault.fredmyers; SDK 23F73; App Uses
  Non-Exempt Encryption No. The existing Fred export helper also carried false.
  Preserved this declaration in ios_release_config.json; this does not claim
  that Godot encryption is limited to Apple operating-system APIs. The Build 11
  native artifact still requires inspection and an identical export declaration.
- Added an offline LICENSES panel that uses the executing engine's own license,
  third-party-license and copyright APIs. The exact pinned Game Center plugin
  MIT license is included. Nineteen headless and twenty real-renderer component
  checks passed. Main-scene integration is separately covered by regression tests.
- Registered Godot, the existing Core snapshot and the exact plugin pin in the
  dependency inventory. Native framework composition is not certified by these
  source or desktop checks; unresolved findings remain visible.
- Reused the established Flins public policy-verification key byte-for-byte,
  SHA-256 152b15f63303294af874952c16ac17054eacfc814a131cda15cf06e2366405a4.
  No private key, certificate or credential was read, changed or transferred.
