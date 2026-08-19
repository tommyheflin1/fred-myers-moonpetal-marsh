extends SceneTree

const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const MarshRouteLayout = preload("res://scripts/marsh_route_layout.gd")

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
	var leap := LeapTraversal.new()
	check(leap.state == LeapTraversal.State.GROUNDED, "leap starts grounded")
	check(leap.request(Vector2.RIGHT), "grounded leap request is accepted")
	check(not leap.request(Vector2.UP), "repeated airborne leap is rejected")
	var heights: Array[float] = []
	var distance := Vector2.ZERO
	var landed_count := 0
	for frame in range(44):
		var result := leap.advance(1.0 / 60.0)
		distance += Vector2(result.movement)
		heights.append(leap.visual_height)
		if bool(result.landed):
			landed_count += 1
	check(landed_count == 1, "deterministic arc emits exactly one landing")
	check(absf(distance.x - LeapTraversal.TRAVEL_SPEED * LeapTraversal.AIRBORNE_SECONDS) < 0.02, "leap distance is fixed-tick deterministic")
	check(heights.max() > 50.0 and heights[0] < heights.max(), "arc has a readable airborne apex")
	leap.advance(LeapTraversal.LANDING_SECONDS)
	check(leap.state == LeapTraversal.State.GROUNDED, "landing recovery returns to grounded")
	check(leap.request(Vector2.ZERO) and leap.direction == Vector2.RIGHT, "neutral intent gets deterministic forward fallback")
	leap.reset()
	check(leap.state == LeapTraversal.State.GROUNDED and leap.visual_height == 0.0, "reset clears transient traversal")

	var repeat_distance := Vector2.ZERO
	for scenario in range(20):
		var seeded := LeapTraversal.new()
		seeded.request(Vector2(3, 4))
		var scenario_distance := Vector2.ZERO
		for frame in range(44):
			scenario_distance += Vector2(seeded.advance(1.0 / 60.0).movement)
		if scenario == 0:
			repeat_distance = scenario_distance
		check(scenario_distance.is_equal_approx(repeat_distance), "seeded leap scenario %02d is repeatable" % (scenario + 1))

	var game: Node2D = load("res://scripts/main.gd").new()
	var prefix := "user://leap_traversal_test"
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix + suffix))
	game.saver = FredSaveAdapter.new(prefix)
	game.device_intent_adapter_enabled = true
	root.add_child(game)
	await process_frame
	game.screen = game.Screen.PLAYING
	game.hazards_enabled = false
	game.predator = Vector2(1200, 650)
	check(game._request_leap(Vector2.RIGHT), "game accepts explicit touch-ready leap intent")
	var airborne_elapsed: float = game.leap.elapsed
	game.session.paused = true
	game._process(0.25)
	check(game.leap.elapsed == airborne_elapsed, "pause freezes airborne simulation")
	game.session.paused = false
	check(not game._request_leap(Vector2.UP), "game rejects repeated input while airborne")
	check(game._is_valid_landing(game._pad_position(0)), "moving lily pad is a valid landing")
	check(game._is_valid_landing(game.SAFE_LOCATION), "safe island is a valid landing")
	check(not game._is_valid_landing(Vector2(600, 200)), "open water is distinguished from a perch")

	game.leap.reset()
	game.fred = Vector2(600, 200)
	var health_before: int = game.session.health
	var checkpoint_before: String = game.session.current_checkpoint
	check(game._resolve_landing(), "open-water landing continues the round")
	check(game.session.health == health_before and game.fred == Vector2(600, 200), "open-water landing never teleports Fred or costs a life")
	check(game.screen == game.Screen.PLAYING and game.countdown_seconds == 0.0, "open-water landing adds no restart countdown")
	check(game.session.current_checkpoint == checkpoint_before, "ordinary landing does not mutate checkpoint progress")
	check(game.save_feedback.contains("kept moving"), "open-water landing gives truthful continuation feedback")

	game.fred = Vector2(520, 320)
	game.predator = game.fred
	game.leap.reset()
	check(game._request_leap(Vector2.RIGHT), "Fred can launch while a surface predator is close")
	game.leap.advance(LeapTraversal.AIRBORNE_SECONDS * 0.5)
	var airborne_health: int = game.session.health
	check(game._leap_clears_predators(), "airborne leap explicitly clears surface predators")
	check(not game._check_danger_collision(), "airborne overlap passes over a predator without damage")
	check(game.session.health == airborne_health and game.screen == game.Screen.PLAYING, "predator clearance keeps the same round and lives")

	game.leap.reset()
	game.fred = Vector2(520, 320)
	game.predator = Vector2(588, 320)
	game.predator_direction = 0.0
	game.danger_cooldown_seconds = 0.0
	game.countdown_seconds = 0.0
	var route_health: int = game.session.health
	var route_checkpoint: String = game.session.current_checkpoint
	check(game._request_leap(Vector2.RIGHT), "touch-ready leap starts a real fixed-tick predator crossing")
	for frame in range(44):
		game._fixed_tick(1.0 / 60.0)
	check(game.fred.x > 650.0 and game.leap.state == LeapTraversal.State.LANDING, "full leap arc lands beyond the predator instead of returning to start")
	check(game.session.health == route_health and game.screen == game.Screen.PLAYING, "full predator crossing preserves the same round and life count")
	check(game.session.current_checkpoint == route_checkpoint and game.countdown_seconds == 0.0, "full predator crossing creates no checkpoint or countdown restart")

	game.leap.reset()
	game.predator = game.fred
	check(not game._leap_clears_predators(), "grounded Fred has no leap clearance")
	check(game._check_danger_collision(), "grounded predator contact remains dangerous")
	check(game.session.health == airborne_health - 1, "grounded predator contact still costs exactly one life")
	game.danger_cooldown_seconds = 0.0
	game.countdown_seconds = 0.0
	game.predator = Vector2(1200, 650)

	game.leap.reset()
	game.screen = game.Screen.PLAYING
	game.session.set_underwater(true)
	game.depth.reset("underwater")
	check(not game._request_leap(Vector2.RIGHT), "underwater state cannot launch a surface leap")
	game.session.set_underwater(false)
	game.depth.reset("surface")
	var synthetic := InputEventAction.new()
	synthetic.action = "leap"
	synthetic.pressed = true
	check(FredInputIntent.event_to_intent(synthetic) == FredInputIntent.Intent.LEAP, "synthetic controller/touch action maps to leap intent")
	game._unhandled_input(synthetic)
	check(game.leap.is_airborne(), "synthetic adapter event launches the same mechanic")

	game.leap.reset()
	game.device_intent_adapter_enabled = false
	game.touch_movement = Vector2.RIGHT
	game._handle_touch(7, Rect2(MarshRouteLayout.touch_action_rects().leap).get_center(), true)
	check(game.leap.is_airborne(), "screen-touch LEAP launches through the player control path")
	game._handle_touch(7, Rect2(MarshRouteLayout.touch_action_rects().leap).get_center(), false)
	game._apply_danger_hit("[DANGER] Test predator contact.")
	check(game.leap.state == LeapTraversal.State.GROUNDED and game.danger_cooldown_seconds == float(game.level_profile.mistake_grace_seconds), "predator contact cancels leap and preserves level-scaled cooldown")

	var save_snapshot: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	game.leap.request(Vector2.RIGHT)
	game.leap.advance(0.2)
	check(game.session.to_save("2000-01-01T00:00:00Z") == save_snapshot, "airborne state does not drift objectives or save data")
	check(not save_snapshot.has("leap") and not save_snapshot.has("airborne"), "save v1 contains no transient leap fields")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "stable checkpoint can save while traversal presentation is transient")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false) and restored.to_save("2000-01-01T00:00:00Z") == save_snapshot, "reload restores stable session without airborne state")
	game.reduced_motion = true
	check(game.leap.cue() == "AIRBORNE", "reduced motion retains an equivalent non-color airborne cue")
	game._fixed_tick(1.0 / 60.0)
	check(game.camera_response_y == 0.0, "reduced motion suppresses leap camera movement")

	game.leap.reset()
	game.screen = game.Screen.PLAYING
	game.session.health = 1
	game.leap.request(Vector2.RIGHT)
	game._apply_danger_hit("[DANGER] Test airborne failure.")
	check(game.screen == game.Screen.FAILED and game.leap.state == LeapTraversal.State.GROUNDED, "airborne predator failure clears traversal safely")
	game._retry()
	check(game.screen == game.Screen.PLAYING and game.session.health == 3, "retry restores stable grounded play")

	var started := Time.get_ticks_msec()
	for iteration in range(10000):
		var stress := LeapTraversal.new()
		stress.request(Vector2(1, 0))
		stress.advance(1.0 / 60.0)
	var elapsed_ms := Time.get_ticks_msec() - started
	check(elapsed_ms < 1000, "leap state calculation remains performance-bounded")
	print("MEASURE leap_iterations=10000 elapsed_ms=%d" % elapsed_ms)

	game.queue_free()
	await process_frame
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix + suffix))
	print("RESULT leap_traversal_passed=%d leap_traversal_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
