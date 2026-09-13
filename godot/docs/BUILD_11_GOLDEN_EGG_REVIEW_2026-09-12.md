# Fred Build 11 Golden Egg and export review

## Later owner-directed superhero revision

The owner rejected the ordinary frog emblem and requested a superhero frog. The
current artwork adds an original domino mask, crimson cape, navy suit and gold F
crest. The old artwork hash and capture below are historical, not the current art.
Current `scripts/golden_egg_art.gd` SHA-256:
2fab9ff30ca97930a10d8fd96d45cb7d79fc38b96e3d1215ab5b751be21962c1.
The revised real-renderer capture was visually inspected; 18 renderer checks,
297 artwork checks, 25 Level 5 checks, 42 consent-review checks and 36 pause checks
passed after this revision. The earlier all-47 run predates only the artwork revision.

The requested reusable fix was also promoted to process candidate 26: privacy registry
serialization now matches the website's actual schema, preserves other entries and
rejects unapproved sync. Canonical regression: 104 tests passed; Fred process audit:
MATCH. Fresh generated app static validation/audit/privacy prepare passed. Historical
fleet checkouts remain explicit MIGRATION_REQUIRED and were not silently modified.
See the canonical harness `docs/PRIVACY_REGISTRY_CANDIDATE_26.md`.
These changes do not resolve the publisher's independent upload timeout or establish
Apple authentication, privacy approval, native testing or submission.

### Subsequent live Mac/Apple verification

The existing RDP session remained usable. Read-only terminal checks confirmed
`/Users/admin/downloads/fred-build10-81814f7/godot`. The preserved command
`tools/release-ios status c1911a422cc33cbd317a5144fbf4a35858f26a09` ran successfully:
version 1.1, Build 10, VALID, APPLE_PROCESSED. Existing external Apple API credentials
therefore work; the signed-out browser is not an authentication blocker for that lane.
Using the same receipt helper's GET-only request and classifier, an exact 1.1 Build 11
query returned APPLE_NOT_RECEIVED. No private key/token was printed or copied and no
source/signing setting was changed on the Mac. An initial punctuation-transport
failure was corrected with explicit shifted key combinations, not session resets.

The superhero revision's unsigned resource pack was exported and inspected: 154
files, no prohibited paths, required configuration present and frog art loadable.
Canonical harness fix is committed locally as
a0e66a2fde2b2cf79f4c83a06a0e2376bd31ef75; no public-source push was performed.
The earlier statement that Apple sign-in is needed is superseded for API release
checks; website publication, approved privacy/store evidence and native-device gates
remain unresolved. Build 11 has still not been archived or submitted.

Scope: Fred Myers: Moonpetal Marsh, iOS 1.1 (11). Local candidate remains on
59f681e669ec186469198e83c68aeea4133cf80d with task changes uncommitted.
This is not frozen-source, signed-iOS, TestFlight, App Review or live-release proof.

## Implemented and actually checked

- Replaced the simple ellipse/face with original procedural artwork: tapered gold
  shell, metallic contours, emerald medallion, smiling frog, lily wreath, jewel and
  fixed highlights. Both the secret room and reveal call the same drawing function.
  No third-party artwork, downloaded texture, private data or new network dependency.
- Kept the discovery/consent/Anonymous/website/Return to Level 5 logic separate from
  artwork. Rendering checks prove the reveal does not draw gameplay HUD controls,
  ordinary gameplay does, and returning restores active Level 5 at its beginning.
- Preserved the fresh read-only Game Center name review and second affirmative
  Share action implemented in the previous continuation. Local fixture checks pass;
  the corresponding production backend changes remain unpublished.
- Both export presets now exclude tests, tools, docs, build caches, store metadata,
  governance, agent instructions and store screenshots. Required runtime configuration
  and the public verification key remain included. This is app-owned configuration,
  not a change to the locked release lane.
- Scene teardown explicitly stops and clears all three audio players, including
  paused music and the Golden Egg chime. Active/paused teardown has a dedicated test.
  The soundtrack test lets the mixer drain after deferred scene destruction.

## Evidence

- 297 deterministic Golden Egg artwork checks passed.
- 18 real-renderer reveal/HUD/title/Level 5 return checks passed. The reveal image was
  visually inspected: frog crest is prominent, no text overlaps the egg, and all four
  consent/website/return buttons remain visible.
