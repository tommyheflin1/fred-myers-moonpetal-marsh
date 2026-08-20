# Fred Myers App Store Connect and TestFlight Build 1 package

Prepared: 2026-08-19

Status: locally prepared for the first owner-approved TestFlight upload. This
document is not evidence that an App Store Connect record, signed archive,
upload, processing result, beta test, review submission, or public release has
occurred.

## Product identity

| Field | Exact Build 1 value |
| --- | --- |
| App name | Fred Myers: Moonpetal Marsh |
| Subtitle | A Frog Hero's Marsh Quest |
| Bundle ID | `com.flinsvault.fredmyers` |
| SKU | `fred-myers-moonpetal-marsh-ios` |
| Version | `1.0` |
| Build | `1` |
| Primary language | English (U.S.) |
| Primary category | Games - Adventure |
| Secondary category | Games - Family |
| Platforms | iPhone and iPad |
| Orientation | Landscape |
| Minimum OS | iOS/iPadOS 15.0 |
| Distribution | Paid download; no ads or in-app purchases |
| U.S. customer price | $2.99 |

The App Store Connect app record must be separate from Snake Reactor. Do not
reuse Apple app ID `6795034810`, which belongs to Snake Reactor. Query Apple
before creation to confirm the name, bundle ID, SKU and build number are still
available.

## Promotional text

Leap, dive, munch and boost through a moonlit marsh as Fred becomes the frog
hero every little frog dreams about.

## Full description

Every little frog dreams of a safe, glowing marsh. When wild currents,
predators and broken lily-pad paths threaten Moonpetal Marsh, Fred Myers takes
the leap.

Guide Fred through Campaign 1, a 100-level touch-first adventure that grows a
little more challenging as new routes, moving lily pads, prey, currents and
predators appear. Leap over danger, dive beneath surface hunters, use Fred's
tongue to munch nearby bugs, boost through tight spaces and reach the
Moonpetal Exit.

Earn coins while you play and use them to give Fred new colors, tongue styles,
sizes, glasses and hero gear. A fairy appears every tenth level and can add a
life to Fred's current adventure. Local progress and scores work offline, and
Apple Game Center personal records are available when the Apple service is
connected.

Fred Myers and the Moonpetal Marsh is designed as a friendly, non-graphic frog
adventure with clear touch controls, a five-second level countdown, readable
status cues, reduced-motion support and no advertising or in-app purchases.

## Keywords

`frog,marsh,adventure,lily pads,animals,kids,family,hero,touch,offline`

## What's New for 1.0

- Campaign 1 with 100 progressively challenging levels.
- Touch-first leap, tongue, boost, dive and surface controls.
- Moving routes, bugs, fish, reptiles, birds, currents and marsh hazards.
- Earnable Fred colors, tongue styles, sizes, glasses and hero gear.
- Offline save recovery, local leaderboards and optional Game Center records.
- Original Moonpetal title and chase music.

## TestFlight beta information

### Beta description

This first Fred Myers beta validates the complete touch-first Campaign 1 loop,
save/recovery, life rules, tenth-level fairy rewards, phone/tablet layout,
audio, cosmetics and Apple Game Center personal-record connection.

### What to test

1. Start from the title, read Fred's hero story and open the touch instructions.
2. Verify steering and MUNCH, LEAP, BOOST, DIVE/SURFACE, PAUSE and EXIT.
3. Lose lives and confirm the run ends only when the current life count reaches zero.
4. Complete levels in both route directions and confirm each next level starts normally.
5. On level 10, eat the fairy and confirm one life is added even when Fred already has three.
6. Background and resume the app, then relaunch and verify the last stable checkpoint.
7. Review readability on both iPhone and iPad, including reduced motion.
8. Open Marsh Leaders and verify local results remain available offline; verify Game Center records when signed in.

### Review notes

- No account is required. Guest and offline play remain available.
- Game Center uses Apple's normal device account and does not create a separate
  Flins App Vault account.
- The game contains no ads, in-app purchases, external checkout, chat, user
  content, location, camera, microphone or developer analytics.
- Touch the playfield to steer. Use the labeled action buttons along the lower
  edge. The in-game EXIT button returns to the title and resets the run while
  keeping earned cosmetic coins.
- A fairy is intentionally available only on levels 10, 20, 30 and so on.

## Game Center configuration

Create these permanent classic leaderboard records under the Fred app before
the signed archive is tested:

| Name | Identifier | Score format | Sort |
| --- | --- | --- | --- |
| Moonpetal Adventure Score | `com.flinsvault.fredmyers.adventure_score` | Integer | High to low |
| Highest Marsh Level | `com.flinsvault.fredmyers.highest_level` | Integer, 1-100 | High to low |

The native adapter uses the official Godot iOS Game Center plugin pinned to
commit `fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb` and Godot tag
`4.7.1-stable`. Failed or unavailable Apple authentication falls back to the
local board; it never blocks gameplay. Build 1 does not claim a developer-run
anti-cheat backend or cross-platform cloud save.

## App Privacy draft

Select **No, we do not collect data from this app** only after archive inspection
confirms the current contract: saves, coins, cosmetics and local scores stay on
the device; no analytics, ads, attribution, crash-reporting or Flins backend is
enabled; and optional Game Center communicates only with Apple. Revisit the
answer before enabling any Flins-operated account, cloud save, analytics or
verified-score service.

