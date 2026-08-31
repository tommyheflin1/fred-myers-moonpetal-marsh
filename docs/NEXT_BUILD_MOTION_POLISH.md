# Next-build water contact and motion polish — 2026-08-31

## Local continuation

This focused graphics pass continues from `108baf0c292d184e9312e5180bec27e2772d017f`
on `codex/fred-next-build-pause-fix`. It retains the earlier Fred/attire/predator
graphics upgrade and the Pause fix from `a668bb0`. No new game mechanics,
customization purchases, assets, dependencies or store metadata were introduced.

The original [character graphics review](NEXT_BUILD_GRAPHICS_UPLIFT.md) and its
images are preserved. New images live in a separate evidence folder.

## What changed

- Fred's gameplay shadow is now anchored to the water/ground plane. It becomes
  softer and wider with leap height instead of rising with his body. The old
  duplicate airborne circle and rig-attached gameplay shadow are gone; character
  menus retain their existing preview shadow.
- Surface swimming has an open contact ring and a short directional trailing
  wake. Water landings have an expanding second ring. Dry perches do not create
  swimming wakes. Airborne Fred has neither bubbles nor a floating foot ring.
- Diving fades surface contact; underwater movement has a small, bounded bubble
  trail. Swimming beneath a lily pad still has underwater presentation rather
  than being mistaken for standing on that pad.
- The heron's shadow and small water rings now follow its actual ankle/foot
  positions. The old horizontal bar halfway up its legs was removed. Foot drawing
  and contact geometry share the same authored leg-lift calculation.
- Fish rendering now uses its existing gill-breathing, eye-focus and separate
  pelvic-fin channels. Reduced-motion gill movement is attenuated; other channels
  retain the existing reduced-motion pose values.
- Right-leg outfit knee pads, trim and ribbons now use mirrored coordinates,
  matching the right hind limb instead of reusing left-leg coordinates.

`water_contact_art.gd` is stateless, app-owned drawing geometry. It creates at
most six short arcs and four bubbles per actor, with no new nodes, particle
systems, trail history, timers or save fields. It uses the existing simulation
clock, so paused gameplay does not advance the contact animation. Reduced motion
freezes decorative wake/bubble drift without concealing depth state.

## Rendered review

These are real Godot renderer captures of the actual rigs and drawing code,
using fictional, isolated test data. Species captions appear only on review
sheets, not over predators in gameplay.

- [Six traversal poses and water-contact states](evidence/next-build-motion-2026-08-31/water-motion.png)
- [Predators and grounded heron feet](evidence/next-build-motion-2026-08-31/predators.png)
- [Fred body builds](evidence/next-build-motion-2026-08-31/builds.png)
- [Attire, including mirrored leg details](evidence/next-build-motion-2026-08-31/attire.png)
- [Gameplay, 1280 × 720](evidence/next-build-motion-2026-08-31/gameplay-1280x720.png)
- [Underwater phone aspect, 1792 × 828](evidence/next-build-motion-2026-08-31/underwater-phone-1792x828.png)
- [Tablet aspect, 1366 × 1024](evidence/next-build-motion-2026-08-31/gameplay-tablet-1366x1024.png)

The pose sheet compares swim, leap apex, landing, diving, deep swim and surfacing.
It is a phase review, not a recording of a complete player-controlled sequence.
Phone/tablet images use exact-resolution SubViewports and the existing logical
layout/letterboxing; they are not physical-device screenshots. Review fixtures
disable hazards and audio. Previous gameplay/HUD/control positions are unchanged.

## Executed checks

| Gate | Result |
| --- | --- |
| Full final Godot run | 31 suites; 16,279 passed, 0 failed |
| New water-contact/motion suite, included above | 4,419 passed, 0 failed |
| Previous character shading/costume-fit suite, included above | 3,463 passed, 0 failed |
| Pause input regression, included above | 36 passed, 0 failed |
| Golden Egg Level 10, included above | 122 passed, 0 failed |
| Game Center adapter, included above | 42 passed, 0 failed |
| Python tooling | 5 scripts; 76 checks passed |
| Readiness | 151 artifacts; 8 fixtures; Core 0.5.1 |
| Headless import | Passed; existing missing App Store capture UID was regenerated only in cache/local import |
| Final rendered review | 7 images; 120 measured game draws; capture exited 0 |
| Render state preservation | Session save, actor positions, level, collected items and simulation time unchanged |
| Render node growth | 0 |

The new tests cover deterministic output, non-mutation of supplied state, fixed
water-plane leap shadows, correct wake direction, dry-perch suppression,
underwater-pad behavior, reduced motion, finite/bounded geometry across depths
and times, exact heron ankle alignment, and the fish's authored animation channels.
The 10,000-call contact stress test retains no growing history/cache. CI has a
new explicit invocation of this suite; no remote CI result is claimed.

Final local logs: `builds/motion-review/final-validation` and
`builds/motion-review/final-render`. Like the previous pass, some older headless
suites report ObjectDB/resource-in-use diagnostics at shutdown (2–6 objects,
1–2 resources). No assertion or script/parse failure occurred. The new suite and
final rendered capture have clean stderr; existing diagnostics are not being
represented as a completely clean engine log.

An initial hidden-window capture produced all seven PNGs but timed out during
its 120-frame measurement loop. That run was not counted as a pass. The exact
cause of that timing stall was not established. Two subsequent offline capture
runs using the installed Godot's documented `--disable-vsync --fixed-fps 60`
options completed successfully; no application or project frame-rate setting
was changed to achieve this.

The final Windows/NVIDIA T1000 capture measured 11.921 ms p95 game-draw CPU time
and 1.186 ms average predator-draw CPU time. This measures drawing work, not total
GPU/frame presentation, battery use or physical-device performance. The capture
uses fixed simulation deltas and is not an FPS guarantee.

## Preserved state and remaining gates

This pass used the canonical `shared-build-process` skill for the exact baseline,
isolated tests and preservation boundaries. Its audit still reports 22 migration
differences against process `1.6.0-candidate.1` (`MIGRATION_REQUIRED`). Resolving
that existing release-tooling gate is separate from graphics development. No
alternative uploader, harness migration, Core upgrade or Apple operation ran.

- Core 0.5.1, Godot 4.7.1 and `fred_save` v1 are unchanged.
- No changes to movement, collision, jump/dive timing, difficulty, level rules,
  Golden Egg eligibility/transport, Game Center, Pause/input, audio, touch-button
  positions, catalog IDs/prices, app identity or build/version numbers.
- The protected Build 4 checkout remains clean at
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner primary/backup save and desktop shortcut hashes remain those recorded in
  the preceding graphics report. The shortcut was not redirected or replaced.
- Nothing was pushed to GitHub, uploaded to Apple, signed, submitted or released.

Remaining acceptance: owner visual preference, physical iPhone/iPad animation
and touch review, real frame pacing/thermal behavior in later levels, native
Pause/background/resume and rotation, and the existing release-process migration.
A local Golden Egg regression does not verify a real website leaderboard entry.

To reproduce the visual review, first point APPDATA/LOCALAPPDATA at fresh ignored
test folders (never owner saves), then run:

```text
godot --disable-vsync --fixed-fps 60 --path godot --script res://tools/capture_next_build_graphics.gd -- --output=<absolute-review-folder>
```

Run `python tools/validate_readiness.py`, the five `tools/tests/test_*.py` scripts,
and every `godot/tests/run_*.gd` suite with that same isolated-data discipline.
