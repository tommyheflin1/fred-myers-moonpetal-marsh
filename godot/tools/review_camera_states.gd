extends SceneTree

const SAVE_PREFIX := "user://m2_camera_visible_review"
const BOARD_PATH := "user://m2_camera_visible_review_board.json"

var game: Node2D
var viewport_size := Vector2i(1280,720)

func _init() -> void:
	_review.call_deferred()

func _review() -> void:
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
	viewport_size = root.get_window().size
	if "--reduced-motion" in OS.get_cmdline_user_args():
		game.reduced_motion = true

	while true:
		_show(Vector2(610,420), Vector2.RIGHT, 0.0, 0.0, 0.0, "[CAMERA 1/7] RIGHT LOOK-AHEAD")
		await create_timer(3.0).timeout
		_show(Vector2(610,420), Vector2.LEFT, 0.0, 0.0, 0.0, "[CAMERA 2/7] REVERSAL")
		await create_timer(3.0).timeout
		_show(Vector2(650,400), Vector2.RIGHT, 52.0, 0.0, 0.0, "[CAMERA 3/7] LEAP APEX")
		await create_timer(3.0).timeout
		game.depth.reset("underwater")
		game.session.set_underwater(true)
		_show(Vector2(720,470), Vector2.UP, 0.0, 1.0, 0.0, "[CAMERA 4/7] UNDERWATER")
		await create_timer(3.0).timeout
		game.depth.reset("surface")
		game.session.set_underwater(false)
		_show(Vector2(650,400), Vector2.RIGHT, 0.0, 0.0, 1.0, "[CAMERA 5/7] BOOST")
		await create_timer(3.0).timeout
		_show(Vector2(1225,625), Vector2.RIGHT, 0.0, 0.0, 0.0, "[CAMERA 6/7] WORLD EDGE")
		await create_timer(3.0).timeout
		game.tongue.reset()
		var review_candidates: Array[Dictionary] = [{
			"id": "review:target",
			"kind": "bug",
			"position": Vector2(810,360),
			"eligible": true,
		}]
		game.tongue.request(Vector2(650,400), Vector2.RIGHT, review_candidates)
		_show(Vector2(650,400), Vector2.ZERO, 0.0, 0.0, 0.0, "[CAMERA 7/7] TONGUE TARGET", true)
		await create_timer(3.0).timeout

func _show(
	focus: Vector2,
	movement: Vector2,
	leap_height: float,
	depth_amount: float,
	boost_strength: float,
	message: String,
	preserve_tongue: bool = false
) -> void:
	game.fred = focus
	if not preserve_tongue:
		game.tongue.reset()
	game.camera_follow.reset()
	var tongue_vector: Vector2 = game.tongue.target_point - focus if game.tongue.is_busy() else Vector2.ZERO
	var state: Dictionary = game.camera_follow.snap(
		focus,
		movement,
		leap_height,
		depth_amount,
		boost_strength,
		tongue_vector,
		game.tongue.is_busy(),
		game.reduced_motion,
		viewport_size
	)
	game.camera_offset = Vector2(state.offset)
	game.camera_response_y = game.camera_offset.y
	game._set_feedback("%s  OFFSET %+.1f,%+.1f" % [message, game.camera_offset.x, game.camera_offset.y])
	game.queue_redraw()

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
