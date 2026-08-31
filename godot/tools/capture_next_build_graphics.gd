extends SceneTree

# Review-only rendering of the real rigs; never used by the shipped scenes.
class CharacterSheet extends "res://scripts/main.gd":
	var review_page := "builds"
	var motion_time := 1.2

	func _draw_whirlpool_sheet() -> void:
		for index in 3:
			var center := Vector2(220 + index * 420, 325)
			draw_set_transform(center, 0, Vector2.ONE * 2.45)
			WhirlpoolArt.draw_water(self, Vector2.ZERO, WhirlpoolArt.geometry(index, 1.2, index == 2))
			_text(Vector2(0, WhirlpoolArt.LABEL_Y), "WHIRLPOOL", 11, Color("cdefff"), HORIZONTAL_ALIGNMENT_CENTER, 110)
			draw_set_transform(Vector2.ZERO)
			_text(center + Vector2(0, 229), ["INWARD WATER / SOFT FUNNEL", "CURVED FOAM / CURRENT SAMPLE", "REDUCED MOTION / STEADY HAZARD"][index], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 405)
		_text(Vector2(640,625), "Original hazard positions, chapter counts and danger radius retained.", 18, Color("afd3d5"), HORIZONTAL_ALIGNMENT_CENTER, 1176)

	func _draw_collectible_sheet() -> void:
		var previous_time := simulation_time
		var previous_calm := reduced_motion
		for column in 3:
			simulation_time = [0.2, 0.3, 1.2][column]
			reduced_motion = column == 2
			var visual := FredVisualState.snapshot(simulation_time, reduced_motion)
			var center := Vector2(220 + column * 420, 238)
			draw_set_transform(center, 0, Vector2.ONE * 3.0)
			_draw_bug(Vector2.ZERO, column, visual.wildlife_flutter)
			draw_set_transform(Vector2.ZERO)
			_text(center + Vector2(0, 151), ["WING / FLIGHT SAMPLE A", "WING / FLIGHT SAMPLE B", "REDUCED-MOTION WINGS"][column], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 395)
			center.y = 530
			draw_set_transform(center, 0, Vector2.ONE * 2.5)
			_draw_fairy(Vector2.ZERO)
			draw_set_transform(Vector2.ZERO)
			_text(center + Vector2(0, 165), ["MOONLIT FAIRY / SAMPLE A", "PETAL TUNIC / SAMPLE B", "REDUCED MOTION / STEADY GLOW"][column], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 395)
		simulation_time = previous_time
		reduced_motion = previous_calm

	func _draw_botanical_sheet() -> void:
		for index in 3:
			var center := Vector2(220 + index * 420, 242)
			draw_set_transform(center, 0, Vector2.ONE * 2.5)
			BotanicalArt.draw_lily(self, Vector2.ZERO, index, -0.10 + index * 0.10)
			draw_set_transform(Vector2.ZERO)
			_text(center + Vector2(0, 117), ["VEINED LILY / OPEN WATER NOTCH", "LAYERED PAD BLOSSOM", "SOFT LEAF EDGE / DEWDROPS"][index], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 395)
		for index in 3:
			var center := Vector2(220 + index * 420, 516)
			draw_set_transform(center, 0, Vector2.ONE * 1.85)
			if index == 0:
				_draw_moonpetal_exit(Vector2.ZERO, 45)
			elif index == 1:
				_draw_safe_island(Vector2.ZERO, 64)
			else:
				for reed in 5:
					BotanicalArt.draw_reed(self, Vector2((reed - 2) * 21, 42), 46.0 + reed % 3 * 8, 2.0, reed % 3 == 0)
			draw_set_transform(Vector2.ZERO)
			# The real exit's label sits below its flower; keep the review caption lower.
			_text(center + Vector2(0, 177), ["MOONPETAL / LIGHT AND PETAL FOLDS", "MOSSY PERCH / CLEAR CENTRAL LABEL", "CURVED REEDS / ORIGINAL BORDER"][index], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 400)

	func _draw_motion_sheet() -> void:
		_sync_fred_style()
		var stages: Array[Dictionary] = [
			{"label": "SWIM / TRAILING WAKE", "state": AnimationCoordinator.State.SURFACE_SWIM, "depth": 0.0, "height": 0.0},
			{"label": "LEAP / GROUNDED SHADOW", "state": AnimationCoordinator.State.LEAP_APEX, "depth": 0.0, "height": 52.0},
			{"label": "LAND / SOFT RIPPLES", "state": AnimationCoordinator.State.LEAP_LANDING, "depth": 0.0, "height": 0.0},
			{"label": "DIVE / SURFACE CONTACT FADES", "state": AnimationCoordinator.State.DIVING, "depth": 0.35, "height": 0.0},
			{"label": "DEEP SWIM / BUBBLE TRAIL", "state": AnimationCoordinator.State.UNDERWATER_SWIM, "depth": 1.0, "height": 0.0},
			{"label": "SURFACE / CONTACT RETURNS", "state": AnimationCoordinator.State.SURFACING, "depth": 0.35, "height": 0.0},
		]
		for index in stages.size():
			var stage: Dictionary = stages[index]
			var anchor := Vector2(220 + (index % 3) * 420, 254 + (index / 3) * 280)
			animation.state = int(stage.state)
			animation.state_ticks = int(motion_time * 60)
			animation._pose = animation._build_pose()
			fred_rig.apply_pose(animation.pose(), float(stage.depth))
			draw_set_transform(anchor, 0, Vector2.ONE * 1.45)
			var contact := WaterContactArt.frog({"depth": stage.depth, "height": stage.height, "airborne": float(stage.height) > 0, "moving": true, "landing": 0.45 if index == 2 else -1.0}, motion_time)
			WaterContactArt.draw_contact(self, Vector2.ZERO, contact)
			fred_rig.render_to(self, Vector2(0, -float(stage.height)), motion_time, false, false)
			draw_set_transform(Vector2.ZERO)
			_text(anchor + Vector2(0, 140), str(stage.label), 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 400)

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("081e29"))
		var title := "WATER HAZARD REVIEW" if review_page == "whirlpools" else ("BOTANICAL REVIEW" if review_page == "botanical" else ("COLLECTIBLE REVIEW" if review_page == "collectibles" else "CHARACTER REVIEW"))
		_text(Vector2(52, 55), "MOONPETAL MARSH / " + title, 26, Color("ffe184"), HORIZONTAL_ALIGNMENT_LEFT, 1176)
		var description := "Actual game rigs | traversal poses and water contact | local next-build review" if review_page == "water-motion" else "Actual game rigs | same pose, lighting and scale | local next-build review"
		if review_page == "botanical":
			description = "Actual game drawing | original placement and gameplay bounds | local next-build review"
		elif review_page == "collectibles":
			description = "Actual game drawing | existing flight poses and reward behavior | local next-build review"
		elif review_page == "whirlpools":
			description = "Actual game drawing | same hazard footprint | normal and reduced-motion samples"
		_text(Vector2(52, 86), description, 17, Color("afd3d5"), HORIZONTAL_ALIGNMENT_LEFT, 1176)
		if review_page == "whirlpools":
			_draw_whirlpool_sheet()
			return
		if review_page == "collectibles":
			_draw_collectible_sheet()
			return
		if review_page == "botanical":
			_draw_botanical_sheet()
			return
		if review_page == "water-motion":
			_draw_motion_sheet()
			return
		if review_page == "predators":
			var species: Array[String] = ["BASS", "PIKE", "MUSKIE", "SNAKE", "HERON"]
			for index in species.size():
				var center := Vector2(230 + (index % 3) * 405, 256 + (index / 3) * 295)
				draw_set_transform(center, 0.0, Vector2.ONE * 1.8)
				_draw_predator(Vector2.ZERO, species[index])
				draw_set_transform(Vector2.ZERO)
				# Keep the review caption below the heron's long legs and feet.
				_text(center + Vector2(0, 156), species[index], 18, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 320)
			return
		var category := "size" if review_page == "builds" else "attire"
		var entries: Array = FredFrogCustomization.CATALOG[category]
		var columns := 4 if review_page == "builds" else 3
		var row_height := 276 if review_page == "builds" else 190
		for index in entries.size():
			customization.selected[category] = str(entries[index].id)
			_sync_fred_style()
			fred_rig.apply_pose(animation.pose(), 0.0)
			var center := Vector2(160 + (index % columns) * 316, 200 + (index / columns) * row_height)
			if columns == 3:
				center.x = 210 + (index % columns) * 420
			draw_set_transform(center, 0.0, Vector2.ONE * (1.7 if columns == 4 else 1.3))
			fred_rig.render_to(self, Vector2.ZERO, 1.2, true)
			draw_set_transform(Vector2.ZERO)
			_text(center + Vector2(0, 111 if columns == 4 else 100), str(entries[index].label), 18, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 300)

