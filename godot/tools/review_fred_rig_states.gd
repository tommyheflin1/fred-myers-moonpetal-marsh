extends SceneTree

const AnimationCoordinator = preload("res://scripts/fred_animation_coordinator.gd")
const SAVE_PREFIX := "user://m2_fred_rig_state_review"
const BOARD_PATH := "user://m2_fred_rig_state_review_board.json"

var game: Node2D
var review_index := 0

func _init() -> void:
	_review.call_deferred()

func _review() -> void:
	_clean()
	root.get_window().title = "Fred M2 Authored Rig State Review"
	game = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.menu_music.volume_db = -80.0
	game.chase_music.volume_db = -80.0
	game._start()
	game.predator = Vector2(1120,560)
	game.fred = Vector2(610,420)
	game.reduced_motion = "--reduced-motion" in OS.get_cmdline_user_args()
	while true:
		_show_next()
		await create_timer(1.75).timeout

func _show_next() -> void:
	var state_value := review_index % AnimationCoordinator.State.size()
	review_index += 1
	var coordinator := AnimationCoordinator.new()
	coordinator.state = state_value
	coordinator.state_ticks = review_index * 3
	coordinator.facing = 1.0 if review_index % 2 == 0 else -1.0
	coordinator.reduced_motion = game.reduced_motion
	coordinator._pose = coordinator._build_pose()
	game.animation = coordinator
	game.depth.depth = 1.0 if state_value in [
		AnimationCoordinator.State.DIVING,
		AnimationCoordinator.State.UNDERWATER_IDLE,
		AnimationCoordinator.State.UNDERWATER_SWIM,
		AnimationCoordinator.State.SURFACING,
	] else 0.0
	game.leap.visual_height = 90.0 if state_value in [
		AnimationCoordinator.State.LEAP_ASCENT,
		AnimationCoordinator.State.LEAP_APEX,
		AnimationCoordinator.State.LEAP_DESCENT,
	] else 0.0
	game.tongue.reset()
	if state_value in [
		AnimationCoordinator.State.TONGUE_WINDUP,
		AnimationCoordinator.State.TONGUE_EXTENSION,
		AnimationCoordinator.State.TONGUE_RECOVERY,
	]:
		game.tongue.state = FredTongueTargeting.State.EXTENDING
		game.tongue.elapsed = 0.09
		game.tongue.target_point = game.fred + Vector2(170,-20)
		game.tongue.outcome = "hit"
	game._set_feedback("[RIG %02d/23] %s | %s | FACING %s" % [
		state_value + 1,
		coordinator.state_name(),
		"REDUCED" if game.reduced_motion else "NORMAL",
		"RIGHT" if coordinator.facing > 0.0 else "LEFT",
	])
	game.queue_redraw()

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
