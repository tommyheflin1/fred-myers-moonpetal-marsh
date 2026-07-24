extends SceneTree

const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const SAVE_PREFIX := "user://m2_boost_visible_review"
const BOARD_PATH := "user://m2_boost_visible_review_board.json"

var game: Node2D

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
	game.predator = Vector2(1200,650)
	game.fred = Vector2(410,455)
	game.last_aim_direction = Vector2.RIGHT
	if "--reduced-motion" in OS.get_cmdline_user_args():
		game.reduced_motion = true

	while true:
		_show_burst()
		await create_timer(3.0).timeout
		_show_sustain()
		await create_timer(3.0).timeout
		_show_exhausted()
		await create_timer(3.0).timeout
		_show_recovery()
		await create_timer(3.0).timeout
		_show_leap()
		await create_timer(3.0).timeout
		_show_underwater()
		await create_timer(3.0).timeout
		_show_paused()
		await create_timer(3.0).timeout

func _show_burst() -> void:
	_reset_surface(100)
	var result: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(result.energy)
	game._set_feedback("[VISIBLE REVIEW 1/7] BOOST BURST - fast launch, clear energy.")

func _show_sustain() -> void:
	_reset_surface(62)
	for tick in range(20):
		var result: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
		game.session.boost_energy = int(result.energy)
	game._set_feedback("[VISIBLE REVIEW 2/7] SUSTAIN - lower speed, fixed energy drain.")

func _show_exhausted() -> void:
	_reset_surface(BoostLocomotion.START_THRESHOLD - 1)
	var result: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(result.energy)
	game._set_feedback("[VISIBLE REVIEW 3/7] EXHAUSTED - release Shift to recover.")

func _show_recovery() -> void:
	_reset_surface(4)
	game.boost.advance(true, true, true, game.session.boost_energy)
	game.boost.advance(false, true, true, game.session.boost_energy)
	for tick in range(BoostLocomotion.EXHAUSTED_RECOVERY_DELAY_TICKS + 12):
		var result: Dictionary = game.boost.advance(false, true, true, game.session.boost_energy)
		game.session.boost_energy = int(result.energy)
	game._set_feedback("[VISIBLE REVIEW 4/7] RECOVERING - energy returns after rest.")

func _show_leap() -> void:
	_reset_surface(100)
	game.leap.request(Vector2.RIGHT)
	var result: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(result.energy)
	game.leap.advance(game.leap.AIRBORNE_SECONDS * 0.5)
	game._set_feedback("[VISIBLE REVIEW 5/7] LEAP + BOOST - bounded arc acceleration.")

func _show_underwater() -> void:
	_reset_surface(100)
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	var result: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(result.energy)
	game._set_feedback("[VISIBLE REVIEW 6/7] UNDERWATER BOOST - shorter controlled surge.")

func _show_paused() -> void:
	_reset_surface(73)
	game.session.paused = true
	game._set_feedback("[VISIBLE REVIEW 7/7] PAUSED - energy and boost state are frozen.")

func _reset_surface(energy: int) -> void:
	game.session.paused = false
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.leap.reset()
	game.tongue.reset()
	game.boost.reset()
	game.session.boost_energy = energy
	game.camera_response_y = 0.0
	game.queue_redraw()

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
