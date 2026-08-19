# M2 Fred rig and child-readable attire uplift

Date: 2026-08-18

## Purpose

This Fred-only revision improves the in-game authored frog and makes every
attire choice immediately recognizable to a young player. It preserves the
existing save-compatible attire identifiers while replacing generic costume
marks with aligned glasses, goggles or a visor plus simple supporting gear.

## Visible contract

| Choice | Face item | Body detail |
| --- | --- | --- |
| Runner Goggles | round gold sport goggles | teal runner vest and badge |
| Explorer Glasses | round explorer glasses | trail vest and red scarf |
| Moon Champion Visor | wide purple-gold visor | champion vest, medal and ribbon |
| Firefly Hero Goggles | bright hero goggles | firefly badge and small cape |

All face gear is derived from Fred's authored head and eye anchors rather than
screen coordinates. It mirrors with facing and follows leap, swim, dive,
tongue, boost, damage and reduced-motion poses. Body gear follows the body
joint. Unknown attire fails closed instead of producing detached decoration.

Fred's base presentation now includes a soft ground shadow, layered body and
head light/shade, restrained skin spots, filled front limbs and hand pads, eye
glints and cheeks. The changes are presentation-only: no collision, gameplay,
difficulty, progression, coin reward, save-v1 or Core data is modified.

## Young-player customizer language

The attire card is named `GEAR + GLASSES`. It displays the selected item, the
next item by name, and either `TAP TO TRY` or the exact coin unlock cost. The
screen explains: `Tap a card to try the next look. Fred wears it right away!`.

## Executed evidence

- Godot 4.7.1 import/parse passed after replacing an initially incompatible
  color helper with the supported constructor.
- Focused rig suite: 408 passed, 0 failed, including all four attire choices,
  head-anchor bounds, mirrored alignment and invalid-attire rejection.
- Focused product-uplift suite: 94 passed, 0 failed, including catalog labels,
  next-choice language, runtime alignment metadata and gameplay/save
  invariance.
- Rig determinism: 100 repeated traces remained identical.
- Rig stress: 10,000 updates completed in 352 ms with 4,620 bytes measured
  static-memory growth, one object delta, zero resource delta, zero node delta
  and zero orphan delta in the standalone Godot test process.
- Visible Windows review: the actual 1280 by 720 Godot customizer cycled Runner
  Goggles, Explorer Glasses, Moon Champion Visor and Firefly Hero Goggles. All
  four remained centered on Fred's eyes; supporting gear stayed attached.

Full regression, package identity and final shortcut evidence are recorded in
`APP_BUILD_1_TEST_REPORT.md`. Physical phone/tablet control feel remains a
separate owner-device gate. No production signing, provider activation,
publication, deployment, push, PR, release or milestone-percentage increase is
claimed.

## Mouth-clear molded fit correction

Owner review found that the vest neckline and explorer scarf rose across
Fred's mouth. Revision 8 lowers and reshapes the garment shoulders and collar
around the torso, moves the scarf below the jaw, and renders the articulated
mouth and jaw finish after attire. The face now also has a restrained throat
highlight, iris rings and defined mouth corners for better small-screen
readability.

The rig exposes a deterministic mouth-to-collar clearance measurement. Focused
coverage checks all four attire choices in all 23 coordinator states, mirrored
facing and the flattened failure pose. The corrected rig suite passes 508/508;
the product-uplift suite remains 94/94. Four actual 1280 by 720 Godot frames
were rendered and inspected:

- `godot/docs/evidence/app-build-1-r8-attire-marsh_runner.png`
- `godot/docs/evidence/app-build-1-r8-attire-trail_scout.png`
- `godot/docs/evidence/app-build-1-r8-attire-moon_champion.png`
- `godot/docs/evidence/app-build-1-r8-attire-firefly_hero.png`

Every frame keeps the closed mouth, jaw and cheeks visible above the garment;
the glasses and visor remain centered on the eyes. The correction changes only
presentation and retains the touch-first phone/tablet control contract.
