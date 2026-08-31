class_name FredCharacterSurface
extends RefCounted

# Texture-free vertex lighting for Fred-owned presentation geometry. One draw
# per surface; no nodes, materials, timers or GPU resources are created here.
# Volume contours must be star-shaped about their mean (not arbitrary polygons).
const MAX_CONTOUR_POINTS := 96
const ELLIPSE_SEGMENTS := 24
static var _index_cache: Dictionary = {}

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
	var points := PackedVector2Array([center])
	var colors := PackedColorArray([base if feathered else base.lightened(0.12)])
	for ring: float in [0.56, 1.0]:
		for point in contour:
			points.append(center.lerp(point, ring))
			var direction := (point - center).normalized()
			var light := direction.dot(Vector2(-0.5, -0.866))
			var color := base
			if feathered:
				color.a *= 0.46 if ring < 1.0 else 0.0
			else:
				color = base.lightened(maxf(0.0, light) * (0.14 + clampf(gloss, 0, 1) * 0.16))
				color = color.darkened(maxf(0.0, -light) * ring * 0.44 + ring * 0.06)
				color.a = base.a
			colors.append(color)
	return {"points": points, "colors": colors, "indices": _triangle_indices(contour.size())}

static func draw_volume(canvas: Node2D, contour: PackedVector2Array, base: Color, gloss: float = 0.0, feathered: bool = false) -> void:
	var mesh := volume_mesh(contour, base, gloss, feathered)
	if not mesh.points.is_empty():
		RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), mesh.indices, mesh.points, mesh.colors)

static func ellipse(center: Vector2, radii: Vector2, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var detail := 8 if radii.length() < 8.0 else (16 if radii.length() < 25.0 else ELLIPSE_SEGMENTS)
	for index in detail:
		var angle := float(index) * TAU / detail
		points.append(center + (Vector2(cos(angle), sin(angle)) * radii).rotated(rotation))
	return points

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
