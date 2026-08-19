# M2 all-character deterministic articulation uplift

Updated: 2026-08-18

## Scope

App Build 1 revision 14 begins at clean local commit
`b5ac15c786c1ada0baad5553f8ef554107271581`. It upgrades the existing Fred,
bass, pike, muskie, marsh snake, heron, bug and life-fairy rigs from largely
single-silhouette movement to connected, deterministic part articulation. The
work is Fred-owned, local and unpushed because the configured GitHub repository
is public.

The exact focused product-source commit is
`2596a691198dcf8dbd08276721d77869151e459e`. The resulting local Android
development APK is guarded by SHA-256
`270160724F63B0C14D7DDAB6DB2348FB709949E5AF91E7068A30E25ECDD3B882`.

This pass does not change gameplay, collision, fixed-tick session state,
difficulty, lives, coins, rewards, progression, touch controls, save v1, Core,
networking or platform providers. It is a stronger review-stage vector rig,
not a claim of final production art.

## Character articulation contract

`FredWildlifeAnimationRig` consumes only stable character kind, actor index,
presentation time and reduced-motion preference. It emits transient pose
channels and cannot mutate the session or save. Stable actor-index phase offsets
keep repeated traces exact while preventing every character from moving in
lockstep.

- Bass, pike and muskie use connected tail-base/tail-tip flex, dorsal and paired
  fin sweeps, body breathing, gill opening, jaw movement and eye focus while
  retaining their unique anatomy and silhouettes.
- The marsh snake uses an 18-joint presentation contract with a traveling
  spinal wave, breathing, head pitch, jaw opening and forked-tongue motion.
- The heron coordinates a 13-joint wing/primary-feather system with S-neck,
  head, bill, alternating leg lift, toes and eye focus.
- Bugs use a 12-joint body with deterministic hover, abdomen movement, four
  independent wings, six legs and eye focus.
- The life fairy uses a 14-joint body with four wings, arms, legs, crown, glow,
  hover and eye focus.
- Fred keeps the authored 34-node rig and 23 coordinator poses, adding only
  subtle throat/body breathing and an eyelid blink. Reduced motion restricts
  these secondary cues while retaining state-readable pose and silhouette.

All outputs are bounded finite values. Unsupported characters, invalid actor
indices and non-finite time fail closed. No articulation field is persisted.

## Automated evidence

- Godot 4.7.1 import/parser gate: passed.
- Fred rig suite: 521 passed, 0 failed, including deterministic micro-motion,
  restrained reduced motion, presentation-only invariance and 12 inspectable
  realism features.
- Predator-depth/identity suite: 299 passed, 0 failed. It covers all seven
  character families, minimum joint counts, fail-closed inputs, reduced-motion
  bounds and 100 identical 240-tick all-character traces.
- Complete deterministic matrix: 22 suites, 4,277 passed, 0 failed in 14.85
  seconds using isolated temporary AppData for every suite.
- Fred's 10,000-update rig loop completed in 351 ms with 4,620 bytes measured
  static-memory growth, zero retained resources, zero nodes and zero orphans.
  Predator depth plus articulation completed 10,000 updates in 14 ms with zero
  measured static-memory growth.

## Real Windows review

Computer Use inspected the actual Godot 4.7.1 runtime rather than a mock or a
static render:

- 1280 by 720 Level 100 lineup: two time-separated captures showed the five
  predator species and their connected parts moving independently, alongside
  four-wing bugs, the life fairy and Fred. Silhouettes and named-species anatomy
  remained distinct against the marsh.
- 960 by 540 Level 1: Fred, bass, bugs, pads, objective, lives, energy, Pause,
  Exit and the full bottom action row remained separated and readable.
- Reduced-motion 640 by 360 Level 1: bounded secondary animation retained the
  character silhouettes and all action choices without button overlap. A real
  pointer contact exercised the same screen-touch MUNCH path used by mobile;
  the tongue originated at Fred's mouth and produced a truthful miss cue.

The readiness inventory, Android packaging identity and exact final
source/artifact hashes are recorded in `APP_BUILD_1_TEST_REPORT.md` after
execution.

## Deferred acceptance

Physical Android and iOS hardware animation performance, production character
assets, provider activation, signing, store submission, publication and release
remain separate protected gates. No milestone percentage is awarded until the
approved M013 denominator and owner acceptance exist.
