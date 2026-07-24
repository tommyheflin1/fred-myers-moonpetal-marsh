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
tongue, boost and camera-follow slices. A separate isolated descendant adds
the Fred-owned locomotion-animation coordinator documented in
`M2_LOCOMOTION_ANIMATION_REPORT.md`. Its 238 focused checks bring the complete
thirteen-suite matrix to 1,600/1,600, with state-to-pose coverage for ground,
leap, depth, tongue, boost, damage, invulnerability, failure and reset.
Animation and camera state remain transient; Core 0.5.1/save-v1 and owner save
bytes are unchanged. Controller/touch evidence remains synthetic. This
evidence does not change milestone percentages or replace owner
physical-control acceptance. Both review branches remain unpushed while the
configured GitHub repository is reported public.

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

Fred model/rig and animation set; lily pads/reeds/pond banks/holes; underwater terrain; bugs/fireflies; Sunken Acorn and Moonpetal; heron, snake, pike, bass models/animations; water/underwater materials; UI icons/fonts; VFX; music; ambience; locomotion/eating/predator/UI audio; app/store icon and promotional art. Current canvas drawings and emoji are references, not shippable 3D assets.

## Readiness scoring

M0 and M1 are complete at the evidence gate. M1 has implementation, 30/30 tests, headless import, readiness validation, visible desktop proof, exact-commit branch CI, and draft PR #3 against `main`. Using the original planning estimate of M0 as 8% and M1 as the next 12%, total migration is **20%** (`8 + 12`). This is a milestone-weighted planning estimate, not a release-readiness claim.