- Final all-game run: **47 suites, zero failed**, process exit 0. Logs:
  `builds/validation/final47-20260912-201703`. Nine suites still emitted shutdown
  ObjectDB/resource warnings; do not call this a warning-free run. Verbose diagnostics
  identify audio streams/playbacks held during shutdown. No on-device audio acceptance
  is inferred from these desktop tests.
- An earlier 46-suite wrapper falsely matched `passed=53 failed=0` as failure; every
  test process exited 0, and anchored reinspection found zero actual failure markers.
  The corrected final 47-suite run above supersedes that wrapper result.
- App release/preparation scripts: 115 checks passed; Fred Python suite: 12 passed.
- Exact canonical harness audit: process 1.8.0-candidate.25 MATCH. Runtime/Apple
  verified flags remain false.
- Final unsigned iOS-preset resource export succeeded. Inspection with Godot's pack
  loader found 154 files, zero prohibited paths/imported review captures, no missing
  required resources, and a loadable frog-art script. This is not an Xcode archive.

SHA-256:

- `scripts/golden_egg_art.gd`: 75e176643805ee381d17569d4bc0b2448e529cf49b74dd773603b866c598d984
- `scripts/main.gd`: 271b41356110f5ce0a2c82c9cf0fa6e7739e93c0da45082571751eb922787288
- `export_presets.cfg`: 2e3e55e167ed8b6940860562afcbd9fdc38882a3cc8511eaa08dbbe57af48f4c
- `builds/validation/art-export/FredBuild11-final.pck`: d4dd463063f09d5fecfce7b89505e0bc36527412a25652d8b0c1933967624d5f
- `builds/reveal-boundary-review/egg-reveal.png`: 98b254e8abe3b28d09add5c08e413218345fdec5484deB1ba08905ec40cd86e5

The capture is local visual evidence, not an approved frozen-commit App Store image.

## Release boundary checked, not bypassed

- Existing website source c0807276b62185c0988655886fc39ca92c99d30e remains pushed.
  Reconciled Sites history: no newer saved version than 82. Retrying its unchanged,
  previously verified archive failed in native file-blob upload after 60008 ms:
  request 4dec5a68-a92d-460e-a1f7-e3317480c9da. No version/deployment was created.
- Public Fred mandatory-update verification actually returned HTTP 404 with network
  permission. A preceding sandbox socket error was not mistaken for a server response.
  The release client must not be shipped while its required startup service is absent.
- Website fixture suite: 152 passed before the registry-marker repair; the five
  focused privacy cases passed after repair. The existing production Vinext build
  succeeded after repair. The helper's package-manager launch failed, so the same
  previously proven local build command was used; no dependencies were replaced.
- The dedicated policy and website registry now both carry draft
  fred-myers-2026-09-10-v2. Existing camelCase web schema is preserved; the generator's
  nested snake_case fields are not blindly copied into the website. Privacy prepare
  succeeded; approval/sync/live verification remain outstanding.
- Apple browser inspection showed empty sign-in fields. No credentials were entered,
  no remote desktop was reconnected, and no Apple/signing account was reset.
- Internal-TestFlight readiness remains FAIL for unreviewed Golden Egg production/
  identity/consent/website gates, mandatory policy, SDK inventory, creative/store
  approval, audio mix and unfrozen screenshot registration. The three existing
  exact-build physical-device deferrals are unchanged and do not waive other gates.

Resume the same release-ios lane only after its actual prerequisites pass. No Build 11
archive, Apple upload, review submission or public update was performed in this pass.

## Premium superhero revision and callback parity follow-up

The two owner briefs received September 12 supersede the earlier procedural egg
visual target. Built-in image generation produced the local transparent collectible
`assets/art/fred-superhero-golden-egg-v1.png` (SHA256
`1c1b2f86b7b35be499dcef1e7fe0aed3e6a299481f7102f70e0aa5d1c64833db`).
Reference: existing Fred app icon, not TurboRack branding. Prompt: production
in-game collectible, polished dimensional gold egg, sculpted amber-eyed Fred
with navy mask/suit, crimson cape, gold F crest, moonpetal engraving, transparent
background, full front-view silhouette; no third-party superhero insignia.
Built-in output: `exec-d9062f5f-3bae-4ee4-87f5-2958ba2f61f1.png`.
The cached texture renders in both the room and reveal, with restrained rim
sparkles/brightness modulation and a static reduced-motion path. This is not a
signed-iPhone performance claim or owner approval of the final rendered frame.

