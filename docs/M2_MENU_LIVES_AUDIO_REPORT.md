# M2 Menu, Lives, Music, and Local Leaderboard Evidence

## Scope

This Fred-only owner candidate adds premium frog-forward title art, an upgraded procedural gameplay Fred, owner-supplied menu and gameplay music, a deterministic three-life rule, an edible every-tenth-level fairy, a five-second level countdown, an explicit exhausted-lives choice, and a functional offline leaderboard.

The supplied file named `The Marshland March.mp3` is treated as the requested main-menu song. `Marshland Chase.mp3` plays during gameplay. Both remain local game assets; no network or provider is activated.

## Behavior

- New games and level-one retries begin with three lives.
- Existing schema-v1 saves remain readable. Restored health is clamped to the supported one-to-three range; no schema field was added.
- A fairy appears only on levels 10, 20, 30, and so on through 100. Fred visibly eats it to restore exactly one missing life, never above three.
- Each level begins behind a deterministic five-second ready countdown.
- Exhausting all lives opens the full-screen `OH NO FRED!!!` frog-splat presentation.
- `Try Again?` creates a clean level-one session with three lives.
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
- menu/music/lives/fairy/countdown/failure/leaderboard: 30

Total: **934 passed, 0 failed**.

The focused suite also proves three-life clamping, the exact every-tenth-level fairy schedule, visible fairy-eating state, unsafe leaderboard-label filtering, ten-entry resource bounds, deterministic countdown duration, music-state switching, single-use fairy behavior, and both exhausted-life actions.

## Integrity and boundaries

- Core remains `0.5.1`; vendored/shared Core files are unchanged.
- Save schema remains v1.
- Owner primary and backup saves remained byte-identical during automated validation.
- Title art was generated with the built-in image-generation workflow and committed locally as `godot/assets/art/moonpetal-title-fred-v2.png`; it contains no text, logos, or network dependency.
- No production export, signing, deployment, publication, account provider, paid service, or real player data was used.
- The local leaderboard does not claim secure/cloud parity.
