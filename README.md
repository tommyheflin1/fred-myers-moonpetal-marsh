# Fred Myers and the Moonpetal Marsh

Fred Myers is a story-driven frog adventure currently playable as a five-level browser prototype. This repository is the independent Fred product repository within **The Flins App Vault**. Fred consumes shared platform capabilities from `mobile-game-core`; Fred-specific movement, predators, environments, story, levels, tuning, and assets stay here.

## Next build: Pause fix (2026-08-30)

The 2026-08-31 local graphics pass adds smooth character shading, more natural
webbed feet, richer attire materials, distinct fish anatomy, a continuous snake
body, feathered heron wings, and unobscured depth text. It retains the Pause fix.
See [graphics changes and actual render evidence](docs/NEXT_BUILD_GRAPHICS_UPLIFT.md).

The next-build candidate on `codex/fred-next-build-pause-fix` fixes duplicate
touch/mouse Pause toggles and clears held controls when pausing or resuming.
See [reproduction, validation, and delivery handoff](docs/NEXT_BUILD_PAUSE_FIX.md).
This is a local source update, not a new Apple binary. The submitted Build 4
checkout and existing desktop owner-test shortcut remain unchanged.

## Current milestone

Milestone M1 is accepted on `main`; the current local M2 owner candidate adds
the deterministic Fred rig, leap/swim/depth/tongue/boost/camera traversal,
surface/diving/underwater predator traversal with depth-aware collisions,
species-specific bass, pike, muskie, snake and heron presentation,
100-level progression foundation, stackable fairy lives, six rotating route
formations and marsh treatments, coin-backed Fred customization, sport-character
and wildlife presentation, continuous leap traversal over predators, mobile-first UI, an Apple Game Center scoring adapter,
the required Moonpetal hero story and touch-first instructions, and a
development-only Android debug artifact. The branch remains local because the configured GitHub
repository is public. No M2 push, production build, signing, deployment, store
submission, or release is claimed.

Campaign 1 is the complete 100-level Moonpetal Promise arc. Each numbered
level has a deterministic difficulty step, while the early chapters teach one
idea at a time and the Level 100 caps preserve reaction time, recovery grace,
safe landing space, and bounded hazards for the age-five design target. The
current player build is touch-only and PG; the Windows mouse follows the same
touch path for owner testing.

Owner direction on 2026-08-03 starts **App Build 1** as a local testing phase.
It packages the exact validated candidate under the existing development-only
Android identity. App Build 1 is not a production build, store submission,
release, deployment, or physical-device acceptance claim.

- Play: https://fred-myers-moonpetal-marsh.tommyheflin.chatgpt.site/
- Current repository: https://github.com/tommyheflin1/fred-myers-moonpetal-marsh
- Preferred future name: `tommyheflin1/fred-myers-adventure` (rename only with owner approval and after link-impact review)
- Engine target: Godot `4.7.1.stable.official.a13da4feb`
- Core pin: Mobile Game Core `0.5.1`
- Save schema proposal: `fred_save` version `1`

## Repository role

The App Vault remains a collection of independently releasable repositories:

```text
The Flins App Vault/
  mobile-game-core/
  mobile-game-template/
  shared-game-backend/
  snake-reactor/
  fred-myers-adventure/
```

This repository owns Fred gameplay. Core owns only reusable, game-neutral services. The backend is optional and injected; the complete story must remain playable offline without an account.

## Discovery package

