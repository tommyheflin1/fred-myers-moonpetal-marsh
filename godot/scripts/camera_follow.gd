class_name FredCameraFollow
extends RefCounted

const REFERENCE_VIEWPORT := Vector2(1280.0, 720.0)
const WORLD_MIN := Vector2(55.0, 105.0)
const WORLD_MAX := Vector2(1225.0, 665.0)
const DEAD_ZONE := Rect2(300.0, 180.0, 680.0, 360.0)
const SAFE_FRAME := Rect2(68.0, 110.0, 1144.0, 544.0)
const MAX_OFFSET := Vector2(26.0, 26.0)
const HORIZONTAL_ANTICIPATION := 18.0
const VERTICAL_ANTICIPATION := 4.0
const BOOST_LOOK_AHEAD := 6.0
const TONGUE_LOOK_AHEAD := Vector2(6.0, 4.0)
const MAX_CATCH_UP_PER_TICK := 1.75
const INPUT_DEAD_ZONE := 0.18

var offset := Vector2.ZERO
var target_offset := Vector2.ZERO
var viewport_scale := 1.0

func advance(
	focus: Vector2,
	movement: Vector2,
	leap_height: float,
	depth_amount: float,
	boost_strength: float,
	tongue_offset: Vector2,
	tongue_active: bool,
	reduced_motion: bool,
	viewport_size: Vector2i,
	frozen: bool = false
) -> Dictionary:
	viewport_scale = _viewport_scale(viewport_size)
	if frozen:
		return snapshot(focus)
	if reduced_motion:
		target_offset = Vector2.ZERO
		offset = Vector2.ZERO
		return snapshot(focus)

	target_offset = _target_for(
		focus,
		movement,
		leap_height,
		depth_amount,
		boost_strength,
		tongue_offset,
		tongue_active
	)
	var catch_up := MAX_CATCH_UP_PER_TICK * viewport_scale
	offset.x = move_toward(offset.x, target_offset.x, catch_up)
	offset.y = move_toward(offset.y, target_offset.y, catch_up)
	offset = _clamp_for_focus(offset, focus)
	return snapshot(focus)

func reset() -> void:
	offset = Vector2.ZERO
	target_offset = Vector2.ZERO
	viewport_scale = 1.0

func snap(
	focus: Vector2,
	movement: Vector2,
	leap_height: float,
	depth_amount: float,
	boost_strength: float,
	tongue_offset: Vector2,
	tongue_active: bool,
	reduced_motion: bool,
	viewport_size: Vector2i
) -> Dictionary:
	viewport_scale = _viewport_scale(viewport_size)
	if reduced_motion:
		reset()
		return snapshot(focus)
	target_offset = _target_for(
		focus,
		movement,
		leap_height,
		depth_amount,
		boost_strength,
		tongue_offset,
		tongue_active
	)
	offset = target_offset
	return snapshot(focus)

func snapshot(focus: Vector2) -> Dictionary:
	return {
		"offset": offset,
		"target": target_offset,
		"framed_focus": focus + offset,
		"viewport_scale": viewport_scale,
	}

func state_hash() -> String:
	return "%.4f:%.4f:%.4f:%.4f:%.4f" % [
		offset.x,
		offset.y,
		target_offset.x,
		target_offset.y,
		viewport_scale,
	]

func _target_for(
	focus: Vector2,
	movement: Vector2,
	leap_height: float,
	depth_amount: float,
	boost_strength: float,
	tongue_offset: Vector2,
	tongue_active: bool
) -> Vector2:
	var target := Vector2.ZERO
	if focus.x < DEAD_ZONE.position.x:
		target.x += minf(MAX_OFFSET.x, (DEAD_ZONE.position.x - focus.x) * 0.08)
	elif focus.x > DEAD_ZONE.end.x:
		target.x -= minf(MAX_OFFSET.x, (focus.x - DEAD_ZONE.end.x) * 0.08)
	if focus.y < DEAD_ZONE.position.y:
		target.y += minf(MAX_OFFSET.y, (DEAD_ZONE.position.y - focus.y) * 0.08)
	elif focus.y > DEAD_ZONE.end.y:
		target.y -= minf(MAX_OFFSET.y, (focus.y - DEAD_ZONE.end.y) * 0.08)

	var normalized_movement := movement.normalized() if movement.length() > INPUT_DEAD_ZONE else Vector2.ZERO
	target.x -= normalized_movement.x * HORIZONTAL_ANTICIPATION * viewport_scale
	target.y -= normalized_movement.y * VERTICAL_ANTICIPATION * viewport_scale
	target.x -= normalized_movement.x * BOOST_LOOK_AHEAD * clampf(boost_strength, 0.0, 1.0) * viewport_scale
	target.y -= minf(10.0, maxf(0.0, leap_height) * 0.18) * viewport_scale
	target.y += clampf(depth_amount, 0.0, 1.0) * 8.0 * viewport_scale
	target.y -= 4.0 * clampf(boost_strength, 0.0, 1.0) * viewport_scale
	if tongue_active and tongue_offset.length_squared() > 0.001:
		var normalized_tongue := tongue_offset.normalized()
		target.x -= normalized_tongue.x * TONGUE_LOOK_AHEAD.x * viewport_scale
		target.y -= normalized_tongue.y * TONGUE_LOOK_AHEAD.y * viewport_scale

	target.x = clampf(target.x, -MAX_OFFSET.x * viewport_scale, MAX_OFFSET.x * viewport_scale)
	target.y = clampf(target.y, -MAX_OFFSET.y * viewport_scale, MAX_OFFSET.y * viewport_scale)
	return _clamp_for_focus(target, focus)

func _clamp_for_focus(candidate: Vector2, focus: Vector2) -> Vector2:
	var clamped := candidate
	clamped.x = clampf(clamped.x, SAFE_FRAME.position.x - focus.x, SAFE_FRAME.end.x - focus.x)
	clamped.y = clampf(clamped.y, SAFE_FRAME.position.y - focus.y, SAFE_FRAME.end.y - focus.y)
	clamped.x = clampf(clamped.x, -MAX_OFFSET.x * viewport_scale, MAX_OFFSET.x * viewport_scale)
	clamped.y = clampf(clamped.y, -MAX_OFFSET.y * viewport_scale, MAX_OFFSET.y * viewport_scale)
	return clamped

func _viewport_scale(viewport_size: Vector2i) -> float:
	var safe_size := Vector2(maxi(1, viewport_size.x), maxi(1, viewport_size.y))
	return clampf(
		minf(safe_size.x / REFERENCE_VIEWPORT.x, safe_size.y / REFERENCE_VIEWPORT.y),
		0.5,
		1.0
	)
