# Fred native leaderboard and Home-return defects

Recorded: 2026-09-20  
Status: CODE REPAIR IMPLEMENTED / LOCAL REGRESSION PASSED / DEVICE RETEST REQUIRED

## Owner report

After installing the Fred update, the owner reported that the standard in-game
leaderboard still has a problem and that selecting Home after viewing the
leaderboard does not return the player to the game's Home screen.

- `FRED-GC-001` remains open: the standard native leaderboard behavior is not
  accepted as working correctly. Its previously reported missing Game Center
  player-name display remains part of the repair scope.
- `FRED-NAV-001` is new: after opening/viewing the leaderboard, the Home control
  does not return to Fred's Home screen.

The owner described this as occurring after the update, but the exact installed
build was not captured with this report. Do not label a specific binary as
independently reproduced until its installed version/build is recorded during the
repair test.

## Scope boundary

These are native Game Center leaderboard and game-navigation defects. They have
nothing to do with the company website, Golden Egg discovery, Golden Egg consent,
or Golden Egg publication. Do not diagnose or repair them through website code,
website availability, or Golden Egg transport.

Use the proven Snake Reactor and TurboRack native leaderboard lifecycle/navigation
behavior as a technical reference for the shared adapter and callback flow. Preserve
Fred's own game design, visuals, menu presentation, saves, Game Center identifiers,
Core pin and Apple artifacts. Harness authority is procedural/nonvisual; it does not
authorize copying another game's presentation or changing Fred's gameplay.

## Deferred repair acceptance

On the next authorized Fred repair candidate:

1. Reproduce the native leaderboard issue on a named physical-device build.
2. Verify the authenticated Game Center player name and expected leaderboard records.
3. Open and close the native leaderboard repeatedly, including cancellation/error paths.
4. Select Home after leaderboard dismissal and verify Fred returns to the actual Home
   screen with gameplay input, pause state and overlays reset correctly.
5. Background/foreground during the native overlay, then verify Home again.
6. Run the same path with the website unavailable and confirm identical behavior and
   zero Golden Egg website requests.

The issue stays open until the repaired exact build passes those checks. Local mocks,
desktop tests, Snake/Turbo success, or a successful Apple upload do not close it.

## Implemented next-build repair

Fred now follows the official Game Center plug-in callback instead of guessing native
leaderboard dismissal from application pause/resume timing. A leaderboard request made
by a signed-out player resumes automatically after successful Game Center authentication.
The native `show_game_center` dismissal event releases the presentation guard, clears any
touch state consumed by the Apple overlay, restores Fred's menu status, and leaves the
in-game Home control able to return to the actual title screen. The authenticated
provider-reported display name is shown in Fred's leaderboard status and is used only as
the device-local score label; this path makes no Golden Egg website request.

Local evidence on 2026-09-20:

- `tests/run_game_center_adapter.gd`: 55 passed, 0 failed.
- `tests/run_menu_lives_leaderboard.gd`: 38 passed, 0 failed.
- Full Godot sweep: every non-website test passed. The pre-existing Build 11/Build 12
  Golden Egg website build-identity mismatch remains intentionally outside this repair.
- Python suite: 38 passed; the only failure is the expected source-bound release-evidence
  invalidation caused by this new repair. Evidence must be regenerated for a newly named
  candidate, never relabeled as Build 12 proof.

This records source and desktop/mock evidence only. `FRED-GC-001` and `FRED-NAV-001`
remain device-open until the repaired exact TestFlight build completes the acceptance
steps above.
