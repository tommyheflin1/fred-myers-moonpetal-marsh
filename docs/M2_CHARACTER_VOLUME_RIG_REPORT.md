# M2 all-character volume, surface, and joint uplift

Updated: 2026-08-18

## Scope

App Build 1 revision 15 begins at clean local commit
`86f700aedf45a275b072ba1019aaab893661033f`. It deepens the current articulated
Fred, fish, snake, heron, bug and life-fairy rigs with layered volume,
species-specific surface response, integrated joints and facial depth. The
work remains local and unpushed because the configured GitHub repository is
public.

This is a bounded Fred-owned presentation pass. It changes no collision,
fixed-tick gameplay, difficulty, rewards, lives, fairy rules, progression,
touch targets, save-v1 fields, Core code, networking or providers. The vector
characters remain review-stage art rather than a final production-art claim.

## Dimensional rig contract

`FredWildlifeAnimationRig.surface_profile()` returns a deterministic,
fail-closed, presentation-only material snapshot. Every wildlife family exposes
at least nine volume layers plus stable key-light, underside-shadow, rim,
joint-depth and facial-depth channels. Species keep distinct treatment:

- bass, pike and muskie use overlapping scale/muscle lighting, dimensional fin
  roots, gill covers, jaw volume and wet specular response;
- the marsh snake uses overlapping muscular segments, keeled-scale highlights,
  a deeper brow, cheek and lower jaw, and a connected spinal silhouette;
- the heron uses layered contour/primary feathers, shoulder volume, S-neck
  lighting, dimensional head and highlighted knee/ankle joints;
- bugs use segmented shell volume, translucent four-wing roots and visible leg
  joints;
- the life fairy uses moonlit head/torso volume, translucent four-wing roots,
  elbow/knee joints, crown and glow;
- Fred retains the authored 34-node/23-pose rig while adding cheek and brow
  volume, subsurface belly shading, wet-skin rim light and integrated shoulder,
  elbow and knee caps.

Reduced motion preserves the same silhouettes and depth information while
restraining moving specular cues to ten percent. Unsupported kinds, invalid
indices and non-finite time fail closed. No material or joint-depth field is
saved.

## Focused automated evidence

- Godot 4.7.1 import/parser gate: passed.
- Fred rig suite: 527 passed, 0 failed, including sixteen inspectable realism
  features, nine-layer surface declaration, integrated joints/facial depth and
  presentation-only invariance.
- Predator-depth/identity suite: 337 passed, 0 failed. It covers all seven
  wildlife families, nine-to-eleven volume layers, deterministic surfaces,
  reduced-motion lighting, fail-closed inputs and 100 repeated 240-tick traces.
- Complete deterministic matrix: 22 suites, 4,321 passed, 0 failed in 15.47
  seconds using isolated temporary AppData for every suite.

The final complete matrix, readiness, package identity, hashes and exact source
commit are recorded after execution in `APP_BUILD_1_TEST_REPORT.md`.

## Real Windows review

Computer Use inspected the actual Godot 4.7.1 runtime:

- 1280 by 720 Level 100, across two live frames: species retained distinct
  silhouettes while scale, feather, shell, skin and joint layers read as body
  volume rather than one flat moving shape.
- 960 by 540 Level 1: Fred, bass and bugs remained readable with separated
  Objective, Lives, Energy, Pause, Exit and bottom touch actions.
- Reduced-motion 640 by 360 Level 1: depth cues remained visible without button
  overlap; a real pointer contact exercised the mobile screen-touch MUNCH path.

Physical Android/iOS rendering, production character assets, provider
activation, signing, store submission, publication and release remain separate
protected gates. No milestone percentage is awarded for this local slice.
