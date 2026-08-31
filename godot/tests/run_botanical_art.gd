extends SceneTree

const Art = preload("res://scripts/botanical_art.gd")
const Surface = preload("res://scripts/character_surface.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")
const Intensity = preload("res://scripts/level_intensity.gd")
const Visual = preload("res://scripts/fred_visual_state.gd")
const Main = preload("res://scripts/main.gd")
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func area(points: PackedVector2Array) -> float:
	var total := 0.0
	for index in points.size():
		total += points[index].cross(points[(index + 1) % points.size()])
	return absf(total) * 0.5

func mesh_valid(contour: PackedVector2Array) -> bool:
	var before := contour.duplicate()
	var mesh := Surface.volume_mesh(contour, Color("4e9852"), 0.45)
	if contour != before or mesh.points.size() != contour.size() * 2 + 1 or mesh.indices.size() != contour.size() * 9:
		return false
	var total := 0.0
	for index in range(0, mesh.indices.size(), 3):
		var a: Vector2 = mesh.points[mesh.indices[index]]
		var b: Vector2 = mesh.points[mesh.indices[index + 1]]
		var c: Vector2 = mesh.points[mesh.indices[index + 2]]
		if not a.is_finite() or not b.is_finite() or not c.is_finite():
			return false
		total += absf((b - a).cross(c - a)) * 0.5
	# Equal total triangle/polygon area detects a fan crossing the leaf notch.
	return absf(total - area(contour)) < 0.1

func _init() -> void:
	check(not Layout.STATUS_TOUCH_RECT.intersects(Layout.PLAYFIELD_RECT), "status feedback cannot obscure gameplay labels")
	check(Layout.rect_inside_canvas(Layout.STATUS_TOUCH_RECT, 30), "status feedback remains within safe canvas margins")
	check(not Layout.STATUS_TOUCH_RECT.grow(8).intersects(Layout.TOUCH_ACTION_WHEEL_RECT), "footer feedback stays clear of left action buttons")
	check(not Layout.STATUS_TOUCH_RECT.grow(8).intersects(Layout.TOUCH_CONTROL_PAD_RECT), "footer feedback stays clear of right movement pad")
	for variant in 7:
		var leaf := Art.leaf_contour(variant)
		check(leaf.size() == Art.LEAF_SEGMENTS + 1, "leaf detail is bounded")
		check(leaf == Art.leaf_contour(variant), "leaf geometry is deterministic")
		check(mesh_valid(leaf), "notched leaf lighting has no overlapping triangles")
		check(not Geometry2D.is_point_in_polygon(Vector2(35, -1), leaf), "notch reveals real background water")
		check(Geometry2D.is_point_in_polygon(Vector2.ZERO, leaf), "leaf keeps its central landing presentation")
		for point in leaf:
			check((point / Art.LEAF_RADII).length() <= 1.001, "leaf stays inside previous pad footprint")
		for vein: PackedVector2Array in Art.leaf_veins():
			var inside := true
			for point in vein:
				inside = inside and Geometry2D.is_point_in_polygon(point, leaf)
			check(inside, "leaf veins do not cross the notch or silhouette")
	var game: Node2D = Main.new()
	for level in range(1, 101):
		game.level_number = level
		game.level_profile = Intensity.profile(level)
		var perch_label := Rect2(game._level_safe_position() + Vector2(-60, -8), Vector2(120, 20))
		check(not perch_label.intersects(Layout.STATUS_TOUCH_RECT), "perch label never shares the feedback box across all levels")
		var radius := float(Intensity.profile(level).safe_radius)
		check(mesh_valid(Art.perch_contour(radius)), "all campaign perch surfaces triangulate safely")
		check(Art.perch_contour(radius) == Art.perch_contour(radius), "perch is deterministic")
		var clear := true
		for blade: PackedVector2Array in Art.perch_grass(radius):
			for point in blade:
				clear = clear and not Art.PERCH_TEXT_CLEAR.grow(2).has_point(point)
		check(clear, "perch grass preserves central label clearance")
		for index in Main.PADS.size():
			var rotation := sin(float(level * 7 + index * 19)) * 0.28
			for time: float in [0.0, 31.2, 99.5]:
				game.simulation_time = time
				var at: Vector2 = game._pad_position(index)
				at.y += Visual.wave(time, index * 0.65, 3, false)
				var fits := true
				for point in Art.leaf_contour(index):
					var placed := at + point.rotated(rotation)
					fits = fits and Layout.PLAYFIELD_RECT.has_point(placed)
				check(fits, "all campaign leaves with live offset, drift and bob stay in the playfield")
	game.free()
	for tick in 61:
		var visual := Visual.snapshot(tick / 12.0, false)
		var radius := 45.0 * float(visual.exit_pulse)
		for petal in 16:
			var contour := Art.petal_contour(radius * (1 if petal < 8 else 0.72), petal * TAU / 8 + (0.18 if petal < 8 else 0.57))
			check(mesh_valid(contour), "all pulsing petal meshes have finite non-overlapping fill")
			var fits := true
			for point in contour:
				fits = fits and point.length() < radius and point.y < radius + 10
			check(fits, "petals retain original flower bounds and exit-label clearance")
		for x in range(55, 1240, 95):
			var height := 46.0 + x % 3 * 8
			var blades := Art.reed_blades(height, float(visual.reed_sway))
			var fits := blades.size() == 3
			for blade in blades:
				for point in blade:
					fits = fits and point.is_finite() and absf(point.x) <= 18 and point.y <= 0 and point.y >= -height
			check(fits, "reeds have finite bounded geometry within the existing border")
		var calm := Visual.snapshot(tick / 12.0, true)
		check(var_to_bytes(Art.reed_blades(62, calm.reed_sway)) == var_to_bytes(Art.reed_blades(62, 0)), "reduced motion freezes reed sway")
		check(calm.exit_pulse == 1.0, "reduced motion retains neutral flower radius")
	for bad: float in [NAN, INF, -1, 101]:
		check(Art.perch_contour(bad).is_empty(), "invalid perch input fails closed")
		check(Art.petal_contour(bad, 0).is_empty(), "invalid petal input fails closed")
		check(Art.reed_blades(bad, 0).is_empty(), "invalid reed input fails closed")
	check(Art.petal_contour(45, NAN).is_empty(), "nonfinite petal angle fails closed")
	check(Art.reed_blades(62, NAN).is_empty(), "nonfinite sway fails closed")
	var started := Time.get_ticks_msec()
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for iteration in 10000:
		Art.leaf_contour(iteration)
		Art.petal_contour(45, iteration / 60.0)
		Art.perch_contour(70)
	var elapsed := Time.get_ticks_msec() - started
	var growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
	check(elapsed < 5000, "botanical generation has bounded CPU cost")
	check(growth < 1024 * 1024, "botanical geometry retains no growing history")
	print("MEASURE botanical_sets=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed, growth])
	print("RESULT botanical_art_passed=%d botanical_art_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
