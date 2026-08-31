class_name FredWhirlpoolArt
extends RefCounted

# Original, app-owned water artwork. Reads the existing simulation clock only;
# it owns no nodes, timers, random state, textures, physics or retained history.
const Surface = preload("res://scripts/character_surface.gd")
const OUTER_RADIUS := 58.0
const LABEL_Y := 72.0
const RING_SEGMENTS := 40
const ARM_COUNT := 3
const ARM_POINTS := 28
const FOAM_COUNT := 9
const FOAM_POINTS := 6

static func geometry(index: int, time: float, reduced_motion: bool = false) -> Dictionary:
	if index < 0 or index > 2 or not is_finite(time) or time < 0:
		return {"valid": false}
	# Same angular speeds as the previous whirlpools. Reduced motion is a fully
	# steady illustration, with the funnel and foam still identifying the hazard.
	var phase := 0.0 if reduced_motion else fposmod(time * (1.1 + index * 0.2), TAU)
	var foam_phase := 0.0 if reduced_motion else fposmod(time * (1.1 + index * 0.2) * 0.7, TAU)
	var arms: Array[Dictionary] = []
	for arm in ARM_COUNT:
		var points := PackedVector2Array()
		var widths := PackedFloat32Array()
		for step in ARM_POINTS:
			var progress := step / float(ARM_POINTS - 1)
			var angle := phase + arm * TAU / ARM_COUNT + progress * TAU * 0.86
			var radius := lerpf(53.0, 10.0, progress)
			points.append(Vector2.from_angle(angle) * radius)
			widths.append(0.18 + sin(progress * PI) * 2.1)
		arms.append({"points": points, "widths": widths})
	var foam: Array[PackedVector2Array] = []
	for fleck in FOAM_COUNT:
		var points := PackedVector2Array()
		var radius := 49.0 + (fleck % 3) * 2.7
		var angle := foam_phase + fleck * TAU / FOAM_COUNT
		for step in FOAM_POINTS:
			var progress := step / float(FOAM_POINTS - 1)
			points.append(Vector2.from_angle(angle + progress * (0.11 + (fleck % 2) * 0.055)) * (radius - progress * 1.8))
		foam.append(points)
	return {"valid": true, "arms": arms, "foam": foam, "phase": phase}

static func funnel_mesh() -> Dictionary:
	# Concentric triangle strips, not overlapping opaque discs. The outer ring
	# dissolves into the existing marsh water without enlarging the old footprint.
	var points := PackedVector2Array([Vector2.ZERO])
	var colors := PackedColorArray([Color("020f19")])
	var indices := PackedInt32Array()
	var radii := PackedFloat32Array([8, 20, 37, 50, OUTER_RADIUS])
	var palette := PackedColorArray([Color(0.01,0.07,0.11,0.99), Color(0.02,0.14,0.19,0.96), Color(0.025,0.28,0.32,0.86), Color(0.12,0.40,0.43,0.66), Color(0.20,0.54,0.56,0.0)])
	for ring in radii.size():
		for step in RING_SEGMENTS:
			var angle := step * TAU / RING_SEGMENTS
			var direction := Vector2.from_angle(angle)
			var contour_scale := 0.99 + sin(angle * 3.0 + 0.4) * 0.005 + cos(angle * 5.0) * 0.005
			points.append(direction * radii[ring] * contour_scale)
			var shade := palette[ring].lightened(maxf(0, direction.dot(Vector2(-0.5,-0.866))) * 0.10)
			shade.a = palette[ring].a
			colors.append(shade)
			var current := 1 + ring * RING_SEGMENTS + step
			var next := 1 + ring * RING_SEGMENTS + (step + 1) % RING_SEGMENTS
			if ring == 0:
				indices.append_array(PackedInt32Array([0, current, next]))
			else:
				indices.append_array(PackedInt32Array([current - RING_SEGMENTS, current, next, current - RING_SEGMENTS, next, next - RING_SEGMENTS]))
	return {"points": points, "colors": colors, "indices": indices}

static func draw_water(canvas: Node2D, at: Vector2, shape: Dictionary) -> void:
	if not bool(shape.get("valid", false)) or not at.is_finite():
		return
	var mesh := funnel_mesh()
	var placed: PackedVector2Array = mesh.points
	for index in placed.size():
		placed[index] += at
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), mesh.indices, placed, mesh.colors)
	for arm: Dictionary in shape.arms:
		var line: PackedVector2Array = arm.points.duplicate()
		for index in line.size():
			line[index] += at
		Surface.draw_ribbon(canvas, line, arm.widths, Color(0.42,0.80,0.82,0.26))
		# Broken inner highlights let dark water show between the foam streaks.
		canvas.draw_polyline(line.slice(3, 15), Color(0.71,0.94,0.93,0.48), 1.15, true)
		canvas.draw_polyline(line.slice(19, 26), Color(0.39,0.75,0.80,0.32), 0.9, true)
	for fleck in shape.foam.size():
		var line: PackedVector2Array = shape.foam[fleck].duplicate()
		for index in line.size():
			line[index] += at
		canvas.draw_polyline(line, Color(0.77,0.97,0.96,0.58 if fleck % 3 == 0 else 0.38), 1.5 if fleck % 3 == 0 else 1.0, true)
	# Small reflection at the funnel throat; no flashing or particle burst.
	canvas.draw_arc(at, 9.0, 3.65, 5.75, 12, Color(0.36,0.70,0.74,0.27), 1.0, true)
