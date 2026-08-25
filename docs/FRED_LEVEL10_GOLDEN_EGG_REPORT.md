# Fred Level 10 Golden Egg — local implementation evidence

## Scope and secrecy

This local, unpushed branch implements the owner-defined hidden Level 10
Golden Egg discovery for Fred Myers and the Moonpetal Marsh. The player-facing
story, instructions, HUD, level objective, failure flow, and public-facing copy
do not disclose the discovery method. This document deliberately does not
publish the hidden input sequence.

The implementation is additive and Fred-owned. It does not alter Mobile Game
Core 0.5.1, `fred_save` v1, ordinary checkpoints, lives, progression, Game
Center, controls, campaign rules, or normal Level 10 completion.

## Build 4 local defect correction

Owner testing exposed a real Level 10 route interaction that the original
state-machine-only coverage did not exercise. Level 10 uses the reversed route,
which places the ordinary Moonpetal exit at `(130, 165)`. The first required
underwater corner is centered at `(130, 167.5)`. After the ordinary three-bug
objective was complete, touching that first corner therefore completed the
level before the hidden sequence could continue.

The correction is intentionally narrow. Ordinary Level 10 completion remains
available until the first valid underwater corner is entered. While a valid
hidden attempt is in progress, the overlapping ordinary exit is suspended. If
the attempt becomes invalid or is abandoned, ordinary completion immediately
becomes available again. No exit geometry, campaign objective, life rule,
secret sequence, collision rule, or save field changed.

The focused suite now drives the actual `main.gd` fixed-tick path with three
bugs collected. It proves the first corner is observed without completing the
level, and proves ordinary completion resumes after an invalid attempt. This
closes the gap that allowed the state machine to pass while owner gameplay
could not finish the sequence.

## Eligibility boundary

- A new protected run begins only from Level 1.
- Level transitions must be sequential through Level 10.
- Any life-loss/death event invalidates the run before ordinary recovery or
  failure handling continues.
- The hidden Level 10 state machine accepts only the owner-defined order and
  exact action counts. Wrong, early, repeated, skipped, or extra actions fail
  closed without player-facing puzzle hints.
- Only the final qualifying predator contact is intercepted. It does not
  consume a life and cannot submit twice. Every other player and collision
  keeps the established behavior.

The guard is stored separately from `fred_save` v1 with atomic replacement.
That prevents an older ordinary checkpoint from reviving an invalidated run.
Malformed or incompatible guard data fails closed. This is deterministic local
anti-rollback state, not a claim that a client device is tamper-proof.

## Reveal and privacy UX

The reveal replaces the ordinary death screen with a full-screen Moonpetal
cinematic: a dimensional gold egg, metallic rings, petals, marsh glow, bubbles,
deterministic particles, and a bounded three-note Moonpetal discovery chime.
The chime is generated locally, contains no external asset or service, and
plays once only after the qualifying intercept. Reduced-motion mode retains the egg, rings,
contrast, copy, and privacy choices while suppressing pulsing and orbit motion.

Anonymous is the default. The player may explicitly choose to share their
existing marsh profile label. No rank, discovery time, public reference, or
secret code is generated locally. The UI states that those fields require the
secure App Vault service.

The owner-test reveal now has two additional explicit actions. **Open Golden
Egg Hunt** opens only the canonical HTTPS hunt page, and **Home** exits the
reveal and begins the next ordinary play session from Level 1. Privacy and
navigation controls use separate, tested rectangles at both requested review
sizes. Neither action changes the one-way discovery guard or manufactures a
server result.

## Shared backend contract

Fred uses the existing universal service at
`https://theflinsappvaultllc.com/golden-eggs` and its existing bootstrap,
discovery, privacy, session, and leaderboard endpoints. Fred's local constants
are:

- game ID: `fred-myers`
- Golden Egg ID: `moonpetal-golden-egg`

The companion local website registry change adds the same IDs and the App Store
record `6803295872`. It keeps global chronology across games and gives Fred
game-local ranks without resetting Overall Rank.

The client request builder implements the existing timestamp, nonce,
idempotency, player bearer, canonical body hash, and HMAC headers. It rejects
unsafe methods, endpoint traversal, incomplete server responses, missing bearer
state, and missing platform signing material. Signing material is ephemeral,
zeroed on clear, never serialized, and absent from this repository.

