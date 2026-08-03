# M2 Fred application-icon uplift

Date: 2026-08-02

Fred now has a dedicated game-app icon aligned with the upgraded title screen.
The v2 square master replaces the photographic poster treatment with a compact,
stylized 3D mascot emblem: Fred dances above a luminous lily pad inside a
rounded moonlit-marsh frame. Large eyes, simplified forms, saturated
green/teal/gold color, and a bold silhouette remain readable at small sizes.

The v2 anatomy correction is explicit: Fred has exactly four visible limbs--
two front arms, one raised rear leg, and one supporting rear leg. The extra
bent rear leg present in the v1 source is not present in the active icon.

## Assets and use

- `godot/assets/art/fred-app-icon-v2.png`: 1,254 by 1,254 square master for
  Godot and future Android/iOS development builds.
- `godot/assets/art/fred-app-icon-v2.ico`: Windows package containing 16, 24,
  32, 48, 64, 96, 128, and 256-pixel icon sizes.
- The v1 files remain tracked as rollback evidence but are no longer active.
- `godot/project.godot` now uses the square PNG as the project icon.
- The single `Fred Myers Owner Test.lnk` uses the multi-size ICO directly.

The built-in image-generation workflow used the v1 icon as the character and
brand reference. Final prompt intent: redesign Fred as a professional square
mobile/PC game mascot emblem with simplified sculpted forms, safe rounded-mask
padding, moonlit marsh colors, no text, and exactly two front arms plus two
rear legs--never a fifth appendage.

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
