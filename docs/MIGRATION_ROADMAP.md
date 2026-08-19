# Migration and milestone roadmap

## Strategy

Keep the legacy site online as a reference. Build the Godot version vertically, one complete level and its contracts at a time. Do not port the React component line-for-line.

| Milestone | Scope | Exit evidence |
| --- | --- | --- |
| M0 Discovery/readiness | Current assessment, contracts, scaffold, risks, evidence | This documentation package; CI scaffold validation |
| M1 Foundation vertical slice | Current template + exact Core 0.5.1; deterministic session; input intents; save v1; one greybox Lily Leap; frog placeholder | Core smoke, save fixtures, headless level completion, desktop runtime |
| M2 Frog and traversal | Authored frog model/rig, jump/land/swim/dive/tongue/boost, camera, controls | Automated movement/energy/state tests and human control review |
| M3 Five-level story | Data-driven objectives/checkpoints and all five greybox levels | Seeded autoplay, save/restore at every checkpoint, full human story completion |
| M4 Predators and polish | Heron/snake/fish AI, holes, telegraphs, art, water, VFX, audio, HUD/accessibility | Fairness matrix, screenshot/audio review, accessibility acceptance |
| M5 Platform hardening | Web/Windows/Android/iOS preparation, lifecycle, performance, privacy/support | Reproducible artifacts and target-specific evidence; no store claim |
| M6 Optional online | Auth/profile/cloud/verified competitive feature only if approved | Local backend security tests, offline degradation, privacy approval |
| M7 Release candidate | Assets, policies, device matrix, signed builds/submissions with owner approval | Exact-SHA CI and owner-approved release checklist |

## Active M2 branch evidence

The local M2 evidence branches now contain deterministic leap, depth, aimed
tongue, boost and camera-follow slices. An isolated descendant adds the
Fred-owned locomotion-animation coordinator documented in
`M2_LOCOMOTION_ANIMATION_REPORT.md`; a second isolated descendant integrates
the coordinator with the authored vector rig documented in
`M2_AUTHORED_FRED_RIG_REPORT.md`. The rig has independently articulated body,
head, eyes, mouth, front and hind legs, toes, accents, tongue anchor and ground
contacts, and it replaces the inline procedural gameplay-body drawing without
changing mechanics. Animation, rig and camera state remain transient; Core
0.5.1/save-v1 and owner save bytes are unchanged. Controller/touch evidence
remains synthetic. This evidence does not change milestone percentages or
replace owner physical-control acceptance. The review branches remain
unpushed while the configured GitHub repository is reported public.

An additional isolated descendant adds the evidence-backed in-play marsh
uplift documented in `M2_MARSH_VISUAL_UPLIFT_REPORT.md`: dimensional
environment/prey/predator presentation, a 96-pixel close-prey tongue assist,
three starting lives with stackable tenth-level fairies through a bounded
13-life campaign maximum, level-to-level life carryover, and real
`InputEventScreenTouch` control routing. Save v1 and Core stay unchanged.
Physical iOS/Android acceptance and final art remain future gates.

The same local descendant now includes the development-only Android export
and lifecycle contract documented in `M2_ANDROID_DEVELOPMENT_EXPORT_REPORT.md`.
The APK identity, signing class, architectures, permissions and contents are
verified, and all deterministic suites remain green. The isolated API 35
SwiftShader emulator could launch the app but could not link Godot's built-in
canvas shader, so mobile presentation and actual touch gameplay remain
explicitly unverified. No platform-hardening score or M013 credit is awarded.

The review correction documented in
`M2_LIVES_ROUTES_PHONE_LAYOUT_REPORT.md` keeps each nonfatal life loss on the
active level, restores the reached midpoint checkpoint, mirrors odd/even
routes, cycles four deterministic marsh treatments, and centralizes the HUD
and touch geometry so essential controls remain separated at 960 by 540 and
640 by 360. The current full 17-suite matrix passes 2,158 checks. This count
is the direct sum of the suite result lines. Physical-phone
acceptance and milestone scores remain unchanged.

The hash-guarded owner workflow in
`M2_PHYSICAL_ANDROID_OWNER_HANDOFF.md` now makes the next physical-phone gate
reproducible without claiming it early. Default execution found zero devices
and returned `DEVICE_NOT_CONNECTED / UNVERIFIED`; 60/60 fictional safety checks
prove fail-closed hash, package, device-state, API/ABI, ambiguity, and explicit
serial behavior. No install or device capture occurred, and milestone scores
remain unchanged.

Owner direction on 2026-08-03 starts the local App Build 1 testing phase. The
exact latest desktop/icon candidate is packaged as a newer debug-only Android
artifact. The next local revision adds a required two-step hero-story and
touch-first instruction path before Level 1. Fred's purpose is explicit: cross
the marsh, restore safe Moonpetal paths, protect the smaller frogs and become
the frog hero in every little frog's dreams. Story and instruction state is
presentation-only and absent from `fred_save` v1. The artifact is refreshed as
touch-first revision 5 version `0.2.1-app-build-1-r5` (`20105`), with the existing development
package identity, zero requested permissions, and a refreshed source/artifact
hash guard. Package creation and automated checks do not substitute for
physical-phone acceptance and do not unlock production or store actions.

