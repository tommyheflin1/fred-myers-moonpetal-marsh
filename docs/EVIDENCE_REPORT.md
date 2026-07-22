# Discovery evidence report

Evidence date: 2026-07-21 MDT.

## Sources inspected

| Source | Commit / runtime | Evidence |
| --- | --- | --- |
| Mobile Game Core | `482d1417e946c7c74176777bbf9d58bb4264717d` | Version 0.5.1; Godot 4.7.1 compatibility; 71/71 documented checks; save/cloud/service contracts; CI |
| Mobile Game Template | `f9ac3b6540a51c5614e2f43d89496d1979188e0b` | Core 0.5.1 pin; compatibility smoke; Godot 4.7 project; setup/build docs; CI |
| Shared Game Backend | `802f325c9706f7f4c89d0b0e4e5b814de66594bb` | Supabase 2.109.1; authenticated profile/CAS save RPC architecture; migrations/security CI; not deployed |
| Snake Reactor | `e0c15d1f8c4f61345f87a04b6610cbe0ac55bc46` | Core 0.5.1; Godot 4.7; save/progression implementation; 109/109 documented runtime checks; deterministic autoplay/content jobs; Android/iOS presets |
| Fred GitHub repository | starting commit `705f747` | README and `fred-myers-source.zip`; no expanded source or CI on main |
| Fred Sites checkout | `3a35b07294baf421ed8ad9c2374731381c526171` plus unrelated untracked files | React canvas implementation, package lock, five chapters, controls/predators/energy/story; local tree is not clean |
| Live Fred prototype | `https://fred-myers-moonpetal-marsh.tommyheflin.chatgpt.site/` | Title/story CTA rendered; browser console showed zero warnings/errors during inspection |
| App Vault tracker | portfolio documentation checkout | Existing four-repo tracker pattern is evidence-based but several registry/workstream statements are stale relative to current remotes/commits |

## Validation in this milestone

- Read current Git status, remotes, and exact HEAD for all four App Vault child repositories and both Fred checkouts.
- Read current engine/Core pins, Core persisted schema, template setup/build contracts, backend tooling and architecture, Snake export presets, CI workflows, save/progression implementation, and portfolio tracker files.
- Inspected the live site through browser automation and collected its semantic title/story state and browser warning/error log.
- Validated the minimal `godot/project.godot` parse/import boundary with the locally pinned Godot executable if available.
- Validated documentation links, required artifacts, exact version agreement, and repository cleanliness before commit.

## Claims deliberately not made

No Godot gameplay rewrite, Core vendoring, export, APK/AAB, Windows package, iOS build, physical-device QA, production backend, analytics provider, deployment, repository rename, store submission, or full campaign playtest was performed in M0.

## Tracker handoff

The App Vault portfolio tracker should add Fred only after this branch/commit is verified remotely. Suggested entry: project `PRJ-002`, independent repository, active discovery milestone complete, overall Godot migration 8% with high confidence for documentation and low confidence for implementation schedule. The root tracker update should reference this exact Fred commit and must not retroactively award gameplay completion.

