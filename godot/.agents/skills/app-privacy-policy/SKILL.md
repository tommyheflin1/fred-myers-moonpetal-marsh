---
name: app-privacy-policy
description: Prepare, publish, and verify an app-specific privacy policy on theflinsappvaultllc.com before Apple release work. Use for privacy inventories, privacy-policy URLs, App Store privacy alignment, or new-game policy publication.
---

# App Privacy Policy

Use the company website as the public authority. Never use the Pokémon Field Academy `/privacy` page for a native game. Every game receives exactly `https://theflinsappvaultllc.com/<game-id>/privacy`.

## Fixed workflow

1. Audit the exact candidate’s local storage, accounts, Game Center, Golden Eggs, analytics, advertising, purchases, location, device permissions, support inputs, and backend traffic.
2. Update `game/game.json` under `privacy`. Claims must match enabled capabilities and actual network behavior; never infer “Data Not Collected” from a draft.
3. Keep `review_status: draft` until the owner reviews the inventory, effective date, business contact, retention language, and App Store privacy answers.
4. Run `python3 tools/privacy_policy.py prepare --root <game-root>` and review the generated registry entry.
5. After approval, set `review_status: approved` and run `python3 tools/privacy_policy.py sync --root <game-root> --website-root <company-website>`.
6. Follow the website’s Sites build, version, deployment, and live-verification workflow. Publishing remains an explicit production action.
7. Run `python3 tools/privacy_policy.py verify --root <game-root>`. Require HTTP 200 plus the exact game ID and policy version markers.
8. Reconcile the live policy with App Store Connect App Privacy answers and the shipped privacy manifest. Record these as separate evidence gates.

## Change rule

Any material capability or data-flow change creates a new policy version and effective date before the feature can ship. A prior game’s policy is a content model, not permission to copy claims. Keep local preparation, website publication, live verification, Apple privacy answers, and shipped-build behavior distinct.
