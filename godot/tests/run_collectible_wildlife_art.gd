extends SceneTree

const Art = preload("res://scripts/collectible_wildlife_art.gd")
const Surface = preload("res://scripts/character_surface.gd")
const Rig = preload("res://scripts/wildlife_animation_rig.gd")
const Visual = preload("res://scripts/fred_visual_state.gd")
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func polygon_area(points: PackedVector2Array) -> float:
	var total := 0.0
	for index in points.size():
		total += points[index].cross(points[(index + 1) % points.size()])
	return absf(total) * 0.5

func mesh_safe(points: PackedVector2Array) -> bool:
	var original := points.duplicate()
	var mesh := Surface.volume_mesh(points, Color(0.7,0.8,1.0,0.5), 0.5)
	if points != original or mesh.points.size() != points.size() * 2 + 1 or mesh.indices.size() != points.size() * 9:
		return false
	var triangle_area := 0.0
	for index in range(0, mesh.indices.size(), 3):
		var a: Vector2 = mesh.points[mesh.indices[index]]
		var b: Vector2 = mesh.points[mesh.indices[index+1]]
		var c: Vector2 = mesh.points[mesh.indices[index+2]]
		if not a.is_finite() or not b.is_finite() or not c.is_finite():
			return false
		triangle_area += absf((b-a).cross(c-a)) * 0.5
	return absf(triangle_area - polygon_area(points)) < 0.01

func check_wings(shape: Dictionary, kind: String) -> void:
	check(shape.valid and shape.wings.size() == 4, kind + " keeps two pairs of wings")
	for wing: Dictionary in shape.wings:
		check(wing.points.size() <= Art.MAX_WING_POINTS and mesh_safe(wing.points), kind + " wing has bounded, non-overlapping membrane triangles")
		var in_bounds := true
		for point: Vector2 in wing.points:
			in_bounds = in_bounds and point.is_finite() and absf(point.x) < (34 if kind == "BUG" else 40) and point.y > -36 and point.y < 26
		check(in_bounds, kind + " wings stay within their existing gameplay silhouette envelope")
		var veins_inside := true
		for line: PackedVector2Array in wing.veins:
			for point in line:
				veins_inside = veins_inside and Geometry2D.is_point_in_polygon(point, wing.points)
		check(veins_inside, kind + " membrane veins remain inside rounded wings")
		check(absf(Vector2(wing.hinge).x) == 5 and Vector2(wing.hinge).y in [2.0,-4.0], kind + " flap keeps wing roots attached to torso")

func _init() -> void:
	check(ThemeDB.fallback_font.get_string_size(Art.FAIRY_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= 80, "compact fairy caption fits an 80-pixel visual span")
	check(Art.FAIRY_LABEL.contains("+1 LIFE"), "compact fairy caption retains exact reward amount")
	check(not Art.bug_geometry({}).valid, "missing bug pose fails closed")
	check(not Art.fairy_geometry({}).valid, "missing fairy pose fails closed")
	var bug_pose := Rig.pose("BUG", 0, 0.2)
	var fairy_pose := Rig.pose("FAIRY", 0, 0.2)
	check(not Art.bug_geometry(fairy_pose).valid and not Art.fairy_geometry(bug_pose).valid, "wrong actor pose cannot become collectible art")
	for field in Art.POSE_FIELDS:
		for kind: String in ["BUG", "FAIRY"]:
			var bad := Rig.pose(kind, 0, 0)
			bad[field] = NAN
			check(not (Art.bug_geometry(bad) if kind == "BUG" else Art.fairy_geometry(bad)).valid, "nonfinite " + kind + " " + field + " fails closed")
			bad.erase(field)
			check(not (Art.bug_geometry(bad) if kind == "BUG" else Art.fairy_geometry(bad)).valid, "missing " + kind + " " + field + " fails closed")
	check(not Art.bug_geometry(bug_pose, INF).valid, "nonfinite decorative flutter fails closed")
	for tick in 121:
		var time := tick / 60.0
		for calm: bool in [false, true]:
			var visual := Visual.snapshot(time, calm)
			for index in 3:
				var pose := Rig.pose("BUG", index, time, calm)
				var before := var_to_bytes(pose)
				var shape := Art.bug_geometry(pose, visual.wildlife_flutter)
				check_wings(shape, "BUG")
				check(before == var_to_bytes(pose), "bug art never mutates animation input")
				check(var_to_bytes(shape) == var_to_bytes(Art.bug_geometry(pose, visual.wildlife_flutter)), "bug geometry is byte-deterministic")
				var legs_clear: bool = shape.legs.size() == 6
				for leg: PackedVector2Array in shape.legs:
					for point in leg:
						legs_clear = legs_clear and point.is_finite() and point.y < Art.BUG_LABEL_Y - 13 and absf(point.x) <= 20
				check(legs_clear, "six bug legs leave the number label clear")
				check(absf(shape.pitch) <= 0.081 and absf(float(shape.abdomen.y)-8.0) <= 2.401, "bug uses bounded authored body flex")
			var pose := Rig.pose("FAIRY", 0, time, calm)
			var before := var_to_bytes(pose)
			var shape := Art.fairy_geometry(pose)
			check_wings(shape, "FAIRY")
			check(before == var_to_bytes(pose), "fairy art never mutates animation input")
			check(var_to_bytes(shape) == var_to_bytes(Art.fairy_geometry(pose)), "fairy geometry is byte-deterministic")
			check(mesh_safe(shape.dress), "fairy dress has no overlapping lit triangles")
			for panel: PackedVector2Array in shape.tunic_panels:
				check(mesh_safe(panel), "fairy tunic panel has no overlapping lit triangles")
				var inside := true
				for point in panel:
					inside = inside and Geometry2D.is_point_in_polygon(point, shape.dress)
				check(inside, "tunic panels fit their dress silhouette")
			check(not Geometry2D.triangulate_polygon(shape.crown).is_empty(), "concave crown can be triangulated by polygon renderer")
			var limbs_clear: bool = shape.arms.size() == 2 and shape.legs.size() == 2
			for field: String in ["arms", "legs"]:
				for limb: PackedVector2Array in shape[field]:
					for point in limb:
						limbs_clear = limbs_clear and point.is_finite() and point.y + 2 < Art.FAIRY_LABEL_Y - 13 and absf(point.x) < 21
			check(limbs_clear, "fairy limbs leave reward text clear")
			check(shape.glow >= 0.74 and shape.glow <= 1.0, "fairy light stays subtle and bounded")
			if calm:
				check(shape.glow == 0.87, "reduced motion freezes decorative reward glow")
	var normal_wing: PackedVector2Array = Art.bug_geometry(Rig.pose("BUG", 0, 0.2)).wings[2].points
	check(normal_wing != Art.bug_geometry(Rig.pose("BUG", 0, 0.3)).wings[2].points, "existing wing channel visibly changes wing pose")
	var started := Time.get_ticks_msec()
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for iteration in 10000:
		Art.bug_geometry(bug_pose, iteration % 4)
		Art.fairy_geometry(fairy_pose)
	var elapsed := Time.get_ticks_msec() - started
	var growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
	check(elapsed < 5000, "collectible geometry has bounded CPU work")
	check(growth < 1024 * 1024, "collectible geometry retains no growing history")
	print("MEASURE collectible_pairs=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed, growth])
	print("RESULT collectible_wildlife_art_passed=%d collectible_wildlife_art_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
