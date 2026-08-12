# M2 entertaining Fred title-art uplift

Date: 2026-08-02

The main menu now uses `godot/assets/art/moonpetal-title-fred-v3.png`: a
cinematic, anatomically believable Fred performing a playful ballerina-style
pose on the Moonpetal Marsh lily pad. His lively eyes, extended frog limbs,
moonpetal-and-leaf costume, and clear silhouette make the opening screen more
entertaining without turning Fred into a flat cartoon or human-shaped mascot.

The art preserves the moonlit marsh, fireflies, reeds, flowers, water, and
16:9 composition. Fred's face, pose, and petal silhouette occupy the unobscured
middle band; the existing title bar and lower menu panel retain their dark,
high-contrast reading surfaces. The image contains no embedded text, logo,
button, watermark, account data, or network dependency.

The former v2 image remains in the repository for rollback and continues to be
the development application icon. Only the main-menu background reference
changes; gameplay, saves, collision, progression, Core 0.5.1, Android identity,
and App Build 1 boundaries are unchanged.

## Validation

- Asset: 1,672 by 941 PNG, 2,359,659 bytes, SHA-256
  `0B7576422DDFD5DD295113DE1B32E8E4EBFBE0127A059B3658ABAF6A9CC510C6`.
- Godot 4.7.1 headless import passed.
- Two focused checks prove the v3 asset loads and is the title-screen texture.
- Complete matrix: 17 suites, 2,158 passed, 0 failed. This is the direct sum
  of the 17 Godot suite result lines; earlier 2,190 wording overcounted 32.
- Readiness: 57 artifacts, eight fixtures, exact Core 0.5.1 tree unchanged.
- Android development identity, orientation, ABIs, SDK policy, and zero
  requested permissions remain unchanged; no new Android artifact was claimed.

The asset was produced with the built-in image-generation workflow using the
v2 title image as the edit target. Final prompt intent: preserve the cinematic
moonlit marsh and replace only central Fred with a realistic, charming
ballerina-inspired bullfrog hero, keeping essential character details within
the menu's visible middle band and adding no text or UI.
