extends SceneTree

const Main = preload("res://scripts/main.gd")

const SAVE_PREFIX := "user://m2_android_readiness"
const BOARD_PATH := "user://m2_android_readiness_board.json"

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func clean_files() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))

func _init() -> void:
	_run.call_deferred()

func _finish(exit_code: int) -> void:
	quit(exit_code)

func _run() -> void:
	clean_files()
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.session.health = 4

	var move_touch := InputEventScreenTouch.new()
	move_touch.index = 11
	move_touch.position = Vector2(248,565)
	move_touch.pressed = true
	game._unhandled_input(move_touch)
	var boost_touch := InputEventScreenTouch.new()
	boost_touch.index = 12
	boost_touch.position = Vector2(1175,625)
	boost_touch.pressed = true
	game._unhandled_input(boost_touch)
	check(game.touch_movement == Vector2.RIGHT and game.touch_boost, "simultaneous movement and boost touch zones remain independent")

	var state_before_pause := [
		game.fred,
		game.session.health,
		game.session.boost_energy,
		game.simulation_time,
	]
	game.notification(NOTIFICATION_APPLICATION_PAUSED)
	check(game.application_backgrounded and game.session.paused, "Android background notification pauses active play")
	check(game.touch_contacts.is_empty() and game.touch_movement == Vector2.ZERO and not game.touch_boost, "background clears every held touch contact")
	check(FileAccess.file_exists(SAVE_PREFIX + ".json"), "background lifecycle flushes a stable fictional save")
	check(not FileAccess.file_exists(SAVE_PREFIX + ".backup.json"), "first background notification performs one save without duplicate rotation")
	game.notification(NOTIFICATION_APPLICATION_PAUSED)
	check(not FileAccess.file_exists(SAVE_PREFIX + ".backup.json"), "duplicate background notification cannot duplicate the save")
	game._process(5.0)
	check(
		state_before_pause == [
			game.fred,
			game.session.health,
			game.session.boost_energy,
			game.simulation_time,
		],
		"backgrounded play consumes no position, lives, energy or simulation time"
	)

	game.notification(NOTIFICATION_APPLICATION_RESUMED)
	check(not game.application_backgrounded and game.session.paused, "resume returns to an explicit paused safety gate")
	check(game.touch_contacts.is_empty() and game.touch_movement == Vector2.ZERO and not game.touch_boost, "resume cannot replay stale touch input")
	game.notification(NOTIFICATION_APPLICATION_RESUMED)
	check(game.session.paused, "duplicate resume notification cannot silently unpause")

	var pause_touch := InputEventScreenTouch.new()
	pause_touch.index = 13
	pause_touch.position = Vector2(1180,42)
	pause_touch.pressed = true
	game._unhandled_input(pause_touch)
	check(not game.session.paused, "touch pause control explicitly resumes after foreground recovery")
	pause_touch.pressed = false
	game._unhandled_input(pause_touch)
	check(game.touch_contacts.is_empty(), "resume-control touch release leaves no stale contact")

	var first_back: String = game._handle_back_request()
	check(first_back == "paused" and game.session.paused, "first Android Back pauses and flushes active play")
	var second_back: String = game._handle_back_request()
	check(second_back == "home" and game.screen == Main.Screen.TITLE, "second Android Back returns to the title")
	check(game._handle_back_request() == "quit", "Android Back from the title requests normal app exit")

	var loaded := AdventureSession.new()
	var load_result: Dictionary = game.saver.load_session(loaded)
	check(bool(load_result.get("ok", false)) and loaded.health == 4, "schema-v1 lifecycle save preserves a stacked life above three")
	var stable_hash := hash(loaded.to_save("2000-01-01T00:00:00Z"))
	var second_load := AdventureSession.new()
	check(bool(game.saver.load_session(second_load).get("ok", false)), "cold lifecycle relaunch reloads the fictional save")
	check(hash(second_load.to_save("2000-01-01T00:00:00Z")) == stable_hash, "cold relaunch canonical state hash is deterministic")

	var touch_hash := 0
	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started := Time.get_ticks_msec()
	for iteration in range(10000):
		var sample := Vector2(
			float((iteration * 137) % 1280),
			float((iteration * 251) % 720)
		)
		touch_hash = hash([touch_hash, game._touch_action_at(sample)])
	var elapsed_ms := Time.get_ticks_msec() - started
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 2500, "10,000 touch-zone decisions remain time-bounded")
	check(memory_growth < 4 * 1024 * 1024, "10,000 touch-zone decisions remain memory-bounded")
	check(touch_hash != 0, "touch-zone stress produces a deterministic non-empty observation")
	print("MEASURE android_touch_decisions=10000 elapsed_ms=%d memory_growth_bytes=%d hash=%d" % [elapsed_ms, memory_growth, touch_hash])

	game.menu_music.stop()
	game.chase_music.stop()
	await process_frame
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	await process_frame
	clean_files()
	print("RESULT android_readiness_passed=%d android_readiness_failed=%d" % [passed, failed])
	_finish.call_deferred(1 if failed else 0)
