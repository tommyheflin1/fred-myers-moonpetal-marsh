# M2 predator depth traversal

Updated: 2026-08-18

## Implemented behavior

Bass, pike, muskie and the marsh snake now follow deterministic surface,
diving, underwater and surfacing phases. The heron remains above water. Each
aquatic cycle has a readable surface hold, an eased dive, a bounded underwater
patrol and an eased return to the surface. Bubble, ripple, tint and explicit
`SURFACE`, `DIVING`, `UNDERWATER` or `SURFACING` text cues communicate the
predator's current band without relying on color alone.

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
It passes **137/137** checks. The 10,000-update loop completed in 14 ms with
zero measured static-memory growth; the complete 22-suite matrix passes
**4,093/4,093** checks.

Computer Use exercised the actual Godot runtime at 1280 by 720 through title,
story, touch-first instructions, countdown and active play. Bass presentation
was observed at the surface, while diving and fully underwater. Bubbles,
depth tint, ripple, and combined species/state text remained readable. A
low-screen label collision found during that review was corrected by placing
low predator labels above the sprite, then rechecked in the runtime. The real
touch Dive path and pass-under collision rule are automated; owner subjective
control feel and physical-device acceptance remain separate gates.
