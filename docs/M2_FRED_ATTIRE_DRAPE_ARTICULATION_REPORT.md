# M2 Fred attire drape and articulation uplift

Updated: 2026-08-18

## Outcome

Revision 17 replaces the remaining rigid costume treatment with clothing that
follows Fred's authored anatomy and deterministic animation poses. The four
existing save-compatible outfits keep their identities, but now use softer
torso contours, pose-aware folds, material-specific lighting, anatomical
armholes, sleeves attached to the real forelimbs, and knee wraps attached to
the real hind-leg joints. The eyewear is smaller and better fitted to Fred's
eye spacing, with slimmer straps, gaskets, bridges, hinges, pads, and lenses.

This remains a Fred-owned vector presentation layer. It does not change
collision, level difficulty, movement, touch targets, tongue reach, lives,
coins, rewards, progression, `fred_save` v1, or Mobile Game Core.

## Tailoring contract

Each outfit declares a finish, drape, roughness, and flexibility profile:

- Marsh Runner: matte breathable knit with athletic stretch;
- Trail Scout: waxed woven canvas with structured utility drape;
- Moon Champion: soft moonlit satin with fluid competition drape; and
- Firefly Hero: reinforced technical knit with supportive hero drape.

The transient attire-motion snapshot derives bounded stretch, compression,
fold bias, and secondary-motion scale from the immutable rig pose. Reduced
motion sharply limits secondary cloth response while retaining the same
silhouette, seams, material identity, eyewear, and non-color cues. No attire
motion value is written to saves or fed back into gameplay.

## Validation

- Focused authored-rig suite: 1,052 passed, 0 failed.
- Complete deterministic matrix: 22 suites, 4,846 passed, 0 failed.
- Every four-outfit by 23-state combination checks bounded cloth motion,
  mouth clearance, stable anchors, and presentation-only invariance.
- The 10,000-update pose loop completed in 376 ms with 4,620 bytes measured
  memory growth, one retained object, and zero resource, node, or orphan
  growth. The standalone test process retained the pre-existing two ObjectDB
  and one resource shutdown warnings; no runtime script warning appeared.
- Real Godot rendering was inspected through the customizer at 1280x720,
  active normal-motion gameplay at 960x540, and reduced-motion gameplay at
  640x360. Idle, leap landing, surfacing, tongue extension, and boost states
  retained limb attachment, face clearance, readable Fred silhouette, and a
  separated HUD/action row.

Evidence captures:

- `godot/docs/evidence/app-build-1-r17-attire-marsh_runner.png`
- `godot/docs/evidence/app-build-1-r17-attire-trail_scout.png`
- `godot/docs/evidence/app-build-1-r17-attire-moon_champion.png`
- `godot/docs/evidence/app-build-1-r17-attire-firefly_hero.png`

The focused implementation commit is
`128e7cda434fad814e9b26adb08749dcfb939738`; the reproducible Android package
source is `b56005e1ec4f2024330bdeb11b1cb24d4dc2b4a8`.

## Owner-build boundary

The local revision 17 development APK is 84,907,755 bytes with SHA-256
`46F188D68058B58D697A950CA3C0EE41BF5575AA6FAE242BAB429EAFF8CB3798`,
version `0.2.1-app-build-1-r17` (`20117`). It remains debug signed, requests
zero Android permissions, supports arm64-v8a and x86_64, and is not a release
or physical-device acceptance result. The configured remote is public, so the
branch remains local and unpushed.

Milestone percentages remain unchanged. Owner visual acceptance and physical
phone/tablet testing remain separate gates.
