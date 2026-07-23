class_name FredLeapTraversal
extends RefCounted

enum State { GROUNDED, AIRBORNE, LANDING }

const AIRBORNE_SECONDS := 0.72
const LANDING_SECONDS := 0.12
const TRAVEL_SPEED := 190.0
const ARC_HEIGHT := 52.0

var state := State.GROUNDED
var elapsed := 0.0
var direction := Vector2.RIGHT
var visual_height := 0.0

func request(requested_direction: Vector2) -> bool:
	if state != State.GROUNDED:
		return false
	direction = requested_direction.normalized() if requested_direction.length_squared() > 0.001 else Vector2.RIGHT
	state = State.AIRBORNE
	elapsed = 0.0
	visual_height = 0.0
	return true

func advance(delta: float) -> Dictionary:
	var safe_delta := maxf(0.0, delta)
	if state == State.GROUNDED:
		return {"movement": Vector2.ZERO, "landed": false}
	if state == State.AIRBORNE:
		var previous := elapsed
		elapsed = minf(AIRBORNE_SECONDS, elapsed + safe_delta)
		var applied := elapsed - previous
		var progress := elapsed / AIRBORNE_SECONDS
		visual_height = sin(progress * PI) * ARC_HEIGHT
		var landed := elapsed >= AIRBORNE_SECONDS
		if landed:
			state = State.LANDING
			elapsed = 0.0
			visual_height = 0.0
		return {"movement": direction * TRAVEL_SPEED * applied, "landed": landed}
	elapsed = minf(LANDING_SECONDS, elapsed + safe_delta)
	if elapsed >= LANDING_SECONDS:
		state = State.GROUNDED
		elapsed = 0.0
	return {"movement": Vector2.ZERO, "landed": false}

func reset() -> void:
	state = State.GROUNDED
	elapsed = 0.0
	visual_height = 0.0
	direction = Vector2.RIGHT

func is_airborne() -> bool:
	return state == State.AIRBORNE

func cue() -> String:
	match state:
		State.AIRBORNE:
			return "AIRBORNE"
		State.LANDING:
			return "LANDING"
		_:
			return "READY"
