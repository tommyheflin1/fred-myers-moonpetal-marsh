# M2 Fred application-icon uplift

Date: 2026-08-02

Fred now has a dedicated, playful application icon aligned with the upgraded
title screen. The square master shows the same realistic ballerina-inspired
bullfrog leaping above a luminous lily pad, framed by the Moonpetal Marsh moon,
fireflies, reeds, and glowing flower. The close mascot crop, bright eyes, bold
silhouette, and green/teal/gold contrast remain readable at small sizes.

## Assets and use

- `godot/assets/art/fred-app-icon-v1.png`: 1,254 by 1,254 square master for
  Godot and future Android/iOS development builds.
- `godot/assets/art/fred-app-icon-v1.ico`: Windows package containing 16, 24,
  32, 48, 64, 96, 128, and 256-pixel icon sizes.
- `godot/project.godot` now uses the square PNG as the project icon.
- The single `Fred Myers Owner Test.lnk` uses the multi-size ICO directly.

The built-in image-generation workflow used the v3 title art as the character
and brand reference. Final prompt intent: create a square professional mobile
game icon with the same realistic Fred in a joyful mid-leap dance pose, strong
small-size silhouette, safe rounded-mask padding, moonlit marsh colors, no
text, watermark, extra frog, or human anatomy.

This source configuration prepares the new identity for later phone builds,
but the existing Android APK is not rebuilt or claimed here. Signing, App
Build 1, store packaging, and physical-device acceptance remain separate.

## Validation

- Godot 4.7.1 imported the square master successfully.
- Complete gameplay matrix: 17 suites, 2,190 passed, 0 failed.
- Readiness inventory: 61 artifacts, eight fixtures, Core 0.5.1.
- The 38-check desktop handoff validator confirms the PNG dimensions, ICO
  directory, all eight standard icon sizes, project icon reference, and
  shortcut wiring.
- Android development configuration still validates its identity, landscape
  orientation, arm64/x86_64 policy, SDK policy, and zero requested permissions.
