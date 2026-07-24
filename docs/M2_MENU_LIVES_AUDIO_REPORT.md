# M2 Menu, Lives, Music, and Local Leaderboard Evidence

## Scope

This Fred-only owner candidate adds a large procedural title-screen presentation pass, owner-supplied menu and gameplay music, a deterministic five-life rule, an extra-life fairy, a five-second level countdown, an explicit exhausted-lives choice, and a functional offline leaderboard.

The supplied file named `The Marshland March.mp3` is treated as the requested main-menu song. `Marshland Chase.mp3` plays during gameplay. Both remain local game assets; no network or provider is activated.

## Behavior

- New games and level-one retries begin with five lives.
- Existing schema-v1 saves remain readable. Restored health is clamped to the supported one-to-five range; no schema field was added.
- A fairy appears once per level and restores exactly one missing life, never above five.
- Each level begins behind a deterministic five-second ready countdown.
- Exhausting all lives opens the full-screen `OH NO FRED!!!` frog-splat presentation.
- `Try Again?` creates a clean level-one session with five lives.
- `Go Home?` returns to the title and restores menu music.
- Completing a level records a sanitized fictional/local score in a bounded top-ten board.
- The leaderboard is explicitly offline. Secure cross-device ranking remains gated on the approved shared authenticated backend and anti-cheat architecture.

## Validation

Godot `4.7.1.stable.official.a13da4feb` imported the project and both MP3 assets successfully.

Nine automated suites pass:

- base/session/save/gameplay: 32
- physical-key event regression harness: 22
- save stress/security: 31
- save/recovery feedback: 28
- visual clarity/reduced motion: 30
- 100-level progression foundation: 645
- leap traversal: 52
- depth traversal: 64
- menu/music/lives/fairy/countdown/failure/leaderboard: 27

Total: **931 passed, 0 failed**.

The focused suite also proves legacy three-life fixture compatibility, five-life clamping, unsafe leaderboard-label filtering, ten-entry resource bounds, deterministic countdown duration, music-state switching, single-use fairy behavior, and both exhausted-life actions.

## Integrity and boundaries

- Core remains `0.5.1`; vendored/shared Core files are unchanged.
- Save schema remains v1.
- Owner primary and backup saves remained byte-identical during automated validation.
- No production export, signing, deployment, publication, account provider, paid service, or real player data was used.
- The local leaderboard does not claim secure/cloud parity.
