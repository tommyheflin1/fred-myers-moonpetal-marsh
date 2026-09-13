# App Store package contract

The harness locks the non-visual work needed from development through Apple.
It does not choose a game's art style, story, characters or marketing voice.

## Mandatory defaults

| Area | Harness requirement | Game-owned decision/evidence |
| --- | --- | --- |
| Identity | Stable name, bundle/SKU/version/build consistency | Final name, subtitle and category |
| Story | Premise, player role, objective and truthful gameplay claims exist | Original story and exact wording |
| Product copy | Apple limits and required fields validated | Description, keywords, What's New, promo and review notes |
| Web | Dedicated `/game-id/privacy` and `/game-id/support` URLs | Approved policy/support copy and live website publication; support page carries `data-support-id="game-id"` |
| Privacy | Runtime capabilities, third-party SDKs and paid status reconcile | Owner-approved inventory and App Store answers |
| Golden Egg identity | No website-entered finder name; server-verified scoped Game Center identity; consent-gated provider-reported display name; linked user data for app functionality and never advertising tracking | Exact device/backend/website evidence and privacy approval |
| Pictures | 1-10 exact-build screenshots per enabled device class, valid current Apple dimensions, no alpha/private data, unique hashes | Original icon, screens, overlays, order and visual approval |
| Game Center | Capability-matched manifest; permanent unique IDs; localized earned/unearned copy; behavior flags; 1-100 points each and 1000 total; one unique hashed 1024x1024 image per achievement | Game-specific achievements, artwork, App Store Connect record review and exact-build device proof |
| Music | At least one hashed, nonempty game-specific OGG/MP3/WAV track; rights, runtime mix and loop/transition gates | Original composition/source, soundtrack role and owner approval |
| Testing | Beta purpose and observable test list required | App-specific controls, story path and edge cases |
| Compliance | Explicit age-rating, rights, privacy, export, accessibility, SDK, price, agreement and availability reviews | Truthful owner/legal/business decisions |
| Apple | One exact-commit preflight/archive/upload/status lane with separate gates | Credentials, signing, upload, testing, submission and release approvals |

`store/app_store_package.json` is the source of truth. `store/screenshots.json`
binds media to the exact capture commit in the final candidate's history and hashes.

Manual release is the default. An explicitly owner-approved automatic release uses
`release_authorization` with `mode: automatic`, `owner_approved: true`, the exact
`exact_version` and `exact_build`, and a nonempty `reason`. That record authorizes
only the selected release mode; all other gates remain unchanged.
This avoids an impossible self-referential final commit hash while forbidding media
from another branch/build. The media manifest's version/build must equal the final
candidate. `draft` validates structure
without pretending placeholders are approved. `release --verify-live` requires
all decisions, assets, exact provenance and both public pages before Apple preflight.

Screenshot files stay under `assets/store/`. For current iPhone support, supply
at least one accepted 6.9-inch set; for iPad support, supply a 13-inch set. The
validator accepts the currently documented portrait or landscape dimensions and
rejects transparency, duplicates, unsupported formats, external paths and hash
mismatches. Visual inspection remains mandatory because dimensions cannot prove
truthfulness, legibility, ownership or quality.

App previews are optional and therefore not generated as a false requirement.
Native Game Center product imagery may be added only after the exact TestFlight
build passes on-device. Screenshots are product-page material, not CI evidence;
privacy-safe CI bundles continue excluding them.

`store/game_center.json` binds Game Center metadata and artwork to runtime behavior.
It does not force every title to have 25 achievements: it forces one valid App Store
Connect record and one unique image for every achievement that title declares. Thus
Snake Reactor's 25-achievement catalog requires exactly 25 matching images. Released
IDs are never renamed or recycled, and released point values are not changed.

Golden Egg participation is a release package, not only an Easter egg asset. A release
must prove the app-to-website contract, server-verified Game Center identity, consent
and Anonymous fallback, production endpoint isolation/replay protection, and the real
TestFlight discovery/privacy/website flow. Typed website names and public player IDs
are forbidden.

The privacy inventory must declare the player identifier, provider display name, and
discovery record as linked data used for app functionality when Golden Eggs are enabled.
The separate public-name choice is consent to publish that provider-reported name; it is
not tracking permission. The contract forbids advertising use, data-broker sharing, and
cross-company advertising linkage. Any such future behavior requires a new privacy and
tracking review before implementation or release.

`store/audio_package.json` proves that the candidate includes custom music made for
that game. A release fails when the track is absent, reused, unhashed, outside the
approved path, unreviewed for rights, or not exercised in runtime mix and transition
tests. An owner may approve a narrow `custom_music` exception only for the exact
version/build with a recorded reason; no blanket waiver or inherited approval exists.

Every other harness failure remains blocking unless its owning contract explicitly
defines an equally narrow owner-approved exception. Approval of one asset or gate does
not approve other functions, signing, submission, or public release.

Official requirements reviewed 2026-09-01:

- Screenshots and previews: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots
- Accepted dimensions: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Name/subtitle/privacy URL: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Version field limits: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Review submission: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- Privacy answers: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Achievement setup: https://developer.apple.com/help/app-store-connect/configure-game-center/manage-achievements/
- Achievement metadata limits: https://developer.apple.com/help/app-store-connect/reference/game-center/achievements
- Achievement artwork: https://developer.apple.com/design/human-interface-guidelines/game-center

Recheck primary Apple documentation before each release. Specifications can
change; do not treat this dated review as permanent legal or platform advice.
