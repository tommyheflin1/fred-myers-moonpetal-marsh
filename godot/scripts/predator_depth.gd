class_name FredPredatorDepth
extends RefCounted

enum State { ABOVE_WATER, SURFACE, DIVING, UNDERWATER, SURFACING }

const CYCLE_SECONDS := 8.0
const SURFACE_HOLD_SECONDS := 2.7
const DIVE_SECONDS := 0.8
const UNDERWATER_HOLD_SECONDS := 3.2
const SURFACE_SECONDS := 0.8
const UNDERWATER_START_SECONDS := SURFACE_HOLD_SECONDS + DIVE_SECONDS
const SURFACING_START_SECONDS := UNDERWATER_START_SECONDS + UNDERWATER_HOLD_SECONDS
const SURFACE_COMPLETE_SECONDS := SURFACING_START_SECONDS + SURFACE_SECONDS
const DEPTH_COLLISION_TOLERANCE := 0.30
const ABOVE_WATER_COLLISION_CEILING := 0.22

const AQUATIC_SPECIES: Array[String] = ["BASS", "PIKE", "SNAKE", "MUSKIE"]

static func naturally_submerges(species: String) -> bool:
	return species.to_upper() in AQUATIC_SPECIES

static func snapshot(species: String, predator_index: int, level_number: int, simulation_time: float) -> Dictionary:
	var normalized_species := species.to_upper()
	if not naturally_submerges(normalized_species):
		return {
			"state": State.ABOVE_WATER,
			"depth": 0.0,
			"cue": "ABOVE WATER",
			"can_submerge": false,
			"phase": 0.0,
		}

	var phase_offset := fmod(
		float(maxi(0, predator_index)) * 1.71 + float(posmod(maxi(1, level_number) - 1, 10)) * 0.11,
		CYCLE_SECONDS
	)
	var phase := fposmod(maxf(0.0, simulation_time) + phase_offset, CYCLE_SECONDS)
	var maximum_depth := 0.78 if normalized_species == "SNAKE" else 1.0
	var state := State.SURFACE
	var amount := 0.0
	var cue := "SURFACE"
	if phase < SURFACE_HOLD_SECONDS:
		state = State.SURFACE
	elif phase < UNDERWATER_START_SECONDS:
		state = State.DIVING
		amount = _smooth_step((phase - SURFACE_HOLD_SECONDS) / DIVE_SECONDS) * maximum_depth
		cue = "DIVING"
	elif phase < SURFACING_START_SECONDS:
		state = State.UNDERWATER
		amount = maximum_depth
		cue = "UNDERWATER"
	elif phase < SURFACE_COMPLETE_SECONDS:
		state = State.SURFACING
		amount = (1.0 - _smooth_step((phase - SURFACING_START_SECONDS) / SURFACE_SECONDS)) * maximum_depth
		cue = "SURFACING"

	return {
		"state": state,
		"depth": clampf(amount, 0.0, 1.0),
		"cue": cue,
		"can_submerge": true,
		"phase": phase,
	}

static func shares_depth(fred_depth: float, predator_snapshot: Dictionary) -> bool:
	var safe_fred_depth := clampf(fred_depth, 0.0, 1.0)
	if int(predator_snapshot.get("state", State.ABOVE_WATER)) == State.ABOVE_WATER:
		return safe_fred_depth <= ABOVE_WATER_COLLISION_CEILING
	var predator_depth := clampf(float(predator_snapshot.get("depth", 0.0)), 0.0, 1.0)
	return absf(safe_fred_depth - predator_depth) <= DEPTH_COLLISION_TOLERANCE

static func _smooth_step(value: float) -> float:
	var amount := clampf(value, 0.0, 1.0)
	return amount * amount * (3.0 - 2.0 * amount)