Privacy policy target: `https://theflinsappvaultllc.com/fred-myers/privacy`.
The currently live `/privacy` page is Pokemon Field Academy-specific and is not
an acceptable Fred privacy-policy destination. Publish and verify the dedicated
Fred policy before entering this field.
Support URL candidate: `https://theflinsappvaultllc.com/` until a dedicated Fred
support route is published. Both URLs must be opened and verified in the same
owner-controlled browser session before saving them in App Store Connect.

## Age rating draft

Answer all advertising, chat, user content, web access, gambling, sexual,
profanity, substance, realistic violence and horror questions as none/no for
this exact build. Answer **Cartoon or Fantasy Violence: Infrequent** because
predator contact can cost Fred a life and the failure screen shows a non-graphic
frog splat. Accept Apple's calculated rating; do not mislabel the build as 4+.
Do not select Made for Kids without a separate durable Kids Category decision.

## Rights and regional gates

- Confirm commercial App Store rights for `The Marshland March.mp3`,
  `Marshland Chase.mp3`, the Fred artwork and all other shipped media.
- Verify the Paid Apps Agreement, tax and banking status before setting $2.99.
- Confirm EU trader information before enabling EU storefronts.
- Keep China mainland, South Korea and Vietnam excluded until their game-specific
  regulatory fields are independently cleared.
- Use Apple's standard EULA. Build 1 has no IAP, subscription or paid coins.

## Required screenshots

The exact-build capture tool creates inspected, unmodified gameplay frames in
`builds/app-store/ios/` for 6.9-inch iPhone landscape and 13-inch iPad landscape:

1. cinematic title and Fred hero branding;
2. hero story;
3. touch controls and instructions;
4. active marsh route with Fred, prey and predators;
5. underwater traversal;
6. level-ten fairy and stacked lives;
7. frog customization;
8. Marsh Leaders.

Upload no more than ten per device class. Screenshots must be from the exact
Build 1 commit, contain no desktop chrome, usernames, paths, device IDs or
notifications, and use RGB output without an alpha channel.

## Ordered App Store Connect execution

1. Create the separate Fred app record with the exact identity above.
2. Enable Game Center on the Fred identifier and create the two leaderboards.
3. Verify agreements; set the U.S. base price to $2.99 and allowed storefronts.
4. Add version 1.0 metadata, privacy/support URLs, age rating, screenshots and
   TestFlight information.
5. On an authenticated Mac, run the hash-guarded handoff and upload Build 1.
6. Wait for processing, inspect encryption/privacy warnings and attach Build 1
   to internal TestFlight.
7. Invite only approved internal testers. Do not submit App Review or release
   publicly without a separate owner decision.

## App Store Connect audit checkpoint - 2026-08-19

- U.S. customer price is verified at $2.99; Apple's equivalent prices are
  configured for 175 countries or regions, while release availability remains
  separately controlled.
- Release availability now matches Snake Reactor's exact 143-country set. An
  authenticated App Store Connect comparison found zero missing and zero extra
  countries. Fred reports `143 Available` and `32 Not Available`; Snake reports
  the same 143 available storefronts as `143 Available`, with 30 explicitly
  unavailable and Afghanistan and Morocco classified separately by Apple as
  `Cannot Sell`. Automatic availability for future App Store countries remains
  enabled, matching Snake. Apple states that availability changes can take up
  to 24 hours to appear.
- Version 1.0 contains eight inspected iPhone screenshots and eight inspected
  iPad screenshots, the full description, promotional text, touch-first review
  notes, manual release selection and the Game Center checkbox.
- The App Privacy response `Data Not Collected` is published for this exact
  offline/Game Center-only build.
- iPhone and iPad accessibility drafts accurately disclose `Differentiate
  Without Color Alone` and `Sufficient Contrast`. They cannot be published to
  the product page until an app version is released.
- TestFlight beta description, review notes, marketing URL, feedback email and
  known review contact name/email are saved. The privacy-policy URL and review
  phone fields remain open.
- App Information remains Games / Adventure / Family. Apple's current
  calculated rating is 9+ because Cartoon or Fantasy Violence and Contests are
  each declared Infrequent. Do not change this to 4+ or Made for Kids without a
  separate owner policy decision.
- Content Rights remains unset pending the owner's commercial-rights
  attestation for both supplied music tracks and all shipped media.
- No build is present in TestFlight. Xcode account reauthentication, upload,
  processing and physical iPhone/iPad Game Center acceptance remain required.

## Build 1 TestFlight checkpoint - 2026-08-19

- The signed `1.0 (1)` candidate was validated and uploaded through the
  existing App Store Connect API-key workflow after Xcode account refresh
  continued to return error `-501`.
- Apple validation and upload both completed with no errors; delivery UUID is
  `e3ec31b7-beff-41fb-ae93-e5d077d706c5`.
- App Store Connect completed processing. The binary is `Validated` and Build
  `1.0 (1)` is `Ready to Test` for 90 days.
- The build is assigned to the manually controlled internal group `Fred Owner
  Testing`; one approved owner tester is invited and automatic distribution is
  disabled.
- Processed metadata confirms `arm64`, iPhone+iPad, minimum iOS 15.0, non-exempt
  encryption `No`, `gamekit`, and the signed Game Center entitlement.
- The upload/TestFlight gate is complete. Physical iPhone/iPad control,
  lifecycle, audio and live Game Center authentication/score/leaderboard proof
  remain owner acceptance gates.
- The dedicated Fred privacy-policy URL, review phone, commercial media-rights
  attestation, Game Center component review, App Review submission and public
  release remain intentionally open. No public release action occurred.
