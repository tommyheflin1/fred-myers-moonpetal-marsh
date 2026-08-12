# M2 Fred application-icon uplift

Updated: 2026-08-12

Fred now uses the unique **Moonpetal Crest**, a purpose-built game identity
rather than a framed frog picture. Fred's readable two-eyed frog face sits
inside a gold-edged, notched lily-pad shield with a moonpetal crown, crescent
moon, teal water curl, and firefly sparks. The crest has only two visible front
hands and no ambiguous extra rear limbs.

The outer Windows silhouette is transparent and organic, so the desktop icon
does not read as a square photograph. Apple, Android, and Godot still require
a square source canvas for their own masking and launcher processing, so a
linked full-bleed platform master preserves the same crest over a moonlit navy
and teal field. No rounded-square mask is baked into that source.

## Assets and use

- `godot/assets/art/fred-moonpetal-crest-v3.png`: 1024 by 1024 RGBA crest with
  a transparent, non-square outer silhouette for desktop and future icon layers.
- `godot/assets/art/fred-app-icon-v3-platform.png`: 1024 by 1024 full-bleed
  platform master for Godot, Android, and future Apple Icon Composer work.
- `godot/assets/art/fred-app-icon-v3.ico`: Windows package containing 16, 24,
  32, 48, 64, 96, 128, and 256-pixel sizes derived from the transparent crest.
- Earlier icon versions remain tracked as rollback evidence but are inactive.
- `godot/project.godot` and the Android Development preset use the platform
  master; the single `Fred Myers Owner Test.lnk` uses the transparent ICO.

The built-in image-generation workflow was directed to create an original,
premium mobile-game emblem: a friendly anatomically credible frog face inside
an asymmetrical notched lily-pad crest, crescent moon, luminous moonpetal,
water curl, emerald/teal/gold palette, no text, no photographic frame, no
rounded-square container, and no duplicate or extra limbs. A second pass
created the linked full-bleed platform master without changing the crest.

This configuration prepares one consistent identity for Windows, Android, and
future Apple work. Apple Icon Composer layers, dark/tinted appearances, Mac
inspection, signing, store packaging, and physical-device acceptance remain
separate gates.

## Validation

- Godot 4.7.1 import, complete gameplay regression, readiness inventory, and
  exact App Build 1 r2 package results are recorded in
  `APP_BUILD_1_TEST_REPORT.md`.
- The desktop handoff validator checks both 1024-pixel sources, RGBA crest,
  eight ICO sizes, project reference, and one-shortcut wiring.
- The Android export contract explicitly binds the v3 platform master and
  preserves landscape, arm64/x86_64, SDK, and zero-permission policy.
