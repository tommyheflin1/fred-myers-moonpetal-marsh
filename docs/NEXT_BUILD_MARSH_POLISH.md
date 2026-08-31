# Next-build marsh graphics and feedback clearance — 2026-08-31

## Scope and baseline

This local continuation starts from `1e62a42992fe2f4c67b1e5c2c784b5ee6f5688cb`
on `codex/fred-next-build-pause-fix`. It preserves the previous character/attire/
predator shading, water contact and motion work, and the Pause fix. Previous
review reports and images are retained unchanged.

The canonical `shared-build-process` skill was used to preserve the submitted
baseline, use isolated test saves, and separate local proof from Apple delivery.
The canonical process audit still reports `MIGRATION_REQUIRED`: 22 differences
against `1.6.0-candidate.1`. That existing release-tooling gate was not bypassed
or migrated as part of this visual-only continuation.

## Implemented

- Lily pads have a lightly irregular 41-point leaf outline, an actual open-water
  notch, shaded upper/under surfaces, curved branching veins, subtle flecks and
  three dewdrops. Their existing 48 × 29 logical radii, positions, rotation and
  bob remain the same. The water-contact arc now follows the flattened leaf
  plane instead of forming a large circular bowl below it.
- The Moonpetal exit has two layers of pointed, shaded petals, folded highlights,
  a soft glow and a detailed golden center. The exit radius/pulse and label anchor
  are unchanged. Tiny pad blossoms use one eight-petal layer at gameplay scale
  to keep their drawing cost modest.
- Safe perches have a shaded moss/soil edge, perimeter stones and tapered grass.
  Grass and detail marks avoid a reserved central text strip. Safe radii and
  gameplay protection rules are unchanged.
- Border reeds have curved, tapered blades and occasional small seed heads.
  They retain the original bases, height envelope and existing sway input;
  reduced motion freezes that sway.
- Actual rendered review exposed the old status-message box over the opening
  safe-perch label. The touch feedback rectangle now sits in the free footer:
  `Rect2(500,642,340,42)`, previously `Rect2(500,568,340,42)`. Text size and box
  dimensions are unchanged. It is outside the water playfield and clear of both
  control groups. Objective, energy, Pause/Exit and touch controls did not move.

`botanical_art.gd` contains original, deterministic, app-owned drawing geometry.
It adds no nodes, physics bodies, materials, textures, random state, timers,
history or growing caches. No media downloads or new dependencies were used.

## Actual rendered review

These images come from the real Godot game drawing code, not mockups. Test
fixtures use fictional progress and disable hazards/audio. Phone and tablet
images use exact-resolution SubViewports with the existing logical layout and
letterboxing; they are **not physical-device screenshots**.

- [Botanical detail sheet](evidence/next-build-marsh-2026-08-31/botanical.png)
- [Opening gameplay and clear safe-perch label](evidence/next-build-marsh-2026-08-31/gameplay-1280x720.png)
- [Underwater phone, 1792 × 828](evidence/next-build-marsh-2026-08-31/underwater-phone-1792x828.png)
- [Tablet, 1366 × 1024](evidence/next-build-marsh-2026-08-31/gameplay-tablet-1366x1024.png)
- [Level 10 reversed-route phone](evidence/next-build-marsh-2026-08-31/level10-reverse-phone-1792x828.png)
- [Retained Fred builds](evidence/next-build-marsh-2026-08-31/builds.png)
- [Retained attire](evidence/next-build-marsh-2026-08-31/attire.png)
- [Retained predators](evidence/next-build-marsh-2026-08-31/predators.png)
- [Retained traversal/contact poses](evidence/next-build-marsh-2026-08-31/water-motion.png)

The four retained character, attire, predator and motion-sheet PNGs are
SHA-256-identical to the preceding motion review, confirming that this pass did
not visually alter those authored poses.

## Executed validation

| Gate | Result |
| --- | --- |
| Final complete Godot run | 32 suites; 22,114 passed, 0 failed |
| New botanical/feedback suite, included above | 5,835 passed, 0 failed |
| Character surfaces, included above | 3,463 passed, 0 failed |
| Water-contact and wildlife motion, included above | 4,419 passed, 0 failed |
| Pause regression, included above | 36 passed, 0 failed |
| Golden Egg Level 10, included above | 122 passed, 0 failed |
| Game Center adapter, included above | 42 passed, 0 failed |
| Python tooling | 5 scripts; 76 checks passed |
| Repository readiness | 153 artifacts; 8 fixtures; Core 0.5.1 |
| Actual renderer | 9 PNG captures; exit 0; clean stderr |
| Render state guard | Save serialization, actor positions, level, collected items and simulation time unchanged over 120 draws |
| Render node growth | 0 |

New tests cover deterministic geometry, finite/bounded contours, triangle-area
coverage (including the concave leaf notch), veins staying inside leaves,
all 100 levels × 7 pads × 3 sampled drift/bob times using the real placement
function, perch grass/text separation, all campaign perch-label/feedback
separation, 61 flower-pulse/reed-sway samples, reduced motion, invalid input and
10,000 botanical-generation sets. The stress run took 125 ms and retained no
growing geometry history. CI includes the new suite; remote CI was not run.

Final logs are in ignored local folders `builds/marsh-review/final-validation-r2`
and `builds/marsh-review/final-render-r2`. Thirteen older headless suites retain
their previously observed shutdown diagnostics (2–5 ObjectDB instances and
1–2 resources still in use at exit). No assertion, parse or script failures
occurred. The new botanical suite and final render have clean stderr; the older
diagnostics are not represented as a completely clean engine log.

The final Windows/NVIDIA T1000 capture measured 13.722 ms p95 drawing CPU time
for the Level 10 fixture, and 0.902 ms average predator drawing CPU time. These
are draw-call preparation measurements, not total frame time, GPU time, FPS,
battery or physical-device performance. No phone performance guarantee is made.

## Preservation and remaining gates

- Godot 4.7.1, Core 0.5.1 and `fred_save` v1 remain unchanged.
- No changes to movement, collision, level rules/difficulty, jump/dive/boost,
  Golden Egg logic/backend, Game Center, Pause/input, audio, customization IDs or
  prices, app identity, version or build numbers.
- The protected Build 4 checkout remains clean at
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner primary/backup saves and the existing desktop shortcut remain unchanged:
  primary SHA-256 `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`;
  backup `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`;
  shortcut `F75617364EAD7899D8ECEB2A8D3D87CED2A73F2FA6D3F9347182ECF563A28D2A`.
- No GitHub push, Apple operation, signing, upload, submission or release ran.

Remaining acceptance is owner visual preference, physical iPhone/iPad layout,
animation/frame pacing and thermal testing, native Pause/background/resume,
rotation, and the existing release-process migration gate. Local Golden Egg
tests do not verify a real discovery on the website leaderboard.

To reproduce, point APPDATA/LOCALAPPDATA at fresh ignored test directories
(never owner saves), then run every `godot/tests/run_*.gd`, the five
`tools/tests/test_*.py` scripts and `python tools/validate_readiness.py`.
For actual visual captures:

```text
godot --disable-vsync --fixed-fps 60 --path godot --script res://tools/capture_next_build_graphics.gd -- --output=<absolute-review-folder>
```
