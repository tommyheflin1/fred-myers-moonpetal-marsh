# Fred Myers Build 12 accepted identity and publication defects

Recorded: 2026-09-14  
Status: OPEN / OWNER ACCEPTED / REPAIR DEFERRED

This app-owned record applies the shared harness decision in
`mobile-game-template/docs/FRED_ACCEPTED_IDENTITY_PUBLICATION_DEFECTS_2026-09-14.md`
to Fred Myers: Moonpetal Marsh version 1.1, build 12, source commit
`4ec15ae26a38a5dafd91409c6fd08a96c21df90b`.

Apple processed build ID: `208e1f81-0ba8-4e58-adb2-5af068b290ba`.  
App Review submission ID: `1e210371-bfe9-4f2b-a0a9-893896253334`.

## Owner-observed failures

- `FRED-GC-001`: The standard in-game leaderboard did not display the
  player's Game Center name.
- `FRED-EGG-001`: Golden Egg publication did not obtain/apply the player's
  Game Center name.
- `FRED-EGG-002`: Anonymous Golden Egg publication could not be completed.

The owner reported that Golden Egg discovery and the hidden room worked. The
installed version/build was not stated with the report, so these defects are not
recorded as independently reproduced on Build 12. Discovery success is not
publication success, and the root causes remain unknown.

## Release decision

After Build 12 was submitted, the owner explicitly accepted these three open
defects for the current Fred rollout and deferred repair until the all-app
completion milestone. This is a narrow release-risk acceptance, not passing test
evidence and not a waiver of any other privacy, security, identity, signing, or
release gate.

The false device-evidence fields in `store/game_center.json` and
`store/app_store_package.json` remain false. The already submitted Build 12
binary and its exact source commit must not be rewritten. This record does not
block TurboRack or Snake Reactor and does not apply to either app.

## Required deferred repair

After the all-app milestone, diagnose native authentication/name delivery and
normal leaderboard display independently from the discovery-only website flow.
Then verify Public and Anonymous publication on a physical device against the
deployed backend, recording the exact installed build and backend version.

Preserve discovery-only networking, explicit publication consent, Anonymous and
Don't Post semantics, secure Game Center identity verification, and normal
gameplay independence from website availability. Do not add typed-name or
insecure publication fallbacks.
