# Apple Delivery Troubleshooting

Resume from the last successful checkpoint. Do not change version, build, bundle ID, signing method, uploader, or source commit while diagnosing.

| Failure | Action |
| --- | --- |
| `host:macOS required` | Move the Apple lane to the approved remote Mac. Windows cannot produce the signed Apple archive. |
| Xcode or iOS SDK below 26 | Update/install the approved Xcode and iOS platform, run first-launch setup, then rerun the doctor. |
| Godot 4.7.1 or templates missing | Install the official editor and exactly matching export templates; do not use mixed versions. |
| `scons` missing | With owner approval run the user-scoped pip command in `remote-mac-setup.md`, fix `PATH`, then rerun the doctor. |
| No signing identity | In Xcode Accounts choose the correct team and refresh certificates/profiles. Do not export a private certificate into the repo. |
| Dirty or wrong commit | Stop. Use a new exact-commit checkout and verify the handoff SHA. Do not archive local edits. |
| Godot plugin build fails | Confirm the project-provided plugin build/validation tools, Xcode SDK, SCons, and exact plugin pin. Do not substitute an unpinned binary. |
| Simulator architecture failure | Remove only the lane's DerivedData, regenerate from the same commit, and rebuild. Do not edit release identity. |
| Provisioning/capability failure | Compare bundle ID, team, entitlements, App ID capabilities, and App Store Connect configuration. Game Center must exist in all layers. |
| Xcode upload error `-501` | Query exact Apple status first; reauthenticate the existing Xcode account once with the owner, preserve the archive and retry the same lane. No automatic new key/uploader; exceptions require a reviewed recovery plan. |
| Duplicate build | Stop. If Apple already accepted the number, create a new authorized candidate with a new build number from source; never mutate the uploaded build. |
| Upload succeeded but build absent | Wait for processing, inspect Apple email/activity, and confirm the exact app/version/build. Upload success alone is not processing evidence. |
| Remote desktop disconnected | Reconnect and inspect the timestamped lane log/checkpoint. `caffeinate` protects the command; resume only from the recorded gate. |
| `Permission denied` launching the wrapper | Verify source handoff hash and exact Git checkout first; run `sh tools/release-ios <mode> <commit>` if the transfer lost executable mode. Do not disable macOS security or build another ZIP runner. |
| `RELEASE_CHECKPOINT_STOP` | Compare commit/tree, identity, gate and archive hash. Never edit the checkpoint to claim success. Resume the existing candidate or prepare a separately approved new lane. |
| Apple status exit 3 | Pending/absent/unknown. Preserve archive; inspect activity/logs and query again later. Do not resubmit based only on this result. |
| Apple status exit 2 | Failed/invalid/expired. Record Apple's reason, fix only that cause in a reviewed candidate, then repeat the appropriate gate. |

Never disable Gatekeeper, firewall, FileVault, 2FA, or code-signature verification as a workaround.
