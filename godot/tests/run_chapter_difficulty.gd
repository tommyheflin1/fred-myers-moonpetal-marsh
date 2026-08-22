extends SceneTree

const Main = preload("res://scripts/main.gd")

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
	var level_one := FredLevelIntensity.profile(1)
	check(is_equal_approx(float(level_one.challenge_multiplier), 1.9), "Level 1 starts at the former Level 10 challenge baseline")
	check(float(level_one.current_strength) > 0.0, "Level 1 starts with an active readable current")
	check(int(level_one.predator_count) == 2 and int(level_one.whirlpool_count) == 0, "Level 1 starts with two readable predators and no whirlpool")

	var previous := level_one
	var profile_signatures: Dictionary = {}
	for chapter in range(1, 11):
		var start_level := (chapter - 1) * FredLevelIntensity.CHAPTER_SIZE + 1
		var chapter_start := FredLevelIntensity.profile(start_level)
		var chapter_end := FredLevelIntensity.profile(start_level + 9)
		var expected_chapter_start := 1.9 + float(chapter - 1)
		check(is_equal_approx(float(chapter_start.challenge_multiplier), expected_chapter_start), "Chapter %02d starts one full step above the prior chapter" % chapter)
		check(is_equal_approx(float(chapter_end.challenge_multiplier), expected_chapter_start + 0.9), "Chapter %02d finishes nine measured steps above its base" % chapter)
		for chapter_level in range(1, 11):
			var level := start_level + chapter_level - 1
			var profile := FredLevelIntensity.profile(level)
			var expected := 1.9 + float(level - 1) * 0.1
			profile_signatures[JSON.stringify(profile)] = true
			check(int(profile.chapter) == chapter and int(profile.chapter_level) == chapter_level, "Level %03d maps to chapter %02d step %d" % [level, chapter, chapter_level])
			check(is_equal_approx(float(profile.challenge_multiplier), expected), "Level %03d uses exact %.1fx challenge" % [level, expected])
			check(str(profile.challenge_label).contains("%.1fx" % expected), "Level %03d exposes its challenge multiplier to the HUD" % level)
			check(float(profile.predator_speed_scale) <= 1.27 and float(profile.bug_flight_speed) <= 0.90, "Level %03d stays inside the age-five movement cap" % level)
			check(float(profile.reaction_window_seconds) >= 1.50 and float(profile.mistake_grace_seconds) >= 1.90, "Level %03d preserves child-readable reaction and recovery time" % level)
			check(float(profile.safe_radius) >= 50.0 and float(profile.danger_radius) <= 46.0, "Level %03d preserves fair safe and danger geometry" % level)
			check(int(profile.predator_count) == mini(5, chapter + 1), "Level %03d applies the stronger bounded chapter predator count" % level)
			var expected_whirlpools := 0 if chapter == 1 else mini(3, 1 + ((chapter - 2) / 3))
			check(int(profile.whirlpool_count) == expected_whirlpools, "Level %03d applies the telegraphed chapter whirlpool count" % level)
			if level > 1:
				check(is_equal_approx(float(profile.challenge_multiplier) - float(previous.challenge_multiplier), 0.1), "Level %03d increases exactly one tenth over the previous level" % level)
				check(float(profile.predator_speed_scale) > float(previous.predator_speed_scale), "Level %03d makes the predator measurably faster" % level)
				check(float(profile.lily_drift) > float(previous.lily_drift), "Level %03d increases lily movement" % level)
				check(float(profile.bug_flight_radius) > float(previous.bug_flight_radius), "Level %03d increases bug movement range" % level)
				check(float(profile.bug_flight_speed) > float(previous.bug_flight_speed), "Level %03d increases bug movement speed" % level)
				check(float(profile.reaction_window_seconds) < float(previous.reaction_window_seconds), "Level %03d tightens reaction timing without removing grace" % level)
			previous = profile

	check(profile_signatures.size() == 100, "all 100 levels have distinct deterministic difficulty profiles")
	check(is_equal_approx(float(FredLevelIntensity.profile(10).challenge_multiplier), 2.8), "Level 10 completes the stronger 1.9x to 2.8x ramp")
	check(is_equal_approx(float(FredLevelIntensity.profile(11).challenge_multiplier), 2.9), "Level 11 starts the second chapter at exactly 2.9x")
	check(is_equal_approx(float(FredLevelIntensity.profile(20).challenge_multiplier), 3.8), "Level 20 completes the 2.9x to 3.8x ramp")
	check(is_equal_approx(float(FredLevelIntensity.profile(21).challenge_multiplier), 3.9), "Level 21 starts the third chapter at exactly 3.9x")
	check(is_equal_approx(float(FredLevelIntensity.profile(100).challenge_multiplier), 11.8), "Level 100 reaches the final bounded 11.8x challenge step")
	check(float(FredLevelIntensity.profile(2).current_strength) > float(level_one.current_strength), "Level 2 strengthens the opening current")
	check(not bool(FredLevelIntensity.profile(2).weaving_patrol) and bool(FredLevelIntensity.profile(3).weaving_patrol), "Level 3 introduces readable predator weaving")
	check(not bool(FredLevelIntensity.profile(7).reversing_current) and bool(FredLevelIntensity.profile(8).reversing_current), "Level 8 introduces the reversing-current pattern")
	check(int(FredLevelIntensity.profile(10).predator_count) == 2 and int(FredLevelIntensity.profile(11).predator_count) == 3, "Level 11 visibly adds a third predator")
	check(int(FredLevelIntensity.profile(10).whirlpool_count) == 0 and int(FredLevelIntensity.profile(11).whirlpool_count) == 1, "Level 11 visibly adds the first whirlpool")
	var even_start := FredMarshRouteLayout.start_point(Main.START, 10)
	var even_start_bounds := Rect2(even_start - Vector2(42.0,42.0), Vector2(84.0,84.0))
	check(not FredMarshRouteLayout.TOUCH_CONTROL_PAD_RECT.intersects(even_start_bounds), "Level 10 starts Fred clear of the right movement pad")

	var reference_trace := ""
	for level in [1, 5, 10, 11, 15, 20, 21, 50, 100]:
		reference_trace += JSON.stringify(FredLevelIntensity.profile(level))
	for repetition in range(100):
		var trace := ""
		for level in [1, 5, 10, 11, 15, 20, 21, 50, 100]:
			trace += JSON.stringify(FredLevelIntensity.profile(level))
		check(trace == reference_trace, "difficulty trace repetition %03d is byte-stable" % (repetition + 1))

	var started_usec := Time.get_ticks_usec()
	var aggregate := 0.0
	for index in range(10000):
		aggregate += float(FredLevelIntensity.profile((index % 100) + 1).challenge_multiplier)
	var elapsed_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0
	check(aggregate > 0.0 and elapsed_ms < 2500.0, "10,000 difficulty calculations stay inside the local performance budget")

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.countdown_enabled = false
	game.hazards_enabled = true
	game.saver = FredSaveAdapter.new("user://chapter_difficulty_test")
	game.leaderboard = FredLocalLeaderboard.new("user://chapter_difficulty_board.json")
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for level in [1, 10, 11, 20, 21, 40, 41, 100]:
		game.level_number = level
		game.level_profile = FredLevelIntensity.profile(level)
		game._update_secondary_predators()
		check(game._active_predator_positions().size() == int(game.level_profile.predator_count), "Level %03d runtime activates the authored predator count" % level)
	check(game.session.to_save("2000-01-01T00:00:00Z").has("schema_version"), "difficulty integration preserves the canonical save contract")
	check(not game.session.to_save("2000-01-01T00:00:00Z").has("challenge_multiplier"), "transient difficulty state remains outside fred_save v1")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("float(level_profile.challenge_multiplier)"), "gameplay HUD renders the exact level multiplier")
	game.queue_free()
	await process_frame
	for path: String in ["user://chapter_difficulty_test.json", "user://chapter_difficulty_test.backup.json", "user://chapter_difficulty_test.tmp.json", "user://chapter_difficulty_board.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	print("RESULT chapter_difficulty_passed=%d chapter_difficulty_failed=%d elapsed_ms=%.3f" % [passed, failed, elapsed_ms])
	quit(1 if failed else 0)