class MeasuredGame extends "res://scripts/main.gd":
	var draw_times: Array[int] = []
	var predator_draw_us := 0
	var measured_predator_draws := 0
	var collectible_draw_us := 0
	var measured_collectible_draws := 0
	var whirlpool_draw_us := 0
	var measured_whirlpool_passes := 0
	func _draw_whirlpools() -> void:
		var started := Time.get_ticks_usec()
		super._draw_whirlpools()
		whirlpool_draw_us += Time.get_ticks_usec() - started
		measured_whirlpool_passes += 1
	func _draw_bug(at: Vector2, index: int, flutter: float) -> void:
		var started := Time.get_ticks_usec()
		super._draw_bug(at, index, flutter)
		collectible_draw_us += Time.get_ticks_usec() - started
		measured_collectible_draws += 1
	func _draw_fairy(at: Vector2) -> void:
		var started := Time.get_ticks_usec()
		super._draw_fairy(at)
		collectible_draw_us += Time.get_ticks_usec() - started
		measured_collectible_draws += 1
	func _draw_predator(at: Vector2, species: String, snapshot: Dictionary = {}) -> void:
		var started := Time.get_ticks_usec()
		super._draw_predator(at, species, snapshot)
		predator_draw_us += Time.get_ticks_usec() - started
		measured_predator_draws += 1
	func _draw() -> void:
		var started := Time.get_ticks_usec()
		super._draw()
		draw_times.append(Time.get_ticks_usec() - started)

