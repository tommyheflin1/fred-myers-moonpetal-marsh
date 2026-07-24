extends SceneTree

const Main = preload("res://scripts/main.gd")
const Leaderboard = preload("res://scripts/local_leaderboard.gd")

var passed := 0
var failed := 0
const SAVE_PREFIX := "user://menu_lives_test_save"
const BOARD_PATH := "user://menu_lives_test_board.json"

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
	check(session.health == 5, "new Fred session starts with exactly five lives")
	check(not session.gain_life() and session.health == 5, "fairy cannot exceed the five-life limit")
	check(not session.damage(2) and session.health == 3, "damage consumes lives deterministically")
	check(session.gain_life() and session.health == 4, "fairy restores one missing life")
	check(session.gain_life() and session.health == 5, "second fairy restoration reaches the cap")
	check(not session.gain_life() and session.health == 5, "five-life cap remains stable")
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/new_game.json"))
	var restored := AdventureSession.new()
	check(restored.restore(legacy).get("ok") and restored.health == 3, "legacy three-life save remains readable")
	legacy.player_state.health = 99
	restored = AdventureSession.new()
	check(restored.restore(legacy).get("ok") and restored.health == 5, "restored health is safely clamped to five")

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
	game.session.health = 4
	game.fred = game._fairy_position()
	game._fixed_tick(0.0)
	check(game.session.health == 5 and game.fairy_collected, "touching the fairy grants exactly one extra life")
	game._fixed_tick(0.0)
	check(game.session.health == 5, "collected fairy cannot grant duplicate lives")
	game.session.health = 1
	game.predator = game.fred
	game.hazards_enabled = true
	game.danger_cooldown_seconds = 0.0
	game._fixed_tick(0.0)
	check(game.screen == game.Screen.FAILED and game.session.health == 0, "using the final life opens the Fred failure screen")
	game._handle_click(Vector2(490,532))
	check(game.screen == game.Screen.PLAYING and game.level_number == 1 and game.session.health == 5, "Try Again restarts at level one with five lives")
	game.screen = game.Screen.FAILED
	game._handle_click(Vector2(790,532))
	check(game.screen == game.Screen.TITLE and game.menu_music.playing, "Go Home returns to title and menu music")
	game._handle_click(Vector2(640,550))
	check(game.screen == game.Screen.LEADERBOARD and game.menu_music.playing, "title leaderboard button opens the functional local board")
	game._handle_click(Vector2(640,648))
	check(game.screen == game.Screen.TITLE, "leaderboard Home button returns to title")
	game.queue_free()
	await process_frame
	remove_test_files()
	print("RESULT menu_lives_leaderboard_passed=%d menu_lives_leaderboard_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
