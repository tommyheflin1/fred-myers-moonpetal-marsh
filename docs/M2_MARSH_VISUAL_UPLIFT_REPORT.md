# M2 Marsh Visual Uplift, Tongue Assist, Stacking Lives, and Touch Evidence

Date: 2026-07-24

## Scope

This isolated Fred-only M2 candidate descends from the accepted authored-rig
evidence commit `6a5f22b68f35335dfb2955352c85c1616e59ac46`. It addresses the
owner's in-play review without changing collision geometry, fixed-tick
traversal, objective/checkpoint identifiers, Core 0.5.1, or save schema v1.
The branch remains local and unpushed because the configured GitHub repository
is currently reported public.

The cohesive slice includes:

- a committed 16:9 moonlit-marsh gameplay background with calm central
  play space and richer banks, submerged vegetation, water depth, reflections,
  and firefly light;
- Fred-owned dimensional drawing for lily pads, flowers, safe perch,
  moonpetal exit, bugs, fairy, fish, snake, heron, shadows, water contact, rim
  light, and non-color labels;
- deterministic close-prey tongue assistance within 96 pixels, even when the
  prey is outside Fred's normal 42-degree aim cone;
- three starting lives with one stackable fairy life on levels 10, 20, ...,
  100, allowing a no-damage maximum of 13;
- preservation of earned lives and energy between level transitions;
- actual `InputEventScreenTouch` handling for movement, leap, depth,
  boost, tongue, and pause through the same gameplay methods used by desktop
  input; and
- numeric lives, a nearby `[F] MUNCH` prompt, restrained transparent touch
  controls, and mobile-safe non-color status cues.

The marsh background is a locally generated review asset committed to this
Fred branch. It introduces no runtime network or external art dependency.

## Deterministic rules

### Tongue

- Maximum reach remains 190 pixels.
- Normal aimed selection remains within plus or minus 42 degrees and retains
  the established alignment, distance, then stable-ID ordering.
- Prey at or below 96 pixels may be selected outside the cone.
- A close assisted candidate wins over a distant cone candidate; assisted ties
  use distance, alignment, then stable ID.
- Cooldown remains 0.55 seconds and duplicate input cannot double-consume a
  target.

### Lives and fairies

- Every fresh run and game-over retry starts with exactly three lives.
- Exactly one fairy is available on each tenth level.
- Eating that fairy always grants one life when below the bounded campaign
  maximum, including when Fred already has three or more lives.
- The legitimate maximum is 13: three starting lives plus ten milestone
  fairies through level 100.
- Damage subtracts from the current stacked total. Earned lives carry into the
  next level; only a full game-over retry starts a new three-life run.
- Save schema remains version 1. The existing `player_state.health` integer
  stores the value; no schema migration or new field was added.

### Touch

Screen-touch contacts are transient and cannot enter save data. A contact is
mapped to one movement direction, tongue, leap, depth toggle, boost hold, or
pause. Touch controls appear automatically when Godot reports a touchscreen;
the explicit review flag only exposes them on desktop. Release clears held
movement/boost state. The logical 1280 by 720
control layout scales through the existing `canvas_items` stretch contract;
physical iOS/Android hardware acceptance remains a separate gate.

## Automated validation

Godot `4.7.1.stable.official.a13da4feb` imported and parsed the project.
The complete 15-suite local matrix passed **2,090 checks, 0 failures**:

| Suite | Passed |
| --- | ---: |
| Core/session baseline | 32 |
| Keyboard regression | 23 |
| Save stress/security | 31 |
| Save feedback | 28 |
| Visual clarity | 30 |
| M2 foundation | 645 |
| Leap traversal | 52 |
| Depth traversal | 64 |
| Menu/lives/leaderboard | 31 |
| Tongue interaction | 82 |
| Boost locomotion | 167 |
| Camera follow | 184 |
| Animation coordinator | 238 |
| Authored Fred rig | 378 |
| Marsh/life/touch uplift | 137 |

Focused evidence includes 100 identical close-assist traces, all ten tenth-level
fairy gains, real injected screen-touch events, schema-v1 round-trip at 13
lives, and 10,000 deterministic marsh-geometry updates. The geometry loop
completed in 64-85 ms with 264 bytes measured static-memory growth. The tongue
loop completed in 73-77 ms with zero measured static-memory growth.

## Visible Windows review

Computer Use selected the uniquely titled
`Fred Myers - Marsh Uplift Owner Review (DEBUG)` window and reviewed:

- 1280 by 720 title, countdown, normal gameplay, real `F` tongue miss,
  and real `P` pause;
- 960 by 540 normal-motion title, countdown, and stable gameplay after the
  refined transparent touch overlay and centered status panel; and
- 640 by 360 reduced-motion title and post-countdown gameplay with visible
  Fred, pads, prey, predators, exit, objective, lives, energy, status, and
  transparent touch controls.

The new background and grounded shadows remove the previous flat-paper
presentation. The touch overlay was reduced and its feedback panel centered
after visible review to avoid covering Fred and the energy/status area.
Controller input remains synthetic; physical controller, touch device, iPhone,
and Android acceptance are not claimed.

## Integrity and security

- Core tree remains
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- Owner primary save remains 592 bytes with SHA-256
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save remains 592 bytes with SHA-256
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Visible validation used fictional isolated AppData.
- No network, provider, credential, PII, analytics, signing, export,
  deployment, publication, or release path was activated.

## Gate truth

This substantive local branch evidence advances M2 implementation quality but
does not award M013 or portfolio percentage credit before approved denominator
decomposition and owner acceptance. Physical phone/controller testing,
campaign authoring, final art, store preparation, and publication remain open.
