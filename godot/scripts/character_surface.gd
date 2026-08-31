class_name FredCharacterSurface
extends RefCounted

# Texture-free vertex lighting for Fred-owned presentation geometry. One draw
# per surface; no nodes, materials, timers or GPU resources are created here.
# Volume contours must be star-shaped about their mean (not arbitrary polygons).
const MAX_CONTOUR_POINTS := 96
const ELLIPSE_SEGMENTS := 24
static var _index_cache: Dictionary = {}
static var _ellipse_cache: Dictionary = {}

static func _triangle_indices(count: int) -> PackedInt32Array:
	# At most MAX_CONTOUR_POINTS distinct entries, independent of play time,
	# position, pose, color or customization. Packed arrays are copy-on-write.
	if not _index_cache.has(count):
		var indices := PackedInt32Array()
		for index in count:
			var next := (index + 1) % count
			indices.append_array(PackedInt32Array([0, 1 + index, 1 + next, 1 + index, 1 + count + index, 1 + count + next, 1 + index, 1 + count + next, 1 + next]))
		_index_cache[count] = indices
	return _index_cache[count]

static func rounded_contour(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 3 or points.size() * 2 > MAX_CONTOUR_POINTS:
		return points.duplicate()
	for index in points.size():
		var next := points[(index + 1) % points.size()]
		result.append(points[index].lerp(next, 0.18))
		result.append(points[index].lerp(next, 0.82))
	return result

static func volume_mesh(contour: PackedVector2Array, base: Color, gloss: float = 0.0, feathered: bool = false) -> Dictionary:
	var empty := {"points": PackedVector2Array(), "colors": PackedColorArray(), "indices": PackedInt32Array()}
	if contour.size() < 3 or contour.size() > MAX_CONTOUR_POINTS or not is_finite(gloss):
		return empty
	var center := Vector2.ZERO
	for point in contour:
		if not point.is_finite():
			return empty
		center += point
	center /= float(contour.size())
	var count := contour.size()
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	points.resize(count * 2 + 1)
	colors.resize(count * 2 + 1)
	points[0] = center
	colors[0] = base if feathered else base.lightened(0.12)
	var highlight_strength := 0.14 + clampf(gloss, 0, 1) * 0.16
	var inner_fade := base
	inner_fade.a *= 0.46
	var outer_fade := base
	outer_fade.a *= 0.0
	# Both rings share a direction and highlight. Soft patches have no directional
	# lighting at all. Keep vertex order and arithmetic identical to the old art.
	for index in count:
		var point := contour[index]
		points[1 + index] = center.lerp(point, 0.56)
		points[1 + count + index] = center.lerp(point, 1.0)
		if feathered:
			colors[1 + index] = inner_fade
			colors[1 + count + index] = outer_fade
		else:
			var direction := (point - center).normalized()
			var light := direction.dot(Vector2(-0.5, -0.866))
			var lit := base.lightened(maxf(0.0, light) * highlight_strength)
			var shade := maxf(0.0, -light)
			var inner := lit.darkened(shade * 0.56 * 0.44 + 0.56 * 0.06)
			var outer := lit.darkened(shade * 1.0 * 0.44 + 1.0 * 0.06)
			inner.a = base.a
			outer.a = base.a
			colors[1 + index] = inner
			colors[1 + count + index] = outer
	return {"points": points, "colors": colors, "indices": _triangle_indices(count)}

static func draw_volume(canvas: Node2D, contour: PackedVector2Array, base: Color, gloss: float = 0.0, feathered: bool = false) -> void:
	var mesh := volume_mesh(contour, base, gloss, feathered)
	if not mesh.points.is_empty():
		RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), mesh.indices, mesh.points, mesh.colors)

static func ellipse(center: Vector2, radii: Vector2, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var detail := 8 if radii.length() < 8.0 else (16 if radii.length() < 25.0 else ELLIPSE_SEGMENTS)
	for unit in _unit_ellipse_points(detail):
		points.append(center + (unit * radii).rotated(rotation))
	return points

static func _unit_ellipse_points(detail: int) -> PackedVector2Array:
	# Exactly 48 static vertices total, not a cache keyed by position/pose/time.
	# Return an isolated copy so even a caller editing it cannot poison the cache.
	if detail not in [8, 16, ELLIPSE_SEGMENTS]:
		return PackedVector2Array()
	if not _ellipse_cache.has(detail):
		var points := PackedVector2Array()
		for index in detail:
			var angle := float(index) * TAU / detail
			points.append(Vector2(cos(angle), sin(angle)))
		_ellipse_cache[detail] = points
	return _ellipse_cache[detail].duplicate()

static func smooth_line(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 2:
		return points.duplicate()
	var result := PackedVector2Array([points[0]])
	for index in points.size() - 1:
		result.append(points[index].lerp(points[index + 1], 0.25))
		result.append(points[index].lerp(points[index + 1], 0.75))
	result.append(points[-1])
	return result

static func draw_ribbon(canvas: Node2D, spine: PackedVector2Array, widths: PackedFloat32Array, base: Color) -> void:
	if spine.size() < 2 or spine.size() != widths.size() or spine.size() > MAX_CONTOUR_POINTS:
		return
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index in spine.size():
		var direction := (spine[mini(index + 1, spine.size() - 1)] - spine[maxi(0, index - 1)]).normalized()
		var normal := Vector2(-direction.y, direction.x)
		points.append_array(PackedVector2Array([spine[index] - normal * widths[index], spine[index] - normal * widths[index] * 0.22, spine[index] + normal * widths[index]]))
		colors.append_array(PackedColorArray([base.darkened(0.20), base.lightened(0.22), base.darkened(0.50)]))
		if index > 0:
			var start := (index - 1) * 3
			indices.append_array(PackedInt32Array([start, start + 3, start + 4, start, start + 4, start + 1, start + 1, start + 4, start + 5, start + 1, start + 5, start + 2]))
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
