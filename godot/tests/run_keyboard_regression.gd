extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

var passed := 0
var failed := 0
var prefix := "user://touch_only_regression"

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	_run.call_deferred()

func clean_files() -> void:
	for suffix: String in [".json", ".tmp.json", ".backup.json"]:
		var path := prefix + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var leaderboard_path := prefix + "_leaderboard.json"
	if FileAccess.file_exists(leaderboard_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(leaderboard_path))

func key_event(keycode: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = false
	return event

func send_key(game: Node2D, keycode: int, pressed: bool) -> void:
	var event := key_event(keycode, pressed)
	Input.parse_input_event(event)
	game._unhandled_input(event)
	await process_frame

func touch(game: Node2D, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	game._unhandled_input(event)
	await process_frame

func tap(game: Node2D, index: int, position: Vector2) -> void:
	await touch(game, index, position, true)
	await touch(game, index, position, false)

func create_game() -> Node2D:
	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(prefix)
	game.leaderboard = FredLocalLeaderboard.new(prefix + "_leaderboard.json")
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	game.set_process(false)
	return game

func _run() -> void:
	clean_files()
	var game := create_game()
	await process_frame
	check(game.touch_controls_visible, "Campaign 1 displays touch controls by default")
	check(not game.device_intent_adapter_enabled, "player gameplay disables non-touch intent adapters by default")
	check(game.screen == Main.Screen.TITLE, "touch-only candidate starts at the title")

	await send_key(game, KEY_ENTER, true)
	await send_key(game, KEY_ENTER, false)
	check(game.screen == Main.Screen.TITLE, "keyboard confirm cannot enter Campaign 1")

	await tap(game, 1, Main.TITLE_START_RECT.get_center())
	check(game.screen == Main.Screen.STORY, "screen touch opens the hero story")
	await tap(game, 2, Main.STORY_CONTINUE_RECT.get_center())
	check(game.screen == Main.Screen.INSTRUCTIONS, "screen touch advances to instructions")
	await tap(game, 3, Main.INSTRUCTIONS_PLAY_RECT.get_center())
	check(game.screen == Main.Screen.PLAYING, "screen touch begins Level 1")

	game.predator = Vector2(1200, 650)
	game.fred = Vector2(400, 400)
	var before: Vector2 = game.fred
	await send_key(game, KEY_D, true)
	game._fixed_tick(1.0 / 60.0)
	await send_key(game, KEY_D, false)
	check(game.fred == before, "keyboard movement cannot move Fred")
	var shot_before: int = game.tongue.shot_serial
	await send_key(game, KEY_F, true)
	await send_key(game, KEY_F, false)
	check(game.tongue.shot_serial == shot_before, "keyboard action cannot fire Fred's tongue")
	await send_key(game, KEY_P, true)
	await send_key(game, KEY_P, false)
	check(not game.session.paused, "keyboard action cannot pause Campaign 1")

	await touch(game, 4, Vector2(700, 400), true)
	game._fixed_tick(1.0 / 60.0)
	await touch(game, 4, Vector2(700, 400), false)
	check(game.fred.x > before.x, "touching the open marsh moves Fred")
	check(game.touch_contacts.is_empty() and game.touch_movement == Vector2.ZERO, "released movement touch clears cleanly")

	game.fred = game._bug_position(0) + Vector2(-100, 0)
	game.last_aim_direction = Vector2.RIGHT
	var action_rects := Layout.touch_action_rects()
	await tap(game, 5, Rect2(action_rects.tongue).get_center())
	check(game.tongue.shot_serial == shot_before + 1, "Munch touch button fires exactly one tongue shot")
	game.tongue.advance(1.0)

	var energy_before: int = game.session.boost_energy
	await touch(game, 6, Vector2(700, 400), true)
	await touch(game, 7, Rect2(action_rects.boost).get_center(), true)
	game._fixed_tick(1.0 / 60.0)
	await touch(game, 7, Rect2(action_rects.boost).get_center(), false)
	await touch(game, 6, Vector2(700, 400), false)
	check(game.session.boost_energy == energy_before - 1, "simultaneous touch steering and Boost consume one energy tick")

	await tap(game, 8, Rect2(Layout.PAUSE_RECT).get_center())
	check(game.session.paused, "Pause touch button pauses the campaign")
	await tap(game, 9, Rect2(Layout.PAUSE_RECT).get_center())
	check(not game.session.paused, "Pause touch button resumes the campaign")

	game.level_number = 100
	game.level_profile = FredLevelIntensity.profile(100)
	game.screen = Main.Screen.COMPLETE
	game.session.completed = true
	await tap(game, 10, Rect2(490,500,300,60).get_center())
	check(game.screen == Main.Screen.TITLE and game.level_number == 1, "Level 100 celebration returns to a fresh Campaign 1 title")
	check(game.save_feedback.contains("CAMPAIGN 1 COMPLETE"), "Campaign 1 ending celebrates Fred's hero promise")

	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(not source.contains("Input.is_key_pressed"), "runtime source contains no direct keyboard movement")
	check(not source.contains("MOUSE_BUTTON_RIGHT"), "runtime source contains no alternate mouse action control")
	check(source.contains("device_intent_adapter_enabled := false"), "non-touch adapter remains explicitly disabled in player builds")
	check(source.contains("touch_controls_visible := true"), "touch presentation is the default player contract")

	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT touch_only_passed=%d touch_only_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
