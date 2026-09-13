---
name: ip-provenance-governance
description: Audit or gate production assets, dependencies, licenses, attribution, repository exposure, and owner risk decisions for a Flins app or fleet. Use before adding external content or preparing a release.
---

# IP provenance governance

Read `governance/IP_PROVENANCE_POLICY.md` before sourcing external production content,
auditing an existing app, changing its registry, generating notices, or preparing release.

Use `governance/asset_registry.json` as evidence, not as a place to guess. Register
material production assets and dependencies with exact paths, source category, license,
commercial/modification/redistribution status, evidence, risk, repository exposure, and
owner decision. Leave unavailable facts `UNKNOWN`.

Run `python tools/ip_provenance.py audit --root <app>` during development and
`release --root <app>` before Apple preflight. Generate notices with
`python tools/generate_attributions.py --root <app>` after registry changes.

The development audit is advisory: findings guide validation and do not stop coding,
research, prototypes, or creation of original/project-generated work. Before an
external item is incorporated as a production/distribution asset, validate its rights
and provenance; if that cannot be completed, pause only that incorporation and ask for
a focused owner decision. Do not treat an approval to investigate, prototype, or keep
working as approval to ship the item. The release gate remains fail-closed.

For an existing questionable item, report it before removal, replacement, relicensing,
public-repository movement, history rewriting, or material app changes. Do not call
`ACCEPT_DOCUMENTED_RISK` license verification. RED remains release-blocking until
remediated or supported by verified compatible rights.

Do not quietly copy third-party material found online. Research and license verification
are allowed. Prefer a suitable original/project-generated solution; otherwise explain the
proposed source and license and obtain the required approval before incorporation.
