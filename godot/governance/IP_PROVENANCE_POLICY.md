# Asset, intellectual-property, licensing, and provenance policy

The Flins App Vault has broad freedom to create and extremely limited freedom to copy.
Original code, shaders, procedural art, effects, mechanics, writing, tests, and other
project-created work may proceed when truthfully registered. Public availability or a
zero price never establishes commercial-use or redistribution rights.

This policy is a validation workflow, not a development stop. Its development audit is
advisory and must return its findings without failing the work session. Research,
prototyping, and original/project-generated creation continue normally. A questionable
external item pauses only at the point where it would be adopted as a material
production/distribution asset: first validate the source, license, commercial use,
modification, redistribution, attribution, and repository exposure; if evidence is
still unavailable, request an item-specific owner decision. Approval to continue work
does not itself clear an asset for distribution, and no decision waives unrelated gates.

Every material production/distribution asset and dependency must be registered in
`asset_registry.json`. Unknown facts stay `UNKNOWN`; agents must not infer rights from
filenames, appearance, popularity, or accessibility. Approved categories are
`SELF_GENERATED`, `PROJECT_GENERATED`, `OWNER_CREATED`, `OWNER_SUPPLIED`,
`OWNER_EXPLICITLY_APPROVED`, `FAB_VERIFIED`, `SUNO_COMMERCIAL_VERIFIED`,
`APPROVED_OPEN_SOURCE`, `APPROVED_PUBLIC_DOMAIN`, `APPROVED_CREATIVE_COMMONS`,
`APPROVED_SYSTEM_OR_PLATFORM_RESOURCE`, and `OTHER_EXPLICITLY_APPROVED_SOURCE`.

Unresolved items are `UNKNOWN_PROVENANCE`, `LICENSE_REVIEW_REQUIRED`, or
`POTENTIALLY_INCOMPATIBLE`. Baseline audits only discover, document, classify, and
report. They never delete, replace, move, relicense, rewrite history, or change a
released build. An owner decision may request `ACCEPT_DOCUMENTED_RISK`, `REPLACE`,
`REMOVE`, `OBTAIN_LICENSE`, `ADD_ATTRIBUTION`, `MOVE_SOURCE_OUT_OF_PUBLIC_REPOSITORY`,
or `INVESTIGATE_FURTHER`. Risk acceptance records direction; it is not legal clearance.

Required attribution flows from the registry into `ATTRIBUTIONS.md`. Do not add
unnecessary attribution. Raw licensed assets in public repositories require explicit
redistribution compatibility, independently of permission to ship them in a compiled app.

Internal provenance evidence may identify a source so rights can be audited, but
discretionary public-facing material must remain vendor-neutral. Do not publish external
company, marketplace, tool, source-site, or unrelated website names in app, website,
policy, support, achievement, screenshot, or marketing copy. First-party service URLs,
platform-required labels, and legally or contractually required attribution or privacy
disclosures are the only exceptions; keep them minimal and record their exact basis.

Agents may research or verify licenses online but may not silently incorporate assets
from image search, social media, fan sites, mirrors, ripped applications, commercial
entertainment, arbitrary repositories, or similarly unapproved sources. Prefer an
original solution when practical. Owner-supplied material is recorded, not presumed
clear when an obvious third-party concern exists.

`tools/ip_provenance.py audit` reports evidence and uncertainty. `release` fails on
unregistered production material, unresolved license/attribution/public-repository
findings, incompatible dependencies, and every RED finding. YELLOW/ORANGE findings
need an explicit item-specific owner decision; RED requires remediation or verified
rights rather than a risk-acceptance label. Passing is engineering evidence against
the available registry, not a legal opinion.

Untracked experiments and temporary research files are outside the production scan.
They must remain excluded from exports and distribution. Once an asset is selected for
the app and tracked as production material, it must be registered and is subject to the
release gate. A clean exact-commit Apple candidate therefore cannot hide a selected
production asset as an untracked experiment.

Tracked review captures under `docs/evidence/` are non-production documentation and are
excluded from the production-asset scan. The release/export process must continue to
exclude that directory. A capture or source asset selected for the shipped app or store
package must live in its production path and be registered there; `docs/evidence/` is not
a provenance bypass.

For the workspace baseline, run `tools/audit_ip_fleet.py` with explicit JSON and
Markdown output paths. It discovers the registered app fleet plus top-level Godot and
Sites projects, records public-repository uncertainty, and lists every non-GREEN item
under `OWNER ATTENTION REQUIRED`. The command is read-only except for its two reports.
