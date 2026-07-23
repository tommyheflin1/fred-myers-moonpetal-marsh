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

## Accepted-M1 save-integrity regression

On 2026-07-23, the accepted M1 save-v1 adapter was exercised from exact accepted
`main` commit `c4f44a2f53462af0df740ad9058ff22936db94e2` with Godot 4.7.1 and fictional
temporary `user://` data only. The first stress run passed 14 assertions and
failed 11, proving that newer recovery candidates could be ignored, malformed
primary data could replace a valid backup, future schema/Core data could be
overwritten, and unsafe save prefixes were accepted.

The focused adapter repair adds bounded reads, safe `user://` prefix validation,
candidate-wide monotonic checkpoint enforcement, newest-valid recovery selection,
verified temporary writes, valid-primary-only backup rotation, future schema/Core
overwrite refusal across primary, backup, and interrupted candidates, and a
re-entrant save guard. It does not change AdventureSession, save schema v1, or
Mobile Game Core 0.5.1.

The deterministic suite performs 250 identical atomic saves and covers backup
rotation, malformed/truncated/oversized JSON, primary/backup/temp disagreement,
interrupted writes, stale/equal checkpoint ordering, timestamp offsets, unsupported
schema/Core versions, re-entrant saves, missing paths, path traversal, cleanup, and
last-known-good preservation. After adding explicit re-entrancy coverage, five
independent final runs passed 31/31 assertions each (155 assertions total). The
250-save loops completed in 431-539 ms, each reported 577 bytes of static-memory
growth, and each produced a 513-byte primary save. The original M1 suite remained
30/30, and the separate accepted-M1 keyboard regression branch remained 19/19.

## Tracker handoff

The App Vault portfolio tracker should add Fred only after this branch/commit is verified remotely. Suggested entry: project `PRJ-002`, independent repository, active discovery milestone complete, overall Godot migration 8% with high confidence for documentation and low confidence for implementation schedule. The root tracker update should reference this exact Fred commit and must not retroactively award gameplay completion.

# Accepted-M1 keyboard regression

The post-M1 regression harness injects Godot `InputEventKey` events through
`Input.parse_input_event`; it does not call title, pause, dive, surface, retry,
or completion handlers directly. It covers Enter start, WASD and arrow
movement, Shift boost, Q/E dive and surface, P/Escape pause and resume,
predator failure, R retry, midpoint save and runtime restoration, bug
collection, and Lily Leap completion.

Run:

`Godot_v4.7.1-stable_win64_console.exe --headless --path godot --script res://tests/run_keyboard_regression.gd`

This is automated desktop-keyboard evidence, not owner physical-keyboard UAT.
It does not add M2 behavior, campaign content, controller/touch behavior, an
export, signing, deployment, or release evidence.

Validated locally with Godot `4.7.1.stable.official.a13da4feb`:

- readiness: passed, 16 required artifacts and 8 fictional fixtures
- headless editor import: passed
- existing M1 suite: 30 passed, 0 failed
- keyboard-event regression: 19 passed, 0 failed
- deterministic repeat: four consecutive keyboard runs produced 19 passed,
  0 failed
- Core: unchanged exact 0.5.1 vendored snapshot
- save schema: unchanged at version 1
- formatting and secret-like-file scan: passed

The keyboard test launches from title with Enter; drives WASD, arrow movement
and Shift through held input state; drives Q, E, P, Escape, and R through
unhandled keyboard events; and reaches failure, retry, checkpoint restoration,
bug collection, and completion through the accepted M1 runtime. No Home action
or accepted controller/touch adapter exists in M1, so those paths were not
invented for this regression.

The isolated visible game process launched at the existing 1280x720 target, but
Computer Use approval timed out before interaction or capture. Therefore this
branch claims no new visible-validation or owner-UAT credit.

## Accepted-M1 regression integration

On 2026-07-23, the keyboard commit
`ea17d2bc1bb2be90b24c9c670e61afd07cb07419` and save-integrity commit
`22deaceab9c57a4d201c9239f1096b308760ae75` were cherry-picked in that order onto
exact accepted `main` `c4f44a2f53462af0df740ad9058ff22936db94e2`. The two expected
additive conflicts in the workflow test steps and readiness artifact list were
resolved by retaining both runners. No product-code conflict occurred.

Five isolated full-union executions varied the order of the original 30 checks,
19 keyboard-event checks, and 31 save-integrity checks. Every execution passed
80/80, for 400/400 assertions total. The 250-save stress loop completed in
374-392 ms per execution, reported 577 bytes of static-memory growth, and produced
a 513-byte primary save before cleanup. The combined run exposed one test-harness
leak: the original runner recreated `m1_test_save.json` during its final gameplay
completion. A final `clean_files()` call now removes that fictional test artifact.
All five repeated order permutations then ended with zero non-log user files and
zero temporary files.

The integration preserves Mobile Game Core 0.5.1, save schema v1, all eight
fixtures, and the owner primary/backup save hashes. It adds no M2 behavior and
does not constitute physical-keyboard owner UAT, deployment, export, signing,
publication, or release evidence.
