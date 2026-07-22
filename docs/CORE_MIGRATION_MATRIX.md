# Core migration matrix

Pin Mobile Game Core `0.5.1`. Copy the exact add-on snapshot from the matching Core release only during the implementation milestone. Do not edit vendored Core files in Fred.

| Concern | Core 0.5.1 | Fred adapter / owner | Disposition |
| --- | --- | --- | --- |
| Service composition/lifecycle | `GameServices` | Fred bootstrap | Reuse |
| Atomic JSON + backup recovery | `SaveService` | `FredCheckpointRepository` owns schema/defaults | Reuse behind adapter |
| Settings | `SettingsService` | Fred accessibility/audio/control settings | Reuse |
| Achievement snapshots | `AchievementService` | Fred event catalog | Reuse after MVP slice |
| Progression labels | Generic progression service is campaign-oriented | Fred five-level unlock/checkpoint model | Wrap; do not force Snake rank semantics |
| Inventory/wallet | Available | Future optional cosmetics; no MVP purchases | Defer |
| Identity | Provider-neutral optional service | Fred sign-in UI adapter | Defer; offline must work |
| Cloud conflicts | Fixed field policy includes Snake-oriented fields | Fred envelope projection | Reuse only compatible monotonic fields; specify Fred fields before enabling |
| Player profile/save RPC | `PlayerSyncService` | Backend transport | Defer until local save proven |
| Leaderboards | Verified sessions/submissions and presentation states | Fred score/time proof model | Defer; story completion is not automatically competitive |
| Analytics | No Core implementation | Fred-owned disabled provider port | Keep outside Core pending reusable contract decision |
| Checkpoints | No game-specific checkpoint model | Fred stable checkpoint IDs and respawn rules | Fred-owned |
| 3D movement/AI/story | Intentionally absent | Fred gameplay modules | Fred-owned |

## Compatibility gate

The implementation branch must include `CORE_VERSION=0.5.1`, copied Core plugin constant/manifest/config agreement, the template compatibility smoke, and a SHA-256 inventory of the vendored add-on. Any Core upgrade requires save fixtures, API compatibility, Fred runtime tests, and all export checks before the pin changes.

