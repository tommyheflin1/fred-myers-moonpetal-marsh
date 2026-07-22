# Milestone M1: playable greybox foundation

Status: complete and ready for review in draft PR #2; no merge or production deployment occurred.

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

The Godot debug build was launched on Windows and visibly checked at 1280x720. Confirmed: title presentation, restored completed-save state, mouse start action, greybox readability, objective/HUD, keyboard dive, keyboard surface, mouse pause, and mouse resume. The deterministic suite covers movement, checkpoint restore, boost, predator damage, safe-location behavior, failure/retry, save recovery, and completion. A keyboard-event issue discovered during the original desktop pass was fixed and the 30-test suite rerun successfully.

Committed captures:

- `godot/docs/evidence/m1-title.png`
- `godot/docs/evidence/m1-lily-leap-greybox.png`
- `godot/docs/evidence/m1-underwater.png`
- `godot/docs/evidence/m1-pause.png`

## Limitations and deferred work

- No export preset or distributable build artifact is produced in M1.
- Branch CI run `29889964435` passed against implementation commit `d7dbf0dcea1769bedd5327f3e18a6f906d6bace8`; exact-current evidence run `29890023421` passed against `38dad1d146f6308ba94049c46078770d1241ef83`.
- Draft PR: `https://github.com/tommyheflin1/fred-myers-moonpetal-marsh/pull/2`, targeting the still-open discovery branch so the M1 review diff remains focused.
- Touch/controller/web adapters have extension points but no final controls or art.
- Final 3D assets, animation, water, audio, cloud sync, monetization, remaining levels, signing, store work, and production release remain out of scope.

## Completion status

- M1 milestone: **100%** of its evidence-gated scope.
- Total Godot migration planning estimate: **20%** (`M0 8% + M1 12%`). This is not a release-readiness percentage.
- Build artifact status: local debug runtime only; no export preset, signed artifact, upload, submission, or deployment was created.
- Working branch remains independently reviewable and unmerged.

## Recommended M2 prompt

`Approved. After Fred Myers M1 draft PR #2 is reviewed and merged through the normal protected-history workflow, begin Milestone M2 on a new branch. Implement the authored frog traversal foundation—jump, land, swim, dive, surface, tongue, boost, camera, desktop input, and adapter-ready touch/controller input—while preserving fred_save version 1, deterministic fixed-tick behavior, Core 0.5.1 compatibility, offline play, regression coverage, and the existing Lily Leap objective/checkpoint identifiers. Do not begin final environment art, remaining campaign levels, production cloud services, signing, store work, or deployment.`
