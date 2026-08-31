class_name FredCollectibleWildlifeArt
extends RefCounted

# Original app-owned rendering; no gameplay, time source, random state or cache.
# Supplied rig poses are read-only. All geometry remains local to the old target.
const Surface = preload("res://scripts/character_surface.gd")
const BUG_LABEL_Y := 38.0
const FAIRY_LABEL_Y := 50.0
const FAIRY_LABEL := "FAIRY +1 LIFE"
const MAX_WINGS := 4
const MAX_WING_POINTS := 18
const POSE_FIELDS: Array[String] = ["wing_primary", "wing_secondary", "body_pitch", "abdomen_flex", "leg_lift", "arm_sweep", "eye_focus", "crown_tilt", "glow"]

static func _pose_valid(pose: Dictionary, kind: String) -> bool:
	if not bool(pose.get("valid", false)) or str(pose.get("kind", "")) != kind:
		return false
	for field in POSE_FIELDS:
		if not pose.has(field) or not is_finite(float(pose[field])):
			return false
	return true

static func _placed(points: PackedVector2Array, at: Vector2, angle: float = 0.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(at + point.rotated(angle))
	return result

static func _wing(kind: String, side: float, rear: bool, sweep: float) -> Dictionary:
	var outline: PackedVector2Array
	var veins: Array[PackedVector2Array] = []
	var hinge := Vector2(5 * side, 2 if rear else -4)
	var angle := 0.0
	if kind == "BUG":
		outline = PackedVector2Array([Vector2.ZERO, Vector2(6,-6), Vector2(17,-8), Vector2(25,-5), Vector2(27,0), Vector2(23,4), Vector2(12,4), Vector2(4,2)])
		veins = [PackedVector2Array([Vector2(2,0), Vector2(12,-3), Vector2(23,-2)]), PackedVector2Array([Vector2(12,-3), Vector2(16,2)])]
		angle = 0.35 + sweep * 0.025 if rear else -0.50 - sweep * 0.018
		if rear:
			for index in outline.size():
				outline[index] *= Vector2(0.82, 0.90)
			for vein_index in veins.size():
				var line := veins[vein_index]
				for index in line.size():
					line[index] *= Vector2(0.82, 0.90)
				veins[vein_index] = line
	else:
		if rear:
			outline = PackedVector2Array([Vector2.ZERO, Vector2(7,-1), Vector2(21,5), Vector2(22,13), Vector2(15,20), Vector2(7,19), Vector2(2,8)])
			veins = [PackedVector2Array([Vector2(2,1), Vector2(10,9), Vector2(15,17)]), PackedVector2Array([Vector2(10,9), Vector2(19,11)])]
		else:
			outline = PackedVector2Array([Vector2.ZERO, Vector2(3,-10), Vector2(12,-21), Vector2(21,-25), Vector2(29,-21), Vector2(31,-12), Vector2(26,-4), Vector2(12,4), Vector2(4,3)])
			veins = [PackedVector2Array([Vector2(2,0), Vector2(13,-10), Vector2(24,-20)]), PackedVector2Array([Vector2(13,-10), Vector2(26,-11)]), PackedVector2Array([Vector2(7,-5), Vector2(12,-18)])]
		angle = sweep * 0.012
	outline = Surface.rounded_contour(outline)
	for index in outline.size():
		var turned := outline[index].rotated(angle)
		outline[index] = hinge + Vector2(turned.x * side, turned.y)
	var placed_veins: Array[PackedVector2Array] = []
	for line in veins:
		var placed := PackedVector2Array()
		for point in Surface.smooth_line(line):
			var turned := point.rotated(angle)
			placed.append(hinge + Vector2(turned.x * side, turned.y))
		placed_veins.append(placed)
	return {"points": outline, "veins": placed_veins, "hinge": hinge, "rear": rear}

static func bug_geometry(pose: Dictionary, flutter: float = 0.0) -> Dictionary:
	if not _pose_valid(pose, "BUG") or not is_finite(flutter):
		return {"valid": false}
	var wings: Array[Dictionary] = []
	for rear: bool in [true, false]:
		var sweep := clampf(float(pose.wing_secondary), -8, 8) if rear else clampf(float(pose.wing_primary) + absf(flutter) * 0.12, -12.5, 12.5)
		for side: float in [-1, 1]:
			wings.append(_wing("BUG", side, rear, sweep))
	var legs: Array[PackedVector2Array] = []
	for side: float in [-1, 1]:
		for index in 3:
			var root := Vector2(5 * side, -2 + index * 6)
			var knee := root + Vector2((8 + index) * side, 2 + index * 2 + clampf(float(pose.leg_lift), -2, 2) * side)
			legs.append(PackedVector2Array([root, knee, knee + Vector2(5 * side, 4)]))
	return {"valid": true, "wings": wings, "legs": legs, "abdomen": Vector2(0, 8 + clampf(float(pose.abdomen_flex), -2.4, 2.4)), "pitch": clampf(float(pose.body_pitch), -0.08, 0.08), "eye_focus": clampf(float(pose.eye_focus), -0.8, 0.8)}

static func fairy_geometry(pose: Dictionary) -> Dictionary:
	if not _pose_valid(pose, "FAIRY"):
		return {"valid": false}
	var wings: Array[Dictionary] = []
	for rear: bool in [true, false]:
		var sweep := clampf(float(pose.wing_secondary), -6, 6) if rear else clampf(float(pose.wing_primary), -9, 9)
		for side: float in [-1, 1]:
			wings.append(_wing("FAIRY", side, rear, sweep))
	var arms: Array[PackedVector2Array] = []
	var legs: Array[PackedVector2Array] = []
	for side: float in [-1, 1]:
		var sweep := clampf(float(pose.arm_sweep), -4, 4)
		var lift := clampf(float(pose.leg_lift), -3, 3) * side
		arms.append(PackedVector2Array([Vector2(5 * side, 1), Vector2((10 + sweep) * side, 8), Vector2((15 + sweep) * side, 5)]))
		legs.append(PackedVector2Array([Vector2(4 * side, 15), Vector2(7 * side, 23 - lift), Vector2(11 * side, 25 - lift)]))
	var dress := Surface.rounded_contour(PackedVector2Array([Vector2(-6,-3), Vector2(6,-3), Vector2(7,5), Vector2(10,17), Vector2(4,20), Vector2(0,17), Vector2(-4,20), Vector2(-10,17), Vector2(-7,5)]))
	var pitch := clampf(float(pose.body_pitch), -0.06, 0.06)
	var tunic_panels: Array[PackedVector2Array] = []
	for side: float in [-1, 1]:
		var petal := Surface.rounded_contour(PackedVector2Array([Vector2(0,-2),Vector2(5*side,3),Vector2(7*side,16),Vector2(2*side,18),Vector2(0,8)]))
		tunic_panels.append(_placed(petal, Vector2.ZERO, pitch))
	var crown_tilt := clampf(float(pose.crown_tilt), -0.08, 0.08)
	var crown := PackedVector2Array([Vector2(-6,-18), Vector2(-7,-24), Vector2(-2,-21), Vector2(0,-26), Vector2(3,-21), Vector2(7,-24), Vector2(6,-18)])
	return {"valid": true, "wings": wings, "arms": arms, "legs": legs, "dress": _placed(dress, Vector2.ZERO, pitch), "tunic_panels": tunic_panels, "pitch": pitch, "crown": _placed(crown, Vector2.ZERO, crown_tilt), "eye_focus": clampf(float(pose.eye_focus), -0.8, 0.8), "glow": 0.87 if bool(pose.get("reduced_motion", false)) else clampf(float(pose.glow), 0.74, 1.0)}

static func _rim(canvas: Node2D, at: Vector2, points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := _placed(points, at)
	closed.append(closed[0])
	canvas.draw_polyline(closed, color, width, true)

static func _draw_wings(canvas: Node2D, at: Vector2, wings: Array, fairy: bool, translucency: float) -> void:
	for wing: Dictionary in wings:
		var color := Color("bfdfee") if bool(wing.rear) else Color("ddedee")
		if fairy:
			color = Color("b9c4ee") if bool(wing.rear) else Color("e0d9f7")
		color.a = clampf(translucency * (0.55 if bool(wing.rear) else 0.72), 0.0, 0.7)
		Surface.draw_volume(canvas, _placed(wing.points, at), color, 0.5)
		_rim(canvas, at, wing.points, Color(0.92, 0.99, 1.0, 0.66), 0.8)
		for line: PackedVector2Array in wing.veins:
			canvas.draw_polyline(_placed(line, at), Color(0.87, 0.98, 1.0, 0.37), 0.65, true)

static func draw_bug(canvas: Node2D, at: Vector2, pose: Dictionary, surface: Dictionary, flutter: float) -> void:
	var shape := bug_geometry(pose, flutter)
	if not shape.valid:
		return
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(7,20), Vector2(20,7)), Color(0.005,0.02,0.025,0.38), 0, true)
	Surface.draw_volume(canvas, Surface.ellipse(at, Vector2.ONE * 27), Color(0.98,0.82,0.28,0.09), 0, true)
	for line: PackedVector2Array in shape.legs:
		Surface.draw_ribbon(canvas, _placed(line, at), PackedFloat32Array([1.1,0.8,0.2]), Color("77562c"))
	_draw_wings(canvas, at, shape.wings, false, float(surface.get("wing_translucency", 0.66)))
	var abdomen: Vector2 = at + Vector2(shape.abdomen)
	Surface.draw_volume(canvas, Surface.ellipse(abdomen, Vector2(8,12), shape.pitch), Color("d9a53e"), 0.65)
	for band in 4:
		var y := -6.0 + band * 5.0
		var half_width := sqrt(maxf(0, 1.0 - pow(y / 12.0, 2))) * 7.3
		var curve := PackedVector2Array([Vector2(-half_width,y-0.7), Vector2(-half_width*0.4,y+0.7), Vector2(half_width*0.4,y+0.7), Vector2(half_width,y-0.7)])
		canvas.draw_polyline(_placed(curve, abdomen, shape.pitch), Color(0.31,0.23,0.12,0.70), 1.1, true)
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(0,-1), Vector2(8.8,8)), Color("967638"), 0.50)
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(-2,-3), Vector2(4.5,5.8), -0.3), Color(0.95,0.81,0.38,0.25), 0, true)
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(0,-11), Vector2(7,7)), Color("69532d"), 0.3)
	for side: float in [-1, 1]:
		var eye := at + Vector2(3.6 * side,-12)
		Surface.draw_volume(canvas, Surface.ellipse(eye, Vector2(2.9,3.0), side * 0.15), Color("5b927b"), 0.8)
		canvas.draw_circle(eye + Vector2(float(shape.eye_focus)*0.3,-0.1),1.0,Color("193e33"))
		canvas.draw_circle(eye + Vector2(-0.7,-1.0),0.75,Color("f8ffdc"))
		var antenna := PackedVector2Array([Vector2(3*side,-16),Vector2(6*side,-21),Vector2(10*side,-23)])
		Surface.draw_ribbon(canvas, _placed(antenna, at), PackedFloat32Array([0.8,0.6,0.25]), Color("a98743"))
		canvas.draw_circle(at + antenna[-1],1.3,Color("dfbf6f"))

