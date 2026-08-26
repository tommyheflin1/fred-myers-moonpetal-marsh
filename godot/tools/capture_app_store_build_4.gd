extends SceneTree

const Main = preload("res://scripts/main.gd")

var output_dir := ""
var device_label := "device"
var target_size := Vector2i(2868, 1320)
var capture_viewport: SubViewport


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--store-output="):
			output_dir = argument.trim_prefix("--store-output=")
		elif argument.begins_with("--store-device="):
			device_label = argument.trim_prefix("--store-device=")
		elif argument.begins_with("--store-width="):
			target_size.x = maxi(1, int(argument.trim_prefix("--store-width=")))
		elif argument.begins_with("--store-height="):
			target_size.y = maxi(1, int(argument.trim_prefix("--store-height=")))
	if output_dir.is_empty():
		push_error("--store-output=<absolute-folder> is required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	call_deferred("_capture")


func _capture() -> void:
	_cleanup()
	capture_viewport = SubViewport.new()
	capture_viewport.size = target_size
	capture_viewport.transparent_bg = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	var background := ColorRect.new()
	background.color = Color(0.01, 0.04, 0.07, 1.0)
	background.size = Vector2(target_size)
	capture_viewport.add_child(background)
	var canvas := Node2D.new()
	var scale_factor := minf(float(target_size.x) / 1280.0, float(target_size.y) / 720.0)
	canvas.scale = Vector2.ONE * scale_factor
	canvas.position = (Vector2(target_size) - Vector2(1280, 720) * scale_factor) * 0.5
	capture_viewport.add_child(canvas)

	# The opener uses Fred's exact Build 4 title artwork and exact campaign copy.
	# It is intentionally composed from shipped assets rather than inventing a
	# different frog, costume, feature, or gameplay promise for the store page.
	var story_hero := _build_story_hero()
	canvas.add_child(story_hero)
	await process_frame
	await _save("01-story-hero")
	story_hero.queue_free()
	await process_frame

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new("user://app_store_build_4_capture_save")
	game.customization = FredFrogCustomization.new("user://app_store_build_4_capture_profile.json")
	game.leaderboard = FredLocalLeaderboard.new("user://app_store_build_4_capture_board.json")
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.touch_controls_visible = true
	canvas.add_child(game)
	await process_frame
	await process_frame
	await _save("02-main-menu")

	game.screen = Main.Screen.CUSTOMIZE
	game.queue_redraw()
	await process_frame
	await _save("03-fred-options")

	game._open_instructions()
	await process_frame
	await _save("04-touch-controls")

	game._start()
	game.set_process(false)
	game.fred = Vector2(430, 430)
	game.last_aim_direction = Vector2.RIGHT
	game.save_feedback = "[HERO READY] Munch the glowing bugs and reach the Moonpetal Exit."
	game.queue_redraw()
	await process_frame
	await _save("05-marsh-adventure")

	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.fred = Vector2(690, 420)
	game.save_feedback = "[UNDERWATER] Steer beneath surface hunters, then tap SURFACE."
	game.queue_redraw()
	await process_frame
	await _save("06-underwater-hero")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.level_number = 10
	game.level_profile = FredLevelIntensity.profile(10)
	game.session.health = 4
	game.fairy_collected = false
	game.fred = Vector2(500, 300)
	game.save_feedback = "[FAIRY LEVEL] Munch the fairy to add one life to this adventure."
	game.queue_redraw()
	await process_frame
	await _save("07-fairy-stacked-lives")

	game.level_number = 17
	game.level_profile = FredLevelIntensity.profile(17)
	game.session = AdventureSession.new(1354)
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.fred = Vector2(700, 430)
	game.predator = Vector2(845, 430)
	game.last_aim_direction = Vector2.RIGHT
	game.leap.reset()
	game._request_leap(Vector2.RIGHT)
	for tick in 12:
		game._fixed_tick(1.0 / 60.0)
	game.save_feedback = "[LEAP] Fred springs over danger!"
	game.queue_redraw()
	await process_frame
	await _save("08-leap-challenge")

	game.queue_free()
	await process_frame
	_cleanup()
	print("APP_STORE_BUILD_4_CAPTURE_PASS device=%s count=8 output=%s" % [device_label, output_dir])
	quit()


func _build_story_hero() -> Control:
	var hero := Control.new()
	hero.size = Vector2(1280, 720)
	var art := TextureRect.new()
	art.texture = load("res://assets/art/moonpetal-title-fred-v4-sport.png")
	art.size = hero.size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	hero.add_child(art)
	var shade := ColorRect.new()
	shade.position = Vector2(0, 0)
	shade.size = Vector2(700, 720)
	shade.color = Color(0.005, 0.025, 0.05, 0.86)
	hero.add_child(shade)
	var accent := ColorRect.new()
	accent.position = Vector2(690, 0)
	accent.size = Vector2(5, 720)
	accent.color = Color("70d6c2")
	hero.add_child(accent)
	_add_label(hero, "FRED MYERS", Vector2(70, 52), Vector2(570, 74), 50, Color("ffe184"))
	_add_label(hero, "AND THE MOONPETAL MARSH", Vector2(73, 118), Vector2(565, 46), 25, Color.WHITE)
	_add_label(hero, "THE MOONPETAL PROMISE", Vector2(72, 215), Vector2(565, 52), 31, Color("70d6c2"))
	_add_label(hero, "Every little frog dreams of a safe, glowing marsh.", Vector2(72, 286), Vector2(555, 40), 20, Color.WHITE)
	_add_label(hero, "Wild currents and predators have broken the lily paths.", Vector2(72, 334), Vector2(555, 40), 18, Color("d9f4e2"))
	_add_label(hero, "Fred promises to cross all 100 levels,\nand carry their hope to the Moonpetal.", Vector2(72, 389), Vector2(555, 90), 18, Color.WHITE, true)
	var mission := ColorRect.new()
	mission.position = Vector2(72, 520)
	mission.size = Vector2(555, 104)
	mission.color = Color(0.015, 0.085, 0.12, 0.94)
	hero.add_child(mission)
	var mission_outline := ReferenceRect.new()
	mission_outline.position = mission.position
	mission_outline.size = mission.size
	mission_outline.border_color = Color("ffe184")
	mission_outline.border_width = 3.0
	hero.add_child(mission_outline)
	_add_label(hero, "BE THE FROG HERO", Vector2(92, 538), Vector2(515, 36), 25, Color("ffe184"), false, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(hero, "LEAP • DIVE • MUNCH • OUTSMART DANGER", Vector2(92, 580), Vector2(515, 30), 15, Color.WHITE, false, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(hero, "CAMPAIGN 1  •  100 LEVELS  •  PG FAMILY ADVENTURE", Vector2(72, 662), Vector2(555, 28), 14, Color("b9f5c7"), false, HORIZONTAL_ALIGNMENT_CENTER)
	return hero


func _add_label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color, wrap: bool = false, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _save(name: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	var image := capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Screenshot image unavailable: " + name)
		quit(1)
		return
	image.convert(Image.FORMAT_RGB8)
	var path := output_dir.path_join("%s-%s.png" % [device_label, name])
	var error := image.save_png(path)
	if error != OK:
		push_error("Screenshot save failed: " + path)
		quit(1)


func _cleanup() -> void:
	for path in [
		"user://app_store_build_4_capture_save.json",
		"user://app_store_build_4_capture_save.backup.json",
		"user://app_store_build_4_capture_save.tmp.json",
		"user://app_store_build_4_capture_profile.json",
		"user://app_store_build_4_capture_profile.tmp.json",
		"user://app_store_build_4_capture_board.json",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
