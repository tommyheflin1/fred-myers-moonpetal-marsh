# M2 deterministic boost locomotion evidence

Date: 2026-07-24 MDT

## Implemented slice

Fred now has an explicit fixed-tick boost state model instead of a single
held-key speed override. The Fred-owned `FredBoostLocomotion` component defines:

- start threshold: 15 energy
- activation cost: 1 energy
- burst: 12 fixed ticks at 1.85x surface speed
- sustain: 1.55x surface speed
- drain: 1 energy every 3 active fixed ticks
- release recovery delay: 30 fixed ticks
- exhausted recovery delay: 54 fixed ticks
- recovery: 1 energy every 2 fixed ticks
- exhaustion latch: the player must release boost before another burst
- energy bounds: 0 through 100

Burst and sustain have smaller, bounded leap multipliers of 1.28x and 1.16x.
Underwater boost retains the existing 0.72 depth scale, so it is faster than
underwater steering but shorter than a surface surge. Reduced motion removes
the boost camera offset while retaining the same text, energy bar, threshold
marker and line-based speed cues.

## Precedence and persistence

Boost can start during directional surface or underwater movement and during
an authored leap. Landing recovery, dive, surfacing and an active tongue shot
cancel or block boost. Countdown and pause freeze the component without
draining or recovering energy. Predator contact cancels an active boost;
failure, retry, home and level transition clear transient state. Retry and a
new level restore the canonical 100 energy for their new session.

Only the existing validated integer `boost_state.energy` field is durable.
Burst, sustain, recovery timers, drain counters and the release latch remain
transient and are absent from `fred_save` schema version 1. Malformed energy is
still clamped to 0 through 100 by `AdventureSession.restore`.

## Automated evidence

Godot `4.7.1.stable.official.a13da4feb` imported and parsed the complete project.
The local eleven-suite matrix passed **1,178 checks with 0 failures**:

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
- focused boost locomotion: 167

The focused boost suite contains 100 repeated 240-tick traces with identical
state transcripts. Its 10,000-cycle resource loop completed in 568-685 ms with
zero measured static-memory growth. The save stress suite completed 250 cycles
in 432-605 ms with a 513-byte fictional primary save and 577 bytes of measured
static-memory growth.

The suite covers threshold boundaries, burst/sustain arithmetic, press/hold/
release, repeated taps, exhaustion and delayed recovery, clamping, countdown,
pause, failure/retry/home/next-level resets, stable save/reload, malformed
energy, surface/underwater/leap/landing/depth/tongue precedence, synthetic
controller and touch intents, and simultaneous-adapter deduplication.

## Visible Windows evidence

Computer Use inspected the exact working candidate in Godot 4.7.1:

- 1280x720 normal presentation: title, keyboard start, five-second countdown,
  keyboard pause/resume, mouse start, gameplay HUD and energy threshold marker
- 1280x720 isolated state review: burst, sustain, recovery, leap plus boost,
  underwater boost and paused/frozen energy
- 960x540 reduced motion: title, keyboard start, countdown, gameplay framing,
  `[REDUCED MOTION]` cue and readable energy/state treatment

Visible control review used isolated fictional AppData and Godot's dummy audio
driver to keep control and rendering evidence independent from the machine's
audio device. Existing music behavior remains covered by the menu/audio suite.
Keyboard Enter and P and the title pointer path were sent through real Windows
input. Shift boost is covered by the parsed physical-key regression and the
focused game suite; controller and touch remain synthetic adapter evidence, not
physical hardware acceptance.

Committed render evidence:

- `godot/docs/evidence/m2-boost-burst.png`
- `godot/docs/evidence/m2-boost-sustain.png`
- `godot/docs/evidence/m2-boost-exhausted.png`
- `godot/docs/evidence/m2-boost-recovery.png`
- `godot/docs/evidence/m2-boost-leap.png`
- `godot/docs/evidence/m2-boost-underwater.png`
- `godot/docs/evidence/m2-boost-reduced-motion-960x540.png`

## Integrity and boundaries

- `fred_save` remains schema version 1.
- Mobile Game Core remains exact 0.5.1 at tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary and backup saves remained outside all review runtimes and are
  verified byte-identical before and after validation.
- Exactly one Fred desktop shortcut remains and targets this worktree launcher.
- All visible and automated scenarios are offline and use fictional data.
- No network call, provider activation, credential, PII, analytics, cloud
  write, export, signing, deployment, publication or release was added.
- Standalone audio-enabled scene suites retain their documented shutdown-only
  ObjectDB/resource cleanup diagnostics; no new gameplay script warning remains.

M2/M013 portfolio scoring remains unchanged pending the approved denominator
decomposition and owner acceptance. This is verified branch engineering
evidence, not mainline, physical-controller/device, release or production
credit.
