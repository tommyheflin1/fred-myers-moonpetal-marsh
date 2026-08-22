# Fred Myers App Build 3 local fixes

Date: 2026-08-21
Branch: `codex/app-build-3-local-fixes`
Base revision: `b4604856bef6b61ab22fbc809bc5d23c08d80e54`

## Owner-reported issues

Physical Build 2 testing identified two focused issues:

1. the energy panel visually overlapped the route/threat summary; and
2. Levels 1 through 10 were not challenging enough.

A subsequent phone screenshot also showed that the left action wheel required
too much thumb reach and Fred should begin directly above it.

## Implemented changes

- The energy meter moved from `930..1230 x 72..86`, with a smaller label, so
  it remains above the route-summary glyph band beginning at y=86.
- Level 1 now begins at the former Level 10 `1.9x` pressure baseline instead
  of `1.0x`.
- Level 1 begins with two readable predator patrols and an active current,
  rather than one predator and no current.
- Every later level still advances by exactly `0.1x`; Level 10 is `2.8x`,
  Level 11 is `2.9x`, and Level 100 is `11.8x`.
- Existing age-five safety limits remain unchanged: bounded predator speed,
  reaction time, mistake grace, safe radius, danger radius, five-predator cap,
  and three-whirlpool cap.
- Difficulty and layout remain transient and do not change `fred_save` v1.
- The action-wheel center moved from x=340 to x=160. Its four 84-pixel actions
  now occupy the far-left short-reach thumb zone while retaining the same
  shared visual and hit-test geometry.
- Odd-route levels place Fred at x=160 with a protected 64-pixel clearance
  above the action wheel. Reversed routes place Fred above the right movement
  pad using the same rule.

## Validation

- Godot 4.7.1 import/parse gate: passed.
- Full deterministic matrix: **27 suites, 8,172 passed, 0 failed**.
- Chapter difficulty: **1,541 passed, 0 failed**, including 100 stable traces
  and 10,000 profile calculations.
- Phone lives/routes/layout: **54 passed, 0 failed**, including the energy
  panel separation and Fred/control-clearance assertions.
- Build 2 phone-control regression: **50 passed, 0 failed**.
- Campaign: **1,430 passed, 0 failed**.
- M2 foundation: **751 passed, 0 failed**.
- Touch-only regression: **22 passed, 0 failed**.
- Readiness: **132 artifacts, eight fixtures, Core 0.5.1, Godot 4.7**.

No iOS archive, TestFlight upload, App Store Connect modification, signing,
submission, deployment, release, public push, save-schema change, or owner-save
mutation occurred. This is a local Build 3 candidate awaiting further owner
testing direction.
