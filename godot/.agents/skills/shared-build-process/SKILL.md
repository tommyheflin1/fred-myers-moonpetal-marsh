---
name: shared-build-process
description: Audit and maintain the shared Flins development-to-Apple process across independent games. Use before a new game, release candidate, harness upgrade, or migration of app-specific release tooling.
---

# Shared build process

Read `docs/SHARED_BUILD_PROCESS.md` from the project root. For Apple work then read
the `apple-remote-delivery` skill and its routed references; for policy changes read
`app-privacy-policy`. These skills are shipped together in this harness.

Run `python tools/audit_process.py --root <candidate>` from the canonical harness.
For all registered checkouts use `--fleet <workspace>`. Missing tools or mismatched
hashes are migration work, not evidence that a different uploader is needed.

Use the app's exact active commit, not its newest folder name or a released baseline.
Review differences before copying anything: preserve app identity, native adapter,
Core pin, saves, achievements, secrets outside the repository, and existing artifacts.
Document pending migrations honestly. Never mark an app adopted from documents alone.

Promote reusable fixes with a reproduction, fictional fixtures, passing regression,
reviewed process-lock digest update, and generated-game smoke check. Keep mechanics
and art in their app. Run the fleet audit after a process revision; carry unresolved
differences forward with a named candidate and next gate. Do not silently rebase apps
or update their Core versions. No automatic publishing, signing, or live data access.
