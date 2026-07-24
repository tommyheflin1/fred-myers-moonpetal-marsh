# M2 deterministic camera follow evidence

Date: 2026-07-24 MDT

Branch: `codex/m2-progression-identity-foundation`

Starting commit: `2fcc1f9ac4d0b3fcbba0efe29700edb2b8a89e49`

## Implemented camera contract

Fred now has a Fred-owned `FredCameraFollow` fixed-tick model. It produces a
transient world-render offset and never mutates the deterministic session.
The contract is:

- logical reference viewport: 1280x720
- camera dead zone: x 300-980 and y 180-540
- input dead zone: 0.18
- maximum render offset: 26 logical pixels per axis
- maximum catch-up: 1.75 logical pixels per 60 Hz fixed tick
- horizontal anticipation: 18 pixels in the movement direction
- vertical movement anticipation: 4 pixels
- boost look-ahead: up to 6 additional horizontal pixels and 4 vertical pixels
- leap bias: up to 10 pixels at the authored arc apex
- underwater bias: up to 8 pixels
- tongue target context: up to 6 horizontal and 4 vertical pixels
- safe frame: x 68-1212 and y 110-654

The response scales to 75% at 960x540 and to a bounded minimum of 50% at
640x360. Normal motion interpolates toward its target at the fixed-tick
catch-up limit. Reduced motion snaps both target and render offset to zero,
retaining objective, depth, boost, tongue, life and status text as equivalent
non-motion information.

The camera freezes during the five-second countdown and pause. Damage,
failure/retry, home, checkpoint start and level transition reset it to zero.
Ground movement and reversal, leap/ascent/landing, surface swimming,
dive/underwater/surfacing, boost burst/sustain/exhaustion, and tongue
extension/recovery all feed the same deterministic model. HUD rendering is
outside the world transform, so camera response cannot move or obscure the
objective, lives, energy, pause control or status panel.

## Automated evidence

Godot `4.7.1.stable.official.a13da4feb` imported and parsed the complete
project. Readiness passed with 28 required artifacts, eight exact save
fixtures, Core 0.5.1 and the Godot 4.7 declaration.

The final local twelve-suite matrix passed **1,362 checks with 0 failures** in
6,362 ms:

- base/session/save/gameplay: 32
- physical-key event regression: 23
- save stress/security: 31
- save/recovery feedback: 28
- visual clarity/reduced motion: 30
- 100-level progression/identity foundation: 645
- leap traversal: 52
- depth traversal: 64
- menu/music/lives/fairy/countdown/leaderboard: 30
- aimed tongue interaction: 76
- boost locomotion: 167
- focused camera follow: 184

The camera suite includes 100 repeated 360-tick traversal traces with
byte-identical state transcripts. It covers dead-zone and world-bound
boundaries, anticipation sign and magnitude, rapid reversal, catch-up,
1280x720/960x540/640x360 response, pause/countdown freeze, reduced motion,
damage/retry/home/next-level resets, leap apex/landing, depth, boost, tongue,
simultaneous input-adapter deduplication, schema-v1 exclusion and progression
invariance. The 10,000-cycle camera loop completed in 28-36 ms with 956 bytes
of measured static-memory movement. The existing 250-cycle save stress gate
remained 31/31 with a 513-byte fictional primary save.

## Visible Windows evidence

Computer Use inspected the exact local candidate with pre-installed Godot
4.7.1 and isolated fictional AppData:

- 1280x720 real Windows input: title, Enter start, five-second countdown,
  P pause/resume, Q invalid-dive feedback, F tongue feedback, and pointer
  pause/resume
- 1280x720 deterministic state review: right anticipation, reversal, leap
  apex/landing context, underwater bias, boost look-ahead, world-edge clamp
  and tongue target context
- 960x540 reduced motion: zero offset with explicit reduced-motion, objective,
  traversal, life, energy and status cues
- 640x360 constrained presentation: Fred, the active route, hazards, objective,
  lives, energy and status remained visible without HUD overlap

The Computer Use API sends a complete key press rather than a held key.
Therefore Enter, P, Q and F are direct visible Windows evidence; continuous
movement, leap and boost are additionally covered by parsed physical-key event
tests and the deterministic state review. Controller and touch are synthetic
device-neutral intent evidence only. No physical controller, touch device,
mobile device or owner personal acceptance is claimed.

Committed render evidence:

- `godot/docs/evidence/m2-camera-right-anticipation.png`
- `godot/docs/evidence/m2-camera-reversal.png`
- `godot/docs/evidence/m2-camera-leap-apex.png`
- `godot/docs/evidence/m2-camera-underwater.png`
- `godot/docs/evidence/m2-camera-world-clamp.png`
- `godot/docs/evidence/m2-camera-reduced-motion-960x540.png`
- `godot/docs/evidence/m2-camera-constrained-640x360.png`

## Integrity and boundaries

- `fred_save` remains schema version 1 and contains no camera fields.
- Mobile Game Core remains exact 0.5.1 at tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary save: 592 bytes, SHA-256
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save: 592 bytes, SHA-256
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Exactly one Fred owner shortcut remains; it was not changed by this slice.
- Isolated visual review directories were removed after validation.
- All scenarios are offline and use fictional local data.
- No network, account, provider, credential, PII, telemetry, cloud write,
  export, signing, deployment, publication or release path was added.

Godot's established standalone-test shutdown diagnostics remain: ObjectDB
instances/resources can be reported as still in use after the test SceneTree
quits. The camera component added no runtime script warning. An initial
isolated visual-review harness exposed a typed-array defect in the harness;
that defect was fixed and the complete corrected visible cycle then ran
without script errors.

The scheduler reported the configured GitHub repository as public before this
slice. This branch therefore remains local and unpushed. M2/M013 scoring
remains unchanged pending denominator approval and owner acceptance; this is
verified branch engineering evidence, not mainline, physical-device, release
or production credit.
