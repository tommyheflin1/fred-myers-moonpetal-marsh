# M2 locomotion animation coordinator evidence

Date: 2026-07-24 MDT

Branch: `codex/m2-locomotion-animation-coordinator`

Starting commit: `529cf5a0568dd624b846be0fd1c7fa25e468dc04`

## Presentation contract

`FredAnimationCoordinator` is a Fred-owned, presentation-only fixed-tick
component. It consumes a deep copy of immutable traversal/session snapshots and
emits pose, silhouette, direction, mouth, eye, leg, accent and text-cue data for
the existing procedural frog. It never owns or changes collision, world
position, objectives, rewards, lives, energy, checkpoints, save data or Core
state.

The explicit transition priority is:

1. latched failure
2. bounded damage, then invulnerability
3. tongue wind-up, extension and recovery
4. diving and surfacing transitions
5. leap anticipation, ascent, apex, descent and landing
6. boost burst, sustain, exhaustion and recovery
7. underwater swim/idle, surface swim and ground move/idle

Failure remains latched until retry, home or level reset. Damage preempts for
exactly 18 fixed ticks, then yields to the existing invulnerability window.
Pause and the five-second countdown perform no coordinator tick. Retry, home,
checkpoint start and level transition reset all transient presentation state.
The renderer reads coordinator output without feeding anything back into
gameplay.

Normal motion uses small, bounded squash/stretch, leg extension, facing, tilt
and secondary bob. Reduced motion preserves the same state, text cue, accent,
mouth/eye expression and recognizable silhouette while removing periodic bob
and directional overshoot. No flash or screen shake was introduced.

## Automated evidence

Godot `4.7.1.stable.official.a13da4feb` imported and parsed the project. The
final complete thirteen-suite matrix passed **1,600 checks with 0 failures**
in 8,340 ms:

- existing twelve-suite baseline: 1,362
- focused animation coordinator: 238

The focused suite covers all 23 presentation states, phase boundaries,
priority/interruption, facing reversal, simultaneous traversal snapshots,
damage/failure preemption, exact damage duration, pause/countdown freeze,
retry/home/next-level reset, reduced-motion equivalence, immutable input
snapshots, save exclusion, gameplay invariance, real keyboard integration and
synthetic controller/touch intent deduplication.

One hundred repeated 420-tick multi-traversal traces produced identical
coordinator and gameplay-facing transcripts. Extra render-order pose reads did
not change either normal or reduced-motion hashes. The 10,000-transition loop
completed in 134 ms on the final run (123-148 ms observed), with 2,480 bytes
of observed static-memory movement,
one temporary RefCounted object delta, and zero retained resources, nodes or
orphan nodes.

Godot's established standalone-test shutdown diagnostics remain: some suites
report ObjectDB/resource instances during immediate SceneTree shutdown. The
untouched camera suite reproduces a larger instance/resource count. The
animation implementation introduced no runtime script warning or parser error.

## Render evidence

The exact local candidate generated these committed Windows/OpenGL captures:

- `godot/docs/evidence/m2-animation-ground-hop.png`
- `godot/docs/evidence/m2-animation-leap-apex.png`
- `godot/docs/evidence/m2-animation-underwater-swim.png`
- `godot/docs/evidence/m2-animation-tongue-snap.png`
- `godot/docs/evidence/m2-animation-boost-burst.png`
- `godot/docs/evidence/m2-animation-reduced-motion-960x540.png`
- `godot/docs/evidence/m2-animation-damage-640x360.png`

They show direction, leap extension, underwater color/silhouette, open-mouth
tongue action, boost stretch, reduced-motion information parity and a
non-color `OUCH` damage cue. The animation cue is spaced above the existing
tongue/boost cue so the two meanings do not overlap.

Computer Use then inspected the exact isolated candidate:

- 1280x720 normal motion: the full 20-state loop visibly covered ground
  movement/reversal, leap phases/landing, dive/deep swim/surfacing, tongue,
  boost phases, damage, failure and reset without a stuck pose or flicker.
- 1280x720 interactive: real Windows `Enter` reached the five-second
  countdown; pointer start, pause and top-toggle resume all produced the
  expected visible state.
- 960x540 reduced motion: semantic pose, text, accent, direction, objective,
  hazards, lives and energy remained readable without periodic bob or tilt.
- 640x360 constrained: Fred, immediate hazard/landing context, route,
  objective, lives, energy and status remained visible without HUD overlap.

Computer Use emits a complete key press rather than a held key. Continuous
WASD/reversal, Space leap and Shift boost are therefore supported by the
parsed physical-key event suite and deterministic visible state loop, not
claimed as fresh held-key or owner physical-hardware acceptance. Controller
and touch remain synthetic intent evidence only.

An early interactive-review helper nulled active audio streams and a repeated
coordinate retry left that isolated helper nonresponsive. The helper was
corrected to keep its existing streams resident at muted volume and use a
short status message. The final bounded title/countdown/pause/resume run
completed, all uniquely titled review windows were closed, and the existing
owner Fred and Snake windows were not touched.

## Integrity and protected boundaries

- `fred_save` remains schema version 1 and has no animation fields.
- Mobile Game Core remains exact 0.5.1 at tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary save baseline: 592 bytes, SHA-256
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save baseline: 592 bytes, SHA-256
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- The camera-review worktree and single Fred owner shortcut remain outside this
  isolated worktree and are not changed by the slice.
- Tests and captures use fictional, isolated local storage and remain offline.
- No account, credential, PII, provider, network, telemetry, export, signing,
  deployment, publication or release path was added.

The configured GitHub repository is reported public. This local branch remains
unpushed, with no PR. M013 and TASK-002 percentages remain unchanged pending
approved denominator decomposition and owner acceptance.
