extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")
const SAVE_PREFIX := "user://pause_input_regression"

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	_run.call_deferred()

func touch_event(position: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	return event

func mouse_event(position: Vector2, pressed: bool, emulated: bool = false) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	if emulated:
		event.device = InputEvent.DEVICE_ID_EMULATION
	return event

func dispatch(event: InputEvent) -> void:
	# Input.parse_input_event expects physical window coordinates. This also
	# exercises the real stretch/letterbox transform on headless and small windows.
	Input.parse_input_event(event.xformed_by(root.get_final_transform()))
	Input.flush_buffered_events()

func game_state(game: Node2D) -> Array:
	return [game.fred, game.predator, game.secondary_predators.duplicate(),
		game.simulation_time, game.session.health, game.session.boost_energy,
		game.countdown_seconds, game.level_number, game.collected.duplicate()]

func _run() -> void:
	check(not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)), "native-touch builds disable duplicate mouse events")
	check(not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", true)), "desktop review uses Fred's pointer path without duplicate touch events")
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(SAVE_PREFIX + "_board.json")
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	var pause_at := Layout.PAUSE_RECT.get_center()
	var resume_at := Layout.PAUSED_RESUME_RECT.get_center()
	var steer_at := Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(60.0, 0.0)
	var boost_at := Vector2(Layout.touch_centers().boost)

	# Replay the native touch + compatibility mouse pair delivered on mobile.
	# Both event orders must represent one tap, never two pause toggles.
	for mouse_first: bool in [false, true]:
		game.session.paused = false
		var native_touch := touch_event(pause_at, true)
		var duplicate_mouse := mouse_event(pause_at, true, true)
		game._unhandled_input(duplicate_mouse if mouse_first else native_touch)
		game._unhandled_input(native_touch if mouse_first else duplicate_mouse)
		check(game.session.paused, "touch plus emulated mouse pauses exactly once (mouse_first=%s)" % mouse_first)
		var frozen := game_state(game)
		game._process(2.0)
		check(game_state(game) == frozen, "Pause freezes gameplay after the complete mobile event pair")
		game._unhandled_input(touch_event(pause_at, false))
		game._unhandled_input(mouse_event(pause_at, false, true))
		check(game.session.paused, "finger release cannot resume gameplay")
		game._unhandled_input(touch_event(resume_at, true))
		game._unhandled_input(mouse_event(resume_at, true, true))
		check(not game.session.paused, "Resume accepts one native touch and ignores its mouse duplicate")
		game._unhandled_input(touch_event(resume_at, false))
		game._unhandled_input(mouse_event(resume_at, false, true))

	# Pause must also release controls held by other fingers, so Resume is safe.
	game.session.paused = false
	game._unhandled_input(touch_event(steer_at, true, 7))
	game._unhandled_input(touch_event(boost_at, true, 8))
	check(game.touch_movement == Vector2.RIGHT and game.touch_boost, "movement and Boost can be held before Pause")
	game._unhandled_input(touch_event(pause_at, true, 9))
	check(game.session.paused, "third finger can pause while moving and boosting")
	check(game.touch_contacts.is_empty() and game.touch_positions.is_empty() and game.touch_movement == Vector2.ZERO and not game.touch_boost, "Pause clears all held movement and action contacts")
	if "--capture-pause" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.save_png("user://pause-overlay.png") == OK, "rendered Pause overlay captured for visual verification")
	game._unhandled_input(touch_event(pause_at, false, 9))
	game._unhandled_input(touch_event(steer_at, true, 10))
	check(game.touch_contacts.is_empty(), "paused controls cannot record fresh movement")
	game._unhandled_input(touch_event(resume_at, true, 11))
	game._unhandled_input(touch_event(resume_at, false, 11))
	check(not game.session.paused and game.touch_movement == Vector2.ZERO and not game.touch_boost, "Resume requires fresh movement and Boost presses")
	game._unhandled_input(touch_event(steer_at, false, 7))
	game._unhandled_input(touch_event(boost_at, false, 8))
	var emulated_drag := InputEventMouseMotion.new()
	emulated_drag.device = InputEvent.DEVICE_ID_EMULATION
	emulated_drag.position = steer_at
	game._unhandled_input(emulated_drag)
	check(not game.pointer_touch_active and game.touch_contacts.is_empty(), "emulated mouse motion cannot resurrect a cleared contact")

	# Exercise the engine dispatcher, not only direct calls to the game handler.
	# Force compatibility mode ON to ensure the guard survives a setting override.
	var previous_mouse_emulation := Input.emulate_mouse_from_touch
	var previous_touch_emulation := Input.emulate_touch_from_mouse
	Input.emulate_mouse_from_touch = true
	for cycle in range(6):
		dispatch(touch_event(pause_at, true))
		await process_frame
		check(game.session.paused, "engine-dispatched phone tap pauses once, cycle %d" % cycle)
		dispatch(touch_event(pause_at, false))
		dispatch(touch_event(resume_at, true))
		await process_frame
		check(not game.session.paused, "engine-dispatched Resume remains responsive, cycle %d" % cycle)
		dispatch(touch_event(resume_at, false))

	# The real desktop mouse still works, even with reverse emulation enabled.
	Input.emulate_touch_from_mouse = true
	dispatch(mouse_event(pause_at, true))
	await process_frame
	check(game.session.paused, "physical mouse pauses once when touch emulation is enabled")
	dispatch(mouse_event(pause_at, false))
	dispatch(mouse_event(resume_at, true))
	await process_frame
	check(not game.session.paused, "physical mouse Resume remains functional")
	dispatch(mouse_event(resume_at, false))
	Input.emulate_mouse_from_touch = previous_mouse_emulation
	Input.emulate_touch_from_mouse = previous_touch_emulation

	game.countdown_enabled = true
	game.countdown_seconds = 3.0
	game._unhandled_input(touch_event(pause_at, true, 1))
	game._unhandled_input(touch_event(pause_at, false, 1))
	game._process(2.0)
	check(game.session.paused and game.countdown_seconds == 3.0, "Pause freezes the level countdown")
	game._unhandled_input(touch_event(pause_at, true, 1))
	game._unhandled_input(touch_event(pause_at, false, 1))
	check(not game.session.paused, "top Pause button can also resume")
	game._process(0.5)
	check(game.countdown_seconds < 3.0, "countdown advances again after Resume")

	game.notification(NOTIFICATION_APPLICATION_PAUSED)
	game.notification(NOTIFICATION_APPLICATION_RESUMED)
	check(game.session.paused, "returning from background stays safely paused")
	game._unhandled_input(touch_event(resume_at, true))
	game._unhandled_input(mouse_event(resume_at, true, true))
	game._unhandled_input(touch_event(resume_at, false))
	check(not game.session.paused and not game.application_backgrounded, "native Resume plus emulated duplicate recovers from background")
	game._unhandled_input(touch_event(pause_at, true))
	game._unhandled_input(touch_event(pause_at, false))
	game._unhandled_input(touch_event(Layout.HOME_RECT.get_center(), true))
	check(game.screen == Main.Screen.TITLE, "Exit remains available while paused")

	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	for suffix: String in [".json", ".backup.json", ".tmp.json", "_board.json"]:
		var path := ProjectSettings.globalize_path(SAVE_PREFIX + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("RESULT pause_input_passed=%d pause_input_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
