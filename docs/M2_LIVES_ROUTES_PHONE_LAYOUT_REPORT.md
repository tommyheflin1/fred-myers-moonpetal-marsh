# M2 lives, routes, backgrounds, and phone layout evidence

Date: 2026-07-24

## Scope and owner finding

This Fred-only correction starts from local uplift/Android candidate
`3b692154c57bc0131cbbe4b1837e52f1e0848912`. Owner review showed two related
playability problems:

- a nonfatal hit removed one life but returned Fred to the level entrance,
  making the event look like an early game-over or full restart; and
- the top-right Moonpetal exit and bottom HUD could collide with or clip
  essential controls at the reviewed window size.

The same review requested alternating lily-pad direction, more background
variety, and continued phone readiness. This slice fixes those bounded issues
without changing Core 0.5.1, `fred_save` v1, campaign rewards, the stackable
tenth-level fairy rule, or the public/release boundary.

## Corrected life and recovery contract

- A fresh run still begins with three lives.
- Each accepted danger hit consumes exactly one current life.
- A nonfatal hit keeps the same level active.
- Before the midpoint, Fred returns to that level's starting perch. After the
  canonical midpoint checkpoint, Fred returns to the midpoint lily pad.
- Recovery provides a deterministic 1.75-second damage grace period and a
  two-second ready countdown.
- The changed life count and checkpoint are saved immediately through the
  existing schema-v1 adapter.
- The full-screen `OH NO FRED!!!` failure choice opens only when the current
  stacked life total reaches zero. `Try Again?` then begins level one with
  three lives.
- Earned tenth-level fairy lives remain stackable through the existing
  campaign maximum; this correction does not reintroduce a three-life cap.

Focused checks exercise the first, second, and final hits separately, including
save restoration and midpoint recovery. They prove that the first and second
deaths cannot reset the campaign or open the final-failure screen.

## Alternating route and background contract

Odd-numbered levels run left to right. Even-numbered levels mirror the stable
route points and run right to left. The start, exit, lily pads, bugs, safe
perch, whirlpools, fairies, predators, current direction, aim direction, and
camera reset all use the same route transform. Moving pads and flying bugs
retain their deterministic per-level variation after mirroring.

Four deterministic marsh treatments cycle through the campaign:

1. Firefly Glade
2. Moonlit Channel
3. Mistflower Reach
4. Rainleaf Basin

Each treatment changes the in-play tint, overlay, and ambient environmental
marks while retaining the authored marsh texture and readable gameplay
contrast. Route/background presentation remains transient and adds no save
fields.

## Responsive HUD and touch layout

One Fred-owned layout contract now drives both drawing and hit testing:

- objective, lives/threats, Pause, energy, status, and telemetry have distinct
  logical safe rectangles;
- lives moved into a persistent top badge instead of the clipped bottom edge;
- the Moonpetal exit is below the header;
- `MUNCH`, `LEAP`, `DIVE/SURFACE`, `BOOST`, and the direct drag surface use shared
  centers/radii for rendering and `InputEventScreenTouch` routing;
- action circles do not overlap, remain inside the 1280 by 720 logical canvas,
  and measure at least 48 dp on the tested 420-dpi phone profile; and
- Godot canvas items preserve the 16:9 aspect ratio during window/device
  scaling.

The layout deliberately remains landscape-first. Cutout/safe-area and physical
phone acceptance are still device gates, not inferred from desktop resizing.

## Automated and visible validation

Godot `4.7.1.stable.official.a13da4feb` passed the complete local matrix:

| Suite | Passed |
| --- | ---: |
| Android lifecycle/readiness | 21 |
| Animation coordinator | 238 |
| Boost locomotion | 167 |
| Camera follow | 184 |
| Depth traversal | 64 |
| Authored Fred rig | 378 |
| Keyboard regression | 23 |
| Leap traversal | 52 |
| Lives/routes/phone layout | 45 |
| M2 foundation | 645 |
| Marsh visual uplift | 137 |
| Menu/lives/leaderboard | 31 |
| Save feedback | 28 |
| Save stress/recovery | 31 |
| Core session/save fixtures | 32 |
| Tongue interaction | 82 |
| Visual clarity | 30 |
| **Total** | **2,188** |

All 2,188 checks passed with zero failures. The focused 45-check suite proves
life decrement/recovery, save restoration, odd/even route transforms,
background cycling, HUD containment/separation, touch hit/draw agreement,
touch-target separation and size, and absence of new save fields.

Computer Use inspected real Windows Godot runtime at:

- 960 by 540, level two: right-to-left route, exit on the left, Fred/start on
  the right, objective/lives/Pause/energy/status separated, and touch controls
  readable; and
- 640 by 360, two-life recovery state: `LIVES 2` remained visible with the
  route, objective, energy, Pause, status, telemetry, and all touch controls
  inside the constrained window without overlap.

Mouse interaction and window inspection were physical Windows input. Touch
contacts remain synthetic `InputEventScreenTouch` evidence in this run; no
physical phone or controller acceptance is claimed.

## Integrity, Android, and open gates

- Mobile Game Core remains the exact vendored 0.5.1 tree.
- `fred_save` remains schema v1.
- Tests and visual review use isolated fictional user-data roots.
- Owner primary/backup saves remain outside the test runtime and byte-identical
  at final handoff.
- The single Fred desktop shortcut remains the owner entry point and targets
  this local candidate; no duplicate shortcut is created.
- The existing development-only Android preset remains arm64 plus x86_64 with
  no requested permissions or production signing.
- A fresh exact-candidate debug APK was rebuilt at
  `builds/android/fred-myers-debug.apk`: 76,684,765 bytes, SHA-256
  `2DCE71E33B321784AD2AEFBBE3E92D5E6B1582F34F1731266CF65A54EBAEC10A`.
  Package/version/SDK/ABI inspection passed, ZIP alignment passed, v2/v3 debug
  signatures passed, no Android permissions were requested, and the 180-entry
  content scan found no tests, tools, evidence, source-control material,
  secret-like content, or private Windows paths. The known API 35 SwiftShader
  uniform-limit blocker still prevents truthful emulator visual/touch
  acceptance, so the APK is a local phone-test candidate, not a release or
  physical-device claim.
- The configured GitHub repository remains public. This proprietary local M2
  branch is not pushed and no PR is opened.

M012 remains 99.3%, M013 remains 0%, and TASK-002 remains 19.9%. This
review-bound correction adds engineering evidence but no milestone credit
before approved denominator decomposition and owner acceptance.
