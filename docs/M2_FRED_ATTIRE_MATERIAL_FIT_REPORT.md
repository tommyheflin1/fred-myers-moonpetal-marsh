# M2 Fred tailored attire material and fit uplift

Updated: 2026-08-18

## Result

App Build 1 revision 16 replaces the four outfits' shared flat vest treatment
with fitted, outfit-specific vector clothing on Fred's authored 34-node rig.
The focused implementation is local commit
`fad55a06cb4ad5b2555fed114edeaef8b4fecac9`; Android packaging configuration is
`909e798c2f1bde96469dae915c53ba6f8536a96f`. The configured GitHub repository
is public, so neither commit is pushed and no PR is opened.

The save-compatible attire identifiers remain unchanged:

| Outfit | Material and construction | Face gear |
| --- | --- | --- |
| Runner Goggles | breathable marsh mesh, athletic panels and runner mark | gasketed sport goggles |
| Explorer Glasses | waxed trail canvas, zipper, scarf knot and utility pockets | hinged round glasses |
| Moon Champion Visor | moonweave athletic satin, crescent medal and split ribbon | inset moon visor |
| Firefly Hero Goggles | reinforced firefly knit, shoulder clasps and lined cape | padded hero goggles |

Every outfit uses a recessed under-panel, three fitted torso panels, ribbed
mouth-clear collar, shoulder gussets, side seams, waist band, top-stitching,
material grain and attire-specific closure. Eyewear uses five visible depth
layers: strap, gasket, frame, inset lens and reflection/hinge detail. Gear is
derived from Fred's body/head/eye/contact anchors and therefore follows facing,
leap, swim, dive, tongue, boost, damage, failure and reduced-motion poses.

This presentation contract adds no node, collision, fixed-tick, objective,
reward, touch target, progression, Core or save field. Fred's mouth, tongue
anchor, eyes and child-readable silhouette remain clear.

## Executed evidence

- Godot 4.7.1 import/parser gate: passed.
- Focused authored-rig suite: 660 passed, 0 failed.
- All four attire choices were checked across all 23 coordinator states and
  mirrored facing, including deterministic fit snapshots and mouth clearance.
- One hundred pose traces were byte-identical.
- The 10,000-rig-update loop completed in 359 ms with 4,620 bytes measured
  static-memory growth, one object delta, and zero resource, node or orphan
  growth.
- Complete deterministic matrix: 22 suites, 4,454 passed, 0 failed in 15.99
  seconds using isolated fictional AppData.
- Readiness validation: 93 artifacts, eight save fixtures, Core 0.5.1 and
  Godot 4.7.
- Actual Godot rendering was inspected at 1280 by 720, 960 by 540 and a
  reduced-motion 640 by 360 layout. The owner customizer showed fitted Runner
  gear in the live Windows runtime; live leap and dive states kept the gear
  attached; and real-renderer frames covered all four outfits without
  mouth/eye obstruction or HUD/action overlap.

Evidence frames:

- `godot/docs/evidence/app-build-1-r16-attire-marsh_runner.png`
- `godot/docs/evidence/app-build-1-r16-attire-trail_scout.png`
- `godot/docs/evidence/app-build-1-r16-attire-moon_champion.png`
- `godot/docs/evidence/app-build-1-r16-attire-firefly_hero.png`

## Android development artifact

The local revision 16 debug APK is
`builds/android/fred-myers-app-build-1-debug.apk`, 84,903,659 bytes, SHA-256
`2F05B4DAC8F6642875D23C13F6828BA451030FF83F409056C3D314A7C4F41DB4`,
package `com.flinsappvault.fredmyers.dev`, version
`0.2.1-app-build-1-r16` (`20116`). It retains arm64-v8a+x86_64, SDK 24/36/36,
landscape orientation, zero requested permissions and Godot debug signing.
Physical Android/iOS rendering and human touch acceptance remain unverified.
