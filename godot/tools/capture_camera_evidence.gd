extends SceneTree

const CameraFollow = preload("res://scripts/camera_follow.gd")
const SAVE_PREFIX := "user://m2_camera_capture"
const BOARD_PATH := "user://m2_camera_capture_board.json"

var game: Node2D

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	_clean()
	game = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.predator = Vector2(1120,560)

	_show_motion(Vector2(610,420), Vector2.RIGHT, "[CAMERA 1/7] RIGHT LOOK-AHEAD - ROUTE VISIBLE", Vector2i(1280,720))
	await _save("res://docs/evidence/m2-camera-right-anticipation.png")
	_show_motion(Vector2(610,420), Vector2.LEFT, "[CAMERA 2/7] REVERSAL - SMOOTH CATCH-UP", Vector2i(1280,720))
	await _save("res://docs/evidence/m2-camera-reversal.png")

	game.leap.reset()
	game.leap.request(Vector2.RIGHT)
	game.leap.advance(game.leap.AIRBORNE_SECONDS * 0.5)
	_show_motion(Vector2(650,400), Vector2.RIGHT, "[CAMERA 3/7] LEAP APEX - LANDING VISIBLE", Vector2i(1280,720), game.leap.visual_height)
	await _save("res://docs/evidence/m2-camera-leap-apex.png")

	game.leap.reset()
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	_show_motion(Vector2(720,470), Vector2.UP, "[CAMERA 4/7] UNDERWATER - HAZARDS VISIBLE", Vector2i(1280,720), 0.0, 1.0)
	await _save("res://docs/evidence/m2-camera-underwater.png")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	_show_motion(Vector2(1225,625), Vector2.RIGHT, "[CAMERA 5/7] WORLD EDGE - FRED IN FRAME", Vector2i(1280,720), 0.0, 0.0, 1.0)
	await _save("res://docs/evidence/m2-camera-world-clamp.png")

	game.reduced_motion = true
	_show_motion(Vector2(650,400), Vector2.RIGHT, "[CAMERA 6/7] REDUCED - STATIC + READABLE", Vector2i(960,540), 52.0, 1.0, 1.0)
	root.get_window().size = Vector2i(960,540)
	await process_frame
	await _save("res://docs/evidence/m2-camera-reduced-motion-960x540.png")

	game.reduced_motion = false
	_show_motion(Vector2(650,400), Vector2.RIGHT, "[CAMERA 7/7] 640x360 - ROUTE READABLE", Vector2i(640,360), 0.0, 0.0, 1.0)
	root.get_window().size = Vector2i(640,360)
	await process_frame
	await _save("res://docs/evidence/m2-camera-constrained-640x360.png")

	game.queue_free()
	await process_frame
	_clean()
	print("CAPTURED 7 M2 camera screenshots")
	quit()

func _show_motion(
	focus: Vector2,
	movement: Vector2,
	message: String,
	viewport_size: Vector2i,
	leap_height: float = 0.0,
	depth_amount: float = 0.0,
	boost_strength: float = 0.0
) -> void:
	game.fred = focus
	game.camera_follow.reset()
	var camera_state: Dictionary = game.camera_follow.snap(
		focus,
		movement,
		leap_height,
		depth_amount,
		boost_strength,
		Vector2.ZERO,
		false,
		game.reduced_motion,
		viewport_size
	)
	game.camera_offset = Vector2(camera_state.offset)
	game.camera_response_y = game.camera_offset.y
	game._set_feedback(message)
	game.queue_redraw()

func _save(path: String) -> void:
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		push_error("Screenshot image unavailable: " + path)
		quit(1)
		return
	var error := image.save_png(path)
	if error != OK:
		push_error("Screenshot save failed: " + path)
		quit(1)

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