static func draw_fairy(canvas: Node2D, at: Vector2, pose: Dictionary, surface: Dictionary) -> void:
	var shape := fairy_geometry(pose)
	if not shape.valid:
		return
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(5,26), Vector2(25,8)), Color(0.01,0.02,0.05,0.30), 0, true)
	Surface.draw_volume(canvas, Surface.ellipse(at, Vector2.ONE * 44), Color(0.86,0.80,1.0,0.18*float(shape.glow)), 0, true)
	Surface.draw_volume(canvas, Surface.ellipse(at, Vector2.ONE * 31), Color(1.0,0.91,0.67,0.13*float(shape.glow)), 0, true)
	_draw_wings(canvas, at, shape.wings, true, float(surface.get("wing_translucency", 0.74)))
	for line: PackedVector2Array in shape.legs:
		Surface.draw_ribbon(canvas, _placed(line, at), PackedFloat32Array([1.7,1.25,0.45]), Color("f4d79b"))
		Surface.draw_volume(canvas, Surface.ellipse(at + line[-1], Vector2(3.2,1.6), -0.12), Color("f8eab2"), 0.2)
	for line: PackedVector2Array in shape.arms:
		Surface.draw_ribbon(canvas, _placed(line, at), PackedFloat32Array([1.7,1.25,0.65]), Color("f4d79b"))
		canvas.draw_circle(at + line[-1],1.6,Color("fff0cd"))
	Surface.draw_volume(canvas, _placed(shape.dress, at), Color("e8be58"), 0.35)
	# Petal-shaped tunic panels use the same pitch as the outer silhouette.
	for petal: PackedVector2Array in shape.tunic_panels:
		Surface.draw_volume(canvas, _placed(petal, at), Color("f9df8b"), 0.3)
	canvas.draw_arc(at + Vector2(0,1),5.5,0.05,PI-0.05,10,Color("bd934b"),0.8,true)
	canvas.draw_circle(at + Vector2(0,0),1.3,Color("e6faf0"))
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(0,-6), Vector2(2.8,3.5)), Color("f4d79b"), 0.2)
	Surface.draw_volume(canvas, Surface.ellipse(at + Vector2(0,-12), Vector2(7,7)), Color("ffe5b7"), 0.3)
	for side: float in [-1, 1]:
		var eye := at + Vector2(2.7*side,-12.7)
		canvas.draw_circle(eye,1.3,Color("574e41"))
		canvas.draw_circle(eye + Vector2(-0.3+float(shape.eye_focus)*0.2,-0.4),0.45,Color("fffef5"))
		canvas.draw_circle(at + Vector2(4.0*side,-10),1.2,Color(0.98,0.63,0.46,0.33))
	canvas.draw_arc(at + Vector2(0,-10.5),2.5,0.3,PI-0.3,8,Color("987345"),0.7,true)
	# A solid tiny crown uses triangulation; unlike a convex surface its points
	# form a concave zigzag, so it must not use the mean-centered volume mesh.
	canvas.draw_colored_polygon(_placed(shape.crown, at), Color("f4ce68"))
	_rim(canvas, at, shape.crown, Color("fff0b1"),0.65)
	canvas.draw_circle(at + Vector2(0,-20.3),1.2,Color("c5edf1"))
	for side: float in [-1, 1]:
		var center := at + Vector2(33*side, -20 if side < 0 else 18)
		var sparkle := PackedVector2Array([center+Vector2(0,-2),center+Vector2(0.7,0),center+Vector2(0,2),center+Vector2(-0.7,0)])
		canvas.draw_colored_polygon(sparkle,Color(1.0,0.94,0.72,0.66*float(shape.glow)))
