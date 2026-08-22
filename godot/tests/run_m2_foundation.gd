extends SceneTree

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
	_run()

func _run() -> void:
	var previous := FredLevelIntensity.profile(1)
	check(previous.level == 1 and previous.chapter == 1, "level one starts in chapter one")
	check(previous.campaign_id == "campaign_1" and previous.campaign_name == "Campaign 1: The Moonpetal Promise", "all levels belong to the named Campaign 1")
	check(previous.content_rating == "PG" and previous.target_min_age == 5, "Campaign 1 declares its PG age-five design target")
	check(FredLevelIntensity.profile(0) == previous, "levels below one clamp safely")
	check(FredLevelIntensity.profile(101) == FredLevelIntensity.profile(100), "levels above 100 clamp safely")
	for level in range(2, 101):
		var current := FredLevelIntensity.profile(level)
		check(float(current.intensity) > float(previous.intensity), "level %03d never repeats or reduces intensity" % level)
		check(is_equal_approx(float(current.intensity) - float(previous.intensity), 0.1), "level %03d advances one bounded chapter step" % level)
		check(float(current.predator_speed_scale) >= float(previous.predator_speed_scale), "level %03d predator pressure is monotonic" % level)
		check(float(current.reaction_window_seconds) <= float(previous.reaction_window_seconds), "level %03d reaction window is monotonic" % level)
		check(int(current.difficulty_step) == level, "level %03d owns one explicit progressive difficulty step" % level)
		check(current == FredLevelIntensity.profile(level), "level %03d profile is deterministic" % level)
		previous = current
	check(float(FredLevelIntensity.profile(100).intensity) > float(FredLevelIntensity.profile(80).intensity), "final twenty levels retain increasing intensity")
	check(is_equal_approx(float(FredLevelIntensity.profile(11).intensity) - float(FredLevelIntensity.profile(1).intensity), 1.0), "level eleven begins one full challenge step above level one")
	check(is_equal_approx(float(FredLevelIntensity.profile(100).intensity), 11.8), "level 100 reaches the final stronger campaign multiplier")
	check(FredLevelIntensity.profile(100).label == "Moonpetal Mastery", "level 100 has mastery identity")
	check(float(FredLevelIntensity.profile(100).reaction_window_seconds) >= 1.35, "even Level 100 preserves a readable reaction window")
	check(float(FredLevelIntensity.profile(100).mistake_grace_seconds) >= 1.8, "even Level 100 preserves recovery grace")
	check(float(FredLevelIntensity.profile(100).safe_radius) >= 50.0, "even Level 100 preserves a child-readable safe island")
	for level in range(1, 101):
		var twist := str(FredLevelIntensity.profile(level).new_twist)
		check(not twist.is_empty(), "level %03d declares a complexity twist" % level)
	check(FredLevelIntensity.profile(2).new_twist == "Follow the first drifting lily", "level two introduces its first visible movement challenge")
	check(not FredLevelIntensity.profile(2).weaving_patrol and FredLevelIntensity.profile(3).weaving_patrol, "the readable patrol weave begins on level three")
	check(not FredLevelIntensity.profile(7).reversing_current and FredLevelIntensity.profile(8).reversing_current, "reversing flow begins on level eight after current practice")
	check(float(FredLevelIntensity.profile(6).danger_radius) > float(FredLevelIntensity.profile(5).danger_radius), "level six widens danger reach")
	check(int(FredLevelIntensity.profile(1).predator_count) == 2, "level one starts with two readable predators")
	check(int(FredLevelIntensity.profile(10).whirlpool_count) == 0 and int(FredLevelIntensity.profile(11).whirlpool_count) == 1, "whirlpools wait until the child completes the first chapter")
	check(int(FredLevelIntensity.profile(100).predator_count) == 5, "late levels reach five active predators")
	check(int(FredLevelIntensity.profile(100).whirlpool_count) == 3, "late levels combine three whirlpools")
	check(float(FredLevelIntensity.profile(100).lily_drift) > float(FredLevelIntensity.profile(1).lily_drift), "lily drift grows progressively")
	check(float(FredLevelIntensity.profile(100).bug_flight_radius) > float(FredLevelIntensity.profile(1).bug_flight_radius), "bug flight range grows progressively")
	check(float(FredLevelIntensity.profile(100).bug_flight_speed) > float(FredLevelIntensity.profile(1).bug_flight_speed), "bug flight speed grows progressively")

	var identity := FredPlayerIdentity.new()
	check(identity.state == FredPlayerIdentity.State.GUEST, "identity starts guest-first")
	check(identity.status_message().contains("Play now"), "guest play is immediately available")
	check(not identity.begin_link(false), "linking requires consent")
	check(identity.offer(FredPlayerIdentity.Provider.APPLE_GAME_CENTER), "Game Center can be offered")
	check(identity.begin_link(true), "consented platform link begins")
	check(identity.complete_link("fictional_player_001", "Lily Friend"), "opaque fictional profile links")
	check(identity.state == FredPlayerIdentity.State.LINKED, "identity reaches linked state")
	var preferences := identity.to_local_preferences()
	check(not preferences.has("password") and not preferences.has("token"), "local preferences exclude credentials")
	check(preferences.opaque_profile_id == "fictional_player_001", "only opaque profile id persists")
	identity.unlink_local()
	check(identity.state == FredPlayerIdentity.State.GUEST and identity.opaque_profile_id.is_empty(), "unlink clears local identity")
	check(identity.offer(FredPlayerIdentity.Provider.SIGN_IN_WITH_APPLE), "Sign in with Apple can be offered")
	check(identity.begin_link(true), "Apple account link begins with consent")
	check(not identity.complete_link("../unsafe", "Unsafe"), "unsafe profile id is rejected")
	check(identity.state == FredPlayerIdentity.State.ERROR, "invalid response enters recoverable error")
	check(identity.status_message().contains("local progress is safe"), "identity error protects offline confidence")
	identity.continue_offline()
	check(identity.state == FredPlayerIdentity.State.OFFLINE, "account setup remains skippable")

	var game: Node2D = load("res://scripts/main.gd").new()
	game.audio_enabled = false
	game.countdown_enabled = false
	game.saver = FredSaveAdapter.new("user://m2_progression_test")
	root.add_child(game)
	await process_frame
	game.screen = game.Screen.COMPLETE
	game._advance_level()
	check(game.level_number == 2 and game.screen == game.Screen.PLAYING, "completion flow enters level two without title")
	check(float(game.level_profile.intensity) >= float(FredLevelIntensity.profile(1).intensity), "level two applies its increased intensity")
	game.level_number = 4
	game.level_profile = FredLevelIntensity.profile(4)
	game.visual_time = 1.0
	check(game._current_vector().x < 0.0, "level four gently introduces current on its deterministic right-to-left route")
	game.level_number = 2
	game.level_profile = FredLevelIntensity.profile(2)
	game._advance_level()
	check(game.level_number == 3 and game.level_profile.weaving_patrol, "level three activates the first readable patrol weave")
	game.level_number = 11
	game.level_profile = FredLevelIntensity.profile(11)
	check(game.direct_route_has_danger(), "later routes add a telegraphed current hazard")
	game.level_number = 1
	game.level_profile = FredLevelIntensity.profile(1)
	game._update_secondary_predators()
	check(game._active_predator_positions().size() == 2, "level one activates two readable predator patrols")
	var pad_one_start: Vector2 = game._pad_position(0)
	var bug_one_start: Vector2 = game._bug_position(0)
	game.simulation_time = 3.0
	check(game._pad_position(0) != pad_one_start, "lily pads drift during gameplay")
	check(game._bug_position(0) != bug_one_start, "bugs fly during gameplay")
	var level_one_pad: Vector2 = game._pad_position(2)
	game.level_number = 12
	game.level_profile = FredLevelIntensity.profile(12)
	check(game._pad_position(2) != level_one_pad, "lily route layout changes by level")
	check(game._pad_position(2).x >= 100.0 and game._pad_position(2).x <= 1135.0, "moving lily pad remains inside safe bounds")
	check(game._bug_position(2).y >= 130.0 and game._bug_position(2).y <= 620.0, "moving bug remains inside safe bounds")
	game.level_number = 1
	game.level_profile = FredLevelIntensity.profile(1)
	game.session = AdventureSession.new(1337)
	game.level_number = 17
	game.level_profile = FredLevelIntensity.profile(17)
	game.fred = game._whirlpool_position(0)
	var health_before: int = game.session.health
	game._fixed_tick(0.0)
	check(game.session.health == health_before - 1 and game.fred == game._level_start_position(), "whirlpool costs one heart and returns Fred safely")
	check(game.impact_burst_seconds > 0.0 and game.impact_burst_kind == "CURRENT BURST", "whirlpool triggers a visible current burst")
	var impact_save_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	game._advance_visual(0.2)
	check(game.impact_burst_seconds < 0.62, "impact burst advances and expires visually")
	check(game.session.to_save("2000-01-01T00:00:00Z") == impact_save_before, "impact burst cannot mutate save state")
	game._fixed_tick(0.0)
	check(game.session.health == health_before - 1, "danger cooldown prevents repeated unavoidable damage")
	game.eat_target = Vector2(200, 200)
	game.eat_effect_seconds = 0.32
	var save_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	game._advance_visual(0.1)
	check(game.eat_effect_seconds < 0.32, "eating animation advances visibly")
	check(game.session.to_save("2000-01-01T00:00:00Z") == save_before, "eating animation cannot mutate gameplay or save state")
	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame

	print("RESULT m2_foundation_passed=%d m2_foundation_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
