# Existing-app migration

Inventory the exact active Apple candidate before editing. Verify app name, game ID,
egg ID, bundle ID, branch and commit from tracked configuration and the compatible
website/API contract. Stop if any identifier conflicts or cannot be verified.

Change only identity and Golden Egg integration. Preserve gameplay, hidden solution,
progression, saves, scoring, native leaderboards, ranks, timestamps, public references,
secret codes, signed artifacts and Apple-review state. Remove every editable finder
name and do not disclose the solution in source comments, test names, logs, analytics,
metadata, screenshots or reports.

Remove Golden Egg policy, availability, campaign, leaderboard, minimum-version and
publication requests from startup/menu/Game Center initialization. Do not replace them
with ignored failures: the request must not occur. Keep an explicitly enabled mandatory
app-update service separate. Instrument the migrated app and prove a zero Golden Egg
request count through launch, menu, gameplay, Game Center authentication, leaderboard
and achievements. Backend contact begins only after verified local discovery and the
YES/NO choice.

The UI shows the authenticated Game Center name read-only and explains that it will
appear publicly when consent is granted. If Game Center is canceled or unavailable,
preserve the discovery for retry or Anonymous publication without exposing internals.

Before enabling strict production enforcement, prove backward compatibility for
existing discoveries and deploy compatible app and website/API changes in a staged
order. Production changes and real-player processing remain protected actions.

Required fictional tests cover: valid submission; automatic read-only name; no custom
name; manipulated display-name rejection; identical-name separation; verified
cross-game recognition; shared-device account switch; forged IDs; invalid signature;
stale/replayed proof; wrong bundle; wrong game credential; idempotent duplicate;
Anonymous/offline queue; existing regression suites; and absence of private identity
or solution material from outputs.

Report the exact candidate and identifiers, files changed, website/API compatibility,
test counts, process audit, naming removal, identity separation, offline/Anonymous
behavior, device/TestFlight state and every untouched protected Apple gate.
