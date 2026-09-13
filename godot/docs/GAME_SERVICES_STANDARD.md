# Game Services Standard

## Game Center

- Use `PlatformGamingService`; game rules provide only leaderboard and achievement identifiers.
- Keep guest/offline play available. A cancelled or unavailable Apple sign-in cannot block the local game.
- Real score writes are disabled in editor/debug builds; fictional test doubles remain testable.
- The iOS plugin is the pinned official source plus the checked scene-window patch. Both authentication and native leaderboard presentation use the active scene controller.
- The plugin build is content-addressed by source commit, Godot tag, patch ID, and patch SHA-256. Device and simulator frameworks, descriptor, license, and provenance must validate before export.
- App ID capability, export capability, provisioning profile, signed entitlement, App Store Connect configuration, TestFlight authentication, and physical native leaderboard presentation are separate checks.

## Golden Eggs

**GOLDEN EGG WEBSITE INTEGRATION IS DISCOVERY-TRIGGERED, NOT STARTUP-TRIGGERED.**

The Golden Egg website/backend must not be required for app startup or core gameplay.
Game Center remains independent. After verified Golden Egg discovery, the player
chooses whether their verified Game Center display name may be publicly published.
Only then does the Golden Egg website publication workflow execute. Launch, menu,
ordinary gameplay, Game Center authentication, native leaderboard and achievement
flows must produce exactly zero Golden Egg website requests. Offline, DNS failure,
HTTP 404, an unavailable backend, or an unlaunched campaign cannot block gameplay.

The shared order is: local condition verification, reveal, resolve fresh Game Center
identity, explicit YES/NO public-name choice, then backend submission. YES permits the
provider-reported display name; NO keeps the established `Anonymous` public label but
does not discard an otherwise valid discovery. The server alone verifies acceptance,
time and rank. Failure remains pending with a durable idempotency key; it never becomes
fake success, damages the gameplay save, or blocks the game.

Golden Egg participation and minimum-version enforcement are independent capabilities.
`updates.enabled: false` with `capabilities.golden_eggs: true` is valid and performs no
version-policy request. Apps that intentionally enforce a minimum build must opt in
with `updates.enabled: true` and retain the separate signed-policy release gates.

- `https://theflinsappvaultllc.com` is authoritative. The hunt URL is exactly `/golden-eggs`; accepted discovery URLs stay on that HTTPS origin under `/golden-eggs/discovery/`.
- Each game has a unique game ID and egg ID. The website owns discovery identity, time, rank, first-finder state, privacy state, and public Secret Code.
- New games start with `auth_protocol: unconfigured`. Enable the capability only after an approved server contract selects `bearer-v2` or `hmac-v1`; never invent a protocol or embed a server signing secret.
- Store pending idempotency, access/session material, and secure URLs only in platform-secure storage. Public saves/logs contain only the allowlisted public snapshot.
- Registration starts after valid in-game evidence, retries with bounded 8/16/32/60-second backoff, and preserves one stable idempotency key across retries. Redirects and foreign origins fail closed.
- Public leaderboard naming requires affirmative consent; Anonymous remains the default. Website success and source tests do not replace a fictional physical-device end-to-end test.
- Golden Egg public names never come from a website input. Read the bundled
  `golden-egg-game-center-identity` skill: the backend first verifies Apple's fresh
  signed identity payload and game/bundle binding, then accepts the authenticated
  device's `GKLocalPlayer.displayName` as `game_center_reported` metadata. Apple does
  not sign that display name, so never call the name cryptographically verified.

## Apple release

Use only `tools/release-ios` and the four fixed gates: `preflight`, `archive`, `upload`, `status`. Preflight authenticates the existing App Store Connect app before lengthy build work. Status queries the exact marketing version and build. Preserve the verified archive and resume from the last checkpoint instead of inventing another uploader or rebuilding.
