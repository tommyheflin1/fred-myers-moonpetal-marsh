---
name: golden-egg-game-center-identity
description: Implement or audit the secure Game Center identity path used for Golden Egg discoveries on theflinsappvaultllc.com. Use when a game, backend, or website records or displays a Golden Egg finder.
---

# Golden Egg Game Center identity

**GOLDEN EGG WEBSITE INTEGRATION IS DISCOVERY-TRIGGERED, NOT STARTUP-TRIGGERED.**

GOLDEN EGG = HIDDEN IN-GAME DISCOVERY. Generated games must not advertise it in
home, rules, settings, leaderboards, badges or persistent navigation. Reveal and
publication controls belong only to verified-discovery results, never normal menus.
Any visible Hunt entry point requires explicit per-app owner approval and review;
enabling the capability alone is not that approval. Test normal navigation both
before discovery and after returning home from a discovery result.

Discovery is a temporary event, not an unlocked navigation category. Closing it
removes reveal, consent and verification controls, including after YES or NO.
Preserve duplicate prevention and pending state without advertising it. Any recovery
UI must be temporary and limited to that already-triggered attempt. Test fresh launch,
all normal menus and pause, actual verifier transition, consent outcomes, close, and
normal navigation again. A replayed result flag must not reopen a closed event.

Never call the Golden Egg website/backend during launch, menus, ordinary gameplay,
Game Center initialization, native leaderboard display, achievements, or generic
version checking. These paths must work offline and must record zero Golden Egg
requests. Only a locally verified Golden Egg discovery may reveal the consent UI and
activate the submission client. Website failure after discovery creates a nonblocking,
durable, idempotent pending submission; it never fabricates verification or blocks play.
Minimum-version enforcement is a separate explicit capability.

Read `references/identity-contract.md` before changing the app, backend, website,
privacy inventory, or release tests for a Golden Egg flow. For an existing app,
also read `references/app-migration.md` and verify every identifier from the active
candidate and deployed website contract; never fill a missing identifier by guess.

The website never accepts a finder name typed into a form. The app obtains
`GKLocalPlayer.displayName` only after successful Game Center authentication and
sends it with a fresh identity-verification payload to the backend. The backend
verifies Apple's signed identity fields, binds the private cross-game identity to
`teamPlayerID`, retains `gamePlayerID` for game-scoped audit, checks the bundle/game
pair, records the display name as `game_center_reported`, and issues the discovery
result. Only the backend may publish a finder record.

Apple does not sign the display name. Never label it cryptographically verified.
Treat it as provider-reported metadata bound to a cryptographically verified player.
Require affirmative public-display consent; otherwise publish `Anonymous`. Do not
expose the player identifier, signature, salt, public-key URL, session token, or a
stable cross-game correlation value to the website or public API. Never merge by
display name. Identical public names remain separate verified identities and receive
a non-sensitive, server-generated display suffix when distinction is necessary.

Preserve offline discoveries without silently binding them to an account. Later
linking is explicit and requires a fresh server-verified exchange. An account switch
on a shared device must not transfer queued or completed discoveries. Roll production
enforcement out backward-compatibly only after participating builds and the website
support the contract.

Use fictional fixtures for local tests. Production Game Center authentication,
website publication, and real-player processing require their respective owner and
privacy approvals. Physical TestFlight evidence remains a separate release gate.
