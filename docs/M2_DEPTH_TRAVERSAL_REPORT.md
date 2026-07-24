# M2 swim and depth traversal evidence

Date: 2026-07-23 MDT

## Implemented slice

Fred now uses a transient fixed-tick depth controller with four explicit states:
surface, diving, underwater and surfacing. Q and E, plus the existing
device-independent `DIVE` and `SURFACE` actions, start authored 0.8-second
transitions instead of changing modes instantly.

Open water accepts a dive. Starting shore, lily pads, the safe island and exit
reject dive entry with a `[DIVE BLOCKED]` explanation. Repeated input is locked
during transition. Pause freezes the transition clock. Underwater steering is
78% of surface speed, while underwater boost uses 72% of the surface boost
speed and consumes the existing energy resource.

Leap has precedence while airborne; depth has precedence underwater. Predator
contact, failure and retry cancel transition state and restore the canonical
safe surface. Completion, checkpoints, bugs, tongue behavior, boost ownership,
health and hazard cooldown rules remain unchanged.

## Presentation and accessibility

The water, Fred and bubbles blend continuously with bounded depth. The HUD
always presents a non-color state and percentage such as `[DIVING] DEPTH 50%`.
A camera response is capped at eight pixels. Reduced motion disables that
camera movement and animated bubble travel while retaining the state, depth,
color and outlined-bubble cues.

## Persistence and architecture

Depth position, timers and transition state are transient and absent from
`fred_save` schema v1. During a transition, saving records the last stable
canonical surface/underwater mode. After transition completion, the existing
`player_state.mode` field records the canonical mode. Reload never resumes
mid-transition.

Mobile Game Core 0.5.1, stable objective/checkpoint IDs, offline play, identity
boundaries and shared backend contracts remain unchanged. No network, provider,
credential, PII, export, signing, deployment or release work is included.

## Automated evidence

- `run_depth_traversal.gd`: state bounds, intermediate depth, entry rules,
  repeated-input rejection, pause, distinct steering, boost, leap precedence,
  adapter intent, stable save/reload, predator/failure/retry, reduced motion,
  20 repeated scenarios and 10,000 complete transition cycles.
- `run_keyboard_regression.gd`: parsed Q/E events start transitions and complete
  in the expected canonical modes.
- All prior base, save, feedback, visual, progression and leap suites remain
  required.

Synthetic controller/touch actions prove the adapter contract only. They do not
constitute physical controller, phone or tablet acceptance.

## Owner controls and review

- Move/steer: WASD or arrows
- Leap: Space or pond click
- Dive: Q in open water
- Surface: E while fully underwater
- Boost: Shift
- Pause/resume: P or Escape

Review dive-entry clarity, transition pacing, underwater steering, surface
recovery, camera comfort, hazards at depth and readability in both tested
window sizes.
