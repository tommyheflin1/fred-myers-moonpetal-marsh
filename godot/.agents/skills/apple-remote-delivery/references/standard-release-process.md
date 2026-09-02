# Standard Apple Release Process

This is the only normal Apple lane for generated games. Do not switch to browser upload, Xcode Organizer, ad-hoc ZIP runners, a new API key, or a newly invented cloud workflow when a gate fails.

## Fixed sequence

1. Freeze one clean candidate commit and record its tree, bundle ID, version, and build.
2. Use the `app-privacy-policy` skill to publish and verify the exact app-specific policy on `theflinsappvaultllc.com`; reconcile it with the candidate and App Store privacy answers.
3. Fill `tools/ios_release_config.json` from the existing App Store Connect app and existing minimum-role API key. The private `.p8` remains outside the repository.
4. Run `tools/release-ios preflight <commit>`. This verifies the live policy, authenticates and matches the live App Store app before Godot/Xcode work, then performs the remote doctor and unsigned preparation.
5. Fix only the failed prerequisite. Rerun the same preflight; do not change the release method.
6. Set the documented archive acknowledgement and team ID, then run `tools/release-ios archive <commit>`.
7. Preserve the verified archive and checkpoint. If upload fails, retry from that archive rather than rebuilding.
8. Set the separate upload acknowledgement and run `tools/release-ios upload <commit>`.
9. Run `tools/release-ios status <commit>` until the API returns the exact marketing version and build. Record the Apple build ID and processing state.
10. Assign the approved internal TestFlight group and perform the physical-device checklist. Stop before App Review or public release until separately authorized.

## Game Center invariant

When Game Center is enabled, preflight must use the pinned official plugin commit, exact Godot tag, scene-window compatibility patch and SHA-256, device and simulator frameworks, export capability, provisioning capability, signed entitlement, and live App Store Connect configuration. Authentication and native leaderboard presentation must both be tested on the physical TestFlight build. Guest/offline play must remain available.

## Resume rule

The last successful checkpoint determines the next command. Never restart from source merely because upload, Apple processing, TestFlight assignment, or device verification is incomplete. Never silently increment the build number after Apple receives it; create a separately authorized new candidate.
