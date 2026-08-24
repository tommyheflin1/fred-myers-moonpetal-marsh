# Fred iOS App Build 3 handoff report

Prepared: 2026-08-24

Build 3 packages the current owner-reviewed Fred candidate as marketing version
`1.0`, build number `3`, production bundle identifier
`com.flinsvault.fredmyers`, iPhone and iPad support, iOS 15 minimum, landscape
sensor rotation, Game Center entitlement, and both permanent Fred leaderboards.

The transfer follows the proven Snake Reactor lane: a clean exact-commit Git
bundle and hash manifest are moved to the existing Mac; the runner clones the
exact commit, performs the Godot/Xcode/Game Center preflight, archives with the
installed Apple Distribution identity and Fred App Store profile, verifies the
signed application and entitlement, exports a separately named Build 3 IPA,
and uploads it with the existing App Store Connect API key through `altool`.
No password, private key, certificate, provisioning profile, save, or player
data is included in the handoff.

Upload success is not TestFlight readiness. Completion requires Apple to expose
exact version `1.0` build `3`, processing to finish, and the build to be
available to the existing internal `Fred Owner Testing` group. Physical iPhone
and iPad control, lifecycle, audio, live Game Center, Golden Egg discovery, and
human visual acceptance remain post-upload test gates. No App Review
submission, automatic public release, or public repository push is authorized.
