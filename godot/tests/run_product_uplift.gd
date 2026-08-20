extends SceneTree

const Main = preload("res://scripts/main.gd")
const Customization = preload("res://scripts/frog_customization.gd")
const AppleScoring = preload("res://scripts/apple_game_scoring.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

const SAVE_PREFIX := "user://product_uplift_save"
const PROFILE_PATH := "user://product_uplift_profile.json"
const BOARD_PATH := "user://product_uplift_board.json"

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _clean() -> void:
	for path in [
		SAVE_PREFIX + ".json", SAVE_PREFIX + ".backup.json", SAVE_PREFIX + ".tmp.json",
		PROFILE_PATH, PROFILE_PATH.trim_suffix(".json") + ".tmp.json", BOARD_PATH,
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_clean()
	var profile := Customization.new(PROFILE_PATH)
	check(profile.coins == 0, "new customization profile starts with zero earned coins")
	check(profile.selected_label("body") == "Marsh Green", "new profile owns a readable starter frog color")
	check(profile.selected_label("attire") == "Runner Goggles", "clear starter goggles are the default Fred identity")
	check(profile.next_label("attire") == "Explorer Glasses", "customizer names the next child-readable gear choice")
	check(profile.earn_coins(200) == 200, "gameplay rewards add bounded local coins")
	for category in Customization.CATEGORIES:
		var result: Dictionary = profile.select_next(category)
		check(bool(result.get("ok", false)), "%s upgrade purchases and equips deterministically" % category)
	var style: Dictionary = profile.current_style()
	check(style.body_color is Color and style.tongue_color is Color, "equipped frog and tongue colors are typed presentation values")
	check(float(style.size_scale) >= 0.88 and float(style.size_scale) <= 1.14, "cosmetic frog sizes stay in a child-readable visual-only range")
	for attire_entry: Dictionary in Customization.CATALOG.attire:
		var label := str(attire_entry.label)
		check("Goggles" in label or "Glasses" in label or "Visor" in label or "Shades" in label, "%s uses an obvious eyewear name" % label)
	check(profile.save_profile(), "customization profile persists locally")
	var restored := Customization.new(PROFILE_PATH)
	check(restored.to_dictionary() == profile.to_dictionary(), "coins, ownership and equipped cosmetics round-trip exactly")
	var memory_only := Customization.new("")
	check(memory_only.earn_coins(9) == 9 and memory_only.save_profile(), "headless memory-only profiles cannot write owner data")
	check(not memory_only.persistent and memory_only.path.is_empty(), "memory-only profile mode exposes its nonpersistent boundary")

	var scoring := AppleScoring.new()
	scoring.configure("Windows")
	var score_result: Dictionary = scoring.record_level_completion(12, 3, 7, restored.coins)
	check(str(score_result.status) == "LOCAL_ONLY_PLATFORM_ADAPTER_READY", "Windows scoring remains local while the Apple adapter contract is ready")
	check(bool(scoring.engine_contract().server_verification_required), "Game Center contract requires verified online submission")
	check(not scoring.can_submit_to_game_center(), "Windows cannot masquerade as an activated Apple provider")
	scoring.configure("iOS", "", false)
	check(scoring.submission_status() == "APPLE_CONFIGURATION_REQUIRED", "iOS fails closed until the real Game Center identifier and bridge exist")
	scoring.configure("iOS", "grp.fred.moonpetal.progress", true)
	check(scoring.can_submit_to_game_center(), "an injected authorized iOS bridge can satisfy the provider boundary")
	for duplicate in range(2):
		scoring.record_level_completion(12, 3, 7, restored.coins)
	check(scoring.pending_events.size() == 1, "repeated identical score events do not duplicate the offline queue")

	var labels: Array[String] = []
	var pad_signatures: Array[String] = []
	for level in range(1, 7):
		labels.append(Layout.formation_label(level))
		var signature := ""
		for index in range(7):
			var point := Layout.pad_point(Main.PADS[index], index, level)
			check(Layout.PLAYFIELD_RECT.grow(-20.0).has_point(point), "level %d pad %d stays in the playable marsh" % [level,index+1])
			signature += "%d,%d;" % [roundi(point.x),roundi(point.y)]
		pad_signatures.append(signature)
	var unique_formations: Dictionary = {}
	for label in labels: unique_formations[label] = true
	var unique_signatures: Dictionary = {}
	for signature in pad_signatures: unique_signatures[signature] = true
	check(unique_formations.size() == 6, "six consecutive levels use six named game formations")
	check(unique_signatures.size() == 6, "six consecutive levels produce six distinct whole-screen routes")
	check(Layout.formation_label(7) == Layout.formation_label(1), "formation rotation repeats predictably after six levels")
	check(not Layout.HOME_RECT.intersects(Layout.PAUSE_RECT) and not Layout.HOME_RECT.intersects(Layout.LIVES_RECT), "Exit, Pause and Lives remain non-overlapping")
	check(Layout.touch_action_at(Layout.HOME_RECT.get_center()) == "home", "the visible gameplay Exit button shares the touch hit contract")
	var fred_start_bounds := Rect2(Main.START - Vector2(42.0,42.0), Vector2(84.0,84.0))
	check(not Layout.TOUCH_ACTION_WHEEL_RECT.intersects(fred_start_bounds), "left action wheel keeps Fred's starting silhouette clear")
	var reversed_start := Layout.start_point(Main.START, 2)
	var reversed_start_bounds := Rect2(reversed_start - Vector2(42.0,42.0), Vector2(84.0,84.0))
	check(not Layout.TOUCH_CONTROL_PAD_RECT.intersects(reversed_start_bounds), "right control pad keeps reversed-route Fred clear")
	check(Layout.touch_action_at(Layout.TOUCH_CONTROL_PAD_CENTER) == "steer", "the right control pad owns touch steering")
	check(Layout.touch_action_at(Vector2(620.0,330.0)) == "", "the open playfield cannot cause unintended touch movement")

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.customization = restored
	game.game_scoring = AppleScoring.new()
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	var coins_before := restored.coins
	check(game._consume_tongue_target("bug:000", "bug"), "eligible prey can be consumed through the canonical eating path")
	check(restored.coins == coins_before + 3, "eating a bug visibly earns three persistent coins")
	var save_before_style: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	game._sync_fred_style()
	game.fred_rig.apply_pose(game.animation.pose(), 0.0)
	check(game.session.to_save("2000-01-01T00:00:00Z") == save_before_style, "sport rig and cosmetics cannot mutate gameplay or save state")
	check(str(game.fred_rig.style_snapshot().attire) == str(restored.current_style().attire), "runtime rig receives the equipped sport attire")
	var gear: Dictionary = game.fred_rig.attire_snapshot()
	check(bool(gear.valid) and bool(gear.child_readable), "runtime attire exposes a child-readable alignment contract")
	check(float(gear.eye_span) >= 20.0 and float(gear.eye_span) <= 40.0, "runtime eyewear remains aligned across Fred's eyes")

	game.level_number = 8
	game.level_profile = FredLevelIntensity.profile(8)
	game.session.health = 6
	game.screen = Main.Screen.PLAYING
	var preserved_coins := restored.coins
	game._handle_click(Layout.HOME_RECT.get_center())
	check(game.screen == Main.Screen.TITLE, "gameplay Exit returns directly to the main screen")
	check(game.level_number == 1 and game.session.health == AdventureSession.STARTING_LIVES, "leaving gameplay resets the next adventure to level one and three lives")
	check(game.session.checkpoint_sequence == 0 and game.session.bug_count == 0, "leaving gameplay clears run-only checkpoint and bug progress")
	check(restored.coins == preserved_coins, "leaving gameplay preserves earned coins and cosmetics")
	var reset_restore := AdventureSession.new()
	check(bool(game.saver.load_session(reset_restore).get("ok", false)) and reset_restore.health == 3 and reset_restore.bug_count == 0, "fresh-run state is durably saved after Exit")

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for banned in ["WASD / arrows", "Space leaps", "Shift boosts", "Q dive", "E surface", "P pause", "[F] MUNCH"]:
		check(banned not in main_source, "player-facing source omits desktop-specific instruction: %s" % banned)
	check(main_source.contains("moonpetal-title-fred-v4-sport.png"), "runtime uses the new sporty game-hero title artwork")
	check(main_source.contains("GEAR + GLASSES") and main_source.contains("NEXT: %s"), "customizer explains gear choices with simple visible labels")

	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	_clean()
	print("RESULT product_uplift_passed=%d product_uplift_failed=%d" % [passed,failed])
	quit(1 if failed else 0)
