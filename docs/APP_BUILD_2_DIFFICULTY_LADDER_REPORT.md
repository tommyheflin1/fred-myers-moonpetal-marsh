# Fred Myers App Build 2 chapter-difficulty evidence

Date: 2026-08-20
Branch: `codex/app-build-2`
Starting revision: `dcfb7a51075aa1b3b2abab3d050e3f17ad0d7af3`

## Outcome

The 100-level campaign now uses a deterministic ten-level chapter ladder
instead of the previous slow whole-campaign curve. Every level advances one
explicit step. Levels 1 through 10 run from `1.0x` through `1.9x`; Level 11
begins the next chapter at exactly `2.0x`, Levels 12 through 20 continue through
`2.9x`, and the same pattern reaches `10.9x` on Level 100.

The multiplier is an authored challenge index, not an unsafe direct speed
multiplier. Pressure increases through combinations of moving lilies, moving
prey, currents, route direction, patrol weave, predator count and whirlpools,
while reaction and recovery floors remain suitable for the game's PG,
age-five-plus target.

## Implemented ladder

- Level 1 is the readable baseline: one predator and no forced current.
- Level 2 introduces a moving lily/current challenge.
- Level 3 adds a readable weaving patrol.
- Level 8 adds a reversing current after the earlier current practice.
- Every level increases lily drift, bug travel and bug speed.
- Chapter 1 uses one predator and no whirlpools.
- Level 11 starts Chapter 2 with two predators and one telegraphed whirlpool.
- Each later chapter adds another predator through the five-predator cap.
- Whirlpool pressure grows from zero in Chapter 1 to three in Chapters 8–10.
- Odd and even levels continue to alternate left-to-right and right-to-left
  routes, and the six lily formations/background treatments keep cycling.
- The HUD identifies the exact challenge index, threat count and new level
  focus so the increase is understandable rather than hidden.

The Level 100 safety bounds remain explicit: predator speed scale is no more
than `1.27`, bug speed is no more than `0.90`, reaction time is at least `1.50`
seconds, post-error grace is at least `1.90` seconds, the safe island radius is
at least `50`, and danger reach is no more than `46`.

## Defects found and corrected

Testing the later chapter boundary found two genuine defects:

1. A later background variant could index past its authored accent list. The
   draw loop is now clamped to the available accent positions.
2. On reversed routes Fred's starting point could sit beneath the right-side
   movement pad. Reversed starts now preserve a 64-pixel actor/control
   clearance without moving or resizing the touch target.

The related foundation regression now checks the first intended direct-route
whirlpool at Level 11, matching the new chapter contract.

## Automated validation

- Godot: `4.7.1.stable.official.a13da4feb`.
- Focused chapter-difficulty suite: **1,551 passed, 0 failed**.
- The focused suite verifies all 100 profiles, every `0.1x` step, all chapter
  boundaries, Level 11 at exactly twice Level 1, active predator schedules,
  whirlpool schedules, phone-start clearance, save-v1 exclusion, HUD output,
  100 byte-stable repeated traces and 10,000 calculations in 86.574 ms.
- Complete repository matrix: **26 suites, 6,936 passed, 0 failed**.
- Readiness: **126 artifacts, eight fixtures**, Core 0.5.1 and Godot 4.7.
- Android export validation passed for package
  `com.flinsappvault.fredmyers.dev`, version
  `0.2.2-app-build-2-r1` (`20201`), landscape, arm64-v8a plus x86_64 and no
  requested permissions.
- iOS preparation validation passed for marketing version 1.0/build 2,
  iPhone+iPad, minimum iOS 15 and both Fred Game Center leaderboard IDs.
- Some older isolated test harnesses still emit their previously known
  ObjectDB/resource-at-exit diagnostics even though their assertions and exit
  codes pass. The new chapter suite emits no such diagnostic.

## Visible Windows review

Computer Use inspected the actual Godot runtime at 960 by 540 with isolated
fictional local storage:

- Level 1: `1.0x`, one readable predator, no whirlpool.
- Level 10: `1.9x`, one predator, chapter fairy, reversed route and a distinct
  formation/background; Fred is clear of the right movement pad.
- Level 11: `2.0x`, two predators, one whirlpool, stronger current, a new
  formation/background and a left-to-right route.

The translucent phone controls remained separated from Fred, the HUD, Pause,
Exit and the immediate route/hazard context in the two later-level reviews.
This is real Windows visual evidence, not physical iPhone/iPad acceptance.

## Android artifact and integrity

The exact local development artifact was rebuilt at
`builds/android/fred-myers-app-build-2-debug.apk`:

- size: `84,924,487` bytes;
- SHA-256: `CF117829B55A9CADED871BBD0118C1B81AB931F5ADD3F487DBDA9E68B20A7DF5`;
- debug certificate, APK signature schemes v2 and v3 verified;
- zip alignment verified;
- package/version: `com.flinsappvault.fredmyers.dev`,
  `0.2.2-app-build-2-r1` (`20201`);
- native architectures: arm64-v8a and x86_64;
- content scan: 207 entries, 69 text entries, no test/tool/evidence,
  source-control, secret or private-path material.

Core remains exact at tree
`288d87420c5694f80c071f00aa71a0b581f9f60c`. `fred_save` remains schema v1;
difficulty and hazard presentation state are transient. All new reviews and
tests used isolated fictional storage and did not open or alter owner saves.
The single accepted desktop shortcut was not changed or duplicated.

## Boundaries

This local branch remains unpushed because the configured GitHub repository is
public. No signed iOS archive, TestFlight upload, App Store Connect change,
physical-device acceptance, release or publication occurred. Milestone scores
remain unchanged pending owner and device acceptance.