Directly inspected TurboRack's actual adapter. Both use asynchronous native
event polling and the native leaderboard. Found shared unbounded queue-drain
risk and Core stopping callback polling after authentication. Added bounded
32-event pump in Core commit `738a910` and harness candidate 27 commit `3e008d2`;
Fred explicitly adopts it. Fred also clears stale identity on reconnect and
rejects successful authentication callbacks missing a player ID. These are
reproduced code risks, not proof of the historical device freeze's root cause.
TurboRack source, leaderboard IDs, signing and released pins were not altered.

Current evidence after these changes:
- Fred full suite: 47 suites, zero failing exits, logs
  `builds/validation/hero-parity-20260912-211046`.
- Fred adapter: 56 checks; egg asset: 298 checks; real rendered boundaries and
  captures: 18 checks, all passed. Captures now show the premium texture.
- Core: 113 normal checks plus dedicated callback-pump regression passed.
- Harness: 104 Python tests passed from its own root. First invocation from
  workspace root had an import-path error, corrected without changing tests.
- Generated candidate-27 app: process MATCH, FRESH_GAME_OK, actual pump test PASS.
- Fred candidate-27 process audit MATCH. Other fleet checkouts still require
  explicit migration; no automatic fleet changes were made.
- Website: 153 tests passed locally; not production verification.
- Existing `iOS Unsigned Preparation` export produced
  `builds/validation/art-export/FredBuild11-premium-hero.pck`; pack scan PASS,
  158 files, no forbidden paths, required resources present, hero art loadable.
  An initial wrong preset name failed before export and was corrected by using
  the exact preset reported by Godot. This is not a native archive or IPA.

Production was rechecked: public Sites project still version 82. Local D1/R2
configuration uses placeholders supplied by Sites; it is not an independent
Cloudflare production deployment. No repository CI/SSH deployment lane was found.
Available publish-on-push capability is owner-private only and cannot replace this
public site's route without changing audience. The connector requires a packaged
archive when local packaging works; omitting it to dodge transport is not supported.
Prior preserved archive transfer failed in the OpenAI blob transport before any
saved version/deployment. Current live Fred policy verifier again returns HTTP 404.
The remote tab was preserved; current screenshot showed only desktop wallpaper,
not an accessible terminal/device, so no blind commands or reconnect were sent.
Privacy v2 exact-disclosure approval was requested separately and remains pending.
Build 11 is not archived/uploaded/submitted by this follow-up. Native-device,
production integration, remaining store review and approval gates are not waived.

### Exact production 404 trace, subsequent owner continuation

Actual request: GET
`https://theflinsappvaultllc.com/api/app-updates/policy?bundle_id=com.flinsvault.fredmyers&platform=ios`.
Fred sends `Accept: application/json`; the release verifier uses
`User-Agent: FlinsUpdatePolicyGate/1.0`. Production returns JSON
`{"error":"Unsupported app policy request."}`, HTTP 404, no-store.
The same domain/path with TurboRack's exact bundle returns HTTP 200 with a signed
900-second policy. This proves the route is running, not absent or statically
exported. The 404 is the handler's supported-app guard, not DNS, login, case,
trailing slash or an unavailable web host. Version 82 source b5290d95 lacks Fred
in supportedApps; c0807276 adds it using the existing signing implementation.

The corrected, previously pushed c0807276 artifact was retried unchanged after
SHA256 verification. Native version-save failed in OpenAI blob transfer to
sdmntprwestcentralus.oaiusercontent.com after 60013 ms, request
f168a066-6677-40b1-a710-11402c79582b. Reconciliation still shows version 82;
no new version or deployment was created. This is a publishing transport failure,
not proof that Cloudflare or the production website is down. Supported public
publishing here requires that connector; private publish-on-push cannot be used
for this public site, and no separate configured production CI/CLI/SSH route
was found. Do not change the audience or use local placeholder database IDs.

The Windows present-device inventory returned no iPhone/iPad/Apple Mobile match.
The existing remote tab still displayed wallpaper without an accessible terminal;
this does not prove the Mac has no device attached. No reset/reconnect was made.
The owner reaffirmed current screenshots and existing test-result acceptance;
do not ask for the same approval again. Exact capture provenance and native
verification are separate from that approval and must not be fabricated.
