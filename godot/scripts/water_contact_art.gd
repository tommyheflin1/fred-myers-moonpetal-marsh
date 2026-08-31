class_name FredWaterContactArt
extends RefCounted

const Surface = preload("res://scripts/character_surface.gd")
const MAX_CURVES := 6
const MAX_BUBBLES := 4

# Stateless, app-owned presentation geometry. Coordinates are local to the
# actor's water-plane position, never its elevated leap/dive drawing position.
static func _empty() -> Dictionary:
	return {"valid": false, "shadow_center": Vector2.ZERO, "shadow_radii": Vector2.ZERO, "shadow_alpha": 0.0, "curves": [], "bubbles": []}

static func _arc(center: Vector2, radii: Vector2, start: float, end: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 17:
		var angle := lerpf(start, end, float(index) / 16.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	return points

static func _ring(result: Dictionary, center: Vector2, radii: Vector2, alpha: float, phase: float = 0.0) -> void:
	if alpha <= 0.001 or result.curves.size() + 2 > MAX_CURVES:
		return
	# Open arcs, not an unbroken outline or a circle across the animal's face.
	result.curves.append({"points": _arc(center, radii, 0.12 + phase, PI - 0.15 + phase), "alpha": alpha})
	result.curves.append({"points": _arc(center, radii, PI + 0.35 + phase, TAU - 0.40 + phase), "alpha": alpha * 0.48})

static func frog(snapshot: Dictionary, time_seconds: float, reduced_motion: bool = false) -> Dictionary:
	var result := _empty()
	var depth := float(snapshot.get("depth", 0.0))
	var height := float(snapshot.get("height", 0.0))
	var scale_size := float(snapshot.get("size", 1.0))
	var landing := float(snapshot.get("landing", -1.0))
	var direction := Vector2(snapshot.get("direction", Vector2.RIGHT))
	if not is_finite(depth) or not is_finite(height) or not is_finite(scale_size) or not is_finite(landing) or not is_finite(time_seconds) or not direction.is_finite():
		return result
	depth = clampf(depth, 0.0, 1.0)
	height = clampf(height, 0.0, 60.0)
	scale_size = clampf(scale_size, 0.5, 1.6)
	var phase := 0.35 if reduced_motion else fposmod(maxf(0.0, time_seconds) * 0.9, 1.0)
	var airborne := bool(snapshot.get("airborne", false))
	var perched := bool(snapshot.get("perched", false))
	var center := Vector2(0, 46.0 * scale_size)
	result.valid = true
	result.shadow_center = center
	result.shadow_radii = Vector2(34.0 + height * 0.18, 8.0 + height * 0.035) * scale_size
	result.shadow_alpha = (0.32 - height * 0.0025) * (1.0 - depth * 0.68)
	# A pad above a submerged frog is not a dry perch at Fred's depth.
	if airborne or (perched and depth <= 0.001):
		return result
	var surface_alpha := 0.31 * (1.0 - depth)
	_ring(result, center, Vector2(38, 9) * scale_size, surface_alpha)
	var moving := bool(snapshot.get("moving", false))
	if moving and depth < 0.85:
		var heading := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
		var boost := 1.4 if bool(snapshot.get("boosting", false)) else 1.0
		var tail := -heading * (18.0 + phase * 28.0) * boost * scale_size
		_ring(result, center + tail, Vector2(39 + phase * 12, 10 + phase * 3) * scale_size, surface_alpha * (1.0 - phase) * 0.72)
	if landing >= 0.0 and depth < 0.15:
		var progress := 0.35 if reduced_motion else clampf(landing, 0.0, 1.0)
		_ring(result, center, Vector2(38 + progress * 32, 9 + progress * 12) * scale_size, (1.0 - progress) * 0.38)
	if depth > 0.10:
		for index in 4:
			var rise := 0.45 if reduced_motion else fposmod(phase + index * 0.24, 1.0)
			var side := -1.0 if index % 2 == 0 else 1.0
			result.bubbles.append({"center": Vector2(side * (42 + index * 3), 35 - rise * 44) * scale_size, "radius": 1.5 + index * 0.3, "alpha": depth * (1.0 - rise) * 0.45})
	return result

static func heron_feet(pose: Dictionary) -> PackedVector2Array:
	var lift := float(pose.get("leg_lift", 0.0))
	if not is_finite(lift):
		lift = 0.0
	lift = clampf(lift, 0.0, 4.5)
	return PackedVector2Array([Vector2(-6, 61 - lift * 0.58), Vector2(12, 61 + lift * 0.42 * 0.58)])

static func predator(kind: String, depth: float, pose: Dictionary, time_seconds: float, reduced_motion: bool = false) -> Dictionary:
	var result := _empty()
	if kind not in ["BASS", "PIKE", "MUSKIE", "SNAKE", "HERON"] or not is_finite(depth) or not is_finite(time_seconds):
		return result
	depth = clampf(depth, 0.0, 1.0)
	result.valid = true
	if kind == "HERON":
		var feet := heron_feet(pose)
		result.shadow_center = (feet[0] + feet[1]) * 0.5 + Vector2(0, 2)
		result.shadow_radii = Vector2(30, 6)
		result.shadow_alpha = 0.25
		for foot in feet:
			_ring(result, foot + Vector2(0, 2), Vector2(17, 3.5), 0.22)
		return result
	var width := 56.0 if kind == "BASS" else (83.0 if kind == "SNAKE" else 69.0)
	result.shadow_center = Vector2(3, 22)
	result.shadow_radii = Vector2(width, 12)
	result.shadow_alpha = 0.30 * (1.0 - depth * 0.55)
	var phase := 0.35 if reduced_motion else fposmod(maxf(0.0, time_seconds) * 0.65, 1.0)
	_ring(result, Vector2(0, 22), Vector2(width, 9), 0.26 * (1.0 - depth))
	_ring(result, Vector2(0, 23), Vector2(width + phase * 16, 10 + phase * 5), (1.0 - phase) * (1.0 - depth) * 0.17)
	return result

static func draw_contact(canvas: Node2D, origin: Vector2, geometry: Dictionary) -> void:
	if not bool(geometry.get("valid", false)):
		return
	Surface.draw_volume(canvas, Surface.ellipse(origin + Vector2(geometry.shadow_center), Vector2(geometry.shadow_radii)), Color(0.005, 0.025, 0.035, float(geometry.shadow_alpha)), 0, true)
	for curve: Dictionary in geometry.curves:
		var points := PackedVector2Array()
		for point: Vector2 in curve.points:
			points.append(origin + point)
		canvas.draw_polyline(points, Color(0.02, 0.12, 0.16, float(curve.alpha) * 0.64), 3.0, true)
		canvas.draw_polyline(points, Color(0.63, 0.92, 0.88, float(curve.alpha)), 1.2, true)
	for bubble: Dictionary in geometry.bubbles:
		var center := origin + Vector2(bubble.center)
		canvas.draw_circle(center, float(bubble.radius), Color(0.67, 0.94, 1.0, float(bubble.alpha)), false, 0.9, true)
		canvas.draw_circle(center + Vector2(-0.5, -0.6), 0.5, Color(0.92, 1.0, 1.0, float(bubble.alpha)))
