# M2 leap-and-landing traversal evidence

Date: 2026-07-23 MDT

## Implemented slice

Fred now has a transient fixed-tick traversal model with grounded, airborne and
landing states. Space or the existing `LEAP` action launches a deterministic
0.72-second arc. A pond click launches toward the pointer. The same
device-independent action accepts synthetic controller/touch adapter events.

Airborne movement uses a fixed distance and readable height curve. Repeated
leap input is rejected until landing completes. Pause freezes the traversal
clock. A restrained camera response follows the arc and is disabled by reduced
motion while the explicit `[AIRBORNE]` and `[LANDING]` cues remain.

Moving lily pads, the starting shore, safe island and exit are valid landing
surfaces. Open-water landings use the existing fair recovery rule: one heart,
safe return and the existing cooldown. Predator contact cancels traversal;
failure and retry return to grounded play.

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

- `run_leap_traversal.gd`: deterministic arc/distance, repeated-input
  rejection, 20 repeated scenarios, valid/invalid landing, pause/resume,
  failure/retry, hazard cooldown, stable save/reload, reduced motion,
  mouse launch, synthetic adapter intent and a 10,000-iteration timing check.
- `run_keyboard_regression.gd`: a real parsed Space key event launches Fred.
- Existing movement, boost, dive/surface, predator, save/recovery, feedback,
  visual and 100-level foundation suites remain required.

Synthetic controller/touch action evidence is not physical controller, phone or
tablet acceptance. Personal owner control feel and all physical-device testing
remain protected human gates.

## Owner controls and review

- Move/aim: WASD or arrows
- Leap: Space
- Pointer leap: click a landing direction in the pond
- Boost: Shift
- Dive/surface: Q/E
- Pause/resume: P or Escape

Review launch readability, apex visibility, landing fairness, invalid-landing
recovery, camera comfort, pause while airborne and coexistence with predators.
