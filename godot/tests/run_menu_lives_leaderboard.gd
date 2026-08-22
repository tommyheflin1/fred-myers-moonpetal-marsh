extends SceneTree

const Main = preload("res://scripts/main.gd")
const Leaderboard = preload("res://scripts/local_leaderboard.gd")

var passed := 0
var failed := 0
const SAVE_PREFIX := "user://menu_lives_test_save"
const BOARD_PATH := "user://menu_lives_test_board.json"

class FakeGameCenterNode:
	extends Node
	var available := true
	var authenticated := false
	var state := "ready"
	var sign_in_requests := 0
	var presentation_requests := 0
	var dashboard_ready := true

	func is_available() -> bool:
		return available

	func is_authenticated() -> bool:
		return authenticated

	func authentication_state() -> String:
		return state

	func begin_sign_in() -> bool:
		sign_in_requests += 1
		state = "authenticating"
		return true

	func show_leaderboards() -> bool:
		if not dashboard_ready:
			return false
		presentation_requests += 1
		dashboard_ready = false
		return true

	func can_show_leaderboards() -> bool:
		return dashboard_ready

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func remove_test_files() -> void:
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	remove_test_files()
	var session := AdventureSession.new(77)
	check(session.health == 3, "new Fred session starts with exactly three lives")
	check(session.gain_life() and session.health == 4, "first fairy stacks a fourth life above the starting count")
	check(not session.damage(2) and session.health == 2, "damage consumes stacked lives deterministically")
	check(session.gain_life(3) and session.health == 5, "fairy life gains remain additive after damage")
	check(session.gain_life(AdventureSession.MAX_LIVES) and session.health == AdventureSession.MAX_LIVES, "earned lives clamp only at the campaign maximum")
	check(not session.gain_life() and session.health == AdventureSession.MAX_LIVES, "campaign life maximum remains bounded")
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/new_game.json"))
	var restored := AdventureSession.new()
	check(restored.restore(legacy).get("ok") and restored.health == 3, "legacy three-life save remains readable")
	legacy.player_state.health = 99
	restored = AdventureSession.new()
	check(restored.restore(legacy).get("ok") and restored.health == AdventureSession.MAX_LIVES, "corrupt restored health is safely clamped to the campaign maximum")

	var board := Leaderboard.new(BOARD_PATH)
	board.submit("Guest Frog", 2, 3, 4)
	board.submit("Moon Kid", 8, 2, 1)
	board.submit("../../unsafe", 4, 1, 5)
	var entries := board.load_entries()
	check(entries.size() == 3, "local leaderboard persists fictional entries")
	check(int(entries[0].level) == 8 and int(entries[0].score) > int(entries[1].score), "leaderboard ranks highest score first")
	var labels_are_safe := true
	for entry in entries:
		labels_are_safe = labels_are_safe and not "/" in str(entry.player) and not "." in str(entry.player)
	check(labels_are_safe, "leaderboard removes unsafe label characters")
	for index in range(15):
		board.submit("Frog %02d" % index, index + 1, index % 4, index % 6)
	check(board.load_entries().size() == Leaderboard.MAX_ENTRIES, "leaderboard stays bounded to ten entries")

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = Leaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	root.add_child(game)
	await process_frame
	check(game.screen == game.Screen.TITLE, "game opens on upgraded title screen")
	check(game.menu_music.stream.resource_path.ends_with("the_marshland_march.mp3"), "menu uses The Marshland March")
	check(game.chase_music.stream.resource_path.ends_with("marshland_chase.mp3"), "gameplay uses Marshland Chase")
	check(game.menu_music.playing and not game.chase_music.playing, "menu music is active only on the menu")
	game._start()
	check(game.screen == game.Screen.PLAYING and is_equal_approx(game.countdown_seconds, 5.0), "every level begins with a five-second countdown")
	check(game.chase_music.playing and not game.menu_music.playing, "gameplay switches to chase music")
	var start_position: Vector2 = game.fred
	for frame in range(299):
		game._fixed_tick(1.0 / 60.0)
	check(game.fred == start_position and game.countdown_seconds > 0.0, "countdown blocks gameplay for its full ready period")
	game._fixed_tick(1.0 / 60.0)
	game._fixed_tick(1.0 / 60.0)
	check(is_zero_approx(game.countdown_seconds), "countdown reaches GO deterministically")
	check(not game._fairy_available(), "level one never exposes the bonus fairy")
	var schedule_is_exact := true
	for level in range(1, 101):
		game.level_number = level
		game.fairy_collected = false
		schedule_is_exact = schedule_is_exact and (game._fairy_available() == (level % 10 == 0))
	check(schedule_is_exact, "fairy is available only on every tenth level")
	game.level_number = 10
	game.level_profile = FredLevelIntensity.profile(10)
	game.session.health = 3
	game.fairy_collected = false
	game.collected.assign([0, 1, 2])
	game.fred = game._fairy_position() - Vector2(100, 0)
	game.tongue.reset()
	game._request_tongue(Vector2.RIGHT)
	check(game.session.health == 4 and game.fairy_collected, "eating the level-ten fairy stacks a fourth life")
	check(game.eat_effect_seconds > 0.0 and game.eat_target == game._fairy_position(), "fairy pickup uses Fred's visible eating animation")
	game.tongue.advance(1.0)
	game._request_tongue(Vector2.RIGHT)
	check(game.session.health == 4, "collected fairy cannot grant duplicate lives")
	game.screen = game.Screen.COMPLETE
	game._advance_level()
	check(game.level_number == 11 and game.session.health == 4, "earned fourth life carries into the next level")
	game.session.health = 1
	game._apply_danger_hit("[DANGER] Test final life.")
	check(game.screen == game.Screen.FAILED and game.session.health == 0, "using the final life opens the Fred failure screen")
	game._handle_click(Vector2(490,532))
	check(game.screen == game.Screen.PLAYING and game.level_number == 1 and game.session.health == 3, "Try Again restarts at level one with three lives")
	game.screen = game.Screen.FAILED
	game._handle_click(Vector2(790,532))
	check(game.screen == game.Screen.TITLE and game.menu_music.playing, "Go Home returns to title and menu music")
	game._handle_click(Main.TITLE_LEADERBOARD_RECT.get_center())
	check(game.screen == game.Screen.LEADERBOARD and game.menu_music.playing, "title leaderboard button opens the functional local board")
	var original_game_center: Node = game.game_center
	game.remove_child(original_game_center)
	original_game_center.queue_free()
	var fake_game_center := FakeGameCenterNode.new()
	game.add_child(fake_game_center)
	game.game_center = fake_game_center
	game.game_center_status = "GAME CENTER SIGN-IN NEEDED — TAP CONNECT"
	game._handle_touch(71, Main.LEADERBOARD_GAME_CENTER_RECT.get_center(), true)
	game._handle_touch(71, Main.LEADERBOARD_GAME_CENTER_RECT.get_center(), false)
	check(fake_game_center.sign_in_requests == 1 and game.game_center_status == "CONNECTING TO GAME CENTER", "leaderboard screen offers an explicit Apple sign-in action")
	fake_game_center.state = "ready"
	game._on_game_center_sign_in_completed({"ok": false, "error": "game_center_auth_failed", "error_code": 6})
	check(game.game_center_status == "GAME CENTER SIGN-IN NEEDED — TAP CONNECT", "failed Apple sign-in remains understandable and retryable")
	game._handle_click(Main.LEADERBOARD_GAME_CENTER_RECT.get_center())
	check(fake_game_center.sign_in_requests == 2, "player can retry Game Center without restarting Fred")
	fake_game_center.authenticated = true
	fake_game_center.state = "authenticated"
	game._on_game_center_sign_in_completed({"ok": true})
	game._handle_click(Main.LEADERBOARD_GAME_CENTER_RECT.get_center())
	check(fake_game_center.presentation_requests == 1, "authenticated player can open the Apple Game Center dashboard")
	game._handle_click(Main.LEADERBOARD_GAME_CENTER_RECT.get_center())
	check(fake_game_center.presentation_requests == 1 and game.game_center_status.contains("ALREADY OPEN"), "repeated Game Center tap is ignored without freezing the leaderboard screen")
	game._handle_click(Main.LEADERBOARD_HOME_SPLIT_RECT.get_center())
	check(game.screen == game.Screen.TITLE, "leaderboard Home button returns to title")
	game.queue_free()
	await process_frame
	remove_test_files()
	print("RESULT menu_lives_leaderboard_passed=%d menu_lives_leaderboard_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
