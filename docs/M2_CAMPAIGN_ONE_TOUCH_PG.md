# Campaign 1 touch-only, age-five, and PG contract

Updated: 2026-08-18

## Campaign identity

**Campaign 1: The Moonpetal Promise** contains exactly 100 numbered levels in
ten chapters of ten levels. Fred learns the marsh one idea at a time, crosses
the entire adventure and completes the promise after Level 100. The ending
celebrates Fred as the hero in every little frog's dreams and returns to a
fresh Campaign 1 title instead of silently replaying Level 100.

## Progressive difficulty

Every level owns a unique deterministic profile and difficulty step. Continuous
speed, current, movement and geometry values increase a small amount across all
100 levels, including the final twenty. Discrete hazards are introduced slowly:

- Level 1 starts with one readable patrol and no whirlpool;
- Levels 1–8 focus on touch movement, landing, Munch, gentle current, Boost,
  Dive/Surface, moving lily pads and flying bugs;
- the first moving patrol begins at Level 9;
- reversing current begins at Level 14;
- the first whirlpool begins at Level 16;
- predator and whirlpool counts grow by at most one at a time;
- Level 100 is capped at five predators and three whirlpools.

The curve never removes the challenge gained by a previous level, but it also
never removes the child's basic chance to recover. Even Level 100 preserves at
least 1.35 seconds of reaction time, 1.8 seconds of post-hit grace, a 50-pixel
safe area and bounded moving-target speed. Three starting lives, nonfatal
checkpoint recovery and every-tenth-level fairy opportunities remain intact.

## Touch-only player contract

The current player runtime displays touch controls by default. Touch and drag
steers Fred, while Munch, Leap, Boost, Dive/Surface, Pause and Exit use large,
separated controls. The Windows owner mouse uses this exact touch adapter.
Direct keyboard movement, actions, pausing, retry and menu confirmation are
ignored. A dormant device-intent seam remains disabled in player builds for
future separately reviewed controller/platform adapters.

## PG family-adventure contract

Campaign 1 targets players age five and older and declares a PG family tone.
Hazards bump or splash Fred back to a safe perch. Failure uses a cartoon muddy
splash, explicitly says Fred is safe, and offers clear Try Again and Home
choices. Player-visible copy excludes blood, gore and graphic harm. This is a
product content target, not an external storefront rating certification.

## Evidence boundary

The focused campaign suite enumerates all 100 profiles, chapter placement,
strict progression, step-size limits, hazard budgets, reaction/recovery floors,
fairy levels, touch-target dimensions, PG copy and the Level 100 ending. The
touch-only regression injects physical key events to prove they cannot move or
control Fred, then uses real `InputEventScreenTouch` contacts to traverse the
story, start play, move, Munch, Boost, Pause and complete the campaign path.

Physical Android/iPhone/iPad acceptance, store rating review, Game Center
activation, signing, TestFlight and release remain separate protected gates.
