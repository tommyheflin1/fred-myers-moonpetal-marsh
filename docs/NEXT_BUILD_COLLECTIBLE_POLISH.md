# Next-build collectible wildlife graphics — 2026-08-31

## Focused continuation

This local graphics pass starts from
`e1bd98ab333444b5fe538dc192baa16a71fe63e2` on
`codex/fred-next-build-pause-fix`. It brings the marsh bugs and chapter fairy
closer to the previously upgraded Fred, attire, predators and botanical artwork.
It does not change their gameplay positions, targets, movement, collection
conditions or rewards. The submitted Build 4 checkout remains separate.

The canonical `shared-build-process` skill was used for baseline preservation,
isolated saves and evidence boundaries. The canonical audit still reports
`MIGRATION_REQUIRED`, with 22 differences against `1.6.0-candidate.1`; no release
tooling migration or alternate Apple delivery method was attempted.

## What changed

- Bugs now have curved, translucent, veined wings instead of rigid quadrilaterals.
  Wing roots remain attached to the torso through the existing flap channels.
  Body segments have shaded shells, curved abdominal bands, glossy eyes, tapered
  antennae and six articulated legs.
- The fairy has softly lit butterfly-shaped wings, a two-panel petal tunic,
  shaded limbs, shoes, two expressive eyes, a small smile and a solid jeweled
  crown. Soft-edged light replaces the previous flat glow discs. Two tiny static
  glints support the reward silhouette; there is no particle system.
- Reduced motion retains the rig's existing attenuated movement and now freezes
  the decorative fairy glow at a neutral value. No new clock was added; paused
  simulation continues to freeze the existing pose input.
- Bug number labels move down eight logical pixels to clear the legs. The fairy
  caption is now `FAIRY +1 LIFE`, fitting an 80-pixel text span instead of the
  previous long caption that ran into a nearby bug in the Level 10 review.
  Both captions have a subtle one-pixel shadow, not a background box. The fairy
  still grants the same stacking +1 life; only its caption changed.

`collectible_wildlife_art.gd` is original app-owned code-native drawing, using
the existing vertex-lighting helper. It creates no nodes, physics bodies,
timers, growing caches, textures, imported models or new external dependencies.
It reads existing rig poses without mutating them. Wings have at most 18 contour
points each, with exactly four wings per actor.

## Real renderer evidence

These are actual Godot captures with fictional isolated data and hazards/audio
disabled. Phone/tablet sizes are SubViewports using the existing logical layout
and letterboxing, not physical-device screenshots. The comparison sheet shows
sampled flight poses, not a video or a complete player-controlled run.

- [Collectible detail and reduced-motion samples](evidence/next-build-collectibles-2026-08-31/collectibles.png)
- [Opening gameplay](evidence/next-build-collectibles-2026-08-31/gameplay-1280x720.png)
- [Underwater phone, 1792 × 828](evidence/next-build-collectibles-2026-08-31/underwater-phone-1792x828.png)
- [Tablet, 1366 × 1024](evidence/next-build-collectibles-2026-08-31/gameplay-tablet-1366x1024.png)
- [Level 10 before this pass](evidence/next-build-marsh-2026-08-31/level10-reverse-phone-1792x828.png)
- [Level 10 after this pass](evidence/next-build-collectibles-2026-08-31/level10-reverse-phone-1792x828.png)

The five retained `builds`, `attire`, `predators`, `water-motion` and `botanical`
review sheets are SHA-256-identical to the preceding marsh review. Their files
are included beside the new captures. Earlier reports and images are preserved.

## Executed checks

| Gate | Result |
| --- | --- |
| Complete final Godot run | 33 suites; 44,060 checks passed, 0 failed |
| New collectible art suite, included above | 21,946 passed, 0 failed |
| Pause input, included above | 36 passed, 0 failed |
| Golden Egg Level 10, included above | 122 passed, 0 failed |
| Game Center adapter, included above | 42 passed, 0 failed |
| Tongue interaction, included above | 82 passed, 0 failed |
| Menu/lives/fairy rewards, included above | 36 passed, 0 failed |
| Python tooling | 5 scripts; 76 checks passed |
| Repository readiness | 155 artifacts; 8 fixtures; Core 0.5.1 |
| Real renderer capture | 10 PNGs; exit 0; clean stderr |
| Render state preservation | Save serialization, actor positions, level, collected items and simulation time unchanged over 120 redraws |
| Render node growth | 0 |

The new suite samples 121 times across three bugs and the fairy, both normal
and reduced motion. It checks bounded/non-overlapping wing meshes, internal
veins, stable wing attachments, body/limb bounds, caption clearance, tunic-panel
fit, crown triangulation, deterministic results, non-mutation of poses, invalid
input and neutral reduced-motion glow. Its 10,000 bug/fairy geometry pairs took
900 ms with zero retained memory growth in the final full run. CI has an explicit
new suite invocation; no remote CI result is claimed.

Final logs: `builds/collectible-review/final-validation` and
`builds/collectible-review/final-render`. The first new-test attempt had three
GDScript type-inference errors in test variables; explicit types corrected those
before the successful runs above. Headless import regenerated the previously
missing App Store capture UID; that incidental file was not included in this
change.

Fourteen older headless suites emitted ObjectDB/resource-at-exit diagnostics
(2–5 objects and 1–2 resources per affected suite). The count varies from earlier
runs, and the cause of that variation was not established. Those suite scripts
were not changed. No final assertion, parse or script error occurred. The new
collectible suite and rendered capture have clean stderr; this is not a claim
that the entire existing engine log is warning-free.

The final Windows/NVIDIA T1000 Level 10 capture measured 16.545 ms p95 game-draw
CPU time, 1.025 ms average predator-draw time and 0.679 ms average collectible-draw
time (480 collectible draws). These are drawing CPU measurements, not total
frame time, GPU time, phone FPS, battery or thermal evidence. Physical-device
profiling remains necessary; no 60-FPS or performance-improvement claim is made.

## Protected state and next acceptance gates

- Godot 4.7.1, Core 0.5.1 and save schema `fred_save` v1 are unchanged.
- No changes to difficulty, jump/dive/boost, targeting/collision, collection or
  fairy spawn/reward rules, Golden Egg, Game Center, Pause, audio, HUD/control
  positions, app identity, build/version numbers or customization prices/IDs.
- The footer feedback clearance and all previous character/botanical work are
  preserved. The desktop shortcut was not redirected.
- Protected Build 4 remains clean at
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner primary/backup save and desktop-shortcut SHA-256 values remain those
  recorded in [the preceding marsh report](NEXT_BUILD_MARSH_POLISH.md).
- No GitHub push, signing, Apple upload, submission or public release ran.

Next acceptance is owner visual review and physical iPhone/iPad testing of
readability, motion, touch, Pause/background/resume, rotation and frame pacing,
including later levels. The existing release-process migration remains a separate
gate. Local Golden Egg regression is not proof of a website leaderboard entry.

For reproduction, first redirect APPDATA/LOCALAPPDATA to fresh ignored test
folders (never owner saves). Run all `godot/tests/run_*.gd`, the five
`tools/tests/test_*.py` files and `python tools/validate_readiness.py`. Render with:

```text
godot --disable-vsync --fixed-fps 60 --path godot --script res://tools/capture_next_build_graphics.gd -- --output=<absolute-review-folder>
```