The subsequent Campaign 1 pass makes the 100-level structure an explicit
product contract rather than a level-number cap. Ten chapters contain ten
levels each; every level has a strictly increasing deterministic difficulty
step, but the curve is bounded for the age-five target. Level 1 has one readable
patrol and no whirlpool, whirlpools wait until Level 16, moving patrol and
reversing-current mechanics are delayed, and Level 100 still preserves at
least 1.35 seconds of reaction time, 1.8 seconds of post-hit grace, a 50-pixel
safe radius, at most five predators and three whirlpools. The player runtime is
touch-only, the Windows mouse maps through that same touch path, and the title,
feedback and failure presentation declare and preserve a PG family-adventure
contract. Completing Level 100 now ends Campaign 1 and celebrates Fred's hero
promise instead of replaying Level 100.

The local Android handoff is refreshed as App Build 1 revision 6,
`0.2.1-app-build-1-r6` (`20106`), from exact Campaign 1 source
`7d26bdaed10f4e07d4e87a11002b7a2c7bb59fa6`. The debug APK remains
permission-free and unpushed; zero connected devices means physical-phone
acceptance remains `UNVERIFIED`.

App Build 1 revision 7 makes Fred and the customization choices easier for a
young player to understand. Four save-compatible attire IDs now render as
recognizable goggles, glasses or a visor, with anchored vest/scarf/medal/badge
details and clearer current/next labels. The rig adds dimensional skin, filled
limbs and grounding while leaving deterministic gameplay, save v1, collision,
Core 0.5.1 and the touch-first phone/tablet contract unchanged.

Revision 8 corrects the owner-observed attire fit: collars and the explorer
scarf are molded below Fred's jaw, and the mouth is preserved as the final face
layer across all 23 poses. New mouth-clearance tests and four real Godot attire
frames prevent the clothing from obscuring Fred's expression again.

Revision 9 corrects missed-leap recovery. Landing in open water now creates a
child-readable splash, returns Fred to the earned safe point, preserves the
current life count even at one life, and runs a short ready countdown. Predator
and whirlpool contact remain damaging. The same fixed behavior is packaged in
the local Android debug candidate; no physical-device or release credit is
claimed.

Revision 10 gives naturally aquatic predators their own deterministic depth
routes. Bass, pike, muskie and marsh snakes surface, dive, patrol underwater
and surface again; herons remain above water. Predator damage now requires
both position and depth overlap, so Fred can dive beneath surface danger or
stay above submerged danger while same-depth contact remains harmful. Bubble,
ripple, tint and explicit state labels keep the mechanic readable without
color alone. The 22-suite matrix passes 4,093 checks; physical-phone and owner
control acceptance remain separate gates.

## M1 sequencing

1. Expand the repository source tree and retain the legacy build under `legacy-web/` or a tagged legacy branch.
2. Generate the Godot project from the current template; vendor Core 0.5.1 and verify its four version declarations.
3. Add Fred save fixtures and a headless compatibility runner before gameplay code.
4. Implement fixed-tick `AdventureSession` and input-intent interfaces.
5. Greybox Lily Leap with stable objective/checkpoint IDs and one escape encounter.
6. Add deterministic completion/failure tests and desktop runtime evidence.

## Risks

| Risk | Severity | Mitigation |
| --- | --- | --- |
| Browser source is a zip in GitHub and local Sites checkout has unrelated untracked generated/database files | High | Establish canonical expanded source on a clean migration branch; never bulk-copy unreviewed files |
| 2D-styled prototype creates false expectation of ready 3D assets | High | Asset manifest and placeholder policy; model/rig milestone before visual parity claim |
| Prototype state is monolithic and non-deterministic | High | Fixed-tick session separated from rendering; seed all scenario tests |
| Core cloud conflict fields are Snake-oriented | Medium | Use only compatible fields; define Fred-specific conflict semantics before cloud enablement |
| Template setup doc says Godot 4.5 while all active compatibility evidence says 4.7.1 | Medium | Treat Core compatibility, project features, and CI 4.7.1 pin as authoritative; correct template docs separately |
| Cross-platform promise exceeds current evidence | High | Separate Web/Windows/Android/iOS gates; do not promise obsolete native Windows Phone distribution |
| Predator challenge can become unfair on touch/small screens | High | Telegraphed AI, difficulty/accessibility settings, seeded scenarios, physical-device playtests |
| Store signing, credentials, privacy, and deployment require approvals | Medium | Keep development artifacts unsigned/debug and providers disabled until explicit gates |

## Missing asset manifest

Final Fred asset polish beyond the current authored vector rig and review-stage
marsh background; production lily pads/reeds/pond banks/holes; underwater
terrain; final bugs/fireflies; Sunken Acorn; final heron, snake, pike and bass
models/animations; production water/underwater materials; UI icons/fonts; VFX;
ambience; locomotion/eating/predator/UI audio; app/store icon and promotional
art. Current generated background and Fred-owned vector drawings are improved
owner-review assets, not a final-art claim.

## Readiness scoring

M0 and M1 are complete at the evidence gate. M1 has implementation, 30/30 tests, headless import, readiness validation, visible desktop proof, exact-commit branch CI, and draft PR #3 against `main`. Using the original planning estimate of M0 as 8% and M1 as the next 12%, total migration is **20%** (`8 + 12`). This is a milestone-weighted planning estimate, not a release-readiness claim.
