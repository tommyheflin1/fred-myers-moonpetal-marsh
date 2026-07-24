class_name FredDepthTraversal
extends RefCounted

enum State { SURFACE, DIVING, UNDERWATER, SURFACING }

const TRANSITION_SECONDS := 0.80
const UNDERWATER_SPEED_SCALE := 0.78
const UNDERWATER_BOOST_SCALE := 0.72

var state := State.SURFACE
var depth := 0.0
var elapsed := 0.0

func request_dive(entry_allowed: bool) -> bool:
	if state != State.SURFACE or not entry_allowed:
		return false
	state = State.DIVING
	elapsed = 0.0
	return true

func request_surface(exit_allowed: bool = true) -> bool:
	if state != State.UNDERWATER or not exit_allowed:
		return false
	state = State.SURFACING
	elapsed = 0.0
	return true

func advance(delta: float) -> Dictionary:
	var safe_delta := maxf(0.0, delta)
	if state not in [State.DIVING, State.SURFACING]:
		return {"completed": false, "mode": stable_mode()}
	elapsed = minf(TRANSITION_SECONDS, elapsed + safe_delta)
	var progress := elapsed / TRANSITION_SECONDS
	depth = progress if state == State.DIVING else 1.0 - progress
	var completed := elapsed >= TRANSITION_SECONDS
	if completed:
		state = State.UNDERWATER if state == State.DIVING else State.SURFACE
		depth = 1.0 if state == State.UNDERWATER else 0.0
		elapsed = 0.0
	return {"completed": completed, "mode": stable_mode()}

func reset(mode: String = "surface") -> void:
	state = State.UNDERWATER if mode == "underwater" else State.SURFACE
	depth = 1.0 if state == State.UNDERWATER else 0.0
	elapsed = 0.0

func stable_mode() -> String:
	return "underwater" if state == State.UNDERWATER else "surface"

func is_transitioning() -> bool:
	return state in [State.DIVING, State.SURFACING]

func is_underwater_band() -> bool:
	return state == State.UNDERWATER

func movement_scale() -> float:
	return UNDERWATER_SPEED_SCALE if state == State.UNDERWATER else 1.0

func cue() -> String:
	match state:
		State.DIVING:
			return "DIVING"
		State.UNDERWATER:
			return "UNDERWATER"
		State.SURFACING:
			return "SURFACING"
		_:
			return "SURFACE"
