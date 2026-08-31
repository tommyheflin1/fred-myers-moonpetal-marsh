# Next-build rendering performance — 2026-08-31

## Result and scope

The next recommended step was reducing rendering cost after the graphics
uplifts. This local update preserves Fred's superhero body, face, all attire,
predators, botanical detail, captions, touch controls and water effects.
All 30 captured images are byte-identical before and after the optimization.

Candidate: `codex/fred-next-build-pause-fix`, starting at
`c44301b53f2c71ba7192e34b6bfe7a5b0794ddbb`, tree
`55a83def5e2bc327b2b5fea50988e74d52e10b31`.

The `shared-build-process` skill guided exact-candidate audit, isolated tests
and protected-state verification. The audit still reports
`MIGRATION_REQUIRED`: 22 differences against `1.6.0-candidate.1`. No release
tool migration, Core upgrade or Apple readiness claim is part of this change.

## Focused implementation

- Surface meshes allocate their final arrays once. Each contour point's
  lighting direction/highlight is calculated once for both rings, and soft
  feathered patches skip directional lighting that they do not use.
- Ellipse trigonometry reuses three fixed unit templates: 8, 16 and 24 points,
  exactly 48 cached vertices. This is not a position/time/pose cache. Returned
  templates are isolated copies; 20,000 varying ellipses do not grow it.
- Fred resolves the joint/global transforms once per contour and transforms
  packed point arrays through native engine operations. The two original
  matrix multiplies remain separate to preserve rounding. No transform is
  retained across frames, so animation, turning and customization stay current.

Only Fred-owned `character_surface.gd` and `fred_rig.gd` runtime code changed.
No visual detail, draw calls, polygon resolution, gameplay rules, input,
simulation timing, catalog items/prices, save schema, app identity, native
plugins or dependencies changed. No new textures, scene nodes or materials.

## Measured comparison

Same Windows host, Godot 4.7.1 compatibility renderer, NVIDIA T1000 8GB.
The unchanged `capture_next_build_graphics.gd` harness ran three baseline
processes and three final processes, each measuring 120 frozen-state redraws
per scene. No other test process ran during these captures. Baselines ran
first, then final runs; this is not a randomized device benchmark.

| CPU drawing-preparation p95 | Baseline runs (ms) | Final runs (ms) | Median reduction |
| --- | --- | --- | --- |
| Level 10 | 15.585 / 15.864 / 16.852 | 14.589 / 15.025 / 14.906 | 6.0% |
| Level 71 | 18.474 / 18.634 / 20.038 | 17.588 / 17.715 / 17.565 | 5.6% |

An independent in-process A/B test alternates the frozen previous mesh builder
and optimized builder across five batches of 4,000 surfaces. In the final full
regression run, median construction cost fell from 31.511 ms to 22.226 ms per
batch (29.5%). Timing is reported, not used as a fragile speedup assertion.

These values are **CPU preparation only**, not GPU/frame timings or iPhone/iPad
FPS. The busy scene remains above 16.67 ms. Native device profiling, frame
pacing and any additional optimization remain open before release.

## Visual and state equivalence

All 30 PNGs have identical SHA-256 hashes across all six baseline/final runs:
180 outputs checked, including 72 body/outfit combinations, phone/tablet
customizers, underwater, reversed levels, late-motion water, Pause and long
feedback. Hero close-up and Level 71 tablet renders were also visually viewed.
The existing [Fred close-up](evidence/next-build-face-2026-08-31/hero-detail.png)
is unchanged; identical PNGs are not duplicated into a new evidence folder.

All six capture processes exited 0 with clean stderr, 30-image completion
markers, unchanged session/actor/progress/simulation snapshots over redraws,
and zero render-node growth. The harness uses fictional isolated data with
hazards/audio disabled; it is not a completed player-controlled run.

- [Exact image hashes, source-file hashes and measurements](evidence/next-build-performance-2026-08-31/renderer-verification.json)
- Baseline renderer logs: [1](evidence/next-build-performance-2026-08-31/baseline-1.txt), [2](evidence/next-build-performance-2026-08-31/baseline-2.txt), [3](evidence/next-build-performance-2026-08-31/baseline-3.txt).
- Final renderer logs: [1](evidence/next-build-performance-2026-08-31/final-1.txt), [2](evidence/next-build-performance-2026-08-31/final-2.txt), [3](evidence/next-build-performance-2026-08-31/final-3.txt).

## Executed validation

- All 36 Godot suites: **97,062 passed, 0 failed**, every process exit 0.
- Expanded surface suite: **17,235 passed**, including old/new byte-equivalent
  mesh output for every supported contour count, multiple colors/alpha/gloss,
  feathered/solid modes, ellipse thresholds/rotation, cache mutation/churn,
  and exact joint transforms across 8 bodies x 9 outfits x 23 poses x 2 facings.
- Pause input: 36 passed; Golden Egg: 122 passed; Game Center adapter: 42 passed
  (included above). Local Golden Egg checks do not prove website submission.
- Python tooling: five scripts, 76 checks passed. Readiness: 161 artifacts,
  eight fixtures, Core 0.5.1. Existing CI includes the expanded surface suite;
  remote CI was not run.
- Eleven existing suites emitted ObjectDB/resource-at-exit diagnostics, with
  no assertion, parse, script or polygon errors. The expanded surface suite,
  hero art suite and all final renderer runs have clean stderr.
- A first-run regression caught a shared ellipse-template array. It was fixed
  with an isolated return copy before the passing focused/full validation.

Local full logs: `builds/render-performance-review/full-validation`; baseline
and final captures/logs: `builds/render-performance-review/baseline-{1,2,3}`
and `final-{1,2,3}`. Copied renderer logs were hash-verified. Patch formatting
was checked with `git diff --check`.

## Protected state

- Core 0.5.1, Godot 4.7.1, save v1 and existing build configuration unchanged.
- Submitted Build 4 checkout remains clean at
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner save SHA-256 unchanged:
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup SHA-256 unchanged:
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Desktop owner-test shortcut SHA-256 unchanged:
  `F75617364EAD7899D8ECEB2A8D3D87CED2A73F2FA6D3F9347182ECF563A28D2A`.
- No shortcut redirection, GitHub push, signing, upload, TestFlight, App Review
  or public-release operation ran.
