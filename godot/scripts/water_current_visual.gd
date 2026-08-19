class_name FredWaterCurrentVisual
extends RefCounted

const STREAM_COUNT := 28
const POINTS_PER_STREAM := 7
const PLAYFIELD := Rect2(15.0, 105.0, 1250.0, 530.0)
const INNER_MARGIN := 34.0
const MAX_CURRENT_MAGNITUDE := 180.0
const MAX_VISUAL_TIME := TAU * 100.0

static func profile(
	level: int,
	current: Vector2,
	depth: float,
	time: float,
	reduced_motion: bool
) -> Dictionary:
	var safe_level := maxi(1, level)
	var safe_depth := clampf(depth if is_finite(depth) else 0.0, 0.0, 1.0)
	var safe_current := current if current.is_finite() else Vector2.ZERO
	var current_magnitude := clampf(safe_current.length(), 0.0, MAX_CURRENT_MAGNITUDE)
	var direction := signf(safe_current.x)
	if is_zero_approx(direction):
		direction = -1.0 if safe_level % 2 == 0 else 1.0
	var intensity := clampf(0.18 + current_magnitude / MAX_CURRENT_MAGNITUDE, 0.18, 1.0)
	var motion_scale := 0.0 if reduced_motion else 1.0
	var safe_time := 0.0 if reduced_motion else fmod(maxf(0.0, time if is_finite(time) else 0.0), MAX_VISUAL_TIME)
	var surface_color := Color(0.60, 0.95, 0.94, 0.09 + intensity * 0.16)
	var deep_color := Color(0.35, 0.76, 0.94, 0.08 + intensity * 0.13)
	return {
		"valid": true,
		"direction": direction,
		"intensity": intensity,
		"depth": safe_depth,
		"flow_time": safe_time,
		"motion_scale": motion_scale,
		"speed": lerpf(11.0, 58.0, intensity) * lerpf(1.0, 0.82, safe_depth),
		"highlight": surface_color.lerp(deep_color, safe_depth),
		"shadow": Color(0.01, 0.18, 0.27, 0.08 + intensity * 0.08),
		"foam_ratio": clampf((intensity - 0.42) / 0.58, 0.0, 1.0),
		"presentation_only": true,
		"collision_mutation": false,
		"save_fields": 0,
	}

static func streamline(index: int, flow: Dictionary) -> Dictionary:
	if index < 0 or index >= STREAM_COUNT or not bool(flow.get("valid", false)):
		return {"valid": false}
	var direction := float(flow.direction)
	var intensity := float(flow.intensity)
	var motion_scale := float(flow.motion_scale)
	var flow_time := float(flow.flow_time)
	var length := 76.0 + float(index % 5) * 15.0 + intensity * 24.0
	var available_width := PLAYFIELD.size.x - INNER_MARGIN * 2.0 - length
	var travel := fmod(float(index * 167) + flow_time * float(flow.speed), maxf(1.0, available_width))
	var start_x := PLAYFIELD.position.x + INNER_MARGIN + travel
	if direction < 0.0:
		start_x = PLAYFIELD.end.x - INNER_MARGIN - travel
	var lane := index % 7
	var band := index / 7
	var base_y := PLAYFIELD.position.y + 42.0 + float(lane) * 70.0 + float(band) * 9.0
	var static_curve := sin(float(index) * 1.37) * 4.5
	var moving_curve := sin(flow_time * 0.52 + float(index) * 0.83) * (3.0 + intensity * 5.0) * motion_scale
	var bend := static_curve + moving_curve
	var points := PackedVector2Array()
	for point_index in range(POINTS_PER_STREAM):
		var ratio := float(point_index) / float(POINTS_PER_STREAM - 1)
		var x := start_x + direction * length * ratio
		var y := base_y + sin(ratio * PI) * bend + sin(ratio * TAU + float(index)) * 2.0
		points.append(Vector2(
			clampf(x, PLAYFIELD.position.x + 18.0, PLAYFIELD.end.x - 18.0),
			clampf(y, PLAYFIELD.position.y + 20.0, PLAYFIELD.end.y - 20.0)
		))
	return {
		"valid": true,
		"points": points,
		"width": 1.25 + float(index % 3) * 0.38 + intensity * 0.35,
		"highlight": Color(flow.highlight) * Color(1.0, 1.0, 1.0, 0.72 + float(index % 4) * 0.07),
		"shadow": Color(flow.shadow),
		"foam": float(flow.foam_ratio) * (0.42 + float(index % 3) * 0.18),
		"presentation_only": true,
	}

static func eddy(index: int, flow: Dictionary) -> Dictionary:
	if index < 0 or not bool(flow.get("valid", false)):
		return {"valid": false}
	var direction := float(flow.direction)
	var motion_scale := float(flow.motion_scale)
	var rotation := float(index) * 1.11 + direction * float(flow.flow_time) * 0.32 * motion_scale
	return {
		"valid": true,
		"rotation": rotation,
		"sweep": direction * (1.05 + float(index % 3) * 0.18),
		"radius": 38.0 + float(index % 4) * 4.0,
		"wake_length": 31.0 + float(flow.intensity) * 24.0,
		"opacity": 0.09 + float(flow.intensity) * 0.12,
		"presentation_only": true,
	}
