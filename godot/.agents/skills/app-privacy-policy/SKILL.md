---
name: app-privacy-policy
description: Prepare, publish, and verify an app-specific privacy policy on theflinsappvaultllc.com before Apple release work. Use for privacy inventories, privacy-policy URLs, App Store privacy alignment, or new-game policy publication.
---

# App Privacy Policy

Use the company website as the public authority. Never use the Pokémon Field Academy `/privacy` page for a native game. Every game receives exactly `https://theflinsappvaultllc.com/<game-id>/privacy`.

## Fixed workflow

1. Audit the exact candidate’s local storage, accounts, Game Center, Golden Eggs, provider-reported display name, public-name consent, analytics, advertising, purchases, location, device permissions, support inputs, and backend traffic.
   Golden Egg identity is linked user data used for app functionality, not tracking,
   only while it is never used for advertising, data-broker sharing, or cross-company
   advertising linkage. Public-name consent is separate from tracking permission:
   declining publishes `Anonymous`, and consent remains revocable.
2. Update `game/game.json` under `privacy`. Claims must match enabled capabilities and actual network behavior; never infer “Data Not Collected” from a draft.
3. Keep `review_status: draft` until the owner reviews the inventory, effective date, business contact, retention language, and App Store privacy answers.
4. Run `python3 tools/privacy_policy.py prepare --root <game-root>` and review the generated registry entry.
   The generated `remoteData` must use the website's camelCase boolean contract;
   never paste the app's nested snake_case audit records directly into that field.
   Keep the dedicated policy page's ID/version consistent with the registry. Registry
   sync alone does not publish or update a hand-authored dedicated policy page.
5. After approval, set `review_status: approved` and run `python3 tools/privacy_policy.py sync --root <game-root> --website-root <company-website>`.
6. Follow the website’s Sites build, version, deployment, and live-verification workflow. Publishing remains an explicit production action.
7. Run `python3 tools/privacy_policy.py verify --root <game-root>`. Require HTTP 200 plus the exact game ID and policy version markers. Golden Egg policies must also expose `data-golden-egg-public-name-contract="game-center-consent-v1"`; text that merely mentions consent is insufficient.
8. Reconcile the live policy with App Store Connect App Privacy answers and the shipped privacy manifest. Record these as separate evidence gates.

## Change rule

Any material capability or data-flow change creates a new policy version and effective date before the feature can ship. A prior game’s policy is a content model, not permission to copy claims. Keep local preparation, website publication, live verification, Apple privacy answers, and shipped-build behavior distinct.
