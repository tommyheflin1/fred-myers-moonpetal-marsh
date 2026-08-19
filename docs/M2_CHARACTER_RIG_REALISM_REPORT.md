# M2 Fred and wildlife character-rig realism uplift

Updated: 2026-08-18

## Scope

App Build 1 revision 13 deepens the existing Fred-owned vector character
system without changing gameplay. The slice begins at clean local commit
`29b12b0d77c1b7ce4bb6e1cd79b2bdbb5a9f4727` and improves Fred, bass, pike,
muskie, marsh snake, heron, marsh bugs, and the tenth-level life fairy. The
work remains local and unpushed because the configured GitHub repository is
public.

This is a focused presentation pass, not final art, a renderer replacement, or
a collision/physics redesign. It adds no networking, account, production
signing, store, deployment, release, or player-data behavior.

## Rig and anatomy contract

Fred's existing 34-node authored scene remains the authoritative articulated
rig. Ten new inspectable realism features are rendered as presentation-only
layers: skin lighting, dorsolateral folds, visible tympanums, nictitating eye
rims, horizontal frog pupils, throat/belly volume, jointed forelimbs,
hind-leg muscle contours, webbed fingers and toe pads, and mottled skin. The
existing 23 deterministic pose states, attire anchors, mouth clearance,
tongue anchor, ground contacts, collision authority, and phone-safe vector
scaling remain intact.

Each named predator now exposes at least six explicit anatomy cues, three
motion channels, eight or more material/detail layers, and a unique
phone-readable silhouette:

- largemouth bass: deep body, hinged jaw, rounded operculum, spiny dorsal,
  paired fins, scales, lateral band, and forked tail;
- pike: long torpedo body, duckbill jaw and teeth, rear dorsal, chain spots,
  lateral line, paired fins, scales, and forked tail;
- muskie: long barred body, predator jaw and teeth, rear dorsal, lateral line,
  paired fins, scales, and forked tail;
- marsh snake: a tapered 16-segment body with dorsal scales, belly scutes,
  flattened dimensional head, slit eyes, jaw line, nostrils, and forked tongue;
- heron: layered body and primary feathers, shoulder contour, S-curved neck,
  crown plume, spear bill/nostril, reflective eye, jointed legs, and three-toed
  feet.

Marsh bugs now have a head, thorax, abdomen, two compound eyes, paired
antennae, six jointed legs and four veined wings. The life fairy has a distinct
head/thorax/abdomen, four veined wings, antennae, articulated limbs, glow, and
Moonpetal crown. These profiles and draw layers are presentation-only and
cannot award prey, lives, coins, damage, progression, or saves.

## Automated evidence

- Godot 4.7.1 import/parser gate: passed.
- Fred rig suite: 516 passed, 0 failed. It covers all 23 states, 100 identical
  pose traces, ten realism features, phone-safe scaling, save exclusion, and
  gameplay/collision invariance.
- Predator-depth/identity suite: 167 passed, 0 failed. It covers five distinct
  predator identities, bugs/fairy, 100 deterministic depth traces, 10,000
  identity reads, and 10,000 depth updates with no canonical save change.
- Complete deterministic matrix: 22 suites, 4,140 passed, 0 failed in 13.50
  seconds.
- Fred's 10,000-update rig loop completed in 376 ms with 4,620 bytes measured
  static-memory growth, zero retained resources, zero nodes, and zero orphan
  nodes. Predator depth completed 10,000 updates in 16 ms with zero measured
  memory growth.
- Readiness remains Godot 4.7, eight fictional save fixtures, and exact Core
  0.5.1. Adding this report brings the tracked readiness inventory to 90
  required artifacts.

Standalone SceneTree suites retain the already documented two-instance and
one-resource shutdown diagnostics after successful immediate process exit.
The measured stress loops retain no resources, nodes, or orphans, and no new
parse, script, runtime, or gameplay error was observed.

## Real Windows review

Computer Use inspected the actual Godot 4.7.1 runtime, not a mock:

- 1280 by 720 Level 100 species lineup: all five predators, Fred, bugs, and
  life fairy remained visually distinct against the marsh. The snake's scaled
  body/head, heron's feather/leg anatomy, fish body types and fairy/bug wing
  structures were visible. The intentionally dense review fixture can crowd
  labels, but the character silhouettes remain distinct.
- 960 by 540 normal Level 1: Fred, bass, three bugs, pads, objective, lives,
  energy, Pause/Exit and all five touch zones remained readable without button
  overlap. Character detail scaled cleanly and the normal route retained open
  play space.

The review used the desktop mouse/touch-equivalent presentation. A physical
Android phone, multitouch feel, iPad/iPhone rendering, and subjective owner
acceptance remain unverified gates.

## Integrity and deferrals

Core remains pinned to 0.5.1 at tree
`288d87420c5694f80c071f00aa71a0b581f9f60c`; `fred_save` remains version 1.
Owner saves, stable objective/checkpoint IDs, collision geometry, difficulty,
lives, fairy rules, touch hit targets, Apple scoring adapter, and offline
behavior are unchanged. Revision 13 receives no milestone percentage increase
until owner acceptance and the approved M013 denominator decomposition.

Final painted/animated production characters, physical-phone GPU/performance
acceptance, iOS device validation, provider activation, signing, store
submission, publication, and release remain deferred.
