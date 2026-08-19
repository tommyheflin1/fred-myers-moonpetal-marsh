# M2 Fred anatomical attire-cut uplift

Updated: 2026-08-18

## Outcome

Revision 18 removes the remaining one-shape-fits-all treatment from Fred's
clothing. Each save-compatible outfit now has its own anatomical garment cut:

- Marsh Runner uses a sleeveless athletic singlet with short tapered sleeves
  and light sweatbands;
- Trail Scout uses a soft field vest with longer canvas sleeves, smaller
  utility pockets, cuffs, and a compact neckerchief;
- Moon Champion uses a draped competition jersey, sash, restrained medal, arm
  ribbons, and light leg ribbons; and
- Firefly Hero uses a fitted technical jersey, restrained bracers and knee
  reinforcement, plus a cape that bends and drops with the current pose.

The common armor-like edge treatment is gone. Cloth panels now blend into one
garment volume with material-dependent soft binding, curved belly hems,
anatomical neck and arm openings, tapered sleeves, subtler emblems, and smaller
eyewear fitted to Fred's eye spacing. Accessories are placed by outfit rather
than repeated on every rig.

## Deterministic contract

Every attire ID declares a typed cut, sleeve ratio, hem drop, and structure
factor. These values only control rendering. Pose-aware stretch, compression,
fold bias, cape sway, and reduced-motion scaling consume immutable rig state
and cannot write gameplay, collision, rewards, progression, or save data.

The attire snapshot now exposes fifteen fit features, twelve fabric layers,
five tailored panel layers, three anatomical openings, and a bounded soft-edge
width. The four cuts and four material identities are independently testable.
Unknown attire continues to fail closed.

## Validation

- Focused authored-rig suite: 1,089 passed, 0 failed.
- Complete deterministic matrix: 22 suites, 4,883 passed, 0 failed.
- All four outfits are validated across all 23 animation states, both facing
  directions, reduced motion, malformed input, runtime traversal, damage,
  failure, retry, and schema-v1 save/reload.
- One hundred pose traces are byte-identical.
- 10,000 rig updates completed in 381 ms with 4,620 bytes measured growth, one
  retained object, and zero resource, node, or orphan growth. The same known
  standalone-suite shutdown warning remains; no new runtime warning appeared.
- Computer Use inspected the real Godot customizer at 1280x720, normal active
  play at 960x540, and reduced-motion active play at 640x360. Fred's eyes and
  mouth stayed clear, garment and limb pieces stayed attached through
  underwater and boost states, and the HUD and touch actions did not overlap.

Evidence captures:

- `godot/docs/evidence/app-build-1-r18-attire-marsh_runner.png`
- `godot/docs/evidence/app-build-1-r18-attire-trail_scout.png`
- `godot/docs/evidence/app-build-1-r18-attire-moon_champion.png`
- `godot/docs/evidence/app-build-1-r18-attire-firefly_hero.png`

The focused implementation commit is
`e794a22fe5267106f25d3b296da09502cea1ed82`; the exact Android package source
is `72e6678d3038df666f1b2f562a94568d85ead378`.

## Owner-build boundary

Revision 18's local development APK is 84,907,755 bytes with SHA-256
`62E9BA3B105C264160D3F6810AB942A49AA666B75676D7BE9BD042FEC33A4D59`,
version `0.2.1-app-build-1-r18` (`20118`). It requests zero permissions,
contains arm64-v8a and x86_64, and uses only Godot's debug certificate. This is
not production signing, publication, release, or physical-device acceptance.

Core 0.5.1, `fred_save` v1, collision, gameplay, owner saves, and milestone
scores remain unchanged. The public-remote boundary remains no push/no PR.
