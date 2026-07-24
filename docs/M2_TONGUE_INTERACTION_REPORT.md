# M2 aimed tongue interaction evidence

Date: 2026-07-23 MDT

## Implemented slice

Fred now eats bugs and the milestone fairy with a deterministic aimed tongue
instead of collecting them by body contact. F uses Fred's last movement aim,
and right-click aims at the pointer. Controller and touch adapters continue to
emit the existing device-neutral `INTERACT` intent.

The targeting contract is:

- maximum range: 190 gameplay pixels
- aim cone: 42 degrees to either side
- stable selection: greatest aim alignment, then shortest distance, then
  lexicographically smallest stable target ID
- extension: 0.16 seconds
- recovery: 0.39 seconds
- total cooldown: 0.55 seconds

An accepted shot always completes its cooldown, whether it hits, misses, or
finds an ineligible target. Bugs are eligible only while uncollected. The fairy
is present only on levels 10, 20, and so on through 100; it is eligible only
below three lives and still restores exactly one life capped at three.

## State and precedence

Tongue state is transient and fixed-tick. Pause freezes it. Countdown, pause,
airborne leap, dive transition, surfacing transition, and underwater play block
a new surface-prey shot. Failure, retry, home, start, and level transition clear
target/cooldown state. A stale or already-consumed target cannot advance the
objective or grant a second life.

The HUD includes `TONGUE READY`, `TONGUE HIT`, `TONGUE MISS`, and
`TONGUE BLOCKED`. A small F reticle shows keyboard aim. Hit, miss, recovery, and
life-cap states use text, shape, and line treatment rather than color alone.
Reduced-motion presentation keeps the full target line and text cue without
animated extension.

## Automated evidence

Godot `4.7.1.stable.official.a13da4feb` imported the project without a script
parse error. The full local matrix passed **1,011 checks with 0 failures**:

- base/session/save/gameplay: 32
- physical-key event regression: 23
- save stress/security: 31
- save/recovery feedback: 28
- visual clarity/reduced motion: 30
- 100-level progression/identity foundation: 645
- leap traversal: 52
- depth traversal: 64
- menu/music/lives/fairy/countdown/leaderboard: 30
- focused aimed tongue interaction: 76

The focused suite passed 76/76 in five consecutive runs, for 380/380 repeated
checks. Each run includes 20 deterministic candidate-order scenarios. A
10,000-shot selection/cooldown loop completed in 70-103 ms with zero measured
static-memory growth. The save stress suite completed 250 cycles in 704 ms with
a 513-byte fictional primary file and 577 bytes of measured static-memory
growth.

The focused tests cover range and cone boundaries, deterministic ties,
reordered candidates, cooldown spam, misses, malformed/despawned/stale targets,
simultaneous candidates, pause, failure/retry, level transition, leap/depth
precedence, every-tenth-level fairy eligibility, the three-life cap, stable
save/reload, reduced motion, keyboard F, pointer aim, and separate synthetic
controller/touch action events. Synthetic adapter evidence is not physical
controller, phone, or tablet acceptance.

The workflow now invokes all four established M2 suites in addition to the M1
regressions. Readiness validation passed 25 artifacts, eight fixtures, Core
0.5.1, and Godot 4.7.

## Visible Windows evidence

Computer Use inspected the exact working candidate in real Godot windows:

- 1280x720 normal motion: nearby bug pointer hit, level-ten fairy consumption
  from two to three lives, blocked fairy at the three-life cap, full failure
  presentation, and `Try Again` returning to Level 1
- 960x540 reduced motion: upgraded title, keyboard start, five-second
  countdown, gameplay HUD, keyboard pause/resume, and pointer miss

Normal-runtime keyboard routing was visibly proven with Enter and P. F is
covered by parsed real-key events in the keyboard suite; personal physical
keyboard feel remains an owner UAT gate. Pointer hit/miss/fairy/cap paths were
visibly exercised. No physical controller or mobile device claim is made.

Committed render evidence:

- `godot/docs/evidence/m2-tongue-bug-hit.png`
- `godot/docs/evidence/m2-tongue-miss.png`
- `godot/docs/evidence/m2-tongue-fairy-life.png`
- `godot/docs/evidence/m2-tongue-fairy-cap.png`
- `godot/docs/evidence/m2-tongue-failure.png`
- `godot/docs/evidence/m2-tongue-retry.png`

## Integrity and boundaries

- `fred_save` remains schema version 1 with no tongue, aim, target, cooldown, or
  animation fields.
- Mobile Game Core remains exact 0.5.1 at tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary and backup files remained byte-identical during validation.
- All visible scenario runs used isolated fictional AppData.
- The implementation adds no network call, provider activation, credential,
  secret, PII, analytics, cloud write, export, signing, deployment, or release.
- Standalone suites retain the baseline Godot shutdown-only ObjectDB/resource
  cleanup diagnostics from constructing the audio-enabled main scene; import
  and gameplay emitted no new script error or warning.

M2/M013 portfolio scoring remains unchanged pending the approved denominator
decomposition and owner acceptance. This evidence advances the M2 engineering
foundation but is not mainline, physical-device, release, or production credit.
