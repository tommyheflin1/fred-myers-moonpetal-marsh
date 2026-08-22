extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

const SAVE_PREFIX := "user://app_build_2_phone_fixes"
const BOARD_PATH := "user://app_build_2_phone_fixes_board.json"

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
		var save_path := ProjectSettings.globalize_path(SAVE_PREFIX + suffix)
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
	var board_path := ProjectSettings.globalize_path(BOARD_PATH)
	if FileAccess.file_exists(board_path):
		DirAccess.remove_absolute(board_path)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	clean_files()
	check(int(ProjectSettings.get_setting("audio/general/ios/session_category", -1)) == 3, "iOS uses Playback audio so Fred's music works with the silent switch enabled")
	check(ResourceLoader.exists(Main.MENU_MUSIC_PATH), "The Marshland March is packaged for the main menu")
	check(ResourceLoader.exists(Main.GAMEPLAY_MUSIC_PATH), "Marshland Chase is packaged for gameplay")
	check(Main.MENU_MUSIC_PATH != Main.GAMEPLAY_MUSIC_PATH, "menu and gameplay use distinct music resources")

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var menu_stream: AudioStream = load(Main.MENU_MUSIC_PATH)
	var chase_stream: AudioStream = load(Main.GAMEPLAY_MUSIC_PATH)
	check(menu_stream is AudioStreamMP3, "main-menu music imports as AudioStreamMP3")
	check(chase_stream is AudioStreamMP3, "gameplay music imports as AudioStreamMP3")
	check((menu_stream as AudioStreamMP3).loop, "main-menu music loops continuously")
	check((chase_stream as AudioStreamMP3).loop, "gameplay music loops continuously")
	menu_stream = null
	chase_stream = null
	check(game._music_route() == "menu", "title screen routes only The Marshland March")
	game._start()
	check(game._music_route() == "gameplay", "starting play routes only Marshland Chase")

	var centers := Layout.touch_centers()
	var radii := Layout.touch_radii()
	check(Layout.TOUCH_ACTION_WHEEL_CENTER.x < Layout.CANVAS_SIZE.x * 0.5, "four circular action buttons are grouped on the left")
	check(Layout.TOUCH_ACTION_WHEEL_CENTER.x <= 160.0, "action wheel remains in the short-reach left-thumb zone")
	check(Layout.TOUCH_CONTROL_PAD_CENTER.x > Layout.CANVAS_SIZE.x * 0.5, "movement control pad is grouped on the right")
	check(Layout.TOUCH_ACTION_WHEEL_CENTER.y > Layout.CANVAS_SIZE.y * 0.7, "action wheel sits in the lower phone-safe reach zone")
	check(Layout.TOUCH_CONTROL_PAD_CENTER.y > Layout.CANVAS_SIZE.y * 0.7, "movement pad sits in the lower phone-safe reach zone")
	check(Layout.TOUCH_ACTION_WHEEL_RECT.end.y <= Layout.CANVAS_SIZE.y - Layout.TOUCH_SAFE_EDGE_MARGIN, "action wheel clears the bottom home-indicator zone")
	check(Layout.TOUCH_CONTROL_PAD_RECT.end.y <= Layout.CANVAS_SIZE.y - Layout.TOUCH_SAFE_EDGE_MARGIN, "movement pad clears the bottom home-indicator zone")
	check(not Layout.TOUCH_ACTION_WHEEL_RECT.intersects(Layout.TOUCH_CONTROL_PAD_RECT), "action wheel and control pad do not overlap")
	check(not Layout.STATUS_TOUCH_RECT.intersects(Layout.TOUCH_ACTION_WHEEL_RECT), "status message does not cover the action wheel")
	check(not Layout.STATUS_TOUCH_RECT.intersects(Layout.TOUCH_CONTROL_PAD_RECT), "status message does not cover the control pad")
	for action: String in ["tongue", "leap", "depth", "boost"]:
		var center := Vector2(centers[action])
		var radius := float(radii[action])
		check(Layout.touch_action_at(center) == action, "%s circle has an exact matching touch target" % action)
		check(Layout.touch_action_at(center + Vector2(radius, radius)) != action, "%s ignores its square corner outside the visible circle" % action)
	check(Layout.touch_action_at(Vector2(640.0,330.0)) == "", "phone playfield taps cannot accidentally steer")
	check(Layout.touch_action_at(Layout.TOUCH_CONTROL_PAD_CENTER) == "steer", "control-pad center begins a movement contact")
	check(Layout.TOUCH_OVERLAY_ALPHA <= 0.2 and Layout.TOUCH_CONTROL_ALPHA <= 0.4, "inactive mobile controls remain transparent over the marsh")
	check(Layout.TOUCH_CONTROL_ACTIVE_ALPHA > Layout.TOUCH_CONTROL_ALPHA and Layout.TOUCH_CONTROL_ACTIVE_ALPHA < 0.75, "pressed controls become clearer without turning opaque")
	check(Layout.TOUCH_OUTLINE_ALPHA < 0.65, "control outlines remain translucent")
	check(Layout.touch_movement_vector(Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(8.0,5.0)) == Vector2.ZERO, "movement pad dead zone rejects finger jitter")
	check(Layout.touch_movement_vector(Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(60.0,0.0)) == Vector2.RIGHT, "movement pad reports a stable right direction")
	check(Layout.touch_movement_vector(Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(0.0,-60.0)) == Vector2.UP, "movement pad reports a stable up direction")

	game._handle_touch(21, Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(60.0,0.0), true)
	game._handle_touch(22, Vector2(centers.boost), true)
	check(game.touch_movement == Vector2.RIGHT and game.touch_boost, "simultaneous right-pad movement and left-wheel Boost stay independent")
	game._handle_touch(21, Vector2.ZERO, false)
	game._handle_touch(22, Vector2.ZERO, false)
	check(game.touch_contacts.is_empty() and game.touch_movement == Vector2.ZERO and not game.touch_boost, "touch releases clear all transient control state")

	game.notification(NOTIFICATION_APPLICATION_PAUSED)
	check(game.application_backgrounded and game.session.paused, "backgrounding pauses gameplay at a safe gate")
	check(game.touch_contacts.is_empty(), "backgrounding clears active touch contacts")
	game.notification(NOTIFICATION_APPLICATION_RESUMED)
	check(not game.application_backgrounded and game.session.paused, "foregrounding keeps gameplay safely paused for the player")
	check(game._music_route() == "gameplay", "foregrounding preserves the gameplay music route")
	check(Layout.touch_action_at(Layout.PAUSED_RESUME_RECT.get_center()) == "", "Resume overlay is not a hidden active-play target")
	check(Layout.touch_action_at(Layout.PAUSED_RESUME_RECT.get_center(), true) == "pause", "paused Resume overlay has an explicit touch target")
	game._handle_touch(23, Layout.PAUSED_RESUME_RECT.get_center(), true)
	check(not game.session.paused, "touching Resume after foreground recovery unfreezes gameplay")
	game._handle_touch(23, Vector2.ZERO, false)
	check(game.touch_contacts.is_empty(), "Resume touch release cannot leave stale input")

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not stable_save.has("touch") and not stable_save.has("music") and not stable_save.has("lifecycle"), "Build 2 phone presentation state remains outside fred_save v1")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("not session.paused and countdown_seconds <= 0.0"), "touch controls stay hidden behind countdown and pause overlays")
	var export_config := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(export_config.contains('application/version="2"'), "iOS development export declares App Store build number 2")
	check(export_config.contains("fred-myers-app-build-2-debug.apk"), "Android development export has a distinct Build 2 artifact name")

	game.menu_music.stop()
	game.chase_music.stop()
	await process_frame
	game.menu_music.stream = null
	game.chase_music.stream = null
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	clean_files()
	print("RESULT app_build_2_phone_fixes_passed=%d app_build_2_phone_fixes_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
