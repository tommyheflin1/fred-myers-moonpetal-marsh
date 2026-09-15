# Fred Myers next-build adoption

Reviewed 2026-09-15. Status: GUIDANCE RECORDED / MIGRATION_REQUIRED FOR THE NEXT BUILD.

This record applies the canonical practical build standard to Fred Myers without
changing, rebuilding, re-uploading, or reopening the already-submitted iOS 1.1
(12) artifact. It is next-build guidance, not a new release candidate and not
evidence that the pending migration or native-device defects are complete.

## Exact checkpoint and preserved identity

- Checkout: `worktrees/fred-game-center-identity/godot`.
- Branch: `codex/fred-game-center-identity`.
- App-owned checkpoint before this record:
  `905af76a3627e779b024b3b90af76f5805c45818`.
- Submitted Build 12 source remains
  `4ec15ae26a38a5dafd91409c6fd08a96c21df90b`; this documentation must not
  be represented as source for that immutable Apple artifact.
- App identity: Fred Myers: Moonpetal Marsh; game ID `fred-myers`; bundle ID
  `com.flinsvault.fredmyers`; App Store Connect app `6803295872`; Team
  `W6WBR6N6S8`.
- Current manifest: marketing version 1.1, build 12. Before the next Apple
  candidate, inspect App Store Connect and select the next unused build number.
- Core pin: `0.5.1`; save schema: `1`; campaign/save game ID:
  `fred-myers-moonpetal-marsh`. Preserve these unless a separately tested,
  compatible migration is required.
- Preserve both existing leaderboard IDs, all 25 achievement IDs/points/art,
  accepted visuals, game rules, native adapters, saves, signing assets, and prior
  Apple artifacts.

## Canonical standard and audit

- Canonical harness commit:
  `7d195b4ba21792a57e5621f14fbf90e788bf4cb3`.
- Canonical process: `1.8.0-candidate.36`.
- `docs/PRACTICAL_BUILD_STANDARD.md` and the locked Turbo-only exception are
  central reference documents, not files to copy into Fred.
- Canonical `tools/audit_process.py --root <fred-root>` run on 2026-09-15
  returned `MIGRATION_REQUIRED` with no backbone errors. Five files require a
  reviewed next-build migration:
  `docs/SHARED_BUILD_PROCESS.md`, `tools/audit_process.py`,
  `tools/privacy_policy.py`, `tools/store_readiness.py`, and
  `tools/backbone_contract.py`.
- Do not update `PROCESS_LOCK.json` merely to conceal differences. Review the
  five diffs, migrate compatible changes, run app regressions, and rerun the
  canonical audit before freezing the next candidate.

## Reused owner decisions

| ID | Status | Scope and evidence |
| --- | --- | --- |
| FRED-D01 | SETTLED | Company-website contact is discovery-triggered only. Launch, menus, gameplay, foreground, Game Center, native leaderboards and achievements remain independent of the website. Public/Anonymous requires verified discovery and explicit player choice; Don't Post sends no request or retry. Reference canonical `docs/OWNER_WEBSITE_CONTACT_DECISION.md`. |
| FRED-D02 | SETTLED | No unsolicited legal, policy, license or credits UI. Keep policies external through App Store links and preserve required bundled notices without adding a menu function. Reference canonical `docs/OWNER_LICENSE_PRESENTATION_DECISION.md`. Build 12 already removed the rejected Licenses control. |
| FRED-D03 | SETTLED | Reuse owner music decision `FLINS-MUSIC-2026-09-14`. Preserve Fred-specific track hashes, audio integration/tests, and the separately accepted `fred-existing-12` and `fred-existing-13` provenance risks. Do not ask the generic commercial-use question again. |
| FRED-D04 | SETTLED | Store materials are listing text, screenshots, icons and achievement art, not player data. Privacy must separately describe local saves/settings, Apple Game Center processing and optional consented Golden Egg website processing; do not invent a no-data claim or add collection. |
| FRED-D05 | SETTLED | Preserve Fred's proven manual-signing, manual-export/altool `tools/release-ios` lane, profile name, bundle/team identity and existing Mac checkpoint. Do not switch uploaders, reset signing, or repeat a valid archive because documentation changed. |
| FRED-D06 | SETTLED | The owner accepted only `FRED-GC-001`, `FRED-EGG-001` and `FRED-EGG-002` for the submitted rollout, with repair deferred. Reference `docs/FRED_ACCEPTED_IDENTITY_PUBLICATION_DEFECTS_2026-09-14.md`. The acceptance is not passing evidence and does not transfer to a future build. |

## Next-build engineering work

- `FRED-E01 / ENGINEERING_WORK`: review and adopt the five candidate-36 process
  changes named by the audit, preserving Fred's game rules, Core pin, save/store
  identities and native adapters. Rerun the app's regression suites and canonical
  audit after migration.
- `FRED-E02 / ENGINEERING_WORK`: repair and reproduce the three deferred identity
  and publication defects on a named physical-device build. Verify standard native
  leaderboard display name, Golden Egg provider-name flow, Anonymous publication,
  Don't Post/no-request behavior, return to the beginning of Level 5, and normal
  gameplay independence from website availability. Do not add a typed-name or
  insecure identity fallback.
- `FRED-E03 / ENGINEERING_WORK`: reconcile the per-app privacy inventory, dedicated
  support/privacy pages and App Store answers against the actual next-build code.
  Preserve the existing truthful local/Game Center/optional website structure.
- `FRED-E04 / ENGINEERING_WORK`: rerun exact-path/hash asset provenance and notice
  packaging against the next exported artifact. Reuse the standing music decision;
  preserve approved art and screenshots unless the next build changes what they show.
- `FRED-E05 / ENGINEERING_WORK`: select an unused Apple build number, freeze the
  tested exact source, and resume the existing lane at its first unfinished gate:
  `tools/release-ios preflight -> archive -> upload -> status`. TestFlight assignment,
  installed-device results, App Review submission and public release remain separate.

## Decisions and external access

- `OWNER_DECISION_PENDING`: none newly identified. Do not repeat settled website,
  music, license-presentation, privacy-structure or existing release-method questions.
- `EXTERNAL_ACCESS`: future App Store Connect state, unused build number, Mac
  toolchain, signing, upload, TestFlight/device and Apple-review evidence must be
  checked only when the next build reaches those gates. This record performs none
  of those actions.

No source migration, gameplay change, build, archive, upload, TestFlight action,
App Review action, public release or live player-data operation occurred in this
adoption pass.