var output_dir := ""
var capture_viewport: SubViewport
var capture_canvas: Node2D
var capture_failed := false

func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_dir = argument.trim_prefix("--output=")
	if output_dir.is_empty():
		push_error("Supply --output=<review directory>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	_capture.call_deferred()

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	capture_viewport = SubViewport.new()
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_canvas = Node2D.new()
	capture_viewport.add_child(capture_canvas)
	_resize(Vector2i(1280, 720))
	var sheet := CharacterSheet.new()
	_configure(sheet)
	capture_canvas.add_child(sheet)
	await process_frame
	sheet.set_process(false)
	sheet.simulation_time = 1.2
	for page: String in ["builds", "attire", "predators", "water-motion", "botanical", "collectibles", "whirlpools"]:
		sheet.review_page = page
		sheet.customization = FredFrogCustomization.new("")
		sheet.queue_redraw()
		await _save(page)
	sheet.queue_free()
	await process_frame
	var game := MeasuredGame.new()
	_configure(game)
	capture_canvas.add_child(game)
	await process_frame
	game._start()
	game.set_process(false)
	game.simulation_time = 1.2
	game.fred = Vector2(480, 420)
	game.queue_redraw()
	await _save("gameplay-1280x720")
	_resize(Vector2i(1792, 828))
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.queue_redraw()
	await _save("underwater-phone-1792x828")
	_resize(Vector2i(1366, 1024))
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.reduced_motion = true
	game.queue_redraw()
	await _save("gameplay-tablet-1366x1024")
	_resize(Vector2i(1792, 828))
	for level in 9:
		game._advance_level()
	game.simulation_time = 1.2
	game.fred = game._level_start_position()
	game.queue_redraw()
	await _save("level10-reverse-phone-1792x828")
	await _measure(game, "level10")
	for level in 7:
		game._advance_level()
	game.simulation_time = 1.2
	game.reduced_motion = false
	game.fred = game._level_start_position()
	game.queue_redraw()
	await _save("level17-phone-1792x828")
	for level in 54:
		game._advance_level()
	_resize(Vector2i(1366, 1024))
	game.simulation_time = 1.2
	game.fred = game._level_start_position()
	game.queue_redraw()
	await _save("level71-tablet-1366x1024")
	await _measure(game, "level71")
	_resize(Vector2i(1792, 828))
	game._set_gameplay_paused(true)
	game.queue_redraw()
	await _save("level71-paused-phone-1792x828")
	game.queue_free()
	await process_frame
	if not capture_failed:
		print("NEXT_BUILD_GRAPHICS_CAPTURE_PASS count=14")
	quit(1 if capture_failed else 0)

func _measure(game: MeasuredGame, label: String) -> void:
	game.draw_times.clear()
	game.predator_draw_us = 0
	game.measured_predator_draws = 0
	game.collectible_draw_us = 0
	game.measured_collectible_draws = 0
	game.whirlpool_draw_us = 0
	game.measured_whirlpool_passes = 0
	var save_before := JSON.stringify(game.session.to_save())
	var gameplay_before := [game.fred,game.predator,game.secondary_predators.duplicate(),game.level_number,game.collected.duplicate(),game.simulation_time]
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for frame in 120:
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
	game.draw_times.sort()
	print("MEASURE %s gameplay_draws=%d cpu_p95_us=%d memory_growth_bytes=%d node_growth=%d" % [label, game.draw_times.size(), game.draw_times[int(game.draw_times.size()*0.95)], int(Performance.get_monitor(Performance.MEMORY_STATIC))-memory_before, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))-nodes_before])
	print("MEASURE %s predator_draws=%d cpu_average_us=%d" % [label, game.measured_predator_draws, game.predator_draw_us / maxi(1,game.measured_predator_draws)])
	print("MEASURE %s collectible_draws=%d cpu_average_us=%d" % [label, game.measured_collectible_draws, game.collectible_draw_us / maxi(1,game.measured_collectible_draws)])
	print("MEASURE %s whirlpool_passes=%d hazards_per_pass=%d cpu_average_us=%d" % [label, game.measured_whirlpool_passes, int(game.level_profile.whirlpool_count), game.whirlpool_draw_us / maxi(1,game.measured_whirlpool_passes)])
	if JSON.stringify(game.session.to_save()) != save_before or gameplay_before != [game.fred,game.predator,game.secondary_predators,game.level_number,game.collected,game.simulation_time]:
		push_error("Drawing mutated the game session")
		capture_failed = true

func _resize(size: Vector2i) -> void:
	capture_viewport.size = size
	var scale_factor := minf(float(size.x) / 1280.0, float(size.y) / 720.0)
	capture_canvas.scale = Vector2.ONE * scale_factor
	capture_canvas.position = (Vector2(size) - Vector2(1280, 720) * scale_factor) * 0.5

func _configure(game: Node2D) -> void:
	game.audio_enabled = false
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.saver = FredSaveAdapter.new("user://next_graphics_review_save")
	game.customization = FredFrogCustomization.new("")
	game.leaderboard = FredLocalLeaderboard.new("user://next_graphics_review_board.json")

func _save(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := capture_viewport.get_texture().get_image()
	if rendered == null or rendered.is_empty() or rendered.get_size() != capture_viewport.size or rendered.save_png(output_dir.path_join(label + ".png")) != OK:
		push_error("Could not save graphics review: " + label)
		capture_failed = true
