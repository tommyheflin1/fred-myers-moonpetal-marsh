# Milestone M1: playable greybox foundation

Status: local implementation and validation complete; remote publication pending GitHub authentication.

## Baseline

- Starting commit: `520013ac161a098ef97a7a78824693f09ce81a43`
- Branch: `milestone/m1-greybox-foundation`
- Godot: `4.7.1.stable.official.a13da4feb`
- Mobile Game Core: `0.5.1`, 29-file vendored snapshot, unchanged from the approved template
- Core aggregate inventory digest: `f755b76ea85b4c6989e6e90ffd03d35ffea1fb6fb0dbc5b6b66b5a9714d231d5`

## Implemented

Fred-owned deterministic `AdventureSession`, device-independent input intents, save schema v1 serialization/restoration, temporary write plus verified atomic replacement, backup and interrupted-write recovery, sequential checkpoint enforcement, eight fictional fixtures, and a presentable Lily Leap greybox are implemented.

The playable slice includes Fred, lily pads, three bugs, boost energy, a moving predator, a safe location, surface/underwater states, health/failure/retry, midpoint and completion checkpoints, save/resume, pause, objective HUD, title, failure, and completion screens.

## Automated evidence

Command:

`Godot_v4.7.1-stable_win64_console.exe --headless --path godot --script res://tests/run_tests.gd`

Result: **30 passed, 0 failed**. Coverage includes deterministic initialization, fixtures, schema/Core rejection, atomic/backup/interrupted recovery, idempotency, checkpoint monotonicity, objectives, bugs, boost, predator damage, hiding, dive/surface, failure/retry, completion, offline startup, title initialization, desktop mouse start, and level completion.

The Godot 4.7.1 headless editor import also exited successfully. `tools/validate_readiness.py` validates the M1 artifacts, eight JSON fixtures, Core pin, and project entry scene.

## Visible desktop evidence

The Godot debug build was launched on Windows and visibly checked at 1280x720. Confirmed: title presentation, mouse start action, greybox readability, objective/HUD, keyboard dive, keyboard surface, keyboard pause, and pause overlay. A keyboard-event issue discovered during this pass was fixed and the 30-test suite rerun successfully.

Committed captures:

- `godot/docs/evidence/m1-title.png`
- `godot/docs/evidence/m1-lily-leap-greybox.png`
- `godot/docs/evidence/m1-underwater.png`
- `godot/docs/evidence/m1-pause.png`

## Limitations and deferred work

- No export preset or distributable build artifact is produced in M1.
- CI cannot be claimed until the branch is pushed and GitHub Actions completes.
- Draft PR creation is pending restored `gh` authentication.
- Touch/controller/web adapters have extension points but no final controls or art.
- Final 3D assets, animation, water, audio, cloud sync, monetization, remaining levels, signing, store work, and production release remain out of scope.
