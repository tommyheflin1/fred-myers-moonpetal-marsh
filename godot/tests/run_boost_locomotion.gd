extends SceneTree

const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const Main = preload("res://scripts/main.gd")
const SAVE_PREFIX := "user://boost_locomotion_test"

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
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))

func _init() -> void:
	_run.call_deferred()

func _trace() -> String:
	var model := BoostLocomotion.new()
	var energy := 100
	var states: Array[String] = []
	for tick in range(240):
		var held := (tick >= 5 and tick < 80) or (tick >= 145 and tick < 195)
		var moving := tick % 37 != 0
		var allowed := tick < 52 or tick >= 58
		var result: Dictionary = model.advance(held, moving, allowed, energy)
		energy = int(result.energy)
		states.append("%d:%d:%d:%d" % [tick, energy, int(result.state), int(bool(result.active))])
	return "|".join(states)

func _run() -> void:
	clean_files()
	var boost := BoostLocomotion.new()
	var idle: Dictionary = boost.advance(false, false, true, 100)
	check(int(idle.energy) == 100 and boost.state == BoostLocomotion.State.READY, "boost starts full and ready")
	check(boost.cue() == "BOOST READY", "ready state has a non-color cue")
	check(BoostLocomotion.START_THRESHOLD == 15, "boost threshold is explicit at fifteen percent")
	check(not bool(boost.advance(true, false, true, 100).active), "boost requires movement")
	check(not bool(boost.advance(true, true, false, 100).active), "blocked traversal cannot start boost")

	var started: Dictionary = boost.advance(true, true, true, 100)
	check(bool(started.active) and boost.state == BoostLocomotion.State.BURST, "eligible press starts the burst")
	check(int(started.energy) == 99, "activation costs exactly one energy")
	check(is_equal_approx(float(started.speed_multiplier), BoostLocomotion.BURST_SPEED_MULTIPLIER), "burst acceleration is authored")
	check(is_equal_approx(float(started.leap_multiplier), BoostLocomotion.BURST_LEAP_MULTIPLIER), "burst leap acceleration is bounded")

	var energy := int(started.energy)
	for tick in range(BoostLocomotion.DRAIN_INTERVAL_TICKS - 1):
		energy = int(boost.advance(true, true, true, energy).energy)
	check(energy == 99, "drain waits for the exact interval")
	energy = int(boost.advance(true, true, true, energy).energy)
	check(energy == 98, "drain interval consumes exactly one energy")
	while boost.state == BoostLocomotion.State.BURST:
		energy = int(boost.advance(true, true, true, energy).energy)
	check(boost.state == BoostLocomotion.State.SUSTAIN, "burst becomes sustain exactly once")
	check(boost.speed_multiplier() == BoostLocomotion.SUSTAIN_SPEED_MULTIPLIER, "sustain is slower than burst")

	var release_energy := energy
	var released: Dictionary = boost.advance(false, true, true, release_energy)
	check(boost.state == BoostLocomotion.State.RECOVERING and not bool(released.active), "release enters recovery")
	check(int(released.energy) == release_energy, "release adds no duplicate drain")
	check(not bool(boost.advance(true, true, true, release_energy).active), "recovery delay blocks repeated taps")
	var recovery_energy := release_energy
	for tick in range(BoostLocomotion.RELEASE_RECOVERY_DELAY_TICKS + BoostLocomotion.RECOVERY_INTERVAL_TICKS + 2):
		recovery_energy = int(boost.advance(false, true, true, recovery_energy).energy)
	check(recovery_energy > release_energy, "energy recovers after release delay")
	check(bool(boost.advance(true, true, true, recovery_energy).active), "recovered energy can restart boost")

	boost.reset()
	var threshold: Dictionary = boost.advance(true, true, true, BoostLocomotion.START_THRESHOLD)
	check(bool(threshold.active) and int(threshold.energy) == BoostLocomotion.START_THRESHOLD - 1, "exact threshold can start")
	boost.reset()
	var below: Dictionary = boost.advance(true, true, true, BoostLocomotion.START_THRESHOLD - 1)
	check(not bool(below.active) and boost.state == BoostLocomotion.State.EXHAUSTED, "below threshold exhausts")
	check(boost.requires_release, "exhaustion requires player release")
	var delay_before := boost.recovery_delay_ticks
	boost.advance(true, true, true, int(below.energy))
	check(boost.recovery_delay_ticks == delay_before - 1 and boost.requires_release, "holding cannot bypass exhaustion")
	boost.advance(false, true, true, int(below.energy))
	check(not boost.requires_release, "release clears exhaustion latch")

	boost.reset()
	energy = 18
	var first_low: Dictionary = boost.advance(true, true, true, energy)
	energy = int(first_low.energy)
	var exhaustion_seen := false
	for tick in range(120):
		var exhausted_step: Dictionary = boost.advance(true, true, true, energy)
		energy = int(exhausted_step.energy)
		if str(exhausted_step.event) == "exhausted":
			exhaustion_seen = true
			break
	check(exhaustion_seen and energy == 0, "sustained boost exhausts exactly at zero")
	check(not boost.is_active() and boost.speed_multiplier() == 1.0, "exhaustion removes acceleration")
	check(int(boost.advance(true, true, true, energy).energy) == 0, "held exhaustion cannot oscillate")
	boost.advance(false, true, true, energy)
	for tick in range(BoostLocomotion.EXHAUSTED_RECOVERY_DELAY_TICKS + BoostLocomotion.RECOVERY_INTERVAL_TICKS + 2):
		energy = int(boost.advance(false, true, true, energy).energy)
	check(energy > 0 and boost.state == BoostLocomotion.State.RECOVERING, "exhaustion uses the longer recovery delay")

	boost.reset()
	check(int(boost.advance(false, false, true, 999).energy) == 100, "oversized energy clamps")
	boost.reset()
	check(int(boost.advance(false, false, true, -99).energy) == 0, "negative energy clamps")

	var reference_trace := _trace()
	for scenario in range(100):
		check(_trace() == reference_trace, "deterministic trace %03d is stable" % (scenario + 1))

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.predator = Vector2(1200,650)
	check(game.screen == game.Screen.PLAYING and game.session.boost_energy == 100, "game starts with canonical energy")

	var surface_start: Vector2 = game.fred
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	check(game.boost.state == BoostLocomotion.State.BURST and game.session.boost_energy == 99, "keyboard starts one surface burst")
	check(game.fred.x - surface_start.x > 210.0 / 60.0, "surface burst exceeds base speed")
	check(game.save_feedback.begins_with("[BOOST BURST]"), "start feedback is readable")
	check(game.camera_response_y < 0.0, "normal motion has restrained camera response")
	game.reduced_motion = true
	game._fixed_tick(1.0 / 60.0)
	check(game.camera_response_y == 0.0 and not game.boost.cue().is_empty(), "reduced motion retains state without camera motion")
	game.reduced_motion = false
	var paused_energy: int = game.session.boost_energy
	var paused_state: int = game.boost.state
	game.session.paused = true
	game._process(0.5)
	check(game.session.boost_energy == paused_energy and game.boost.state == paused_state, "pause freezes boost")
	game.session.paused = false
	Input.action_release("move_right")
	Input.action_release("boost")
	game._fixed_tick(1.0 / 60.0)
	check(not game.boost.is_active(), "keyboard release cancels boost")

	game.boost.reset()
	game.session.boost_energy = 100
	game.fred = Vector2(400,400)
	game.leap.reset()
	game._request_leap(Vector2.RIGHT)
	Input.action_press("move_right")
	Input.action_press("boost")
	var leap_before: Vector2 = game.fred
	game._fixed_tick(1.0 / 60.0)
	check(game.leap.is_airborne() and game.boost.is_active(), "leap and boost share explicit precedence")
	check(game.fred.x > leap_before.x and game.boost.leap_multiplier() > 1.0, "boost accelerates the authored arc")
	game.leap.state = game.leap.State.LANDING
	game._fixed_tick(1.0 / 60.0)
	check(not game.boost.is_active(), "landing cancels boost")
	Input.action_release("move_right")
	Input.action_release("boost")
	game.leap.reset()

	game.boost.reset()
	game.session.boost_energy = 100
	game.fred = Vector2(550,300)
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	check(game.boost.is_active() and game._request_dive(), "surface boost preserves dive input")
	check(not game.boost.is_active(), "dive transition cancels boost")
	var dive_energy: int = game.session.boost_energy
	game._fixed_tick(1.0 / 60.0)
	check(game.session.boost_energy == dive_energy, "dive transition blocks duplicate drain")
	Input.action_release("boost")
	Input.action_release("move_right")
	for frame in range(48):
		game._fixed_tick(1.0 / 60.0)
	check(game.depth.is_underwater_band(), "depth remains canonical after cancellation")

	game.boost.reset()
	game.session.boost_energy = 100
	var underwater_start: Vector2 = game.fred
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	var underwater_distance: float = game.fred.x - underwater_start.x
	check(game.boost.is_active() and game.session.boost_energy == 99, "underwater uses shared boost")
	check(underwater_distance > 210.0 * game.depth.movement_scale() / 60.0, "underwater boost exceeds underwater base speed")
	check(game._request_surface() and not game.boost.is_active(), "surfacing cancels underwater boost")
	Input.action_release("boost")
	Input.action_release("move_right")
	for frame in range(48):
		game._fixed_tick(1.0 / 60.0)
	check(game.depth.state == game.depth.State.SURFACE, "surfacing still completes")

	game.boost.reset()
	game.session.boost_energy = 100
	game.collected.assign([0,1,2])
	game.tongue.reset()
	game._request_tongue(Vector2.UP)
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	check(game.tongue.is_busy() and not game.boost.is_active(), "tongue recovery takes precedence")
	check(game.session.boost_energy == 100, "tongue precedence prevents energy drain")
	Input.action_release("move_right")
	Input.action_release("boost")
	game.tongue.reset()

	game.boost.reset()
	game.session.boost_energy = 100
	game.countdown_enabled = true
	game.countdown_seconds = 5.0
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	check(game.session.boost_energy == 100 and not game.boost.is_active(), "countdown freezes boost")
	game.countdown_enabled = false
	game.countdown_seconds = 0.0
	Input.action_release("move_right")
	Input.action_release("boost")

	var controller := InputEventAction.new()
	controller.action = "boost"
	controller.pressed = true
	controller.device = 1
	var touch := InputEventAction.new()
	touch.action = "boost"
	touch.pressed = true
	touch.device = 2
	check(FredInputIntent.event_to_intent(controller) == FredInputIntent.Intent.BOOST, "synthetic controller maps to boost")
	check(FredInputIntent.event_to_intent(touch) == FredInputIntent.Intent.BOOST, "synthetic touch maps to boost")
	game.boost.reset()
	game.session.boost_energy = 100
	Input.action_press("move_right")
	Input.parse_input_event(controller.duplicate())
	Input.parse_input_event(touch.duplicate())
	Input.parse_input_event(controller.duplicate())
	await process_frame
	game._fixed_tick(1.0 / 60.0)
	check(game.session.boost_energy == 99, "simultaneous adapters consume one activation per fixed tick")
	var release := InputEventAction.new()
	release.action = "boost"
	release.pressed = false
	Input.parse_input_event(release)
	Input.action_release("move_right")
	await process_frame

	game.boost.reset()
	game.session.boost_energy = 100
	var stable_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("boost")
	var active_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(int(active_save.boost_state.energy) == 99, "stable boundary records durable energy")
	check(not active_save.has("boost") and not active_save.has("boost_state_machine"), "save excludes transient boost")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "save v1 succeeds after boost")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false) and restored.boost_energy == 99, "reload restores energy without burst")
	var malformed: Dictionary = stable_before.duplicate(true)
	malformed.boost_state = {"energy": 999}
	var high := AdventureSession.new(1337)
	check(high.restore(malformed).get("ok", false) and high.boost_energy == 100, "restore clamps oversized energy")
	malformed.boost_state = {"energy": -50}
	var low := AdventureSession.new(1337)
	check(low.restore(malformed).get("ok", false) and low.boost_energy == 0, "restore clamps negative energy")

	game.boost.reset()
	game.session.boost_energy = 100
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("boost")
	game.session.health = 2
	game._apply_danger_hit("[DANGER] Focused boost collision.")
	check(not game.boost.is_active() and game.session.health == 1, "predator hit cancels boost")
	game.session.health = 1
	game._apply_danger_hit("[DANGER] Focused boost failure.")
	check(game.screen == game.Screen.FAILED and not game.boost.is_active(), "failure clears boost")
	game._retry()
	check(game.screen == game.Screen.PLAYING and game.session.boost_energy == 100 and game.boost.state == BoostLocomotion.State.READY, "retry resets boost")
	game.boost.advance(true, true, true, game.session.boost_energy)
	game._go_home()
	check(game.screen == game.Screen.TITLE and game.boost.state == BoostLocomotion.State.READY, "home clears transient boost")
	game.screen = game.Screen.COMPLETE
	game._advance_level()
	check(game.screen == game.Screen.PLAYING and game.level_number == 2 and game.session.boost_energy == 100 and game.boost.state == BoostLocomotion.State.READY, "next level resets boost")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started_ms := Time.get_ticks_msec()
	for iteration in range(10000):
		var stress := BoostLocomotion.new()
		var stress_energy := 100
		for tick in range(24):
			stress_energy = int(stress.advance(tick < 16, true, true, stress_energy).energy)
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 2000, "10,000 cycles are time-bounded")
	check(memory_growth < 2 * 1024 * 1024, "10,000 cycles are memory-bounded")
	print("MEASURE boost_cycles=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed_ms, memory_growth])

	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT boost_locomotion_passed=%d boost_locomotion_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
