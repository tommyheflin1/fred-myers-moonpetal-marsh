---
name: app-store-package
description: Prepare and validate non-code App Store requirements for a Flins game, including app-owned story and product copy, support and privacy URLs, screenshots, icon, compliance decisions, TestFlight notes, and review readiness. Do not use it to invent or approve the game's visual identity.
---

# App Store package

Treat `store/app_store_package.json` as the versioned manifest and
`store/screenshots.json` as its exact-build media inventory. When Game Center is
enabled, `store/game_center.json` is the immutable-ID and achievement-art contract;
every runtime achievement must have a matching App Store Connect record and unique
1024x1024 image under `assets/store/game-center/`. Run
`python tools/store_readiness.py draft --root <project>` while developing and
`release --verify-live` before Apple preflight.

Every game also carries `store/audio_package.json`. Release requires at least one
nonempty, hashed track created specifically for that game under `assets/audio/custom/`,
plus rights, runtime mix, loop/transition and owner review. Do not reuse another game's
music as compliance. A missing-music exception is valid only when the owner explicitly
approves the `custom_music` gate for the exact marketing version and build.

The harness owns required fields, limits, evidence, order, validation and gates.
The game owns its story premise, player role, objective, product language,
visual direction, icon, screenshots and optional preview. Do not reuse another
game's names, story, screenshots, characters, claims or age rating.

Derive claims from the tested build. Screenshots must show the real app, use the
exact candidate version/build/commit, contain no account chrome or private data,
and receive owner visual review. Do not fabricate a native Game Center screen;
capture it only after the exact TestFlight build passes on an Apple device.

Keep every discretionary public-facing field vendor-neutral. Do not name external
companies, vendors, marketplaces, websites, tools, or content sources in app copy,
screenshots, website copy, policies, support text, achievements, or marketing. Record
the completed review in `public_copy_review` with empty external-name lists. Necessary
first-party URLs, platform UI labels, and legally or contractually required attribution
or privacy disclosures are narrow exceptions; record their exact text and basis under
`required_disclosures` and do not turn them into promotional references.

Reconcile privacy URL and App Store privacy answers with all first- and
third-party code. Confirm content/media rights, age rating, accessibility,
export compliance, price, storefront availability, agreements and any Game
Center records. Achievement IDs and live point values are permanent after release;
the validator caps each at 100 points, the app total at 1000, and refuses duplicate
IDs or artwork. Use manual release unless the owner explicitly decides otherwise.

For a Golden Egg game, release readiness also requires the bundled website contract,
verified Game Center identity, affirmative public-name consent, production endpoint,
and exact TestFlight device flow to be separately reviewed. Local fixtures do not
satisfy those five gates.

Never treat a general instruction to finish or release as permission to waive a failed
harness gate. `release_exceptions` must name one gate, state a reason, match the exact
version/build, and record owner approval. It does not authorize signing, submission or
public release.

Draft validation proves only schema/limits. Release validation requires approved
content, real assets and live support/privacy pages; it does not authorize upload,
TestFlight assignment, App Review submission, pricing, or public release.
The support page must return HTTP 200 with `data-support-id="<game-id>"`; a
generic homepage, redirect or catch-all response does not satisfy the gate.
