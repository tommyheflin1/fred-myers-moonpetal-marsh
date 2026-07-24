extends SceneTree

const DepthTraversal = preload("res://scripts/depth_traversal.gd")

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
	var depth := DepthTraversal.new()
	check(depth.state == DepthTraversal.State.SURFACE and depth.depth == 0.0, "depth starts at the surface ceiling")
	check(not depth.request_dive(false), "invalid entry rejects dive")
	check(depth.request_dive(true), "valid entry starts dive")
	check(not depth.request_dive(true), "repeated dive input is rejected during transition")
	var halfway := depth.advance(DepthTraversal.TRANSITION_SECONDS * 0.5)
	check(not halfway.completed and is_equal_approx(depth.depth, 0.5), "dive exposes deterministic intermediate depth")
	check(depth.depth >= 0.0 and depth.depth <= 1.0, "intermediate dive remains depth-bounded")
	var dive_complete := depth.advance(DepthTraversal.TRANSITION_SECONDS * 0.5)
	check(dive_complete.completed and depth.state == DepthTraversal.State.UNDERWATER, "dive completes in underwater band")
	check(is_equal_approx(depth.movement_scale(), DepthTraversal.UNDERWATER_SPEED_SCALE), "underwater steering uses authored speed scale")
	check(not depth.request_dive(true), "underwater repeated dive remains locked")
	check(depth.request_surface(), "underwater state starts surfacing")
	check(not depth.request_surface(), "repeated surface input is rejected")
	depth.advance(DepthTraversal.TRANSITION_SECONDS)
	check(depth.state == DepthTraversal.State.SURFACE and depth.depth == 0.0, "surface transition returns to ceiling")
	depth.reset("underwater")
	check(depth.state == DepthTraversal.State.UNDERWATER and depth.depth == 1.0, "canonical underwater reset reaches floor")
	depth.reset("surface")
	check(depth.cue() == "SURFACE", "surface retains explicit non-color cue")

	var repeated_depth := 0.0
	for scenario in range(20):
		var seeded := DepthTraversal.new()
		seeded.request_dive(true)
		for frame in range(48):
			seeded.advance(1.0 / 60.0)
		if scenario == 0:
			repeated_depth = seeded.depth
		check(is_equal_approx(seeded.depth, repeated_depth), "depth scenario %02d is repeatable" % (scenario + 1))

	var prefix := "user://depth_traversal_test"
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix + suffix))
	var game: Node2D = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(prefix)
	root.add_child(game)
	await process_frame
	game.screen = game.Screen.PLAYING
	game.hazards_enabled = false
	game.predator = Vector2(1200, 650)

	game.fred = game.START
	check(not game._request_dive(), "shore perch blocks invalid dive entry")
	check(game.save_feedback.begins_with("[DIVE BLOCKED]"), "invalid entry has readable non-color feedback")
	game.fred = Vector2(550, 300)
	check(game._request_dive(), "open water accepts dive")
	var paused_elapsed: float = game.depth.elapsed
	game.session.paused = true
	game._process(0.25)
	check(game.depth.elapsed == paused_elapsed, "pause freezes depth transition")
	game.session.paused = false
	check(not game._request_dive(), "game rejects repeated dive during descent")
	for frame in range(48): game._fixed_tick(1.0 / 60.0)
	check(game.depth.state == DepthTraversal.State.UNDERWATER and game.session.player_state == "underwater", "game reaches canonical underwater state")

	var before_move: Vector2 = game.fred
	Input.action_press("move_right")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	var underwater_distance: float = game.fred.x - before_move.x
	check(underwater_distance > 0.0 and underwater_distance < 210.0 / 60.0, "underwater steering is slower but controllable")
	var energy_before: int = game.session.boost_energy
	Input.action_press("boost")
	Input.action_press("move_right")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("boost")
	check(game.session.boost_energy == energy_before - 1, "underwater boost consumes existing energy")

	check(not game._request_leap(Vector2.RIGHT), "underwater depth takes precedence over leap")
	check(game._request_surface(), "underwater game begins surfacing")
	check(not game._request_surface(), "surface request remains locked during ascent")
	for frame in range(48): game._fixed_tick(1.0 / 60.0)
	check(game.depth.state == DepthTraversal.State.SURFACE and game.session.player_state == "surface", "game completes surfacing canonically")

	game.leap.request(Vector2.RIGHT)
	check(not game._request_dive(), "active leap takes precedence over dive")
	game.leap.reset()
	var synthetic_dive := InputEventAction.new()
	synthetic_dive.action = "dive"
	synthetic_dive.pressed = true
	game.fred = Vector2(550, 300)
	check(FredInputIntent.event_to_intent(synthetic_dive) == FredInputIntent.Intent.DIVE, "synthetic adapter maps dive intent")
	game._unhandled_input(synthetic_dive)
	check(game.depth.state == DepthTraversal.State.DIVING, "synthetic adapter starts shared dive mechanic")

	var objective_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "transition saves stable canonical session")
	var restored_surface := AdventureSession.new(1337)
	check(game.saver.load_session(restored_surface).get("ok", false) and restored_surface.player_state == "surface", "reload during descent restores stable surface mode")
	for frame in range(48): game._fixed_tick(1.0 / 60.0)
	check(game.session.player_state == "underwater", "descent completes after stable transition save")
	check(game.saver.save(game.session, "2000-01-01T00:00:01Z").get("ok", false), "completed underwater mode saves through schema v1")
	var restored_underwater := AdventureSession.new(1337)
	check(game.saver.load_session(restored_underwater).get("ok", false) and restored_underwater.player_state == "underwater", "reload after transition restores canonical underwater mode")
	check(game.session.bug_count == int(objective_before.bugs_collected), "depth transition does not drift objectives")
	check(not objective_before.has("depth") and not objective_before.has("depth_state"), "save v1 excludes transient depth fields")

	game.reduced_motion = true
	game.camera_response_y = 4.0
	game._fixed_tick(1.0 / 60.0)
	check(game.camera_response_y == 0.0, "reduced motion removes depth camera response")
	check(not game.depth.cue().is_empty(), "reduced motion retains explicit depth cue")

	game.session.health = 2
	game._apply_danger_hit("[DANGER] Test underwater predator.")
	check(game.depth.state == DepthTraversal.State.SURFACE and game.session.player_state == "surface", "predator recovery resets canonical safe surface")
	check(game.danger_cooldown_seconds == 1.0 and game.session.health == 1, "underwater predator preserves damage cooldown")
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.session.health = 1
	game._apply_danger_hit("[DANGER] Test underwater failure.")
	check(game.screen == game.Screen.FAILED and game.depth.state == DepthTraversal.State.SURFACE, "underwater failure clears transition state")
	game._retry()
	check(game.screen == game.Screen.PLAYING and game.session.health == 3 and game.depth.state == DepthTraversal.State.SURFACE, "retry restores safe surface traversal")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started := Time.get_ticks_msec()
	for iteration in range(10000):
		var stress := DepthTraversal.new()
		stress.request_dive(true)
		stress.advance(0.4)
		stress.advance(0.4)
		stress.request_surface()
		stress.advance(0.8)
	var elapsed_ms := Time.get_ticks_msec() - started
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 1200, "10,000 depth cycles remain time-bounded")
	check(memory_growth < 2 * 1024 * 1024, "10,000 depth cycles remain memory-bounded")
	print("MEASURE depth_cycles=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed_ms, memory_growth])

	game.queue_free()
	await process_frame
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix + suffix))
	print("RESULT depth_traversal_passed=%d depth_traversal_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
