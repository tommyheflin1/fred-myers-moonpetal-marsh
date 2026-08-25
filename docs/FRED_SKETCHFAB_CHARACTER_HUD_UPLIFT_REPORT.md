# Fred character, predator, and HUD uplift report

Date: 2026-08-24

## Candidate boundary

- Branch: `codex/fred-build4-sketchfab-visual-hud-fix`
- Starting commit: `0fe2c71834db19bf4979ba614d63ad2e38d9c4a9`
- Scope: Fred, attire, predator presentation and the crowded gameplay header only
- Delivery: local owner-test candidate; no push, pull request, Apple upload,
  signing, publication, or release

## Implemented result

- The objective, campaign, route summary, energy label, energy meter, Pause,
  and Exit now occupy explicit non-overlapping bands at the 1280 by 720 and
  960 by 540 review layouts.
- Fred received additional cranial, jaw, throat, hindquarter, toe-webbing, and
  wet-skin planes. Attire received a fitted inner collar, shoulder piping, and
  bound hem below an explicit mouth exclusion boundary.
- Bass, pike, snake, and heron presentation gained additional species-readable
  silhouette, scale, fin, plate, feather, and surface layers.
- Sketchfab sources were used as reference-only anatomy research. No model,
  texture, thumbnail, archive, viewer, or remote dependency was downloaded or
  bundled. The source and license register is in
  `docs/SKETCHFAB_ART_REFERENCE_AND_ATTRIBUTION.md`.

Collision, deterministic gameplay, difficulty, Golden Egg rules, Game Center,
touch intent, progression, lives, `fred_save` v1, and Mobile Game Core were not
changed by this slice.

## Automated validation

- Complete matrix: **8,348 passed, 0 failed across 28 suites**.
- Fred rig: **2,061 passed, 0 failed**.
- Phone/header layout: **63 passed, 0 failed**.
- Predator depth and presentation: **349 passed, 0 failed**.
- Golden Egg Level 10 regression: **122 passed, 0 failed**.
- Fred rig 10,000-update stress: 379 ms, 4,620 bytes measured memory growth,
  zero node/resource/orphan growth.
- Predator 10,000-update stress: 14 ms, zero measured memory growth.
- Godot 4.7.1 import passed.
- Android source configuration validation passed for landscape phone/tablet,
  arm64-v8a plus x86_64, package `com.flinsappvault.fredmyers.dev`, and zero
  requested permissions.
- iOS source preparation validation passed for iPhone and iPad, build number 3,
  bundle ID `com.flinsvault.fredmyers`, and minimum iOS 15. Signed archive,
  physical-device, live Game Center, and Apple upload evidence remain separate
  owner-controlled gates.

## Visible Windows review

Real Godot OpenGL rendering was inspected at 1280 by 720 and 960 by 540. The
Level 10 header bands remained separate; Fred's mouth remained visible in play
and in the customizer; energy, lives, objectives, touch controls, predators,
and the Moonpetal exit remained readable. Captures were generated in the
isolated local review directory
`%LOCALAPPDATA%\Temp\fred-build4-sketchfab-uplift-review`.

This is Windows owner-review evidence, not physical phone/tablet acceptance.

## Integrity

- Mobile Game Core 0.5.1 tree:
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary save remained 592 bytes with SHA-256
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save remained 592 bytes with SHA-256
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Owner save timestamps remained 2026-07-22 UTC.
- The existing Golden Egg path stayed green in all 122 focused checks.

