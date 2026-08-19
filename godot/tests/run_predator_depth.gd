extends SceneTree

const Main = preload("res://scripts/main.gd")
const PredatorDepth = preload("res://scripts/predator_depth.gd")
const MarshRouteLayout = preload("res://scripts/marsh_route_layout.gd")

const SAVE_PREFIX := "user://predator_depth_test"

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
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	clean_files()
	check(PredatorDepth.naturally_submerges("BASS"), "bass naturally uses surface and underwater bands")
	check(PredatorDepth.naturally_submerges("PIKE"), "pike naturally uses surface and underwater bands")
	check(PredatorDepth.naturally_submerges("MUSKIE"), "muskie naturally uses surface and underwater bands")
	check(PredatorDepth.naturally_submerges("SNAKE"), "marsh snake naturally uses surface and underwater bands")
	check(not PredatorDepth.naturally_submerges("HERON"), "heron correctly remains above water")

	var surface := PredatorDepth.snapshot("BASS", 0, 1, 0.0)
	var diving := PredatorDepth.snapshot("BASS", 0, 1, PredatorDepth.SURFACE_HOLD_SECONDS + PredatorDepth.DIVE_SECONDS * 0.5)
	var underwater := PredatorDepth.snapshot("BASS", 0, 1, PredatorDepth.UNDERWATER_START_SECONDS + 0.4)
	var surfacing := PredatorDepth.snapshot("BASS", 0, 1, PredatorDepth.SURFACING_START_SECONDS + PredatorDepth.SURFACE_SECONDS * 0.5)
	check(int(surface.state) == PredatorDepth.State.SURFACE and float(surface.depth) == 0.0, "fish begins with a readable surface patrol")
	check(int(diving.state) == PredatorDepth.State.DIVING and float(diving.depth) > 0.0 and float(diving.depth) < 1.0, "fish has an explicit dive transition")
	check(int(underwater.state) == PredatorDepth.State.UNDERWATER and float(underwater.depth) == 1.0, "fish reaches the full underwater band")
	check(int(surfacing.state) == PredatorDepth.State.SURFACING and float(surfacing.depth) > 0.0 and float(surfacing.depth) < 1.0, "fish has an explicit surface transition")
	var snake_underwater := PredatorDepth.snapshot("SNAKE", 0, 1, PredatorDepth.UNDERWATER_START_SECONDS + 0.4)
	check(int(snake_underwater.state) == PredatorDepth.State.UNDERWATER and is_equal_approx(float(snake_underwater.depth), 0.78), "snake uses a shallower but collidable underwater band")
	var heron := PredatorDepth.snapshot("HERON", 2, 50, 999.0)
	check(int(heron.state) == PredatorDepth.State.ABOVE_WATER and float(heron.depth) == 0.0, "heron never receives a fictional underwater state")

	check(PredatorDepth.shares_depth(0.0, surface), "surface Fred shares danger depth with a surface fish")
	check(not PredatorDepth.shares_depth(1.0, surface), "underwater Fred can safely pass beneath a surface fish")
	check(not PredatorDepth.shares_depth(0.0, underwater), "surface Fred is safe above an underwater fish")
	check(PredatorDepth.shares_depth(1.0, underwater), "underwater Fred shares danger depth with an underwater fish")
	check(PredatorDepth.shares_depth(1.0, snake_underwater), "underwater snake remains a real underwater threat")
	check(PredatorDepth.shares_depth(0.0, heron) and not PredatorDepth.shares_depth(1.0, heron), "Fred can dive beneath the above-water heron")

	var reference_hash := 0
	for trace in range(100):
		var trace_hash := 0
		for tick in range(480):
			for predator_index in range(Main.PREDATOR_SPECIES.size()):
				var sample := PredatorDepth.snapshot(Main.PREDATOR_SPECIES[predator_index], predator_index, 37, float(tick) / 60.0)
				trace_hash = hash([trace_hash, int(sample.state), snappedf(float(sample.depth), 0.0001), str(sample.cue)])
		if trace == 0:
			reference_hash = trace_hash
		check(trace_hash == reference_hash, "predator depth trace %03d is fixed-tick deterministic" % (trace + 1))

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.countdown_enabled = false
	game.hazards_enabled = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.screen = game.Screen.PLAYING
	game.level_number = 1
	game.level_profile = FredLevelIntensity.profile(1)
	game.secondary_predators.assign([Vector2(1100,650), Vector2(1100,650), Vector2(1100,650), Vector2(1100,650)])
	game.in_safe_location = false
	check(game._predator_label_offset(Vector2(600,520)).y < 0.0 and game._predator_label_offset(Vector2(600,300)).y > 0.0, "low predator depth labels move above the bottom status panel")
	var phase_before_pause: Dictionary = game._predator_depth_snapshot(0)
	game.session.paused = true
	game._process(0.75)
	check(game._predator_depth_snapshot(0) == phase_before_pause, "pause freezes every predator depth phase")
	game.session.paused = false

	game.simulation_time = 0.0
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.session.health = 3
	game.fred = Vector2(600,300)
	game.predator = game.fred
	check(not game._predator_can_hit(0), "integrated surface bass cannot hit underwater Fred")
	check(not game._check_danger_collision() and game.session.health == 3, "passing under a surface predator preserves every life")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	check(game._predator_can_hit(0), "integrated surface bass can threaten surface Fred")
	check(game._check_danger_collision() and game.session.health == 2, "same-depth surface contact applies one normal predator hit")

	game.danger_cooldown_seconds = 0.0
	game.session.health = 3
	game.simulation_time = PredatorDepth.UNDERWATER_START_SECONDS + 0.4
	game.fred = Vector2(600,300)
	game.predator = game.fred
	game.depth.reset("surface")
	game.session.set_underwater(false)
	check(not game._predator_can_hit(0), "integrated underwater bass cannot hit surface Fred")
	check(not game._check_danger_collision() and game.session.health == 3, "staying above an underwater predator preserves every life")

	game.depth.reset("underwater")
	game.session.set_underwater(true)
	check(game._predator_can_hit(0), "integrated underwater bass can threaten underwater Fred")
	check(game._check_danger_collision() and game.session.health == 2, "same-depth underwater contact applies one normal predator hit")
	check(game.depth.state == game.depth.State.SURFACE and game.session.player_state == "surface", "underwater predator recovery returns Fred to the canonical safe surface")

	game.predator = Vector2(1150,650)
	game.fred = Vector2(600,300)
	game.simulation_time = 0.0
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.danger_cooldown_seconds = 0.0
	game._handle_touch(71, Rect2(MarshRouteLayout.touch_action_rects().depth).get_center(), true)
	game._handle_touch(71, Rect2(MarshRouteLayout.touch_action_rects().depth).get_center(), false)
	check(game.depth.state == game.depth.State.DIVING, "phone/tablet Dive button starts Fred's canonical descent")
	for frame in range(48):
		game._fixed_tick(1.0 / 60.0)
	check(game.depth.state == game.depth.State.UNDERWATER and game.session.player_state == "underwater", "touch-driven Fred reaches the underwater band")
	game.predator = game.fred
	check(not game._check_danger_collision(), "touch-driven underwater Fred passes beneath the surface bass")

	game.simulation_time = 12.5
	var save_snapshot: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not save_snapshot.has("predator_depth") and not save_snapshot.has("predator_phase"), "save v1 excludes transient predator depth state")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "stable session still saves with predator depth active")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false) and restored.to_save("2000-01-01T00:00:00Z") == save_snapshot, "reload preserves canonical gameplay without transient predator depth")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started := Time.get_ticks_msec()
	var stress_hash := 0
	for iteration in range(10000):
		var stress := PredatorDepth.snapshot(Main.PREDATOR_SPECIES[iteration % Main.PREDATOR_SPECIES.size()], iteration % 5, 1 + iteration % 100, float(iteration) / 60.0)
		stress_hash = hash([stress_hash, int(stress.state), snappedf(float(stress.depth), 0.0001)])
	var elapsed_ms := Time.get_ticks_msec() - started
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 1500, "10,000 predator depth updates remain time-bounded")
	check(memory_growth < 2 * 1024 * 1024, "10,000 predator depth updates remain memory-bounded")
	check(stress_hash != 0, "predator depth stress loop produces a stable observation")
	print("MEASURE predator_depth_updates=10000 elapsed_ms=%d memory_growth_bytes=%d hash=%d" % [elapsed_ms, memory_growth, stress_hash])

	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT predator_depth_passed=%d predator_depth_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
