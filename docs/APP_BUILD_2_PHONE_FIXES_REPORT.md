# Fred Myers App Build 2 phone-fixes report

Date: 2026-08-20
Branch: `codex/app-build-2`
Starting revision: `3402f89a1b42045bd8029f2ca2886f7b8bb624e3`

## Outcome

This local Build 2 candidate addresses the three defects reported from physical
Build 1 testing: missing iPhone music, an unsuitable phone control layout, and
a foreground Resume overlay that did not accept touch. The work remains local
and unpushed. It does not claim a signed iOS archive, TestFlight processing, or
physical-device acceptance.

## Implemented fixes

### Music

- The Marshland March remains the menu/story/instructions/customization music.
- Marshland Chase remains the playing/failure/completion music.
- Both committed MP3 imports now loop, and runtime loading defensively enables
  MP3 looping.
- `audio/general/ios/session_category` is `3` (Playback), matching the proven
  App Generation Engine/Snake Reactor iPhone-silent-switch correction.
- Background handling pauses active players; foreground handling releases the
  audio pause and reapplies the deterministic menu/gameplay route.

The source MP3 SHA-256 values are:

- The Marshland March:
  `3AD3D7A4BD4A4959870365DDAF219C3E75B7389F04748C7AD2FB6A6E89D5F627`;
- Marshland Chase:
  `0ED4938C2C5F84AFC3B823BFFCF0E2E6A2EC81AAA97E200674CBCEF111DEE517`.

### Phone controls

- Movement is limited to a circular control pad on the right.
- Munch, Leap, Dive/Surface and Boost are four independent 84-pixel circular
  targets arranged in one action cluster on the left.
- The inactive overlays are translucent rather than solid: the marsh remains
  visible beneath them, while a pressed control gains bounded contrast.
- Both clusters sit in lower landscape reach zones with 36 logical pixels of
  bottom safe-area clearance for modern phone home indicators and tablet use.
- Circular visual bounds and hit testing share one layout contract; square
  corners outside each circle do not trigger an action.
- The pad has an 18-pixel dead zone, radial clamping and stable direction output.
- Simultaneous movement/action contacts remain independent and releases clear
  all transient state.
- Instructions and the Level 1 introduction now teach the right control pad and
  left action wheel. Open-playfield taps no longer cause unintended movement.
- Controls hide behind countdown and pause overlays, so inactive UI does not
  overlap the active modal action.

### Foreground Resume

The paused Resume rectangle is now part of the authoritative touch-layout
contract. It resolves to the same pause/resume action only while the session is
paused, so a foregrounded phone can resume from the visible button without
making that area an active-play control. Background and foreground events clear
all contacts, held Boost and pointer emulation before presenting the safe gate.

## Automated validation

- Godot: `4.7.1.stable.official.a13da4feb`.
- Import/parse gate: passed.
- Focused Build 2 phone fixes: 49 passed, 0 failed.
- Touch-first controls: 65 passed, 0 failed.
- Android lifecycle/touch readiness: 21 passed, 0 failed; 10,000 routing
  decisions completed in 24 ms with zero measured static-memory growth in the
  affected-suite run.
- Phone lives/routes/layout: 49 passed, 0 failed.
- Product regression: 95 passed, 0 failed.
- Complete repository matrix: **25 suites, 5,280 passed, 0 failed**.
- Eight save fixtures remain valid and `fred_save` remains schema v1.
- iOS development export metadata is version `1.0` build `2`; Android's local
  development artifact name is distinct for Build 2.
- Android debug export: `builds/android/fred-myers-app-build-2-debug.apk`,
  84,924,487 bytes, SHA-256
  `E533CAC69285CAB8E53D5642740033AE9283FBFBD6DA39B38D19D2F0BD7E708E`.
  It is debug signed, zip-aligned, min/target SDK 24/36, contains arm64-v8a and
  x86_64, requests no Android permissions, and passed the private-path/source/
  secret content scan.

One stale test still expected whole-playfield steering. It correctly failed on
the first full run, was updated to exercise the new right control pad, and the
entire matrix then passed.

## Visible Windows review

Computer Use exercised the actual Godot runtime with isolated fictional app
data at:

- 1280 by 720 normal motion;
- 960 by 540 reduced motion;
- 640 by 360 constrained reduced-motion layout.

The review covered title, story, corrected instructions, countdown, active
gameplay, translucent left action wheel, translucent right control pad, Munch,
Pause and the visible Resume gate. The controls remained separated from Fred's
starting silhouette, status, Pause and Exit while leaving the marsh visible
underneath. The 640 by 360 countdown and Pause views hid inactive controls, and
the Resume surface remained unobstructed at the constrained size.

## Integrity and boundaries

- Mobile Game Core remains pinned to 0.5.1.
- No gameplay, collision, lives, fairy, progression, score or save-schema rule
  changed.
- All review runs used isolated fictional app data; owner saves were not opened
  or modified. The owner primary and backup files remain 592 bytes with their
  exact prior timestamps and SHA-256 values
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`
  and `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- The single desktop owner shortcut remains unchanged on the accepted Build 1
  review candidate; this Build 2 phone slice did not replace or duplicate it.
- No credentials, PII, network provider, analytics, account, signing, upload,
  store submission, release or publication path was activated.
- The GitHub remote remains public; this branch is not pushed and no PR is open.
- Milestone percentages remain unchanged pending owner and physical-device
  acceptance.

## Remaining Build 2 gate

Local validation cannot prove iPhone speaker output, the real iOS lifecycle, or
touch feel on the owner's device. The next protected action is to create and
upload the signed iOS build number 2 from the authorized Mac workflow, wait for
TestFlight processing, attach it to the existing internal group, then repeat
the three owner workflows on a physical iPhone.
