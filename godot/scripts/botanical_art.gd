class_name FredBotanicalArt
extends RefCounted

# App-owned presentation only. These local contours never become collision,
# landing or exit geometry. No clock, randomness, nodes or growing cache.
const Surface = preload("res://scripts/character_surface.gd")
const LEAF_RADII := Vector2(48, 29)
const LEAF_SEGMENTS := 40
const PERCH_SEGMENTS := 32
const PERCH_TEXT_CLEAR := Rect2(-56, -10, 112, 24)

static func leaf_contour(variant: int = 0) -> PackedVector2Array:
	var contour := PackedVector2Array()
	# A real open notch reveals the water beneath it, rather than painting a
	# triangle over a complete disc. The center of the mesh stays left of it.
	for index in LEAF_SEGMENTS:
		var angle := lerpf(0.20, TAU - 0.32, float(index) / (LEAF_SEGMENTS - 1))
		var edge := 0.982 + sin(angle * 7.0 + posmod(variant, 3) * 0.7) * 0.018
		contour.append(Vector2.from_angle(angle) * LEAF_RADII * edge)
	contour.append(Vector2(9, -1))
	return contour

static func leaf_veins() -> Array[PackedVector2Array]:
	var veins: Array[PackedVector2Array] = []
	var root := Vector2(4, -1)
	for index in 9:
		var angle := lerpf(0.45, TAU - 0.55, float(index) / 8.0)
		var tip := Vector2.from_angle(angle) * LEAF_RADII * 0.86
		var middle := root.lerp(tip, 0.53) + Vector2(-2, -2)
		veins.append(PackedVector2Array([root, middle, tip]))
		var branch_angle := angle + (0.17 if index % 2 else -0.17)
		veins.append(PackedVector2Array([middle, Vector2.from_angle(branch_angle) * LEAF_RADII * 0.71]))
	return veins

static func petal_contour(radius: float, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not is_finite(radius) or not is_finite(angle) or radius <= 0 or radius > 80:
		return points
	# Narrow, pointed water-lily petals, with a curved shoulder and folded base.
	for point in PackedVector2Array([Vector2(0.10, 0), Vector2(0.25, -0.10), Vector2(0.51, -0.18), Vector2(0.76, -0.13), Vector2(0.98, 0), Vector2(0.73, 0.13), Vector2(0.49, 0.18), Vector2(0.23, 0.09)]):
		points.append((point * radius).rotated(angle))
	return points

static func perch_contour(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not is_finite(radius) or radius < 20 or radius > 100:
		return points
	for index in PERCH_SEGMENTS:
		var angle := float(index) * TAU / PERCH_SEGMENTS
		var edge := 0.98 + sin(angle * 5.0 + 0.4) * 0.02
		points.append((Vector2.from_angle(angle) * Vector2(radius, radius * 0.62) * edge).rotated(-0.08))
	return points

static func perch_grass(radius: float) -> Array[PackedVector2Array]:
	var blades: Array[PackedVector2Array] = []
	if not is_finite(radius) or radius < 20 or radius > 100:
		return blades
	# Keep every blade above the label's reserved central strip.
	for tuft in 5:
		var base := Vector2((tuft - 2) * radius * 0.27, -maxf(14, radius * 0.30))
		blades.append(PackedVector2Array([base, base + Vector2(-2, -6), base + Vector2(-7, -12 - tuft % 2 * 3)]))
		blades.append(PackedVector2Array([base, base + Vector2(3, -7), base + Vector2(7, -16)]))
	return blades

static func reed_blades(height: float, sway: float) -> Array[PackedVector2Array]:
	var blades: Array[PackedVector2Array] = []
	if not is_finite(height) or not is_finite(sway) or height < 1 or height > 80:
		return blades
	sway = clampf(sway, -5, 5)
	blades.append(PackedVector2Array([Vector2.ZERO, Vector2(sway * 0.18, -height * 0.35), Vector2(sway * 0.55, -height * 0.72), Vector2(sway, -height)]))
	blades.append(PackedVector2Array([Vector2(sway * 0.18, -height * 0.30), Vector2(6 + sway * 0.40, -height * 0.48), Vector2(14 + sway * 0.65, -height * 0.68)]))
	blades.append(PackedVector2Array([Vector2(0, -height * 0.18), Vector2(-5 + sway * 0.25, -height * 0.32), Vector2(-9 + sway * 0.5, -height * 0.50)]))
	return blades

static func _placed(points: PackedVector2Array, at: Vector2, angle: float = 0.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(at + point.rotated(angle))
	return result

static func _rim(canvas: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 3:
		return
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, color, width, true)

static func draw_lily(canvas: Node2D, at: Vector2, index: int, angle: float) -> void:
	var leaf := leaf_contour(index)
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(7, 10), Vector2(52, 30), angle), Color(0.005, 0.025, 0.035, 0.43), 0, true)
	var ripple := PackedVector2Array()
	for segment in 17:
		var phase := lerpf(0.18, PI - 0.18, segment / 16.0)
		ripple.append(at + Vector2(2, 8) + (Vector2.from_angle(phase) * Vector2(52, 29)).rotated(angle))
	canvas.draw_polyline(ripple, Color(0.55, 0.92, 0.93, 0.18), 1.2, true)
	Surface.draw_volume(canvas, _placed(leaf, at + Vector2(0, 3), angle), Color("244c34"), 0.2)
	var green := Color("4e9852").lightened(posmod(index, 3) * 0.035)
	var top := _placed(leaf, at, angle)
	Surface.draw_volume(canvas, top, green, 0.45)
	_rim(canvas, top, Color(0.73, 0.87, 0.45, 0.70), 1.1)
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(-17, -7).rotated(angle), Vector2(22, 13), angle), Color(0.78, 0.88, 0.43, 0.16), 0, true)
	var veins := leaf_veins()
	for vein in veins.size():
		canvas.draw_polyline(_placed(Surface.smooth_line(veins[vein]), at, angle), Color(0.69, 0.82, 0.44, 0.20 if vein % 2 else 0.32), 0.6 if vein % 2 else 0.8, true)
	for fleck in 6:
		var phase := 0.6 + fleck * 0.88
		var center := at + (Vector2.from_angle(phase) * LEAF_RADII * (0.58 if fleck % 2 else 0.75)).rotated(angle)
		canvas.draw_circle(center, 0.7, Color(0.84, 0.92, 0.55, 0.19))
	for drop in 3:
		var center := at + Vector2(-20 + drop * 11, -9 + drop % 2 * 9).rotated(angle)
		var radius := 2.2 if drop == 0 else 1.4
		Surface.draw_volume(canvas, Surface.ellipse(center, Vector2.ONE * radius), Color(0.72, 0.91, 0.79, 0.67), 0.8)
		canvas.draw_circle(center + Vector2(-0.5, -0.5), radius * 0.32, Color("eaffdf"))
	if posmod(index, 3) == 1:
		draw_flower(canvas, at + Vector2(-7, -8), 15.0, false)

