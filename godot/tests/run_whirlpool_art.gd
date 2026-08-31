extends SceneTree

const Art = preload("res://scripts/whirlpool_art.gd")
const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")
const Intensity = preload("res://scripts/level_intensity.gd")
const SAVE_PREFIX := "user://whirlpool_art_test"
var passed := 0
var failed := 0

class CollisionProbe extends "res://scripts/main.gd":
	var recorded_hit := ""
	func _apply_danger_hit(message: String) -> void:
		# Observe the real collision predicate without damage/save side effects.
		recorded_hit = message

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for bad: float in [NAN, INF, -INF, -1]:
		check(not Art.geometry(0, bad).valid, "invalid time fails closed")
	check(not Art.geometry(-1, 0).valid and not Art.geometry(3, 0).valid, "only the three existing hazards have art")
	var mesh := Art.funnel_mesh()
	check(mesh.points.size() == 201 and mesh.colors.size() == 201 and mesh.indices.size() == 1080, "funnel draw has a fixed mesh budget")
	check(var_to_bytes(mesh) == var_to_bytes(Art.funnel_mesh()), "funnel mesh is deterministic")
	var area := 0.0
	var positive := true
	for offset in range(0, mesh.indices.size(), 3):
		var a: Vector2 = mesh.points[mesh.indices[offset]]
		var b: Vector2 = mesh.points[mesh.indices[offset + 1]]
		var c: Vector2 = mesh.points[mesh.indices[offset + 2]]
		var signed_area := (b - a).cross(c - a) * 0.5
		positive = positive and signed_area > 0
		area += signed_area
	var boundary_area := 0.0
	for step in Art.RING_SEGMENTS:
		var a: Vector2 = mesh.points[161 + step]
		var b: Vector2 = mesh.points[161 + (step + 1) % Art.RING_SEGMENTS]
		boundary_area += a.cross(b) * 0.5
	check(positive and absf(area - boundary_area) < 0.02, "funnel strips have consistent winding and no overlapping fill")
	var finite := true
	var edge_fades := true
	for index in mesh.points.size():
		var point: Vector2 = mesh.points[index]
		var color: Color = mesh.colors[index]
		finite = finite and point.is_finite() and point.length() <= Art.OUTER_RADIUS + 0.001 and color.a >= 0 and color.a <= 1
		if index >= 161:
			edge_fades = edge_fades and color.a == 0
	check(finite and edge_fades, "bounded funnel fades into water without a solid outer disc")
	check(Art.OUTER_RADIUS < Art.LABEL_Y - 12, "water stays clear of the unchanged label baseline")
	for tick in 91:
		for index in 3:
			for calm: bool in [false, true]:
				var time := tick / 15.0
				var shape := Art.geometry(index, time, calm)
				check(shape.valid and shape.arms.size() == Art.ARM_COUNT and shape.foam.size() == Art.FOAM_COUNT, "three currents and nine foam streaks stay bounded")
				check(var_to_bytes(shape) == var_to_bytes(Art.geometry(index, time, calm)), "current geometry is deterministic")
				for arm: Dictionary in shape.arms:
					var fits: bool = arm.points.size() == Art.ARM_POINTS and arm.widths.size() == Art.ARM_POINTS
					var previous_radius := 54.0
					for step in arm.points.size():
						var point: Vector2 = arm.points[step]
						var width: float = arm.widths[step]
						fits = fits and point.is_finite() and point.length() < previous_radius and point.length() + width < Art.OUTER_RADIUS and width > 0 and width < 2.3
						previous_radius = point.length()
					check(fits, "tapered current flows inward without crossing the footprint")
				var foam_fits := true
				for line: PackedVector2Array in shape.foam:
					foam_fits = foam_fits and line.size() == Art.FOAM_POINTS
					for point in line:
						foam_fits = foam_fits and point.is_finite() and point.length() + 0.75 < Art.OUTER_RADIUS
				check(foam_fits, "foam strokes remain within the existing water silhouette")
				if calm:
					check(var_to_bytes(shape) == var_to_bytes(Art.geometry(index, 0, true)), "reduced motion freezes every decorative channel")
	# Foam has its own wrapped phase: crossing the current's period cannot jump it.
	for index in 3:
		var period := TAU / (1.1 + index * 0.2)
		var before := Art.geometry(index, period - 0.0001)
		var after := Art.geometry(index, period + 0.0001)
		check(Vector2(before.foam[0][0]).distance_to(after.foam[0][0]) < 0.03, "foam is continuous across current phase wrap")
		check(Vector2(before.arms[0].points[0]).distance_to(after.arms[0].points[0]) < 0.03, "current is continuous across phase wrap")
	var probe := CollisionProbe.new()
	probe.predator = Vector2(-1000,-1000)
	probe.secondary_predators.clear()
	for level in range(1, 101):
		probe.level_number = level
		probe.level_profile = Intensity.profile(level)
		var count := int(probe.level_profile.whirlpool_count)
		for index in 3:
			var center: Vector2 = probe._whirlpool_position(index)
			check(center == Layout.route_point(Main.WHIRLPOOLS[index], level), "campaign keeps original mirrored hazard centers")
			var fits := true
			for point: Vector2 in mesh.points:
				fits = fits and Layout.PLAYFIELD_RECT.has_point(center + point)
			check(fits, "all campaign whirlpool meshes stay inside the water playfield")
			for radius: float in [49.9, 50.0, 50.1]:
				probe.fred = center + Vector2(radius, 0)
				probe.recorded_hit = ""
				var hit: bool = probe._check_danger_collision()
				check(hit == (index < count and radius < 50.0), "actual collision retains strict 50-pixel radius and chapter count")
				check(not hit or probe.recorded_hit.begins_with("[WHIRLPOOL]"), "hazard is still a whirlpool event, never a predator or Golden Egg")
	probe.free()
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.customization = FredFrogCustomization.new("")
	game.leaderboard = FredLocalLeaderboard.new(SAVE_PREFIX + "_board.json")
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.simulation_time = 1.25
	var save_before := JSON.stringify(game.session.to_save())
	var positions_before: Array = [game.fred, game.predator, game.secondary_predators.duplicate(), game.level_number]
	var art_before: PackedByteArray = var_to_bytes(game._whirlpool_visual(0))
	for iteration in 120:
		game._whirlpool_visual(iteration % 3)
	check(save_before == JSON.stringify(game.session.to_save()) and positions_before == [game.fred,game.predator,game.secondary_predators,game.level_number], "visual snapshots never mutate game state or saves")
	game._set_gameplay_paused(true)
	game._process(2.0)
	check(art_before == var_to_bytes(game._whirlpool_visual(0)), "Pause freezes swirl and foam despite the menu clock advancing")
	game.notification(NOTIFICATION_APPLICATION_PAUSED)
	game.notification(NOTIFICATION_APPLICATION_RESUMED)
	game._process(1.0)
	check(game.session.paused and art_before == var_to_bytes(game._whirlpool_visual(0)), "background-return overlay keeps hazard art frozen")
	game._set_gameplay_paused(false)
	game._process(0.1)
	check(art_before != var_to_bytes(game._whirlpool_visual(0)), "Resume advances existing swirl clock again")
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	for suffix: String in [".json", ".backup.json", ".tmp.json", "_board.json"]:
		var path := ProjectSettings.globalize_path(SAVE_PREFIX + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var started := Time.get_ticks_msec()
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for iteration in 10000:
		Art.geometry(iteration % 3, iteration / 60.0)
	var elapsed := Time.get_ticks_msec() - started
	var growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
	check(elapsed < 5000 and growth < 1024 * 1024, "10,000 geometry snapshots have bounded cost and no growing history")
	print("MEASURE whirlpool_snapshots=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed,growth])
	print("RESULT whirlpool_art_passed=%d whirlpool_art_failed=%d" % [passed,failed])
	quit(1 if failed else 0)
