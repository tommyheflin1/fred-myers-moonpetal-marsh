# Feature inventory

## Browser prototype evidence

| Capability | Current behavior | Migration classification |
| --- | --- | --- |
| Story | Recover the Sunken Acorn before dawn to save Fred's family pond; ending restores the Moonpetal and dawn | Preserve and expand through data-driven story beats |
| Levels | Five sequential chapters: Lily Leap, The Deep, Firefly Fen, Predator Pass, Moonpetal Rise | Preserve IDs/titles; redesign as testable level resources |
| Frog | Custom-drawn green frog with head, body, eyes, pupils, legs and facing | Rebuild as authored 3D frog model/rig; current visual is reference only |
| Movement | Device-neutral intent adapter plus touch-and-drag playfield steering | Preserve direct touch steering; keep future platform adapters disabled until separately reviewed |
| Eating | Collision and nearby click/tap consume bugs; bugs restore energy | Implement tongue/targeting with readable range/cooldown |
| Energy boost | Space/Shift or touch; drains energy and regenerates | Preserve; make rates data-driven and deterministic |
| Surface/dive | Q/E described; surface/dive UI; fish active underwater | Preserve as explicit state machine with depth limits |
| Hiding | Two holes grant temporary invincibility and energy recovery | Preserve; replace hidden invincibility with readable safe-state rules |
| Predators | Herons/snakes above, pike/bass below; chase and cost hearts | Preserve species fantasy; add telegraphs, fairness budgets, difficulty profiles |
| Lily pads | Drawn throughout the surface pond | Convert to 3D traversal/support surfaces; define jump and landing rules |
| Objectives | Bug count and coordinate gates drive chapter transitions | Replace with stable objective/checkpoint IDs |
| Failure | Three hearts; caught Fred respawns; zero hearts shows gobbled screen | Preserve tone; persist only durable checkpoints |
| Victory/replay | Story ending and play-again reset | Preserve; add completion record and continue/new-adventure choice |
| HUD | Chapter, objective, hearts, bug count, boost meter, depth controls | Rebuild with accessible scale/contrast/reduced-motion options |
| Responsiveness | Desktop and coarse-pointer layouts | Validate portrait/landscape policy, safe areas, touch target sizes |
| Installability | Web manifest exists; hosted public browser game | Keep browser reference; Godot export plan covers Windows, Web, Android, iOS |

## Missing or not yet proven

- True 3D world, model, rig, animations, camera, lighting, water shader, underwater post-processing, VFX, original predator assets, UI icon set, audio/music, haptics.
- Save/reload, schema migrations, checkpoint recovery, cloud sync, achievements, settings persistence, telemetry consent/provider, localization.
- Data-driven level loader, deterministic tests, reachability validation, gameplay accessibility review, controller input, pause/lifecycle recovery.
- Web export cross-origin/storage behavior, Windows package, Android APK/AAB, iOS export/signing, physical-device QA, store assets/submissions.

## Reference acceptance baseline

Superseding owner direction defines Campaign 1 as a touch-only, 100-level,
age-five-accessible PG adventure. The Windows pointer must emulate the same
touch path; direct keyboard gameplay is not part of the player contract.
