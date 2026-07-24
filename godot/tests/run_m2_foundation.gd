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
	check(FredLevelIntensity.profile(0) == previous, "levels below one clamp safely")
	check(FredLevelIntensity.profile(101) == FredLevelIntensity.profile(100), "levels above 100 clamp safely")
	for level in range(2, 101):
		var current := FredLevelIntensity.profile(level)
		check(float(current.intensity) >= float(previous.intensity), "level %03d never reduces intensity" % level)
		check(float(current.intensity) - float(previous.intensity) <= 0.02, "level %03d increase remains bounded" % level)
		check(float(current.predator_speed_scale) >= float(previous.predator_speed_scale), "level %03d predator pressure is monotonic" % level)
		check(float(current.reaction_window_seconds) <= float(previous.reaction_window_seconds), "level %03d reaction window is monotonic" % level)
		check(current == FredLevelIntensity.profile(level), "level %03d profile is deterministic" % level)
		previous = current
	check(float(FredLevelIntensity.profile(100).intensity) > float(FredLevelIntensity.profile(80).intensity), "final twenty levels retain increasing intensity")
	check(float(FredLevelIntensity.profile(100).intensity) >= 2.0, "level 100 reaches the stronger approved intensity")
	check(FredLevelIntensity.profile(100).label == "Moonpetal Mastery", "level 100 has mastery identity")
	for level in range(1, 101):
		var twist := str(FredLevelIntensity.profile(level).new_twist)
		check(not twist.is_empty(), "level %03d declares a complexity twist" % level)
	check(FredLevelIntensity.profile(2).new_twist == "Marsh current", "level two introduces the current")
	check(FredLevelIntensity.profile(3).weaving_patrol, "level three introduces weaving patrol")
	check(FredLevelIntensity.profile(4).reversing_current, "level four introduces reversing flow")
	check(float(FredLevelIntensity.profile(6).danger_radius) > float(FredLevelIntensity.profile(5).danger_radius), "level six widens danger reach")
	check(int(FredLevelIntensity.profile(1).predator_count) == 2, "level one starts with multiple predators")
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
	game.countdown_enabled = false
	game.saver = FredSaveAdapter.new("user://m2_progression_test")
	root.add_child(game)
	await process_frame
	game.screen = game.Screen.COMPLETE
	game._advance_level()
	check(game.level_number == 2 and game.screen == game.Screen.PLAYING, "completion flow enters level two without title")
	check(float(game.level_profile.intensity) >= float(FredLevelIntensity.profile(1).intensity), "level two applies its increased intensity")
	game.visual_time = 1.0
	check(game._current_vector().x > 0.0, "level two current applies deterministic pressure")
	game._advance_level()
	check(game.level_number == 3 and game.level_profile.weaving_patrol, "level three adds weaving patrol complexity")
	check(game.direct_route_has_danger(), "straight-line route intersects a telegraphed hazard")
	game.level_number = 1
	game.level_profile = FredLevelIntensity.profile(1)
	game._update_secondary_predators()
	check(game._active_predator_positions().size() == 2, "level one activates bass and pike")
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
	game.fred = game.WHIRLPOOLS[0]
	var health_before: int = game.session.health
	game._fixed_tick(0.0)
	check(game.session.health == health_before - 1 and game.fred == game.START, "whirlpool costs one heart and returns Fred safely")
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
	game.queue_free()

	print("RESULT m2_foundation_passed=%d m2_foundation_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
