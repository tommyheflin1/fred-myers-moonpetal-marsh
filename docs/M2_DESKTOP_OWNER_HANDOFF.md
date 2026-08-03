# M2 desktop owner-test handoff

Date: 2026-08-02

## Purpose

This Fred-only handoff applies the reusable operating rules from the workspace
`App Generation Engine (Reference Only)` discovery baseline to the already
built Fred candidate. It does not copy Snake Reactor gameplay or create a
monorepo. It keeps Fred independently releasable, preserves the immutable Core
pin, isolates automated test data, identifies exact evidence gates, and makes
the desktop owner entry point fail closed on candidate drift.

Starting Fred commit: `75b843e13a7be52356f6dc51a062092ce95a18d2`.
The Godot gameplay/content tree is unchanged by this handoff.

## Desktop contract

- One canonical shortcut: `Fred Myers Owner Test.lnk`.
- The legacy `Fred Myers M1 Owner Test.lnk` is renamed in place, never copied.
- The shortcut passes the exact installed commit and candidate-manifest hash to
  the canonical launcher.
- The installer requires a clean checkout and records every tracked file hash;
  the launcher rejects a different manifest, commit, or pinned file.
- Godot `4.7.1`, Core `0.5.1`, Core tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`, the project entry point, and
  `fred_save` v1 boundary are checked before launch.
- Normal owner launches preserve the existing owner-progress location.
- `-IsolatedReview` uses a disposable fictional data root and removes it when
  the review process exits.
- The launcher performs no export, signing, deployment, publication, account,
  provider, or App Build 1 action.

## Validation

- Godot 4.7.1 headless import: passed.
- Complete 17-suite matrix: 2,188 passed, 0 failed.
- Desktop owner-handoff static contract: 29 passed, 0 failed.
- Readiness inventory: 54 artifacts, eight fixtures, Core 0.5.1, Godot 4.7.
- Android export static contract and physical-device preflight static contract:
  passed; no device action occurred.
- PowerShell parser validation and `git diff --check`: passed.
- All suites used isolated fictional user-data roots; owner primary and backup
  saves were not used by the test run.

The Windows Computer Use helper successfully started the installed Godot
runtime, but its target-window API rejected the returned Godot window with an
internally contradictory owner-binding error. No new screenshot or interactive
Computer Use credit is claimed. This handoff changes no Godot gameplay files;
the parent candidate's existing 1280x720, 960x540, and constrained 640x360
runtime evidence remains the applicable visual baseline. Owner control feel is
still the protected human acceptance gate.

## Boundary and next gate

The configured GitHub remote remains public, so this local M2 source is not
pushed and no pull request is opened. Milestone percentages do not move for
handoff tooling. The owner should now test through the single pinned shortcut
and report any desktop defects. App Build 1 begins only after that owner review
and a separate explicit instruction.
