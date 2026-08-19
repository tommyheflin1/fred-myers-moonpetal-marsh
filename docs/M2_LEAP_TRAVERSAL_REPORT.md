# M2 leap-and-landing traversal evidence

Date: 2026-07-23 MDT

## Implemented slice

Fred has a transient fixed-tick traversal model with grounded, airborne and
landing states. The large touch-first `LEAP` action launches a deterministic
0.72-second arc in Fred's current movement or facing direction. The same
device-independent intent remains available to synthetic platform adapters.

Airborne movement uses a fixed distance and readable height curve. Repeated
leap input is rejected until landing completes. Pause freezes the traversal
clock. A restrained camera response follows the arc and is disabled by reduced
motion while the explicit `[AIRBORNE]` and `[LANDING]` cues remain.

Moving lily pads, the starting shore, safe island and exit remain recognizable
perches, but a leap does not require one. Every completed arc lands exactly at
its deterministic endpoint and continues the same round. Open-water landing
never teleports Fred, removes a life, mutates a checkpoint, or starts a ready
countdown. While airborne Fred passes above surface predators, making `LEAP`
a practical evasive move. Once grounded, predator contact is dangerous again;
whirlpools remain hazardous throughout the arc.

## Persistence and architecture

Leap state is deliberately transient. `fred_save` remains schema version 1 and
contains no airborne, velocity, timer or camera fields. A save/reload during the
presentation restores the latest stable session/checkpoint only. Core 0.5.1,
objective IDs, checkpoint IDs, offline play, identity boundaries and shared
backend contracts are unchanged.

The implementation uses the existing GL Compatibility renderer and fixed-tick
gameplay path. It adds no network calls, provider activation, credentials,
personal data, deployment, export or signing.

## Automated evidence

- `run_leap_traversal.gd`: 65/65 checks for deterministic arc/distance,
  repeated-input rejection, 20 repeated scenarios, perch/open-water landing,
  a full fixed-tick predator crossing, grounded danger, pause/resume,
  failure/retry, stable save/reload, reduced motion, screen-touch input,
  synthetic adapter intent and a 10,000-iteration timing check.
- Complete regression matrix: 22 suites, 4,116 passed, 0 failed.
- Existing movement, boost, dive/surface, predator, save/recovery, feedback,
  visual and 100-level foundation suites remain required.

Synthetic controller/touch action evidence is not physical controller, phone or
tablet acceptance. Personal owner control feel and all physical-device testing
remain protected human gates.

## Owner controls and review

- Move/aim: touch and drag in the marsh
- Leap: use the large bottom-row `LEAP` action
- Boost, dive/surface and munch: use the named bottom-row actions
- Pause/resume and exit: use the isolated top-row actions

Review launch readability, apex visibility, landing continuity, camera comfort,
pause while airborne, surface-predator clearance and coexistence with
grounded predator/whirlpool danger.

## App Build 1 safe-leap correction

Owner feedback on 2026-08-18 identified that a missed leap incorrectly shared
the predator/whirlpool life-loss path. The App Build 1 revision 9 correction
separates those outcomes: a missed perch now emits a non-color landing splash,
returns Fred to the current safe recovery point, preserves every life, and
shows a two-second ready countdown. Predator and whirlpool damage is unchanged.

The focused suite passes 56/56, including the one-life boundary. The complete
21-suite matrix passes 3,956/3,956. A real 1280x720 Windows touch-path review
confirmed that `LIVES 3` remains unchanged after a missed leap and that the
full `[SAFE SPLASH] Fred is safe. No life lost!` status fits the player panel.
This runtime used isolated fictional AppData; owner saves were not opened.

## App Build 1 revision 12 continuous-leap correction

Owner review on 2026-08-18 clarified that `LEAP` must be a normal move Fred can
use to jump over a predator, never a round-restart action. Revision 12 removes
the missed-perch recovery route entirely. Open-water and perch landings both
continue from the exact endpoint with the same lives, checkpoint and round;
no respawn or countdown is created. Airborne predator overlap is ignored while
grounded contact and whirlpools retain their established damage rules.

The focused suite passes 65/65 and the complete 22-suite matrix passes
4,116/4,116. A real 1280x720 Windows review used the same visible touch `LEAP`
button as the phone layout, crossed a surface bass, and froze on the landing
with the explicit status `[LEAP VERIFIED] Same round, 3 lives, no restart
countdown.` The review used isolated fictional AppData and did not open owner
saves.
