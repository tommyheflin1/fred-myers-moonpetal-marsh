extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

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
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new("user://app_store_capture_save")
	game.customization = FredFrogCustomization.new("user://app_store_capture_profile.json")
	game.leaderboard = FredLocalLeaderboard.new("user://app_store_capture_board.json")
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.touch_controls_visible = true
	canvas.add_child(game)
	await process_frame
	await process_frame
	await _save("01-title-hero")

	game._open_story()
	await process_frame
	await _save("02-hero-story")

	game._open_instructions()
	await process_frame
	await _save("03-touch-controls")

	game._start()
	game.set_process(false)
	game.fred = Vector2(430, 430)
	game.last_aim_direction = Vector2.RIGHT
	game.save_feedback = "[HERO READY] Munch the glowing bugs and reach the Moonpetal Exit."
	game.queue_redraw()
	await process_frame
	await _save("04-marsh-adventure")

	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.fred = Vector2(690, 420)
	game.save_feedback = "[UNDERWATER] Steer beneath surface hunters, then tap SURFACE."
	game.queue_redraw()
	await process_frame
	await _save("05-underwater-hero")

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
	await _save("06-fairy-stacked-lives")

	game.screen = Main.Screen.CUSTOMIZE
	game.queue_redraw()
	await process_frame
	await _save("07-customize-fred")

	game.leaderboard.submit("Marsh Hero", 25, 3, 5)
	game.leaderboard.submit("Lily Scout", 18, 3, 4)
	game.leaderboard.submit("Moon Jumper", 10, 3, 4)
	game.game_center_status = "GAME CENTER READY"
	game.screen = Main.Screen.LEADERBOARD
	game.queue_redraw()
	await process_frame
	await _save("08-marsh-leaders")

	game.queue_free()
	await process_frame
	_cleanup()
	print("APP_STORE_CAPTURE_PASS device=%s count=8 output=%s" % [device_label, output_dir])
	quit()


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
		"user://app_store_capture_save.json",
		"user://app_store_capture_save.backup.json",
		"user://app_store_capture_save.tmp.json",
		"user://app_store_capture_profile.json",
		"user://app_store_capture_profile.tmp.json",
		"user://app_store_capture_board.json",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
