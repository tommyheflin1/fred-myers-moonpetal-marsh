# M2 authored Fred rig evidence

## Scope and boundary

This local M2 slice starts from accepted animation-coordinator commit
`658832a2fcdc15a740e37118869312bf899208e6` and replaces only the inline
procedural gameplay-body drawing with a Fred-owned authored vector rig. It
does not alter collision, movement, fixed-tick session rules, objectives,
rewards, lives, progression, camera behavior, audio, save schema, Core, or
online architecture.

The work remains local on `codex/m2-authored-fred-rig`. GitHub reported the
configured repository as public at the start of the slice, so no push or pull
request was made.

## Authored rig contract

`godot/scenes/fred_rig.tscn` contains 34 required inspectable nodes built from
native `Node2D`, `Polygon2D`, `Line2D`, and `Marker2D` primitives:

- root, body, and head joints;
- independent eye whites, pupils, mouth cavity, mouth line, and nostrils;
- independent front legs, hind-leg joints, webbed toe lines, and two ground
  contact markers;
- body belly and state-accent geometry;
- stable tongue and non-color cue anchors.

`FredRig.apply_pose()` consumes an immutable `FredAnimationCoordinator` pose,
applies facing, scale, tilt, limb extension, eye squint, mouth state, depth
palette, and reduced-motion rules, and exposes deterministic snapshots and
hashes. Both pupils carry a directional cue that mirrors with the rig root.
Presentation is one-way: rig state never enters `fred_save` v1 and cannot
mutate the player, collision, session, objective, reward, or progression.

The render bridge draws the authored scene geometry at Fred's existing
gameplay position while preserving the established world/HUD order. Missing
nodes and malformed poses fail with an observable local error and a
high-contrast fallback marker; stale presentation is neutralized rather than
shown as valid gameplay.

## State mapping and accessibility

All 23 coordinator states drive explicit rig output:

`RESET`, `IDLE`, `GROUND_MOVE`, `SURFACE_SWIM`, five leap/landing phases,
`DIVING`, two underwater states, `SURFACING`, three tongue phases, four boost
phases, `DAMAGE`, `INVULNERABLE`, and `FAILURE`.

Priority and interruption remain owned by the coordinator: failure and damage
preempt interactions; tongue preempts traversal; depth transition preempts
leap and boost; leap preempts boost. The rig only presents the chosen state.
Reduced motion removes tilt and secondary overshoot while retaining silhouette,
eye direction, mouth/limb pose, accent, and text cue.

## Automated evidence

- Focused authored-rig suite:
  `Godot_v4.7.1-stable_win64_console.exe --headless --path godot --script res://tests/run_fred_rig.gd`.
- The focused suite validates the 34-node contract, all 23 states, mirrored
  facing, leap/land articulation, depth palette, tongue origin/mouth, boost,
  damage/failure/reset, reduced motion, missing-node and malformed-pose paths,
  main-scene integration, keyboard movement, save-v1 exclusion, and gameplay
  invariance.
- 100 repeated multi-state pose traces are exactly identical. Extra
  snapshot/anchor reads and reduced-motion read-order variation do not alter
  hashes.
- The 10,000-update rig loop completed in 452 ms in the final focused rerun,
  with 4,620 bytes of transient static-memory growth, one temporary object,
  and zero retained resources, nodes, or orphan nodes.
- The final fourteen-suite matrix passed 1,978/1,978 in 10.39 seconds:
  the unchanged thirteen-suite 1,600-check baseline plus 378 focused rig
  checks. Every suite exited zero.
- Readiness inventory expands from 31 to 35 required artifacts while retaining
  the same eight fictional save fixtures, Core `0.5.1`, and Godot `4.7`.

Several existing standalone SceneTree suites, including the untouched
baseline, report ObjectDB/resource instances during immediate process
shutdown. The rig suite reports the same two-instance/one-resource diagnostic
class already documented by the animation report; its measured update loop
retains zero resources, nodes, and orphans. No parser warning, script warning,
or runtime error occurred during import, gameplay, or rendered capture.

## Rendered and desktop evidence

Committed captures:

- `godot/docs/evidence/m2-rig-ground-hop.png`
- `godot/docs/evidence/m2-rig-leap-apex.png`
- `godot/docs/evidence/m2-rig-underwater.png`
- `godot/docs/evidence/m2-rig-tongue-anchor.png`
- `godot/docs/evidence/m2-rig-boost.png`
- `godot/docs/evidence/m2-rig-reduced-motion-960x540.png`
- `godot/docs/evidence/m2-rig-damage-640x360.png`

`review_fred_rig_states.gd` cycles all 23 states, alternating facing, and
`review_fred_rig_interactive.gd` provides an isolated local keyboard/pointer
runtime. Computer Use inspected the real Godot 4.7.1 runtime at 1280x720,
960x540 reduced motion, and 640x360. The 1280x720 workflow covered
title/start/countdown, the complete state-cycle loop, keyboard pause/resume,
keyboard tongue, and right-click tongue with visible mouth/anchor output.
Reduced-motion and constrained layouts retained Fred, immediate hazards,
objective, lives, energy, depth/tongue status, and non-color cues without HUD
overlap or clipping. No visible pose flicker or frame-pacing regression was
observed. Continuous held-key traversal and physical controller, touch-device,
and phone acceptance remain explicitly unclaimed; adapter coverage is
synthetic.

## Security, integrity, and deferrals

The slice is offline and uses only fictional isolated `user://` paths. It adds
no credentials, player data, providers, network calls, analytics, purchases,
signing, exports, deployment, or publication. Core remains exact, owner saves
remain byte-identical, and the existing single owner shortcut and protected
review checkouts are not changed.

This branch evidence does not increase M013, M012, or TASK-002 percentages
before the approved denominator decomposition and owner acceptance. Final art
polish, physical-device QA, touch/controller acceptance, publication, and
release remain protected future gates.

Final integrity recheck:

- Core tree: `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary save: 592 bytes,
  SHA-256 `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save: 592 bytes,
  SHA-256 `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Animation source checkout remains clean at `658832a2fcdc15a740e37118869312bf899208e6`.
- Camera/owner-review checkout remains clean at
  `529cf5a0568dd624b846be0fd1c7fa25e468dc04`.
- Exactly one Fred owner shortcut remains and still targets the unchanged
  camera/owner-review launcher.