- [Architecture assessment](docs/ARCHITECTURE_ASSESSMENT.md)
- [Feature inventory](docs/FEATURE_INVENTORY.md)
- [Core migration matrix](docs/CORE_MIGRATION_MATRIX.md)
- [Save contract](docs/SAVE_CONTRACT.md)
- [Testing and build plan](docs/TEST_BUILD_PLAN.md)
- [Migration and milestone roadmap](docs/MIGRATION_ROADMAP.md)
- [Evidence report](docs/EVIDENCE_REPORT.md)
- [Milestone M1 report](docs/MILESTONE_M1_REPORT.md)
- [M2 camera follow evidence](docs/M2_CAMERA_FOLLOW_REPORT.md)
- [M2 locomotion animation evidence](docs/M2_LOCOMOTION_ANIMATION_REPORT.md)
- [M2 authored Fred rig evidence](docs/M2_AUTHORED_FRED_RIG_REPORT.md)
- [M2 marsh visual, tongue, lives, and touch evidence](docs/M2_MARSH_VISUAL_UPLIFT_REPORT.md)
- [M2 Android development export evidence](docs/M2_ANDROID_DEVELOPMENT_EXPORT_REPORT.md)
- [M2 lives, alternating routes, backgrounds, and phone layout evidence](docs/M2_LIVES_ROUTES_PHONE_LAYOUT_REPORT.md)
- [M2 physical Android owner-acceptance handoff](docs/M2_PHYSICAL_ANDROID_OWNER_HANDOFF.md)
- [Current desktop owner-test handoff](docs/DESKTOP_OWNER_TEST.md)
- [Desktop handoff evidence](docs/M2_DESKTOP_OWNER_HANDOFF.md)
- [Entertaining realistic Fred title-art uplift](docs/M2_TITLE_ART_UPLIFT.md)
- [Fred application-icon uplift](docs/M2_APP_ICON_UPLIFT.md)
- [App Build 1 local test evidence](docs/APP_BUILD_1_TEST_REPORT.md)
- [App Generation Engine adoption and Apple readiness](docs/APP_GENERATION_ENGINE_APPLE_READINESS_STATUS.md)
- [Fred iOS unsigned handoff plan](docs/IOS_HANDOFF_PLAN.md)
- [App Store Connect and TestFlight Build 1 package](docs/APP_STORE_CONNECT_BUILD_1_PACKAGE.md)
- [Fred privacy policy content draft](docs/FRED_PRIVACY_POLICY_DRAFT.md)
- [Fred support content draft](docs/FRED_SUPPORT_DRAFT.md)
- [iOS App Build 1 handoff report](docs/IOS_APP_BUILD_1_HANDOFF_REPORT.md)
- [M2 mobile-first product and visual uplift](docs/M2_PRODUCT_UPLIFT_REPORT.md)
- [M2 touch-first phone and tablet controls](docs/M2_TOUCH_FIRST_PHONE_TABLET_CONTROLS.md)
- [M2 Fred hero story and touch-first instructions](docs/M2_HERO_STORY_INSTRUCTIONS.md)
- [Campaign 1 touch-only, age-five, and PG contract](docs/M2_CAMPAIGN_ONE_TOUCH_PG.md)
- [Fred rig and child-readable attire uplift](docs/M2_FRED_ATTIRE_VISUAL_UPLIFT.md)
- [Fred tailored attire material and fit uplift](docs/M2_FRED_ATTIRE_MATERIAL_FIT_REPORT.md)
- [Fred attire drape and articulation uplift](docs/M2_FRED_ATTIRE_DRAPE_ARTICULATION_REPORT.md)
- [Fred anatomical attire-cut uplift](docs/M2_FRED_ATTIRE_ANATOMICAL_CUT_REPORT.md)
- [Fred mouth-clear rig and graphics Revision 21](docs/M2_FRED_RIG_GRAPHICS_REV21_REPORT.md)
- [Realistic marsh-current visual uplift](docs/M2_WATER_CURRENT_VISUAL_REPORT.md)
- [Predator surface and underwater traversal](docs/M2_PREDATOR_DEPTH_TRAVERSAL.md)
- [Fred and wildlife character-rig realism uplift](docs/M2_CHARACTER_RIG_REALISM_REPORT.md)
- [Sketchfab art reference and attribution boundary](docs/SKETCHFAB_ART_REFERENCE_AND_ATTRIBUTION.md)
- [Fred Sketchfab-reference character and HUD uplift](docs/FRED_SKETCHFAB_CHARACTER_HUD_UPLIFT_REPORT.md)
- [All-character deterministic articulation uplift](docs/M2_ALL_CHARACTER_ARTICULATION_REPORT.md)
- [All-character volume, surface, and joint uplift](docs/M2_CHARACTER_VOLUME_RIG_REPORT.md)

## Godot desktop owner candidate

`godot/project.godot` launches the current Fred owner candidate. The exact Core
0.5.1 add-on is vendored under `godot/addons/mobile_game_core` and remains
unchanged; Fred-owned code lives under `godot/scripts`. The single desktop
shortcut `Fred Myers Owner Test` is pinned to an exact clean commit plus a
tracked-file SHA-256 manifest and verifies Godot, Core, project, and save
boundaries before launch. Run
`python tools/validate_desktop_owner_handoff.py` for its static safety contract
and see the desktop handoff for the owner acceptance route.

The local `Android Development` preset now produces an ignored debug APK for
arm64 and x86_64 validation. It adds no Android permissions or production
signing. API 35 phone-emulator presentation remains blocked by the tested
SwiftShader GLES3 uniform limit; see the Android evidence report. No Android
release or physical-device acceptance is claimed.

The current owner candidate also preserves the active level across nonfatal
life loss, resumes from the midpoint checkpoint when reached, alternates
left-to-right and right-to-left routes, cycles six whole-screen formations and
six marsh treatments, and uses one non-overlapping layout contract for the HUD,
Exit action, Fred start area, and landscape touch controls.

App Build 2 uses a controller-style touch layout on phones and tablets: the
right control pad steers Fred while the four large circular Munch, Leap, Boost,
and Dive/Surface actions form a separate wheel on the left. Pause and Exit
remain isolated in the top HUD, and inactive controls hide behind countdown and
pause overlays. Starting the adventure requires two short,
touch-friendly screens: the Moonpetal Promise explains why Fred must become the
hero in every little frog's dreams, and How to Be a Marsh Hero teaches the
movement, action, danger, life, fairy, objective, coin, and customization rules.
The desktop owner runtime can display this same interface and maps pointer
dragging through the exact touch-control path for review.

The physical-phone handoff is hash guarded and read-only by default. With no
authorized phone connected it returns `DEVICE_NOT_CONNECTED / UNVERIFIED`;
install, launch, and bounded Fred-only diagnostics require an explicit physical
serial plus owner/save acknowledgements.

The iOS source boundary now includes an unsigned iPhone+iPad preset for version
1.0 build 1, an offline-safe native Game Center adapter and a hash-guarded Mac
handoff. Run `python tools/validate_ios_preparation.py` on Windows. After the
exact commit is frozen, `python tools/prepare_ios_handoff.py
--expected-commit <SHA>` creates the ignored transfer bundle. The authenticated
Mac runner is the only path that may sign and upload the owner-approved first
TestFlight build; App Review and public release remain separate gates.

## Legacy source

`fred-myers-source.zip` is the original GitHub-uploaded browser source artifact. The deployed site and the separately maintained Sites checkout are the current runtime reference. Do not treat the zip as a reproducible Godot project.
