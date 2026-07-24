extends SceneTree

const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const SAVE_PREFIX := "user://m2_boost_capture"
const BOARD_PATH := "user://m2_boost_capture_board.json"

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	_clean()
	var game: Node2D = load("res://scripts/main.gd").new()
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

	var started: Dictionary = game.boost.advance(true, true, true, 100)
	game.session.boost_energy = int(started.energy)
	game._apply_boost_event(str(started.event))
	await _save("res://docs/evidence/m2-boost-burst.png")

	for tick in range(20):
		var sustain: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
		game.session.boost_energy = int(sustain.energy)
		game._apply_boost_event(str(sustain.event))
	await _save("res://docs/evidence/m2-boost-sustain.png")

	game.boost.reset()
	game.session.boost_energy = BoostLocomotion.START_THRESHOLD
	var low: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(low.energy)
	for tick in range(90):
		var drain: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
		game.session.boost_energy = int(drain.energy)
		if str(drain.event) == "exhausted":
			game._apply_boost_event("exhausted")
			break
	await _save("res://docs/evidence/m2-boost-exhausted.png")

	game.boost.advance(false, true, true, game.session.boost_energy)
	for tick in range(BoostLocomotion.EXHAUSTED_RECOVERY_DELAY_TICKS + 12):
		var recovery: Dictionary = game.boost.advance(false, true, true, game.session.boost_energy)
		game.session.boost_energy = int(recovery.energy)
	game._set_feedback("[BOOST RECOVERING] Energy returns after Fred rests.")
	await _save("res://docs/evidence/m2-boost-recovery.png")

	game.boost.reset()
	game.session.boost_energy = 100
	game.leap.reset()
	game.leap.request(Vector2.RIGHT)
	var leap_boost: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(leap_boost.energy)
	game.leap.advance(game.leap.AIRBORNE_SECONDS * 0.5)
	game._set_feedback("[LEAP + BOOST] Fred powers through the arc.")
	await _save("res://docs/evidence/m2-boost-leap.png")

	game.leap.reset()
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.boost.reset()
	game.session.boost_energy = 100
	var underwater: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(underwater.energy)
	game._set_feedback("[UNDERWATER BOOST] Shorter surge, same readable energy.")
	await _save("res://docs/evidence/m2-boost-underwater.png")

	game.reduced_motion = true
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.boost.reset()
	game.session.boost_energy = 42
	var reduced: Dictionary = game.boost.advance(true, true, true, game.session.boost_energy)
	game.session.boost_energy = int(reduced.energy)
	game._set_feedback("[REDUCED MOTION] Boost stays readable without camera motion.")
	root.get_window().size = Vector2i(960,540)
	await process_frame
	await _save("res://docs/evidence/m2-boost-reduced-motion-960x540.png")

	game.queue_free()
	await process_frame
	_clean()
	print("CAPTURED 7 M2 boost screenshots")
	quit()

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
