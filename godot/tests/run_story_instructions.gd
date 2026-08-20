extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

const SAVE_PREFIX := "user://story_instructions"
const BOARD_PATH := "user://story_instructions_board.json"

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
		var path := ProjectSettings.globalize_path(SAVE_PREFIX + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var board_path := ProjectSettings.globalize_path(BOARD_PATH)
	if FileAccess.file_exists(board_path):
		DirAccess.remove_absolute(board_path)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	clean_files()
	for rect in [
		Main.STORY_HOME_RECT,
		Main.STORY_CONTINUE_RECT,
		Main.INSTRUCTIONS_HOME_RECT,
		Main.INSTRUCTIONS_PLAY_RECT,
	]:
		check(Layout.rect_inside_canvas(Rect2(rect),10.0), "story and instruction button stays inside the safe canvas")
	check(not Main.STORY_HOME_RECT.intersects(Main.STORY_CONTINUE_RECT), "story Home and Continue buttons do not overlap")
	check(not Main.INSTRUCTIONS_HOME_RECT.intersects(Main.INSTRUCTIONS_PLAY_RECT), "instruction Home and Play buttons do not overlap")
	check(Main.STORY_CONTINUE_RECT.size.y >= 60.0 and Main.INSTRUCTIONS_PLAY_RECT.size.y >= 60.0, "primary story buttons remain child-sized touch targets")

	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for phrase in [
		"THE MOONPETAL PROMISE",
		"THE LITTLE FROGS' DREAM",
		"THE MARSH IN TROUBLE",
		"FRED'S HERO PROMISE",
		"FROG HERO OF EVERY LITTLE FROG'S DREAMS",
		"Gather bugs. Outsmart danger. Bring courage home.",
	]:
		check(phrase in source, "hero story includes: %s" % phrase)
	for phrase in [
		"HOW TO BE A MARSH HERO",
		"RIGHT CONTROL PAD",
		"MUNCH",
		"LEAP",
		"BOOST",
		"DIVE / SURFACE",
		"STAY SAFE",
		"MUNCH 3 BUGS",
		"Every 10th level hides a fairy",
	]:
		check(phrase in source, "instructions include: %s" % phrase)
	for forbidden in ["WASD", "ARROW KEYS", "PRESS SPACE", "PRESS F"]:
		check(forbidden not in source.to_upper(), "story and instructions omit keyboard wording: %s" % forbidden)

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.screen == Main.Screen.TITLE, "new session begins on the title screen")
	var stable_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	var coins_before: int = game.customization.coins

	game._handle_click(Main.TITLE_START_RECT.get_center())
	check(game.screen == Main.Screen.STORY, "Begin Fred's Story opens the required story screen")
	check(game.session.to_save("2000-01-01T00:00:00Z") == stable_before, "opening the story cannot mutate gameplay or save state")
	check(game.customization.coins == coins_before, "opening the story cannot change coins or cosmetics")
	check(game.countdown_seconds == 0.0, "level countdown cannot start behind the story")

	game._handle_click(Main.STORY_CONTINUE_RECT.get_center())
	check(game.screen == Main.Screen.INSTRUCTIONS, "story continues directly to How to Play")
	check(game.session.to_save("2000-01-01T00:00:00Z") == stable_before, "instructions remain outside canonical gameplay state")
	check(game.countdown_seconds == 0.0, "level countdown cannot start behind instructions")

	game._handle_click(Main.INSTRUCTIONS_PLAY_RECT.get_center())
	check(game.screen == Main.Screen.PLAYING, "I'm Ready begins the playable adventure")
	check(is_equal_approx(game.countdown_seconds,5.0), "instructions lead into the existing five-second ready countdown")
	check(game.session.health == AdventureSession.STARTING_LIVES, "story flow preserves the three-life starting contract")

	game._go_home()
	game._handle_click(Main.TITLE_START_RECT.get_center())
	game._handle_click(Main.STORY_HOME_RECT.get_center())
	check(game.screen == Main.Screen.TITLE, "story Home returns to the title")
	game._handle_click(Main.TITLE_START_RECT.get_center())
	game._handle_click(Main.STORY_CONTINUE_RECT.get_center())
	game._handle_click(Main.INSTRUCTIONS_HOME_RECT.get_center())
	check(game.screen == Main.Screen.TITLE, "instruction Home returns to the title")

	var title_touch := InputEventScreenTouch.new()
	title_touch.index = 21
	title_touch.position = Main.TITLE_START_RECT.get_center()
	title_touch.pressed = true
	game._unhandled_input(title_touch)
	check(game.screen == Main.Screen.STORY and game.touch_controls_visible, "real screen touch opens the hero story")
	title_touch.pressed = false
	game._unhandled_input(title_touch)
	var story_touch := InputEventScreenTouch.new()
	story_touch.index = 22
	story_touch.position = Main.STORY_CONTINUE_RECT.get_center()
	story_touch.pressed = true
	game._unhandled_input(story_touch)
	check(game.screen == Main.Screen.INSTRUCTIONS, "real screen touch advances the story")
	story_touch.pressed = false
	game._unhandled_input(story_touch)
	var play_touch := InputEventScreenTouch.new()
	play_touch.index = 23
	play_touch.position = Main.INSTRUCTIONS_PLAY_RECT.get_center()
	play_touch.pressed = true
	game._unhandled_input(play_touch)
	check(game.screen == Main.Screen.PLAYING, "real screen touch starts Level 1 from instructions")
	play_touch.pressed = false
	game._unhandled_input(play_touch)
	check(game.touch_contacts.is_empty(), "story flow touch releases leave no stale contacts")

	var stable_after: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not stable_after.has("story") and not stable_after.has("instructions") and not stable_after.has("tutorial"), "story presentation remains absent from fred_save v1")
	check(Main.Screen.STORY != Main.Screen.PLAYING and Main.Screen.INSTRUCTIONS != Main.Screen.PLAYING, "story and instructions are explicit non-gameplay states")

	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT story_instructions_passed=%d story_instructions_failed=%d" % [passed,failed])
	quit(1 if failed else 0)
