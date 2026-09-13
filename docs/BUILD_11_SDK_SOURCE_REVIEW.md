# Build 11 SDK source review

Source baseline: 4f3c0db, reviewed September 12, 2026. This is a source inventory,
not a signed-binary or production-backend privacy attestation.

- Godot 4.7.1 is the intended engine. The only project addon directory is
  mobile_game_core. No advertising/analytics SDK was found in project configuration.
- The configured iOS native plugin is GameCenter. Its existing build script pins
  fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb and the reviewed scene-presentation,
  signed-identity and device-only Keychain patches. The compiled Build 11 plugin
  has not yet been produced and inspected; expected provenance is not actual proof.
- App-owned network entry points are GoldenEggNetworkBridge and FredUpdateGate.
  The latter is explicitly disabled by game/game.json and returns before allocating
  an HTTP request. The former bounds its company-service destination and response
  size, uses TLS, and runs outside the gameplay thread.
- Game Center authentication, scores and campaign achievements use platform services.
  Golden Egg identity data is separately disclosed as linked functionality data.
  User-facing publication remains an explicit Public/Anonymous/Don't Post choice.
- GoldenEggLocalStore requires the GameCenter Keychain bridge on iOS, refuses a
  plaintext fallback there and removes legacy material only after migration readback.
- The app privacy manifest declares linked UserID and GameplayContent for app
  functionality, no tracking domains, and explicit required-reason categories.
  Privacy regression tests validate these fields and preserve plugin-owned manifests
  when staging the app manifest.

Apple's current documentation requires declarations for app and SDK collection and
required-reason APIs. Reference checked during this review:
https://developer.apple.com/documentation/bundleresources/privacy-manifest-files

Remaining: inspect the generated native plugin and final signed archive, reconcile
actual linked engine dependencies and manifests, and verify the deployed website.
`third_party_sdk_inventory_reviewed` remains false pending that reconciliation.
No settings, Apple privacy answers, or privacy promises were loosened by this audit.
