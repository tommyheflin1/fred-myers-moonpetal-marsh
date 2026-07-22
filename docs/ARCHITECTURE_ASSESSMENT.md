# Architecture assessment

Reviewed 2026-07-21 from the live Fred site and current checkouts of Mobile Game Core, Mobile Game Template, Shared Game Backend, and Snake Reactor.

## Decision

Use a **strangler migration**, not a direct rewrite. Keep the public browser prototype available as the behavioral and visual reference while building a new Godot application from the current template. Preserve one independent Fred repository and vendor a pinned Core release. Do not put Fred scenes, predators, level definitions, story state, physics, art, or tuning in Core.

## Current Fred architecture

The reference game is a React 19/TypeScript canvas application built by Vinext/Vite and hosted as a PWA-style website. One client component owns input, simulation, drawing, story transitions, HUD, and state. The visual treatment is 2D canvas with gradients, shadows, scaling, and emoji predators; it reads as 3D-styled but is not a 3D engine scene. Five chapters run in one pond coordinate space. State is memory-only and resets on reload.

Strengths: immediately playable, responsive pointer/keyboard/touch controls, coherent story arc, clear HUD, surface/underwater states, energy boost, predators, holes, bugs, and a public reference URL.

Migration liabilities: simulation and rendering are coupled; frame updates are delta-scaled inconsistently; chapter transitions are coordinate triggers; no schema/versioned save, checkpoint, analytics contract, deterministic seed, data-driven levels, accessibility settings, native export project, or gameplay unit boundary exists.

## App Vault target architecture

| Layer | Owner | Fred use |
| --- | --- | --- |
| Game-neutral lifecycle, atomic save/backup, settings, achievements, inventory, wallet, progression, optional identity/cloud/leaderboards | `mobile-game-core` 0.5.1 | Vendored, unchanged, exact pin |
| Starter structure and Core compatibility smoke | `mobile-game-template` | Source for the initial Godot project |
| Story, levels, 3D pond, frog controller, tongue/eating, energy, surface/dive state, holes, predators, fish, checkpoints, Fred-specific accessibility and tuning | Fred repository | Product authority |
| Authenticated profile/save RPCs and optional verified score services | `shared-game-backend` | Optional adapter after offline MVP |
| Proven campaign/save/test/export patterns | `snake-reactor` | Reference only; do not copy Snake-specific semantics blindly |

Recommended Godot boundaries:

```text
FredApp
  GameServices (Core composition)
  AdventureSession (deterministic Fred state machine)
  StoryDirector (data-driven chapter/objective transitions)
  FrogController3D (input intent -> locomotion)
  SurfaceDiveController (surface / submerged / hole-safe states)
  PredatorDirector (telegraphed game-owned AI)
  CheckpointService (Fred wrapper over Core SaveService)
  Presentation (camera, animation, VFX, audio, HUD)
```

The deterministic session should be testable without rendering. Presentation observes state and emits intent. A fixed physics tick owns movement and collision. Level definitions should be data resources with stable IDs, prerequisites, objectives, checkpoint IDs, predator sets, and spawn transforms.

## Contracts discovered

- Core `SaveService` writes the consumer dictionary unchanged to `user://save.json` and retains `user://save.backup.json`.
- Consumers own top-level schema version and defaults. Core snapshot readers are additive and ignore unknown achievement/catalog IDs.
- Core cloud merges stable-union `completed_levels`, `owned_cosmetics`, and `unlocked_achievements`; it takes maxima for `unlocked_level`, `campaign_completions`, `prestige_rank`, and `lifetime_coins_earned`; wallet coins remain server-authoritative.
- Template CI checks exact agreement among `CORE_VERSION`, plugin constant, plugin manifest, and `GameConfig.framework_version`.
- Backend uses authenticated `sync_player_profile` and compare-and-swap `sync_player_save`; guests remain local/offline.
- No reusable analytics implementation exists. Snake Reactor documents modeled results and local evidence, not production player telemetry.

## Checkpoint architecture

Fred needs two distinct concepts:

1. **Durable adventure checkpoint**: written after an objective completes, a chapter transition finishes, an item is acquired, or a settings change occurs. It stores a safe respawn state, not arbitrary mid-collision state.
2. **Transient encounter restart**: in-memory snapshot at the start of the current encounter. Predator contact consumes a heart and restores this snapshot without creating a cloud write.

Durable writes go through Core SaveService. On load, validate IDs and bounds, then spawn at the latest valid checkpoint. If primary JSON fails, Core backup recovery applies. Cloud sync is opt-in and only at stable boundaries—not every physics frame.

## Analytics contract

No production analytics is approved or required for the offline MVP. Define a provider-neutral, disabled-by-default port with an allowlist of event names and non-identifying properties. Recommended events: `adventure_started`, `checkpoint_reached`, `level_completed`, `frog_caught`, `boost_depleted`, `dive_started`, `bug_eaten`, `adventure_completed`. Exclude free text, device identifiers, account IDs, precise location, and raw input traces. Local test sinks may assert event shape; enabling a production provider requires separate privacy/security approval.

## Tracker integration

Add Fred as its own project row and workstream in the App Vault documentation-only portfolio repository. Evidence must reference Fred commit SHAs and executed validations. Scores roll up from Fred technical tasks; the existence of this plan is not gameplay implementation credit. The Codex workstream is titled **Fred Myers and the Moonpetal Marsh** under **The Flins App Vault**.
