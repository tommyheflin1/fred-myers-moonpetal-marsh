# Next-build whirlpool artwork — 2026-08-31

## Focused continuation

This local pass starts from `7db28f2a350e9492aee697e1990ea8e0a7b31bb2`
(tree `eece62fd2a05e0573fd382f09f010cda75b5c411`) on
`codex/fred-next-build-pause-fix`. It improves the remaining hard-ring whirlpool
art without modifying the submitted Build 4 checkout or the existing Fred,
attire, predator, botanical and collectible upgrades.

The canonical `shared-build-process` skill was used for baseline preservation,
isolated user data, full regression and distinct local/device/Apple evidence.
The process audit remains `MIGRATION_REQUIRED`, with 22 differences against
`1.6.0-candidate.1`. No release-tool migration, signing or alternate uploader ran.

## What changed

- One shaded funnel mesh replaces the stacked opaque discs and polygonal hole.
  Its 201 vertices and 360 triangles form non-overlapping radial strips. The
  outer ring fades into the existing water instead of ending in a hard disc.
- Three tapered inward currents and nine curved foam streaks replace bright
  concentric rings and large dots. The original angular speeds remain; the
  foam has an independently wrapped phase to avoid jumps when a current wraps.
- The new art stays within the old 58-pixel water footprint, with the old
  oversized offset shadow removed. The label remains at the same 72-pixel
  baseline, now with a one-pixel dark shadow and no added text box.
- Animation reads `simulation_time`, not the menu's `visual_time`. Pause and
  background-return screens freeze the swirl/foam while reduced motion uses a
  fully steady illustration. There is no new clock or update loop.

`whirlpool_art.gd` is original app-owned code-native artwork: no imported assets,
new dependencies, nodes, materials, textures, particles, randomness, physics,
caches or retained history. Geometry generation never changes gameplay state.

The original strict `< 50.0` collision predicate, route mirrors, chapter hazard
counts, damage, cooldown, Golden Egg disqualification and respawn logic are not
edited. The route danger check remains `< 58.0`. Jump/dive/boost, rewards, saves,
Game Center, audio, controls, HUD boxes and app identity are also unchanged.

## Real Godot renderer review

- [Whirlpool detail: normal and reduced motion](evidence/next-build-whirlpools-2026-08-31/whirlpools.png)
- [Level 17 phone: early water hazards](evidence/next-build-whirlpools-2026-08-31/level17-phone-1792x828.png)
- [Level 71 tablet: five predators and three whirlpools](evidence/next-build-whirlpools-2026-08-31/level71-tablet-1366x1024.png)
- [Level 71 phone: Pause and Resume presentation](evidence/next-build-whirlpools-2026-08-31/level71-paused-phone-1792x828.png)

These are actual drawing-code captures using fictional, isolated data, with
hazards and audio disabled for review. Exact-resolution phone/tablet SubViewports
use the existing letterboxed layout. They are not physical-device screenshots,
nor evidence of a complete player-controlled run. All 14 generated PNGs remain
in ignored `builds/whirlpool-review/final-render`; the four new scenes are retained
above. Earlier review documents and images remain untouched.

The six retained character/attire/predator/motion/botanical/collectible sheets,
opening 1280×720 scene and opening tablet scene are SHA-256-identical to the
preceding collectible review. The newly tested busy Level 71 scene also exposes
existing world-label crowding: a safe perch can cover the second whirlpool's
label. World-label placement and drawing order were intentionally not changed
in this pass; this remains a presentation follow-up, not a claim of universally
unobscured labels. Header controls and the Pause overlay remain clear in review.

## Executed checks

| Gate | Result |
| --- | --- |
| Complete Godot regression | 34 suites; 50,030 checks passed, 0 failed |
| New whirlpool suite, included above | 5,970 passed, 0 failed |
| Pause input, included above | 36 passed, 0 failed |
| Golden Egg Level 10, included above | 122 passed, 0 failed |
| Game Center adapter, included above | 42 passed, 0 failed |
| Python tooling | 5 scripts; 76 checks passed |
| Readiness | 157 artifacts, 8 fixtures, Core 0.5.1 |
| Render capture | 14 PNGs; exit 0; clean stderr |
| Level 10 and 71 redraw guards | Session save, actor positions, level, collected items and simulation time unchanged over 120 redraws each |
| Render node growth | 0 in both measured scenes |

The new suite samples 91 times across all three hazards in both motion modes.
It verifies mesh winding/area, finite bounded geometry, transparent outer edge,
inward paths, foam bounds, label clearance from the water silhouette, phase-wrap
continuity and reduced-motion stability. All 100 levels exercise the real
collision predicate at 49.9, 50.0 and 50.1 pixels, preserving chapter counts and
mirrored positions. A live main-scene instance verifies Pause, background return,
Resume and non-mutating snapshots. Its 10,000 geometry snapshots took 267 ms
with no retained memory growth. CI includes the new suite; no remote CI ran.

Final test logs: `builds/whirlpool-review/final-validation`. Thirteen older suites
emitted their previously observed ObjectDB/resource-at-exit diagnostics (2–5
objects, 1–2 resources). Their scripts were not changed. There were no assertion,
parse or script failures. The new suite and renderer have clean stderr. Editor
import regenerated an unrelated missing App Store capture UID from cache; that
incidental file was removed and is not part of the change.

The Windows/NVIDIA T1000 renderer measured Level 10 game-draw p95 at 13.984 ms
and Level 71 at 18.337 ms. Level 71's three-whirlpool drawing pass averaged
1.294 ms. These measure CPU drawing preparation, not GPU or total frame time.
The busy-scene p95 exceeds a 16.67-ms 60-Hz frame budget even before other work;
no 60-FPS, phone-performance or performance-improvement claim is made. Device
profiling and any necessary optimization are still acceptance gates.

## Protected state and delivery boundaries

- Godot 4.7.1, Core 0.5.1 and `fred_save` v1 remain pinned. No build-number change.
- Protected Build 4 remains clean at `c261e37979b0f306ff86ce7e450922a2c919c2f0`,
  tree `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner primary/backup saves and desktop shortcut hashes remain those recorded
  in [the marsh review](NEXT_BUILD_MARSH_POLISH.md). The shortcut was not redirected.
- No GitHub push, Apple upload, signing, TestFlight assignment, App Review or
  public release ran.

Remaining work includes owner visual preference, busy world-label clearance,
physical iPhone/iPad readability and frame pacing, native Pause/background/Resume
and rotation, and the separate release-tooling migration. Local Golden Egg tests
are not proof of a website leaderboard entry.

To reproduce, redirect APPDATA/LOCALAPPDATA to fresh ignored test folders, then
run all `godot/tests/run_*.gd`, the five `tools/tests/test_*.py` scripts and
`python tools/validate_readiness.py`. For renderer evidence:

```text
godot --disable-vsync --fixed-fps 60 --path godot --script res://tools/capture_next_build_graphics.gd -- --output=<absolute-review-folder>
```
