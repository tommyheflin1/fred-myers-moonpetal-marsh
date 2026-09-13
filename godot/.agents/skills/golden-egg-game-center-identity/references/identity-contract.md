# Identity contract

## App to backend

Before a locally verified discovery, the Golden Egg network request count is exactly
zero. Game Center authentication or use, normal startup, menus, gameplay, leaderboards,
achievements and campaign availability must not activate this client.

Submit a Golden Egg discovery only after the local Game Center authentication event
and `fetchItems(forIdentityVerificationSignature:)` succeed. The request contains:

- game ID, egg ID, evidence token, stable idempotency key and affirmative consent;
- bundle ID, `teamPlayerID`, and `gamePlayerID`;
- Apple public-key URL, signature, salt and timestamp;
- `GKLocalPlayer.displayName` as `provider_display_name` with source
  `game_center_reported`.

No free-text website name, client rank, discovery time, or first-finder claim is
accepted. A local solve is not a registered discovery.

After the reveal, resolve fresh identity and ask the explicit public-name question.
YES permits the provider-reported Game Center display name. NO submits consent=false,
uses `Anonymous` publicly, and may still register the verified discovery. A transport
failure preserves one pending logical discovery and the same idempotency key across
retries/restarts. It never reports server success locally.

## Backend verification

Fail closed unless the exact game/bundle pair is registered and enabled. Use the
server-verified `teamPlayerID` as the private identity across participating Flins
games and retain the provider-reported `gamePlayerID` for game-scoped audit. For
non-Arcade games Apple signs `teamPlayerID`, not the separately supplied
`gamePlayerID`; the latter must not reassign or deduplicate an account. Bind the
signed team identity atomically within the game namespace. Never merge by
display name, and never permit an app credential to cross a game/bundle boundary.
Require a recent
timestamp, single-use signature/nonce, stable idempotency semantics, rate limits and
an HTTPS Apple public-key URL on Apple's allowed host. Validate the certificate chain
and cache lifetime, then verify the Apple signature over the scoped player ID, bundle
ID, big-endian timestamp and salt with the documented algorithm. Bind the verified
signed ID to the authenticated account and game namespace. Reject raw or forged IDs.

Normalize the provider display name for length, Unicode controls and unsafe markup.
It may be stored or changed only during a fresh successful identity exchange. Record
its provenance and verification time. The signed proof authenticates the player ID,
not this display name.

Issue a short-lived, one-purpose discovery authorization. The discovery transaction
validates game evidence, consumes that authorization once, assigns server time/rank,
and returns only the public allowlist. Retries reuse the idempotency key and result.
Public references and secret codes cannot claim, link, or modify private identity.

## Website

The website reads only server-created public discovery records. It has no editable
finder-name field. Show `Anonymous` unless public consent is current. Otherwise show
the sanitized `public_player` and, when useful, a non-misleading “Game Center name”
label. If two verified identities have the same display name, append a stable,
non-sensitive server-generated suffix such as `A7K2`; do not derive it visibly from
a player identifier. Never expose provider IDs, account IDs, tokens, signatures,
salts or key URLs.

Provide revocation/anonymization and data-deletion paths. Refresh the game privacy
policy and App Store privacy answers whenever stored identity behavior changes.
Offline discoveries remain queued or Anonymous. Linking them later requires explicit
consent plus a fresh verified identity exchange; never auto-link by device or name.

## Required evidence

- fictional valid, stale, replayed, wrong-bundle, wrong-game and foreign-key tests;
- duplicate/idempotency, consent-off, name-change and deletion tests;
- website tests proving no name-input path and no private fields in responses;
- exact TestFlight build on a physical device proving cancel, sign-in, relaunch,
  discovery, website display, consent withdrawal and offline failure behavior.

Primary Apple reference, checked 2026-09-05:
https://developer.apple.com/documentation/gamekit/gklocalplayer/fetchitems(foridentityverificationsignature:)
