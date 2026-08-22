extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

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

func _run() -> void:
	var profiles: Array[Dictionary] = []
	var signatures: Dictionary = {}
	var chapters: Dictionary = {}
	var previous := FredLevelIntensity.profile(1)
	for level in range(1, 101):
		var profile := FredLevelIntensity.profile(level)
		profiles.append(profile)
		chapters[int(profile.chapter)] = int(chapters.get(int(profile.chapter), 0)) + 1
		var signature := JSON.stringify(profile)
		signatures[signature] = true
		check(int(profile.level) == level and int(profile.difficulty_step) == level, "Campaign 1 owns exact progressive Level %03d" % level)
		check(str(profile.campaign_id) == "campaign_1" and str(profile.content_rating) == "PG", "Level %03d preserves Campaign 1 and PG identity" % level)
		check(int(profile.target_min_age) == 5, "Level %03d preserves the five-year-old design floor" % level)
		check(int(profile.chapter) == ((level - 1) / 10) + 1 and int(profile.chapter_level) == ((level - 1) % 10) + 1, "Level %03d has the correct ten-level chapter position" % level)
		check(float(profile.reaction_window_seconds) >= 1.50 and float(profile.mistake_grace_seconds) >= 1.9, "Level %03d preserves child-readable reaction and recovery time" % level)
		check(float(profile.safe_radius) >= 50.0 and float(profile.danger_radius) <= 48.0, "Level %03d preserves fair safe and danger geometry" % level)
		check(int(profile.predator_count) >= 1 and int(profile.predator_count) <= 5 and int(profile.whirlpool_count) >= 0 and int(profile.whirlpool_count) <= 3, "Level %03d keeps hazards inside the PG campaign budget" % level)
		check(float(profile.predator_speed_scale) <= 1.27 and float(profile.bug_flight_speed) <= 0.90, "Level %03d keeps moving targets inside the age-five speed cap" % level)
		var expected_challenge := 1.9 + float(level - 1) * 0.1
		check(is_equal_approx(float(profile.challenge_multiplier), expected_challenge), "Level %03d owns its exact chapter challenge multiplier" % level)
		check(not str(profile.new_twist).is_empty(), "Level %03d explains its next learnable challenge" % level)
		if level > 1:
			check(float(profile.intensity) > float(previous.intensity), "Level %03d becomes measurably harder than the level before" % level)
			check(is_equal_approx(float(profile.intensity) - float(previous.intensity), 0.1), "Level %03d advances one exact chapter difficulty step" % level)
			check(int(profile.predator_count) >= int(previous.predator_count) and int(profile.predator_count) - int(previous.predator_count) <= 1, "Level %03d predator count changes gradually" % level)
			check(int(profile.whirlpool_count) >= int(previous.whirlpool_count) and int(profile.whirlpool_count) - int(previous.whirlpool_count) <= 1, "Level %03d current hazards change gradually" % level)
		previous = profile

	check(profiles.size() == 100 and signatures.size() == 100, "Campaign 1 contains 100 deterministic, distinct level profiles")
	check(chapters.size() == 10, "Campaign 1 contains ten chapters")
	for chapter in range(1, 11):
		check(int(chapters.get(chapter, 0)) == 10, "Campaign 1 chapter %02d contains ten levels" % chapter)
	check(int(profiles[0].predator_count) == 2 and int(profiles[0].whirlpool_count) == 0, "Level 1 begins with two readable patrols and no whirlpool")
	check(is_equal_approx(float(profiles[10].challenge_multiplier), 2.9), "Level 11 begins one full challenge step above Level 1")
	check(int(profiles[9].predator_count) == 2 and int(profiles[10].predator_count) == 3, "Level 11 adds the third readable predator at the chapter boundary")
	check(int(profiles[9].whirlpool_count) == 0 and int(profiles[10].whirlpool_count) == 1, "Level 11 adds the first telegraphed whirlpool challenge")
	check(int(profiles[99].predator_count) == 5 and int(profiles[99].whirlpool_count) == 3, "Level 100 reaches the bounded campaign challenge")
	check(float(profiles[99].intensity) > float(profiles[79].intensity), "the final twenty levels continue increasing")
	check(str(profiles[0].assist_mode) == "FULL" and str(profiles[99].assist_mode) == "HERO", "guidance tapers from full learning support to hero mastery")

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.countdown_enabled = false
	game.saver = FredSaveAdapter.new("user://campaign_one_test")
	game.leaderboard = FredLocalLeaderboard.new("user://campaign_one_board.json")
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var fairy_levels: Array[int] = []
	for level in range(1, 101):
		game.level_number = level
		game.fairy_collected = false
		if game._fairy_available():
			fairy_levels.append(level)
	check(fairy_levels == [10,20,30,40,50,60,70,80,90,100], "Campaign 1 offers one possible extra life on every tenth level")
	game.level_number = 100
	game.level_profile = FredLevelIntensity.profile(100)
	game.screen = Main.Screen.COMPLETE
	game.session.completed = true
	game._advance_level()
	check(game.screen == Main.Screen.TITLE and game.level_number == 1, "Campaign 1 ends after Level 100 instead of replaying Level 100")
	check(game.save_feedback.contains("CAMPAIGN 1 COMPLETE"), "Campaign 1 ending celebrates Fred as the little frogs' hero")

	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(source.contains("PG FAMILY ADVENTURE"), "the main screen identifies the PG family campaign")
	check(source.contains("touch_controls_visible := true"), "touch controls are the default presentation")
	check(not source.contains("Input.is_key_pressed"), "Campaign 1 has no direct keyboard movement path")
	for prohibited: String in ["BLOOD", "GORE", "KILL FRED"]:
		check(prohibited not in source.to_upper(), "PG presentation excludes graphic language: %s" % prohibited)
	var action_rects := Layout.touch_action_rects()
	for rect: Rect2 in [Rect2(action_rects.tongue), Rect2(action_rects.leap), Rect2(action_rects.boost), Rect2(action_rects.depth)]:
		check(rect.size.x >= 84.0 and rect.size.y >= 84.0, "circular action targets remain child-sized")
	for rect: Rect2 in [Layout.PAUSE_RECT, Layout.HOME_RECT]:
		check(rect.size.x >= 120.0 and rect.size.y >= 54.0, "top touch actions remain child-sized")

	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	for path: String in ["user://campaign_one_test.json", "user://campaign_one_test.backup.json", "user://campaign_one_test.tmp.json", "user://campaign_one_board.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESULT campaign_one_passed=%d campaign_one_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
