# Fred hero styles and reusable wardrobe — 2026-08-31

## Scope

Local next-build work on `codex/fred-next-build-pause-fix`, from
`809db23fd2404e20021ce98e03aa3d7c80b6d677` (tree
`72fe0fd35400c95423867e43b22273a0964245cd`). The submitted Build 4 checkout is
unchanged. No upload, signing, App Review, public release or GitHub push ran.

The canonical `shared-build-process` skill guided isolated tests and protected
state verification. The exact-candidate audit still reports
`MIGRATION_REQUIRED`: 22 differences against `1.6.0-candidate.1`. Release-tool
migration is separate from this focused wardrobe/art change.

## Player-visible changes

- Three free hero styles: existing Classic Fred, new Girl Hero and new Boy
  Hero. Girl Hero has a rounder face, larger eyes, softer expression and a
  small petal clip; Boy Hero has a broader chest, stronger arms/thighs and a
  firmer jaw/brow. These extend the original stylized 2D superhero rig rather
  than introducing photorealistic models or external media.
- Four new coin outfits: Petal Guardian (460), Moon Blossom (480), Reed
  Sentinel (500), Storm Striker (520). Each has distinct colors, fabric/armor
  cuts, accessories and an original chest emblem.
- Two new skin colors: Rose Dew (275), Forest Jade (295).
- Total catalog: 44 choices across 3 hero styles, 11 skins, 8 body builds,
  9 tongues and 13 outfits. Every hero can use every build, color and outfit.
  Older prices and item IDs are unchanged. All changes are cosmetic.

## Purchase/reselection repair

The old category button advanced toward the next item and tried to buy it;
an unaffordable locked item prevented reaching older purchases. The new
wardrobe uses explicit item cards and independent preview/equip actions:

1. Open **Customize Fred**, then choose a category.
2. Turn **Owned Only** on to see only unlocked items, or leave it off to browse.
3. Tap a card to preview; use the arrows for additional pages.
4. Tap **Equip — Free** for a purchased item, or **Buy & Equip** for a new item.
5. Return Home. Equipped choices persist; unconfirmed previews are discarded.

Re-equipping does not charge coins, including at a zero balance. Repeated
purchase taps charge only once. Invalid/unaffordable choices do not alter the
wallet or equipment. A reported save failure rolls back the in-memory change.
Legacy save-v1 purchases, selections and balances are retained; missing hero
selection defaults to Classic Fred and the three free styles are available.
No owner profile was edited or granted test currency.

## Executed validation

| Check | Result |
| --- | --- |
| Full Godot regression | 37 suites, all exit 0; 146,787 assertions passed, 0 failed |
| New wardrobe suite, included above | 30,509 passed, 0 failed |
| Hero art suite, included above | 41,222 passed, 0 failed |
| Pause input / Golden Egg / Game Center adapter | 36 / 122 / 42 passed, 0 failed; included above |
| Readiness | 163 artifacts, 8 fixtures, Core 0.5.1 |
| Desktop handoff validator | 51 checks passed |
| Android export and physical-device preflight validators | Passed; static gates only, no device/export run |
| Game Center plugin / source-patch tests | 7 / 8 checks passed |
| Actual Godot renderer | 45 PNGs, exit 0, clean stderr |
| Formatting | `git diff --check` passed |

New tests exercise legacy/sparse ownership, persistence/restart, failed-save
rollback, no-charge equip, preview isolation, and actual engine-dispatched
touch and pointer input. All 3 heroes x 8 builds x 13 outfits x 23 poses x 2
facings accept their animation and keep mouths clear. Reset/idle preview
bounds fit the wardrobe for every hero/build/outfit/facing combination.
These are programmatic checks, not human review of every animation frame.

Full logs: `builds/wardrobe-review/validation-20260831T203243Z`.
Fourteen existing suites emitted ObjectDB/resource-at-exit warnings; no
assertion, script or parse failures occurred. The new wardrobe suite has no
such diagnostics. An initial Windows PowerShell wrapper run stopped on a
native stderr warning; its wrapper was corrected and the entire suite rerun.
An unrelated editor-generated App Store capture UID was removed.

## Actual visual evidence

Six inspected PNGs are preserved under `evidence/next-build-wardrobe-2026-08-31/`:

- [Same outfit, three distinct hero styles](evidence/next-build-wardrobe-2026-08-31/hero-styles.png)
- [Four new outfits](evidence/next-build-wardrobe-2026-08-31/attire-new.png)
- [Girl Hero phone wardrobe](evidence/next-build-wardrobe-2026-08-31/wardrobe-girl_hero-1792x828.png)
- [Strong Boy Hero tablet wardrobe](evidence/next-build-wardrobe-2026-08-31/wardrobe-boy_hero-1366x1024.png)
- [Strong Firefly Hero preview fit](evidence/next-build-wardrobe-2026-08-31/customize-strong-1366x1024.png)
- [Earlier purchase at zero coins](evidence/next-build-wardrobe-2026-08-31/wardrobe-owned-zero-coins.png)

These are real Godot renders using isolated fictional profiles, not physical
iPhone/iPad captures or generated concepts. Copy hashes match all six source
PNGs. Hero-styles SHA-256:
`1B846E8A3DC1BE3D6AC078E6FDBC66EDB378E934D8295F2D4DC8E2293A8D4A46`.
Final render source: `builds/wardrobe-review/render-20260831T203401Z`.

Visual review corrected the clipped tablet coin counter. The review harness
now buys its fictional Strong build/outfit before rendering the real menu,
so the new ownership-aware preview cannot normalize an unowned test choice.

Over 120 redraws each at Levels 10 and 71, node growth was zero and save/game
snapshots were unchanged. CPU drawing-preparation p95 was 26.570 ms / 29.603 ms.
These are not GPU/frame timings, device performance, or a controlled before/
after benchmark. Device profiling and any necessary optimization remain open.

## Protected state and handoff

- Godot 4.7.1, Core 0.5.1, save schema v1, bundle/build identity and game rules
  are unchanged. Pause, Golden Egg, Game Center and gameplay code were not
  modified by this wardrobe change.
- Submitted Build 4 remains clean at
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- All 11 owner JSON save/profile/leaderboard files match their before hashes.
  Profile SHA-256:
  `B96ADD69C0547BB36D449A2B784EF0F45A77AE74FF9AF1EB79C1C04D4F3CC2F4`.
  Save SHA-256:
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
  Backup SHA-256:
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Refresh the existing single `Fred Myers Owner Test.lnk` through the existing
  clean-commit installer, then require the pinned manifest preflight to report
  `READY`. Do not create a second link or redirect the submitted checkout.
- Owner visual acceptance and physical iPhone/iPad touch, safe-area, rotation,
  native lifecycle and frame-pacing checks remain open. Local Golden Egg
  regression does not establish a website leaderboard entry.
