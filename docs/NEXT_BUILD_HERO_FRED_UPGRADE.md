# Superhero Fred and attire upgrade — 2026-08-31

## Scope and process

Local next-build graphics work on `codex/fred-next-build-pause-fix`, starting
from `fa42cd0f19702bb3e7e2bc54621c191a3d2dca81` (tree
`508b9b10aeb747d89e5d8fcbd52b13fba611699f`). The owner requested a more realistic,
superhero-like frog and better attire. This is an original stylized 2D hero,
not a photorealistic model or a new external asset import.

The canonical `shared-build-process` skill guided isolation, protected-state
checks and validation. Its exact-candidate audit still reports
`MIGRATION_REQUIRED`: 22 differences against `1.6.0-candidate.1`. Release-tool
migration is not included in this artwork change. No Apple-ready claim is made.

## What changed

- Broader, longer torso; stronger shoulders, upper arms, forearms and thighs;
  smaller head; defined jaw, horizontal frog pupils and larger webbed hands.
  Eight saved body types have independent chest/head/limb profiles in addition
  to their retained original overall proportions.
- All nine saved outfits use raised chest panels, shoulder guards, bracers,
  belts, kneepads and shin wraps. Each has an original marsh insignia. Scout,
  catcher and pilot have diagonal harnesses; utility outfits have pouches;
  moon/star outfits have sashes; Firefly Hero has a broad folded burgundy cape.
- Existing color choices, eyewear, catalog IDs, prices, ownership and save-v1
  schema remain unchanged. This upgrades existing items; it does not add or
  sell nine additional items.
- `hero_frog_art.gd` is deterministic app-owned geometry, with no new textures,
  nodes, physics, dependencies, timers, network calls or growing caches. The
  original pose controller and joint hierarchy remain; the head's visual
  tongue anchor follows its new anatomy. Movement, collision rules, controls,
  progression, Golden Egg eligibility, Game Center and audio are unchanged.
- Actual customizer review exposed Fred overlapping the footer text and
  return button. The preview now uses a 1.6 scale at `(640,483)` within the
  space between cards and footer. Card/button positions and in-game Fred size
  were not changed by that menu-only adjustment.

## Actual renderer evidence

- [Hero close-up: runner, Firefly Hero and Moon Champion](evidence/next-build-hero-2026-08-31/hero-detail.png)
- [Eight body silhouettes](evidence/next-build-hero-2026-08-31/builds.png)
- [Nine upgraded outfits](evidence/next-build-hero-2026-08-31/attire.png)
- [Swim, leap, landing, dive and surfacing](evidence/next-build-hero-2026-08-31/water-motion.png)
- [Phone customizer, starter Fred](evidence/next-build-hero-2026-08-31/customize-quick-1792x828.png)
- [Tablet customizer, Strong Firefly Hero](evidence/next-build-hero-2026-08-31/customize-strong-1366x1024.png)
- [Level 10 reversed phone route](evidence/next-build-hero-2026-08-31/level10-reverse-phone-1792x828.png)
- [Level 71 tablet scene](evidence/next-build-hero-2026-08-31/level71-tablet-1366x1024.png)
- [Level 71 phone Pause overlay](evidence/next-build-hero-2026-08-31/level71-paused-phone-1792x828.png)

Nineteen selected PNGs are preserved in the evidence directory, including all
eight `hero-fit-<body>.png` sheets (72 body/outfit combinations) and four actual
customizer phone/tablet captures. These were visually inspected. They are real
Godot renders using isolated fictional data, with hazards and audio disabled,
not physical-device captures or a completed player-controlled run. Review-only
selection of outfits does not purchase/unlock items in an owner's profile.

The final renderer generated 30 PNGs with exit 0 and clean stderr. Its first
26 images are SHA-256-identical to the preceding inspected renderer run; four
customizer images show the corrected preview. Copy hashes were verified.
Hero close-up SHA-256:
`8368FD56B60F4B6BAEBCEB52B3862D80374482BAB8FACBBD74C03BFB0231A329`.

## Executed validation

| Gate | Result |
| --- | --- |
| Full Godot regression | 36 suites, each exit 0; 82,303 assertions passed, 0 failed |
| Hero anatomy/attire/menu suite, included above | 27,732 passed, 0 failed; clean stderr |
| Pause input, included above | 36 passed, 0 failed |
| Golden Egg Level 10, included above | 122 passed, 0 failed |
| Game Center adapter, included above | 42 passed, 0 failed |
| Python tooling | 5 scripts; 76 checks passed |
| Readiness | 161 artifacts, 8 fixtures, Core 0.5.1 |
| Actual renderer | 30 PNGs, exit 0, clean stderr |
| Repeated redraw guards | Save snapshot, actor positions, level, collected items and simulation time unchanged over 120 redraws each on Levels 10 and 71 |
| Render node growth | 0 in both measured scenes |
| Patch formatting | `git diff --check` passed |

The new suite covers all 8 bodies x 9 outfits x 23 poses x 2 facings x 2 motion
modes for pose acceptance, mouth clearance and nonmutating snapshots. It also
checks finite/triangulatable geometry, non-overlapping volume meshes, distinct
profiles/insignias, invalid input, save compatibility, and customizer bounds
for all body/outfit combinations in reset/idle stances. These are programmatic
checks, not visual review of every animation frame. CI/readiness are updated;
remote CI was not run.

Final Godot logs: `builds/hero-review/verified-validation`; final renders/logs:
`builds/hero-review/verified-render`; Python logs:
`builds/hero-review/python-validation`. Thirteen existing suites emitted
ObjectDB/resource-at-exit diagnostics, with no assertion, parse, script or
polygon errors. The new hero suite and final renderer have clean stderr.
Earlier iterations caught and fixed a crossed hand-web polygon, review-caption
overlap and actual customizer-footer overlap before final validation. An
unrelated App Store capture UID regenerated by editor import was removed.

Final Windows renderer CPU drawing-preparation p95 was 16.200 ms on Level 10
and 19.252 ms on Level 71 while the separate regression process was running.
These are not GPU/frame timing, an isolated benchmark, or phone performance.
The busy scene exceeds a 16.67-ms CPU budget; device profiling and any necessary
optimization remain open before release.

## Protected state and remaining gates

- Godot 4.7.1, Core 0.5.1, save v1, app identity and build number are unchanged.
- Submitted Build 4 remains clean at
  `c261e37979b0f306ff86ce7e450922a2c919c2f0`, tree
  `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner save SHA-256:
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup SHA-256:
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Existing desktop shortcut SHA-256:
  `F75617364EAD7899D8ECEB2A8D3D87CED2A73F2FA6D3F9347182ECF563A28D2A`.
- No shortcut redirection, GitHub push, signing, upload, TestFlight assignment,
  App Review action or public release ran.

Owner art preference, physical iPhone/iPad readability and frame pacing,
native Pause/background/Resume and rotation remain separate acceptance gates.
Local Golden Egg checks do not prove a website leaderboard entry.
