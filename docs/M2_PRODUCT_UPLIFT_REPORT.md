# M2 mobile-first product and visual uplift

Date: 2026-08-18

## Engine-reference decisions

This slice follows the locked App Generation Engine 1.0.0 reference instead of
copying another game's product code. Fred remains an independent repository;
Mobile Game Core 0.5.1 remains immutable; gameplay stays deterministic and
offline-first; input presentation is device-neutral; cosmetics and economy are
Fred-owned; and Apple scoring is behind an injected provider boundary.

`FredAppleGameScoring` now emits the stable
`fred_marsh_adventure_progress` score envelope, bounds its offline queue, and
requires server verification. Windows reports
`LOCAL_ONLY_PLATFORM_ADAPTER_READY`. iOS reports
`APPLE_CONFIGURATION_REQUIRED` until an owner-authorized Game Center
leaderboard identifier, native bridge, App ID and entitlement exist. No Apple
account, credential, provider, entitlement, signing or network service was
activated.

## Player-facing uplift

- Replaced the title hero with an original game-poster composition showing an
  athletic four-limbed Fred in Moonpetal sport gear.
- Removed desktop-key wording from the application UI while preserving the
  internal desktop test adapter.
- Added `Customize Fred`, persistent fictional coins, unlockable body colors,
  bounded visual sizes, tongue colors and four attire themes. Cosmetics never
  change collision, difficulty, lives or save-v1 state.
- Bugs earn three coins; a completed level earns a bounded level reward.
- Added a permanent non-overlapping `Exit` action. Leaving active gameplay
  returns home and durably prepares a fresh level-one, three-life run while
  profile coins/cosmetics survive.
- Expanded levels from a mirrored line into six deterministic whole-screen
  formations: River Arc, Zigzag Sprint, Moon Ring, Cross Current, Firefly
  Spiral and Island Scatter. Six marsh lighting treatments rotate with them.
- Moved the phone movement cluster away from Fred's start silhouette after
  actual Windows touch-overlay review found a visual obstruction.

## Presentation uplift

The authored rig now accepts a presentation-only cosmetic style and renders a
layered jersey, trim, chest badge, headband, highlights and toe accents. Fred's
default visual scale is larger, but canonical position and collision are
unchanged. Fish now use animated lift and tail flex, layered highlights, gills
and scales; the snake uses a connected articulated spine and patterned scales;
the heron has layered wing-feather, head and beak detail. Marsh mist, glints,
route-dependent light and depth layers reduce the prior flat-paper appearance.

## Verification boundary

- Godot 4.7.1 import/parse: passed.
- Complete automated matrix: 18 suites / 2,280 checks / 0 failures.
- New focused product suite: 88 checks, including profile persistence, headless
  test isolation, cosmetic
  gameplay invariance, six routes, UI separation, fresh-run Exit semantics and
  Game Center fail-closed behavior.
- Visible Windows review: 1280 by 720 title, customizer, countdown, gameplay
  HUD, touch overlay and corrected Fred-start clearance inspected.
- Core remains 0.5.1 and save schema remains `fred_save` v1. Cosmetics use a
  separate Fred-owned local profile; no schema migration is introduced.
- Android App Build 1 revision 3 remains development-only. Physical Android,
  iOS Simulator, physical Apple device, Game Center sandbox and owner control
  acceptance remain separate gates.

No production export, signing, provider activation, publication, deployment,
release, push, PR or milestone-percentage increase is claimed by this slice.

## Child-readable Fred gear refinement

The next owner-review correction replaces the generic headband treatment with
four recognizable face items: Runner Goggles, Explorer Glasses, Moon Champion
Visor and Firefly Hero Goggles. Each item is drawn from authored head and eye
anchors, mirrors with Fred, and follows every coordinator pose. Tailored vests,
scarf, medal, firefly badge and cape remain body-anchored and presentation-only.
The customizer now names both the current and next look and uses the plain
instruction `Tap a card to try the next look. Fred wears it right away!`.

Fred also gains a grounded shadow, layered skin light/shade, spots, filled
front limbs, hand pads, eye glints and cheeks. These improvements do not change
collision, movement, difficulty, progression, coins, save v1 or Core 0.5.1.
Focused rig and product-uplift checks cover the typed attire catalog, eye-span
alignment, mirrored facing, invalid-style rejection and save/gameplay
invariance. Actual Godot review at 1280 by 720 cycled all four looks in the
real customizer and found no floating or detached eyewear.
