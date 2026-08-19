# M2 touch-first phone and tablet controls

Updated: 2026-08-18

## Purpose

Fred App Build 1 now uses one device-neutral touch interaction model intended
for landscape phones, iPads, and Android tablets. The marsh itself is the
movement surface: touching and dragging directs Fred toward the active contact.
Munch, Leap, Boost, and Dive/Surface are large, separated buttons in a single
bottom action row. Pause and Exit remain isolated in the top HUD.

The desktop owner launcher always displays this touch-first interface. A mouse
press and drag follows the same contact, steering, dead-zone, clamping, action,
and release code as a screen touch. This is a review adapter, not a claim of
physical-device acceptance.

## Deterministic contract

- The gameplay surface excludes the top HUD and bottom action row.
- Movement targets clamp to the playable surface and use an 18-pixel logical
  dead zone to reject finger jitter.
- The lowest touch-contact index owns steering deterministically.
- A second contact can hold Boost while the first continues steering.
- Action contacts cannot silently become steering contacts when dragged away.
- Releasing, pausing, backgrounding, retrying, returning Home, failing, or
  advancing a level clears transient touch state.
- Dive changes to Surface while Fred is underwater or transitioning.
- Touch state remains presentation/input state and is absent from `fred_save`
  schema v1.

## Layout and accessibility

All four action targets are 205 by 84 logical pixels and meet the existing
48-dp minimum under the tested phone-density conversion. The action rectangles,
steering guide, status feedback, Objective, Lives, Energy, Pause, and Exit
contracts do not overlap. Labels and distinct accent colors communicate action
meaning without relying on color alone. The fixed 1280 by 720 logical canvas
uses Godot `canvas_items`/`keep` scaling so the same bounded layout remains
stable on 16:9 phones and wider or 4:3 landscape tablets.

## Evidence boundary

The focused deterministic suite covers layout geometry, direct touch/drag,
dead-zone behavior, clamping, two-contact steer-plus-Boost, action release,
Leap, Dive, Pause, desktop pointer parity, stale-contact cleanup, and save
invariance. Full regression, visible Windows phone/tablet-size review, Android
re-export, exact APK inspection, and final candidate identity are recorded in
the App Build 1 report after execution.

Executed local evidence:

- focused touch-first suite: 55 passed, 0 failed;
- complete matrix: 19 suites, 2,335 passed, 0 failed;
- Godot 4.7.1 headless import/parse: passed;
- readiness: 76 artifacts and eight fictional save fixtures;
- visible Windows review: 1280 by 720 normal motion, 960 by 540 reduced
  motion, and 1024 by 768 aspect-preserving tablet layout;
- desktop mouse activated the exact touch-first Leap path, while direct
  touch/drag and two-contact steering are automated rather than mislabeled as
  physical-device evidence;
- Objective, Lives, Energy, status, Pause, Exit, steering guide, and all four
  bottom action buttons remained readable and non-overlapping;
- Core 0.5.1 tree and both owner-save bytes/timestamps remained unchanged.

No physical Android device or iPad was connected, installed to, controlled, or
captured in this slice. iOS export, signing, Game Center activation, TestFlight,
and store submission remain separate protected Apple gates.
