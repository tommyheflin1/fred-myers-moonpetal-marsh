# Fred Myers and the Moonpetal Marsh

Fred Myers is a story-driven frog adventure currently playable as a five-level browser prototype. This repository is the independent Fred product repository within **The Flins App Vault**. Fred consumes shared platform capabilities from `mobile-game-core`; Fred-specific movement, predators, environments, story, levels, tuning, and assets stay here.

## Current milestone

Milestone M1's playable greybox foundation is complete at its evidence gate on branch `milestone/m1-greybox-foundation` and is open for review against `main` in [draft PR #3](https://github.com/tommyheflin1/fred-myers-moonpetal-marsh/pull/3). The browser prototype remains the five-level reference; the Godot build now proves Lily Leap, deterministic session logic, input intents, save/recovery, and offline startup. No merge, mobile build, or production release is claimed.

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

## Godot M1 foundation

`godot/project.godot` launches the Lily Leap greybox. The exact Core 0.5.1 add-on is vendored under `godot/addons/mobile_game_core` and remains unchanged; Fred-owned code lives under `godot/scripts`. Run `Godot --headless --path godot --script res://tests/run_tests.gd` for the deterministic suite. Export presets, signing, and production distribution remain deferred.

The local `Android Development` preset now produces an ignored debug APK for
arm64 and x86_64 validation. It adds no Android permissions or production
signing. API 35 phone-emulator presentation remains blocked by the tested
SwiftShader GLES3 uniform limit; see the Android evidence report. No Android
release or physical-device acceptance is claimed.

The current owner candidate also preserves the active level across nonfatal
life loss, resumes from the midpoint checkpoint when reached, alternates
left-to-right and right-to-left routes, cycles four marsh treatments, and uses
one non-overlapping layout contract for the HUD and landscape touch controls.

## Legacy source

`fred-myers-source.zip` is the original GitHub-uploaded browser source artifact. The deployed site and the separately maintained Sites checkout are the current runtime reference. Do not treat the zip as a reproducible Godot project.
