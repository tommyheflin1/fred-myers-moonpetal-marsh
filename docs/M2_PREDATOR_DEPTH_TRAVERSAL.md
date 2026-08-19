# M2 predator depth traversal

Updated: 2026-08-18

## Implemented behavior

Bass, pike, muskie and the marsh snake now follow deterministic surface,
diving, underwater and surfacing phases. The heron remains above water. Each
aquatic cycle has a readable surface hold, an eased dive, a bounded underwater
patrol and an eased return to the surface. Waterlines, concentric ripples,
bubbles, depth tint and partial water occlusion communicate the predator's
current band through shape and motion without relying on color or overhead
text.

Predator contact now requires both spatial overlap and depth overlap. Fred can
swim underneath a predator while it is above water, or remain above one while
it is submerged. A submerged fish or snake can still hit an underwater Fred,
and a surface predator can still hit a surface Fred. Whirlpools and ordinary
life-loss/recovery rules remain unchanged.

## Determinism and persistence

Depth phases derive only from fixed-tick simulation time, predator index and
level number. They do not use random or render-time state. Predator depth is
transient presentation/gameplay state and adds no field to `fred_save` v1.
Core 0.5.1 and the existing Fred depth, traversal, life, checkpoint and
campaign contracts are unchanged.

The focused suite covers all species, every phase, depth-overlap boundaries,
surface/underwater pass-under behavior, same-depth damage, 100 identical
eight-second traces, stable save/reload and a 10,000-update resource loop.
The initial depth slice passed **137/137** checks. Its 10,000-update loop
completed in 14 ms with zero measured static-memory growth; its complete
22-suite matrix passed **4,093/4,093** checks.

Computer Use exercised the actual Godot runtime at 1280 by 720 through title,
story, touch-first instructions, countdown and active play. Bass presentation
was observed at the surface, while diving and fully underwater. Bubbles,
depth tint, ripple, and combined species/state text remained readable. A
low-screen label collision found during that review was corrected by placing
low predator labels above the sprite, then rechecked in the runtime. The real
touch Dive path and pass-under collision rule are automated; owner subjective
control feel and physical-device acceptance remain separate gates.

## Species-identity refinement

The follow-up presentation pass replaces the shared fish silhouette with
species-specific anatomy. Bass are deep-bodied olive largemouths with a large
hinged jaw, spiny dorsal fin and broken dark lateral band. Pike use a long
torpedo body, duckbill snout, rear dorsal fin and pale chain spots. Muskies use
a longer barred predator body and rear-set fin. The snake now has a tapered
scaled S-curve, belly plates, flattened head, slit eyes and forked tongue; the
heron has a layered feather body, S-curved neck, spear bill, long jointed legs
and visible toes.

Fred's transient animation/location words are no longer drawn above his head.
Depth remains visible through the bottom `DIVE`/`SURFACE` action and the
existing HUD/status feedback, while the coordinator retains its internal cue
contract for deterministic accessibility and testing.

The refined focused suite passes **151/151**, including explicit anatomy and
unique silhouette contracts for all five named predators plus a source guard
against restoring Fred's overhead text. The complete 22-suite matrix passes
**4,107/4,107** checks.

## Revision 19 nameplate removal

The predator species/depth nameplate is no longer drawn above or below any
predator. Recognizable anatomy continues to identify bass, pike, muskie,
snake and heron, while waterlines, ripples and bubbles preserve readable depth
information. This is presentation-only: depth collision, damage, lives,
progression, touch controls, save v1 and Core 0.5.1 are unchanged.

The focused predator suite passes **338/338** and the complete 22-suite matrix
passes **4,884/4,884**. Computer Use inspected the actual Level 100 lineup at
1280x720 and 640x360; no predator name appeared, the five silhouettes remained
distinct, and the bottom touch controls stayed separated.
