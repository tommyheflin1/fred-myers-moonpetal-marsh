# Next-build character graphics pass — 2026-08-31

## Outcome and scope

Implemented locally on `codex/fred-next-build-pause-fix`, in the separate
`fred-myers-next-build-pause-fix` checkout. This is an incremental upgrade to
the actual game renderers, not a concept-art replacement or a new game.

Starting source: `a668bb0536c9988f42eaa75471ee55c3ac770f73`.
Starting tree: `ed428d1a756dd806b75e6753e78e742b228b435f`.
That source already contains the native-touch Pause fix. The graphics commit
descends from it; the previous Pause fix has not been reverted or replaced.

- Fred: smoother shaded skin and contours, softer highlights, filled webbed
  feet attached to the existing hind joints, and corrected mirrored hind-leg
  detail placement. All eight existing body builds retain their distinct shapes.
- Attire: shaded cloth/gear panels on all nine existing outfits, retaining
  costume cuts, fit, goggles/visors and an unobstructed mouth and jaw.
- Fish: bass has a deep body and broken lateral band; pike has a tapered body
  with pale spots; muskie has vertical bars. Attached fins, gill covers, eyes,
  jaws and restrained scale detail replace the old elliptical outline treatment.
- Snake: continuous tapered body instead of overlapping round segments, with
  shaded head volume and quieter scale markings.
- Heron: filled wing feathers and a smoother bent neck, using the existing pose
  channels and attachment endpoints.
- Water/HUD: flatter water-contact rings no longer form a circle across a
  predator's face. The depth label now has a dedicated screen-space area and
  draws after scenery, preventing the Moonpetal flower from covering its words.

This pass uses original, code-native vector geometry and existing authored rigs.
No new third-party model, texture, music or license dependency was downloaded.
The existing Sketchfab reference register and shipped media are unchanged.
It does not claim photorealistic 3D models or new customization catalog entries.

## Actual rendered review

The following PNGs were produced by Godot 4.7.1 from the actual candidate rigs
and gameplay drawing code, then visually inspected. The review sheets use the
same fixed pose, scale and lighting per page. Species captions are review-only;
no predator species-name labels were added to gameplay.

- [All eight Fred body builds](evidence/next-build-graphics-2026-08-31/builds.png)
- [All nine attire options](evidence/next-build-graphics-2026-08-31/attire.png)
- [All five predator species](evidence/next-build-graphics-2026-08-31/predators.png)
- [Gameplay, 1280 × 720](evidence/next-build-graphics-2026-08-31/gameplay-1280x720.png)
- [Underwater phone aspect, 1792 × 828](evidence/next-build-graphics-2026-08-31/underwater-phone-1792x828.png)
- [Tablet aspect, 1366 × 1024](evidence/next-build-graphics-2026-08-31/gameplay-tablet-1366x1024.png)
- [Previous Fred body rendering](evidence/next-build-graphics-2026-08-31/before-builds.png)
- [Previous predator rendering](evidence/next-build-graphics-2026-08-31/before-predators.png)

The before images were rendered from an isolated `git archive` of the starting
commit, not by modifying the protected Build 4 checkout. The capture uses exact
resolution SubViewports with the existing 1280 × 720 logical game layout and
letterboxing. Phone/tablet aspect captures are desktop-rendered evidence, not
screenshots from physical iPhone/iPad hardware. Capture fixtures disable hazards
and audio and freeze simulation to make visual comparisons repeatable.

## Executed validation

Tests used fictional data and isolated APPDATA/LOCALAPPDATA beneath the ignored
`builds/graphics-review` directory. Owner save files were not used by test runs.

| Check | Actual result |
| --- | --- |
| Full Godot deterministic regression | 30 suites; 11,860 passed, 0 failed |
| New character surface/costume-fit suite, included above | 3,463 passed, 0 failed |
| Pause native/emulated-input regression, included above | 36 passed, 0 failed |
| Golden Egg Level 10 regression, included above | 122 passed, 0 failed |
| Game Center adapter regression, included above | 42 passed, 0 failed |
| Existing authored Fred rig regression, included above | 2,061 passed, 0 failed |
| Predator depth regression, included above | 349 passed, 0 failed |
| Lives/routes/HUD layout, included above | 76 passed, 0 failed |
| Python tooling regression | 5 scripts; 76 checks passed |
| Local readiness inventory | 149 artifacts; 8 fixtures; Core 0.5.1 |
| Godot headless project import | Passed |
| Real rendered capture | 6 PNGs; 120 measured gameplay draws; no session mutation |
| Geometry stress | 10,000 surface meshes in 179 ms; 0 bytes retained growth |