Live verification on 2026-08-23/24 now proves the public hunt page returns HTTP
200 and the Fred-filtered leaderboard returns HTTP 200 with both `snake-reactor`
and `fred-myers` in `participating_games`. The tested companion website commit
`426cb062b72ed20b088b7738c578d10af35cbaa5` has therefore reached the live
site. A deliberately invalid fictional bootstrap signature returned HTTP 401
`Request signature is invalid` instead of HTTP 503 `Game integration is not
configured`. The backend checks configuration before signature verification,
so this proves the protected Fred runtime key is present without authenticating
or writing a player, nonce, discovery, rank, or privacy record.

The owner-test Windows process does not contain a local Fred signer, and this
candidate intentionally stops at its signed-request builder and durable local
retry queue when a platform secure provider is unavailable. The credential was
not read, printed, copied, or stored in this workstream. Real client submission,
server timestamp/rank/code receipt, authenticated privacy update, and
discovery-specific link ownership remain **BLOCKED / UNVERIFIED** until an
approved client secure provider supplies the signer and the transport is
activated and validated. The secret must not be pasted into chat, committed,
or embedded in the ordinary save.

## Retry and recovery

The qualifying event first atomically stages a fictional/local pending record
with one stable idempotency key. Relaunch recovers that record. Retries keep the
logical payload/idempotency key while refreshing timestamp, nonce, and HMAC.
Only a complete authenticated server response can change the record to
accepted. Privacy updates are player-bound and a copied public code/link has no
ownership authority under the existing backend.

## Validation

Focused Godot coverage includes eligibility, ordered transitions, tight zones,
exact action counts, multiple death levels, direct-entry rejection,
save/reload/rollback resistance, idempotency, duplicate prevention, privacy,
path safety, ephemeral signing, authoritative server fields, reveal interception,
and 10,000 ordinary state observations. The complete historical Godot matrix,
readiness/import, Core/save invariants, owner-save hashes, desktop visuals, and
single shortcut are revalidated at the final local checkpoint.

Final executed evidence:

- focused Golden Egg suite: **104 passed, 0 failed**;
- complete Fred matrix: **28 suites, 8,294 passed, 0 failed**;
- readiness: **141 artifacts, eight fixtures**, Core 0.5.1, Godot 4.7;
- Windows runtime: normal 1280×720 and reduced-motion 960×540; privacy choices
  were exercised in the actual Godot window and remained responsive. The final
  owner-test pass also checks the canonical Hunt URL, non-overlapping controls,
  and reveal-to-Home Level 1 reset;
- final owner-handoff normal evidence:
  `godot/docs/evidence/golden-egg-owner-handoff-normal-1280x720.png`, SHA-256
  `f55a598ca1fb77c039e0d2c9f0815cb00ed646f95bc3975a00fe529ac4b72474`;
- reduced-motion evidence:
  `godot/docs/evidence/golden-egg-owner-handoff-reduced-960x540.png`, SHA-256
  `70ebbdef4491b6ebf77eccb68d7d24f7c295d4787fade0971811fa93285c8e37`.

The short-lived capture runner emitted the repository's known standalone
ObjectDB/resource teardown diagnostic during the second capture. The persistent
runtime review showed no script error, stuck input, overlap, or freeze, and the
capture-only hook was removed before the candidate commit.

The final desktop-link audit reproduced and fixed an Explorer-only launch
failure: an already-open Explorer process can retain a PATH that predates the
Godot WinGet installation. The launcher now resolves the existing pinned Godot
4.7.1 executables from the user-local WinGet package first, falling back to a
verified PATH file only when needed. A bounded ignored diagnostic records a
hidden launch failure and is cleared before the next successful attempt. The
launcher also computes candidate hashes through .NET so an Explorer process
with a stale PowerShell module path cannot disable integrity verification. It
does not install software or change machine settings. The exact `.lnk` path,
not just a direct script invocation, is required to pass the final launch gate.

The companion website build/tests cover Fred/Snake identity separation, global
rank continuity, per-game first/rank behavior, HMAC/bearer/idempotency controls,
server-owned timestamps/ranks, privacy ownership, and public data minimization.
The local website build completed and all **65 tests passed**. Live GETs and the
deliberately invalid authentication preflight above were executed; no live
player or discovery authenticated, no rank/code was issued, and no production
database record was changed.

## Release boundary

This is local owner-test evidence only. No branch was pushed, no PR was opened,
and this workstream did not deploy the website or change its production
database/secret. No Apple build was signed, uploaded, submitted, or released.
Authenticated app-to-backend and physical-device acceptance remain separate
owner-controlled gates.