static func draw_flower(canvas: Node2D, at: Vector2, radius: float, is_exit: bool = true) -> void:
	if not is_finite(radius) or radius <= 0 or radius > 80:
		return
	if is_exit:
		Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(4, 10), Vector2(radius + 10, (radius + 10) * 0.62)), Color(0.02, 0.03, 0.08, 0.48), 0, true)
		Surface.draw_volume(canvas, Surface.ellipse(at, Vector2.ONE * (radius + 8)), Color(0.78, 0.63, 1.0, 0.28), 0, true)
	# Tiny pad blossoms need only one eight-petal layer at gameplay scale.
	for layer in (2 if is_exit else 1):
		var length := radius * (1.0 if layer == 0 else 0.72)
		for petal in 8:
			var angle := float(petal) * TAU / 8 + (0.18 if layer == 0 else 0.57)
			var contour := _placed(petal_contour(length, angle), at)
			Surface.draw_volume(canvas, contour, Color("ae83cd") if layer == 0 and is_exit else Color("e2bdf0"), 0.35)
			_rim(canvas, contour, Color(0.96, 0.83, 1.0, 0.66), 0.85 if is_exit else 0.55)
			if is_exit:
				canvas.draw_line(at + Vector2.from_angle(angle) * length * 0.26, at + Vector2.from_angle(angle) * length * 0.79, Color(0.98, 0.89, 1.0, 0.34), 0.8, true)
	Surface.draw_volume(canvas, Surface.ellipse(at, Vector2.ONE * radius * 0.24), Color("f0c05c"), 0.6)
	for stamen in 8:
		var tip := at + Vector2.from_angle(stamen * TAU / 8) * radius * 0.16
		canvas.draw_circle(tip, radius * 0.034, Color("fff0a6"))
	canvas.draw_circle(at + Vector2(-0.05, -0.06) * radius, radius * 0.065, Color("fff4b8"))

static func draw_perch(canvas: Node2D, at: Vector2, radius: float) -> void:
	var contour := perch_contour(radius)
	if contour.is_empty():
		return
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(5, 9), Vector2(radius + 12, radius * 0.68), -0.08), Color(0.01, 0.04, 0.03, 0.48), 0, true)
	Surface.draw_volume(canvas, _placed(contour, at + Vector2(0, 5)), Color("635437"), 0.1)
	var top := _placed(contour, at)
	Surface.draw_volume(canvas, top, Color("427342"), 0.15)
	_rim(canvas, top, Color(0.58, 0.79, 0.42, 0.78), 1.4)
	# Moss and smooth stones stay on the far and near edges, away from text.
	for detail in 12:
		var angle := detail * TAU / 12.0
		var local := Vector2.from_angle(angle) * Vector2(radius * 0.85, radius * 0.53)
		if PERCH_TEXT_CLEAR.grow(4).has_point(local):
			continue
		Surface.draw_volume(canvas, Surface.ellipse(at + local, Vector2(4.4, 2.0), angle * 0.1), Color("a7a079") if detail % 3 == 0 else Color("789956"), 0.1)
	for blade: PackedVector2Array in perch_grass(radius):
		Surface.draw_ribbon(canvas, _placed(blade, at), PackedFloat32Array([1.5, 1.3, 0.0]), Color("a4bd6c"))

static func draw_reed(canvas: Node2D, at: Vector2, height: float, sway: float, seed_head: bool) -> void:
	var blades := reed_blades(height, sway)
	for index in blades.size():
		var widths := PackedFloat32Array([1.5, 1.9, 1.1, 0.0]) if index == 0 else PackedFloat32Array([0.8, 2.1, 0.0])
		Surface.draw_ribbon(canvas, _placed(blades[index], at), widths, Color("80a75b") if index == 0 else Color("99b767"))
	if seed_head and not blades.is_empty():
		var center := at + blades[0][-1] + Vector2(0, 6)
		Surface.draw_volume(canvas, Surface.ellipse(center, Vector2(2.0, 5.0), sway * 0.015), Color("a88659"), 0.1)
