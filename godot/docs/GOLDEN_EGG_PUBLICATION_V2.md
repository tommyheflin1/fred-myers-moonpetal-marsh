# Shared publication-v2 wire contract

Candidate 30 adds `GoldenEggPublicationContract` in Core and the generated template.
Website source reviewed: Fred-owned checkpoint
`afe3e141ab8e6de9ab799b5463335f78d907219a`. This source checkpoint is NOT proof of
production deployment. Do not enable publication based on a source commit alone.

Use the existing app-bound authenticated transport, secure credentials and nonce /
idempotency handling. The adapter does not bootstrap, sign, send HTTP, retry, or verify
an Apple signature. `game-center-identity-v1` is now an allowed identity-exchange header
protocol; discovery uses the established authenticated app lane, not an embedded secret.

After local discovery and explicit Public/Anonymous choice, exchange fresh identity.
For Public, show the sanitized provider name returned by that authenticated exchange
and require the player to approve that exact name. A changed name needs another review.
Call `discovery_body` with the original logical discovery and exchange authorization.
It allowlists fields, marks `golden-egg-publication-v2`, rejects expired authorizations,
and never emits typed names/ranks or any Local-only body. Local-only stays in the durable
discovery service and never reaches transport. Anonymous is a distinct publishing action.

Pass only the matching authenticated HTTP success response to `accepts_discovery`.
It rejects pending/privacy-choice responses, mismatched choices/names, malformed ranks,
foreign URLs and misleading anonymous identity labels. Use `public_result` for UI data;
private session URLs/tokens are stripped. Preserve required private credentials only in
the existing secure store. This allowlist does not prove the server actually verified
the discovery or that the caller routed the matching response: test the real handlers.

Use `privacy_body` for explicit later Public/Anonymous changes. Public requires another
fresh exchange and reviewed name; Anonymous revocation does not require new public-name
consent. The authenticated server still enforces ownership and game/app isolation.

On 401 refresh identity; on name-conflict409 require review; on transport/404 failure
preserve pending without blocking play. Never downgrade v2 to legacy typed-name behavior.
Keep ordinary startup, menu, native leaderboard, and gameplay free of Hunt requests.

Regression: `tests/golden_egg_publication_contract_test.gd` uses fictional fixtures.
It is not real player, production backend, native Keychain or installed-device proof.
All consumers still require their own transport/lifecycle tests and release evidence.