The new suite covers finite and bounded geometry, triangle coverage, deterministic
lighting, cache isolation, transparent highlight edges, retained neck endpoints,
fish body bounds, and every existing body/attire/animation-state/facing combination
for mouth clearance. Thirteen extra HUD checks reserve depth-label space and
measure all three depth-state strings against its width. CI includes the new
graphics suite; no remote CI run or GitHub push is claimed.

Some existing headless suites still report ObjectDB/resource-in-use diagnostics
at shutdown (2–5 objects, 1–2 resources). These are not being represented as a
clean engine log. No script/parse failures or failed assertions occurred. The
new character suite, Pause suite, Golden Egg suite and rendered capture logs
were clean. Earlier readiness caught the not-yet-written report link; it was
resolved by adding this report and rerunning readiness.

Full final Godot logs: `builds/graphics-review/hud-final-validation`.
Rendered logs: `builds/graphics-review/hud-final-render` and subsequent review
capture logs under `builds/graphics-review`. These local logs are ignored, not
shipped assets. Durable PNGs are stored beside this report.

## Performance boundary

Geometry detail adapts to feature size (8/16/24 ellipse points). Triangle-index
layouts are reused through a cache bounded by contour count, independent of
position, pose or elapsed play time. Lighting uses Godot's documented
[CanvasItem triangle-array drawing](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-canvas-item-add-triangle-array),
without adding per-surface scene nodes, materials or textures.

On this Windows NVIDIA T1000 desktop, the isolated previous renderer measured
10.224 ms p95 game draw-call CPU time across 120 draws. Optimized candidate runs
measured 9.429–14.949 ms across the same bounded sample; concurrent headless
testing and desktop load add noise. This is a modest but variable CPU cost,
not proof of identical performance or a frame-rate guarantee. The latest
final capture measured 9.429 ms p95 game draw CPU and 0.866 ms average for a
predator draw (`builds/graphics-review/caption-final-render/capture.log`). Node count did not
grow during capture, and reported static memory decreased after cleanup.

These numbers do not include complete GPU/frame presentation or establish
mobile performance. Physical iPhone/iPad frame pacing, thermal behavior and
worst-case late-level predator loads remain acceptance gates.

## Preserved boundaries

- No changes to collision, movement, difficulty, level progression, Golden Egg
  eligibility/transport, Game Center, save schema, audio, catalog IDs/prices,
  touch-control positions, Pause logic, store identity or build/version numbers.
- Godot 4.7.1, Core 0.5.1 and `fred_save` v1 remain pinned.
- Protected `fred-myers-app-build-2` remains clean at commit
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner primary save remains 592 bytes, SHA-256
  `20de8645123bfecd973d3a1a1f82a4be4f9731b3a015246c64908a07b40f1318`.
- Owner backup remains 592 bytes, SHA-256
  `89056c555969729ab89e17b78e82b0f632f55aa9fff375b83dcbec03c9793c76`.
- Existing desktop shortcut remains unchanged, SHA-256
  `f75617364ead7899d8eceb2a8d3d87ced2a73f2fa6d3f9347182ecf563a28d2a`.
  It was not silently redirected to this unshipped candidate.
- No GitHub push/visibility change, Apple access, archive, signing, upload,
  submission, public deployment or release occurred in this graphics task.

The canonical `shared-build-process` skill and process were followed for scope,
identity preservation and isolated validation. Its audit returns
`MIGRATION_REQUIRED` for this candidate against process `1.6.0-candidate.1`:
22 missing/different implementation or identity-adapter entries. The native
Game Center build/validation helpers differ, and current shared release tools
are missing. This is an explicit, separate migration gate before a future Apple
candidate; documentation alone does not make this app process-compliant.
No new uploader or migration was invented during the art pass.

## Reproduce the local visual review

From this checkout, with Godot 4.7.1 and Python available:

1. Set APPDATA and LOCALAPPDATA to fresh, ignored test folders under
   `builds/graphics-review`; do not run review captures against the owner's data.
2. Run `python tools/validate_readiness.py`.
3. Run `godot --headless --path godot --script res://tests/run_character_surface.gd`.
4. Run every existing `godot/tests/run_*.gd` suite in the same isolated profile.
5. Run the rendered capture (without `--headless`):
   `godot --path godot --script res://tools/capture_next_build_graphics.gd -- --output=<absolute-review-output-directory>`.
6. Review the six PNGs and the process exit/log. This does not launch an Apple
   build or update the desktop shortcut.

Next acceptance work is owner visual review and real device testing of animation,
readability, touch interaction, Pause/background/resume, both landscape rotations
and performance. Golden Egg local tests are not evidence of a real website
leaderboard submission. Apple delivery remains a separately validated process.
