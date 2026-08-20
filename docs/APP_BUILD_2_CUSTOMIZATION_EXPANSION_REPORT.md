# Fred Myers App Build 2 customization expansion

Date: 2026-08-20
Branch: `codex/app-build-2`
Starting revision: `1a60b2a6aeba2c7946d9db9ba1d8cd333435d599`

## Outcome

Fred now has exactly **20 new unique customizations**, growing the local
collection from 15 to 35 choices. The expansion remains fictional,
offline-first and coin-earned: there are no purchases, advertisements, online
accounts or platform-service dependencies.

The customizer now announces `35 HERO LOOKS • 20 NEW`, shows the selected
position in each category, and adds a non-text swatch or icon. The cards remain
touch targets and the central authored rig changes immediately.

## Twenty new choices

### Five frog colors

- Golden Glider
- River Sapphire
- Berry Bolt
- Night Hero
- Pearl Hopper

### Five athletic builds

- Pocket Hopper
- Springy
- Swift
- Trail Fit
- Strong

These are presentation-only scales from 0.88 through 1.12. They do not change
collision, speed, leap distance, health, difficulty or targeting.

### Five tongue colors

- Coral Pop Tongue
- Lime Spark Tongue
- Cherry Flash Tongue
- Ice Stream Tongue
- Golden Zap Tongue

### Five fitted gear designs

- Pond Pilot Goggles: aviator twill, wing badge and wide pilot lenses.
- Rain Ranger Glasses: water-shedding shell, raindrop badge and tall lenses.
- Bug Catcher Shades: field ripstop, bug emblem and low shade silhouette.
- Star Jumper Visor: spring jersey, star badge and full star visor.
- Lily Lifeguard Goggles: rescue neoprene, rescue badge and cross-marked lenses.

Each design has a unique material, finish, drape, anatomical cut, palette,
eyewear silhouette and child-readable name. All reuse Fred's existing jaw
exclusion zone, articulated shoulder/limb anchors, fitted panels and mouth-clear
collar rather than floating decorations.

## Economy and compatibility

- New options are earned in deterministic catalog order with local gameplay
  coins; unlocking every item deducts each cost exactly once.
- Completing a category wraps to its already-owned starter without another
  charge.
- Existing profiles keep their owned and selected legacy choices.
- Unknown or malformed gear still fails closed to Runner Goggles.
- The complete expanded profile stays below the 32 KiB bounded profile limit.
- The local customization profile remains schema 1. `fred_save` remains schema
  v1 and gains no cosmetic fields.
- Mobile Game Core 0.5.1, collision, campaign rules, Game Center scoring,
  touch controls and owner saves are unchanged.

## Automated evidence

- Focused customization expansion: **313 passed, 0 failed**.
- Product/cosmetic integration: **101 passed, 0 failed**.
- Authored Fred rig: **2,044 passed, 0 failed** across all nine outfits and all
  23 deterministic animation states.
- Complete repository matrix: **27 suites, 8,176 passed, 0 failed**.
- Readiness: **130 artifacts, eight save fixtures**, Core 0.5.1/Godot 4.7.
- Godot: `4.7.1.stable.official.a13da4feb`.
- The full matrix retains the known shutdown-only ObjectDB/resource diagnostics
  in older standalone SceneTree harnesses; all assertions and exits passed.

## Visible Windows evidence

Computer Use inspected the real Godot customizer with isolated fictional data:

- all five new coordinated looks at 960 by 540;
- Lily Lifeguard at constrained 640 by 360 after correcting a tight gear-label
  edge;
- every selected/next label, swatch, look counter and Save/Home control remained
  visible;
- Fred's eyes, mouth, collar, chest badge, limbs and eyewear remained separated;
- the five outfits were visually distinct without obscuring Fred's face.

This is Windows runtime evidence, not physical iPhone/iPad acceptance.

## Rebuilt local Android companion

`builds/android/fred-myers-app-build-2-debug.apk` was rebuilt from the expanded
source:

- size: `84,932,679` bytes;
- SHA-256:
  `AF5AE1CC10561861FAAED7113A9C53D7A97DC30E8D0552EB99E29986D9327E84`;
- package/version: `com.flinsappvault.fredmyers.dev`,
  `0.2.2-app-build-2-r1` (`20201`);
- minimum/target SDK 24/36;
- arm64-v8a and x86_64;
- zero requested permissions;
- debug certificate and APK signature schemes v2/v3 verified;
- ZIP alignment verified;
- 207 entries with no test, tool, evidence, source-control, secret, credential
  or private-path material found.

The Android artifact is development-only and does not validate Apple Game
Center or physical-device behavior. No signed iOS archive, TestFlight upload,
App Store Connect change, release, remote push or publication occurred.
