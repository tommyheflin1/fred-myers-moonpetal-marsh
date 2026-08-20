# Fred iOS App Build 2 handoff report

Prepared: 2026-08-20

Build 2 uses the clean committed Fred candidate, marketing version `1.0`, build
number `2`, production bundle identifier `com.flinsvault.fredmyers`, iPhone and
iPad support, iOS 15 minimum, and the existing Game Center entitlement and two
Fred leaderboard identifiers. The signed runner uses distinct Build 2 archive,
export, entitlement, result and acknowledgement names so it cannot silently
reuse the historical Build 1 upload.

The Windows package is a Git bundle plus checksums and contains no Apple team
ID, signing certificate, provisioning profile, credential, owner save or player
data. On the authenticated Mac, the runner must verify the exact commit and
clean tree, Godot 4.7.1, Xcode 26+, iOS SDK 26+, the pinned Game Center plugin,
the generated privacy manifest, Simulator build, signed Game Center entitlement
and App Store distribution profile before requesting App Store Connect upload.

An upload is not considered complete until Xcode reports success, App Store
Connect processes exact Build 2, and the build is assigned to `Fred Owner
Testing`. Physical iPhone audio, touch, lifecycle, save and live Game Center
acceptance remain separate post-upload gates. No App Review submission or
public release is authorized by this handoff.
