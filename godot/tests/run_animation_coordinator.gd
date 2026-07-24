extends SceneTree

const AnimationCoordinator = preload("res://scripts/fred_animation_coordinator.gd")
const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")
const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const Main = preload("res://scripts/main.gd")
const SAVE_PREFIX := "user://animation_coordinator_test"

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

func _base_snapshot() -> Dictionary:
	return {
		"movement": Vector2.ZERO,
		"moving": false,
		"on_perch": true,
		"leap_state": LeapTraversal.State.GROUNDED,
		"leap_elapsed": 0.0,
		"depth_state": DepthTraversal.State.SURFACE,
		"depth_amount": 0.0,
		"tongue_state": TongueTargeting.State.READY,
		"tongue_elapsed": 0.0,
		"boost_state": BoostLocomotion.State.READY,
		"invulnerable": false,
		"failed": false,
	}

func _with(changes: Dictionary) -> Dictionary:
	var snapshot := _base_snapshot()
	snapshot.merge(changes, true)
	return snapshot

func _state(changes: Dictionary, reduced: bool = false) -> int:
	var coordinator := AnimationCoordinator.new()
	coordinator.advance(_with(changes), false, reduced)
	return coordinator.state

func _trace(extra_pose_reads: bool = false, reduced: bool = false) -> String:
	var coordinator := AnimationCoordinator.new()
	var transcript: Array[String] = []
	for tick in range(420):
		var snapshot := _base_snapshot()
		var phase := tick % 140
		if phase < 12:
			snapshot.movement = Vector2.RIGHT
			snapshot.moving = true
		elif phase < 56:
			snapshot.leap_state = LeapTraversal.State.AIRBORNE
			snapshot.leap_elapsed = float(phase - 12) / 60.0
			snapshot.movement = Vector2.RIGHT
			snapshot.moving = true
		elif phase < 64:
			snapshot.leap_state = LeapTraversal.State.LANDING
		elif phase < 82:
			snapshot.depth_state = DepthTraversal.State.DIVING
		elif phase < 96:
			snapshot.depth_state = DepthTraversal.State.UNDERWATER
			snapshot.movement = Vector2.LEFT
			snapshot.moving = true
		elif phase < 104:
			snapshot.tongue_state = TongueTargeting.State.EXTENDING
			snapshot.tongue_elapsed = float(phase - 96) / 60.0
		elif phase < 112:
			snapshot.tongue_state = TongueTargeting.State.RECOVERING
		elif phase < 122:
			snapshot.boost_state = BoostLocomotion.State.BURST
			snapshot.movement = Vector2.RIGHT
			snapshot.moving = true
		elif phase < 132:
			snapshot.boost_state = BoostLocomotion.State.EXHAUSTED
		else:
			snapshot.boost_state = BoostLocomotion.State.RECOVERING
		coordinator.advance(snapshot, false, reduced)
		if extra_pose_reads:
			coordinator.pose()
			coordinator.cue()
			coordinator.pose()
		transcript.append(coordinator.state_hash())
	return "|".join(transcript)

func _clean_files() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))

func _run() -> void:
	_clean_files()
	check(AnimationCoordinator.FIXED_TICK_SECONDS == 1.0 / 60.0, "animation contract uses the gameplay fixed tick")
	check(AnimationCoordinator.DAMAGE_TICKS == 18, "damage preemption has an explicit bounded duration")
	check(AnimationCoordinator.State.size() == 23, "coordinator exposes every documented presentation state")

	check(_state({}) == AnimationCoordinator.State.IDLE, "idle perch maps to IDLE")
	check(_state({"moving": true, "movement": Vector2.RIGHT}) == AnimationCoordinator.State.GROUND_MOVE, "perch movement maps to GROUND_MOVE")
	check(_state({"on_perch": false}) == AnimationCoordinator.State.SURFACE_SWIM, "open-water idle maps to SURFACE_SWIM")
	check(_state({"depth_state": DepthTraversal.State.UNDERWATER}) == AnimationCoordinator.State.UNDERWATER_IDLE, "underwater idle maps distinctly")
	check(_state({"depth_state": DepthTraversal.State.UNDERWATER, "moving": true}) == AnimationCoordinator.State.UNDERWATER_SWIM, "underwater steering maps distinctly")
	check(_state({"depth_state": DepthTraversal.State.DIVING}) == AnimationCoordinator.State.DIVING, "dive transition is explicit")
	check(_state({"depth_state": DepthTraversal.State.SURFACING}) == AnimationCoordinator.State.SURFACING, "surface transition is explicit")

	for phase_case: Dictionary in [
		{"elapsed": 0.01, "expected": AnimationCoordinator.State.LEAP_ANTICIPATION, "label": "anticipation"},
		{"elapsed": 0.18, "expected": AnimationCoordinator.State.LEAP_ASCENT, "label": "ascent"},
		{"elapsed": 0.36, "expected": AnimationCoordinator.State.LEAP_APEX, "label": "apex"},
		{"elapsed": 0.60, "expected": AnimationCoordinator.State.LEAP_DESCENT, "label": "descent"},
	]:
		check(
			_state({"leap_state": LeapTraversal.State.AIRBORNE, "leap_elapsed": phase_case.elapsed}) == int(phase_case.expected),
			"leap %s phase is deterministic" % phase_case.label
		)
	check(_state({"leap_state": LeapTraversal.State.LANDING}) == AnimationCoordinator.State.LEAP_LANDING, "landing phase is explicit")

	check(_state({"tongue_state": TongueTargeting.State.EXTENDING, "tongue_elapsed": 0.01}) == AnimationCoordinator.State.TONGUE_WINDUP, "tongue begins with a readable wind-up")
	check(_state({"tongue_state": TongueTargeting.State.EXTENDING, "tongue_elapsed": 0.08}) == AnimationCoordinator.State.TONGUE_EXTENSION, "tongue extension is explicit")
	check(_state({"tongue_state": TongueTargeting.State.RECOVERING}) == AnimationCoordinator.State.TONGUE_RECOVERY, "tongue recovery is explicit")
	check(_state({"boost_state": BoostLocomotion.State.BURST}) == AnimationCoordinator.State.BOOST_BURST, "boost burst is explicit")
	check(_state({"boost_state": BoostLocomotion.State.SUSTAIN}) == AnimationCoordinator.State.BOOST_SUSTAIN, "boost sustain is explicit")
	check(_state({"boost_state": BoostLocomotion.State.EXHAUSTED}) == AnimationCoordinator.State.BOOST_EXHAUSTED, "boost exhaustion is explicit")
	check(_state({"boost_state": BoostLocomotion.State.RECOVERING}) == AnimationCoordinator.State.BOOST_RECOVERY, "boost recovery is explicit")

	var coordinator := AnimationCoordinator.new()
	var mutable_snapshot := _with({"movement": Vector2.RIGHT, "moving": true, "nested": {"sentinel": 7}})
	var immutable_copy: Dictionary = mutable_snapshot.duplicate(true)
	coordinator.advance(mutable_snapshot)
	check(mutable_snapshot == immutable_copy, "coordinator treats gameplay snapshots as immutable")
	check(float(coordinator.pose().facing) == 1.0, "right movement faces Fred right")
	coordinator.advance(_with({"movement": Vector2.LEFT, "moving": true}))
	check(float(coordinator.pose().facing) == -1.0, "reversal deterministically faces Fred left")

	var before_freeze := coordinator.state_hash()
	coordinator.advance(_with({"failed": true}), true)
	check(coordinator.state_hash() == before_freeze, "pause and countdown freeze retain exact animation state")
	coordinator.advance(_with({"failed": true}))
	check(coordinator.state == AnimationCoordinator.State.FAILURE, "failure preempts every active locomotion state")
	coordinator.reset()
	check(coordinator.state == AnimationCoordinator.State.RESET and coordinator.cue() == "READY", "reset snaps to a stable ready pose")

	coordinator.trigger_damage()
	coordinator.advance(_with({
		"invulnerable": true,
		"tongue_state": TongueTargeting.State.EXTENDING,
		"depth_state": DepthTraversal.State.DIVING,
		"leap_state": LeapTraversal.State.AIRBORNE,
		"boost_state": BoostLocomotion.State.BURST,
	}))
	check(coordinator.state == AnimationCoordinator.State.DAMAGE, "damage preempts simultaneous interaction and traversal")
	for tick in range(AnimationCoordinator.DAMAGE_TICKS - 1):
		coordinator.advance(_with({"invulnerable": true}))
	check(coordinator.state == AnimationCoordinator.State.DAMAGE, "damage pose lasts its exact authored tick count")
	coordinator.advance(_with({"invulnerable": true}))
	check(coordinator.state == AnimationCoordinator.State.INVULNERABLE, "invulnerability cue follows damage without a flicker gap")

	check(_state({
		"invulnerable": true,
		"tongue_state": TongueTargeting.State.EXTENDING,
		"depth_state": DepthTraversal.State.DIVING,
		"leap_state": LeapTraversal.State.AIRBORNE,
		"boost_state": BoostLocomotion.State.BURST,
	}) == AnimationCoordinator.State.INVULNERABLE, "safety feedback outranks all non-terminal actions")
	check(_state({
		"tongue_state": TongueTargeting.State.EXTENDING,
		"depth_state": DepthTraversal.State.DIVING,
		"leap_state": LeapTraversal.State.AIRBORNE,
		"boost_state": BoostLocomotion.State.BURST,
	}) == AnimationCoordinator.State.TONGUE_WINDUP, "tongue interaction outranks traversal when snapshots overlap")
	check(_state({
		"depth_state": DepthTraversal.State.DIVING,
		"leap_state": LeapTraversal.State.AIRBORNE,
		"boost_state": BoostLocomotion.State.BURST,
	}) == AnimationCoordinator.State.DIVING, "depth transition outranks leap and boost")
	check(_state({
		"leap_state": LeapTraversal.State.AIRBORNE,
		"leap_elapsed": 0.2,
		"boost_state": BoostLocomotion.State.BURST,
	}) == AnimationCoordinator.State.LEAP_ASCENT, "leap phase outranks boost")

	var normal := AnimationCoordinator.new()
	var reduced := AnimationCoordinator.new()
	var active_snapshot := _with({"leap_state": LeapTraversal.State.AIRBORNE, "leap_elapsed": 0.20})
	var normal_pose: Dictionary = normal.advance(active_snapshot, false, false)
	var reduced_pose: Dictionary = reduced.advance(active_snapshot, false, true)
	check(normal.state == reduced.state and normal.cue() == reduced.cue(), "reduced motion preserves the same semantic state and cue")
	check(float(normal_pose.tilt) != 0.0 and float(reduced_pose.tilt) == 0.0, "reduced motion removes directional overshoot")
	for tick in range(12):
		normal_pose = normal.advance(_with({"moving": true, "movement": Vector2.RIGHT}), false, false)
		reduced_pose = reduced.advance(_with({"moving": true, "movement": Vector2.RIGHT}), false, true)
	check(absf(float(normal_pose.body_offset.y)) > 0.01 and is_zero_approx(float(reduced_pose.body_offset.y)), "reduced motion suppresses secondary movement bob")
	check(not str(reduced_pose.cue).is_empty() and Color(reduced_pose.accent).a > 0.99, "reduced motion retains text and non-motion accent cues")

	for state_value in AnimationCoordinator.State.values():
		var pose_coordinator := AnimationCoordinator.new()
		pose_coordinator.state = int(state_value)
		pose_coordinator._pose = pose_coordinator._build_pose()
		var pose: Dictionary = pose_coordinator.pose()
		check(Vector2(pose.body_scale).x > 0.0 and Vector2(pose.body_scale).y > 0.0, "state %02d has a valid silhouette" % int(state_value))
		check(not str(pose.cue).is_empty(), "state %02d has a non-color cue" % int(state_value))
		check(Color(pose.accent).a > 0.99, "state %02d has an opaque readable accent" % int(state_value))

	var reference_trace := _trace()
	for scenario in range(100):
		check(_trace() == reference_trace, "multi-traversal animation trace %03d is identical" % (scenario + 1))
	check(_trace(true) == reference_trace, "render-order pose reads cannot change fixed-tick animation hashes")
	check(_trace(false, true) == _trace(true, true), "reduced-motion hashes are independent of render read rate")

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.predator = Vector2(1200,650)
	check(game.animation.state == AnimationCoordinator.State.RESET, "start resets the integrated coordinator")

	var stable_session: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	var stable_fred: Vector2 = game.fred
	for query in range(100):
		game.animation.pose()
		game.animation.state_hash()
	check(game.session.to_save("2000-01-01T00:00:00Z") == stable_session and game.fred == stable_fred, "presentation queries cannot mutate gameplay or session state")

	Input.action_press("move_right")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	check(game.animation.state in [AnimationCoordinator.State.GROUND_MOVE, AnimationCoordinator.State.SURFACE_SWIM], "real keyboard movement drives one integrated locomotion state")
	game.leap.reset()
	game._request_leap(Vector2.RIGHT)
	game._fixed_tick(1.0 / 60.0)
	check(game.animation.state == AnimationCoordinator.State.LEAP_ANTICIPATION, "integrated leap begins with anticipation")
	for tick in range(19):
		game._fixed_tick(1.0 / 60.0)
	check(game.animation.state in [AnimationCoordinator.State.LEAP_ASCENT, AnimationCoordinator.State.LEAP_APEX], "integrated leap reaches an airborne phase")

	game.leap.reset()
	game.fred = Vector2(560,330)
	game.depth.reset("surface")
	check(game._request_dive(), "integration fixture accepts dive in open water")
	game._fixed_tick(1.0 / 60.0)
	check(game.animation.state == AnimationCoordinator.State.DIVING, "integrated dive drives the coordinator")
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game._fixed_tick(1.0 / 60.0)
	check(game.animation.state == AnimationCoordinator.State.UNDERWATER_IDLE, "integrated stable depth drives underwater idle")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.collected.assign([0,1,2])
	game.tongue.reset()
	game._request_tongue(Vector2.RIGHT)
	game._fixed_tick(1.0 / 60.0)
	check(game.animation.state in [AnimationCoordinator.State.TONGUE_WINDUP, AnimationCoordinator.State.TONGUE_EXTENSION], "integrated tongue drives an aimed-mouth pose")
	game.tongue.reset()
	game.boost.reset()
	game.session.boost_energy = 100
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("boost")
	check(game.animation.state == AnimationCoordinator.State.BOOST_BURST, "integrated boost drives the burst silhouette")

	var frozen_hash: String = game.animation.state_hash()
	game.session.paused = true
	game._process(0.5)
	check(game.animation.state_hash() == frozen_hash, "integrated pause freezes animation exactly")
	game.session.paused = false
	game.countdown_enabled = true
	game.countdown_seconds = 2.0
	game._fixed_tick(1.0 / 60.0)
	check(game.animation.state_hash() == frozen_hash, "integrated countdown freezes animation exactly")
	game.countdown_enabled = false
	game.countdown_seconds = 0.0

	game.session.health = 2
	game._apply_danger_hit("[DANGER] Animation damage test.")
	check(game.animation.state == AnimationCoordinator.State.DAMAGE and game.session.health == 1, "damage feedback preempts after the real health change")
	game.session.health = 1
	game._apply_danger_hit("[DANGER] Animation failure test.")
	check(game.animation.state == AnimationCoordinator.State.FAILURE and game.screen == game.Screen.FAILED, "final-life damage latches failure presentation")
	game._retry()
	check(game.animation.state == AnimationCoordinator.State.RESET and game.screen == game.Screen.PLAYING, "retry clears failure and resets level one")
	game._go_home()
	check(game.animation.state == AnimationCoordinator.State.RESET and game.screen == game.Screen.TITLE, "home clears transient animation")
	game.screen = game.Screen.COMPLETE
	game._advance_level()
	check(game.animation.state == AnimationCoordinator.State.RESET and game.level_number == 2, "level transition clears transient animation")

	var controller := InputEventAction.new()
	controller.action = "move_right"
	controller.pressed = true
	controller.device = 1
	var touch := controller.duplicate()
	touch.device = 2
	check(FredInputIntent.event_to_intent(controller) == FredInputIntent.Intent.MOVE_RIGHT, "synthetic controller uses the shared device-neutral intent")
	check(FredInputIntent.event_to_intent(touch) == FredInputIntent.Intent.MOVE_RIGHT, "synthetic touch uses the shared device-neutral intent")
	game.animation.reset()
	Input.parse_input_event(controller)
	Input.parse_input_event(touch)
	await process_frame
	game._fixed_tick(1.0 / 60.0)
	check(game.animation.state_ticks == 1, "simultaneous adapters advance animation once per fixed tick")
	var release := InputEventAction.new()
	release.action = "move_right"
	release.pressed = false
	release.device = 1
	Input.parse_input_event(release)
	var touch_release := release.duplicate()
	touch_release.device = 2
	Input.parse_input_event(touch_release)
	await process_frame
	controller = null
	touch = null
	release = null
	touch_release = null

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not stable_save.has("animation") and not stable_save.has("animation_state") and not stable_save.has("pose"), "save v1 excludes transient animation fields")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "schema-v1 save succeeds after animation traversal")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false), "schema-v1 reload succeeds without animation data")
	check(restored.to_save("2000-01-01T00:00:00Z") == stable_save, "animation coordination does not drift canonical save state")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var objects_before := Performance.get_monitor(Performance.OBJECT_COUNT)
	var resources_before := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var started_ms := Time.get_ticks_msec()
	var stress := AnimationCoordinator.new()
	for iteration in range(10000):
		var stress_snapshot := _base_snapshot()
		stress_snapshot.movement = Vector2.RIGHT if iteration % 2 == 0 else Vector2.LEFT
		stress_snapshot.moving = true
		stress_snapshot.leap_state = LeapTraversal.State.AIRBORNE if iteration % 7 < 4 else LeapTraversal.State.GROUNDED
		stress_snapshot.leap_elapsed = float(iteration % 44) / 60.0
		stress_snapshot.depth_state = DepthTraversal.State.UNDERWATER if iteration % 17 < 3 else DepthTraversal.State.SURFACE
		stress_snapshot.tongue_state = TongueTargeting.State.EXTENDING if iteration % 31 < 2 else TongueTargeting.State.READY
		stress_snapshot.boost_state = BoostLocomotion.State.BURST if iteration % 23 < 4 else BoostLocomotion.State.READY
		stress.advance(stress_snapshot, false, iteration % 11 == 0)
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	var object_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_COUNT) - objects_before))
	var resource_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT) - resources_before))
	var node_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) - nodes_before))
	var orphan_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) - orphans_before))
	check(elapsed_ms < 1800, "10,000 coordinator cycles remain time-bounded")
	check(memory_growth < 2 * 1024 * 1024, "10,000 coordinator cycles remain memory-bounded")
	check(node_growth == 0 and orphan_growth == 0, "10,000 coordinator cycles create no nodes or orphans")
	check(resource_growth == 0, "10,000 coordinator cycles create no retained resources")
	print("MEASURE animation_cycles=10000 elapsed_ms=%d memory_growth_bytes=%d object_growth=%d resource_growth=%d node_growth=%d orphan_growth=%d" % [
		elapsed_ms, memory_growth, object_growth, resource_growth, node_growth, orphan_growth
	])

	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	_clean_files()
	print("RESULT animation_coordinator_passed=%d animation_coordinator_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
