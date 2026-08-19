extends SceneTree

const CameraFollow = preload("res://scripts/camera_follow.gd")
const Main = preload("res://scripts/main.gd")
const SAVE_PREFIX := "user://camera_follow_test"

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

func _advance(
	camera: RefCounted,
	focus: Vector2 = Vector2(640,360),
	movement: Vector2 = Vector2.ZERO,
	leap_height: float = 0.0,
	depth_amount: float = 0.0,
	boost_strength: float = 0.0,
	tongue_offset: Vector2 = Vector2.ZERO,
	tongue_active: bool = false,
	reduced_motion: bool = false,
	viewport_size: Vector2i = Vector2i(1280,720),
	frozen: bool = false
) -> Dictionary:
	return camera.advance(
		focus,
		movement,
		leap_height,
		depth_amount,
		boost_strength,
		tongue_offset,
		tongue_active,
		reduced_motion,
		viewport_size,
		frozen
	)

func _trace() -> String:
	var camera := CameraFollow.new()
	var transcript: Array[String] = []
	for tick in range(360):
		var focus := Vector2(
			120.0 + float((tick * 11) % 1030),
			140.0 + float((tick * 7) % 480)
		)
		var movement := Vector2(
			sin(float(tick) * 0.13),
			cos(float(tick) * 0.09)
		).normalized()
		var leap_height := sin(float(tick % 44) / 44.0 * PI) * 52.0 if tick % 90 < 44 else 0.0
		var depth_amount := float(tick % 61) / 60.0
		var boost_strength := 1.0 if tick % 73 < 12 else (0.65 if tick % 73 < 32 else 0.0)
		var tongue_active := tick % 47 < 9
		var tongue_vector := Vector2(150, -80) if tongue_active else Vector2.ZERO
		var viewport := Vector2i(640,360) if tick >= 180 and tick < 240 else Vector2i(1280,720)
		_advance(camera, focus, movement, leap_height, depth_amount, boost_strength, tongue_vector, tongue_active, false, viewport)
		transcript.append(camera.state_hash())
	return "|".join(transcript)

func _clean_files() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))

func _run() -> void:
	_clean_files()
	check(CameraFollow.REFERENCE_VIEWPORT == Vector2(1280,720), "camera contract uses the authored logical viewport")
	check(CameraFollow.WORLD_MIN == Vector2(55,105) and CameraFollow.WORLD_MAX == Vector2(1225,665), "camera contract matches exact movement clamps")
	check(CameraFollow.INPUT_DEAD_ZONE == 0.18, "input anticipation has an explicit dead zone")
	check(CameraFollow.HORIZONTAL_ANTICIPATION == 18.0, "horizontal anticipation is explicit and restrained")
	check(CameraFollow.MAX_OFFSET.x == 26.0 and CameraFollow.MAX_OFFSET.y == 26.0, "camera response is bounded on both axes")
	check(CameraFollow.MAX_CATCH_UP_PER_TICK == 1.75, "fixed-tick catch-up limit is explicit")

	var camera := CameraFollow.new()
	var idle: Dictionary = _advance(camera)
	check(Vector2(idle.offset) == Vector2.ZERO and Vector2(idle.target) == Vector2.ZERO, "centered idle focus remains still")
	for tick in range(10):
		_advance(camera)
	check(camera.offset == Vector2.ZERO, "idle fixed ticks do not drift")

	_advance(camera, Vector2(640,360), Vector2(0.17,0))
	check(camera.target_offset == Vector2.ZERO, "sub-threshold input adds no anticipation")
	var right: Dictionary = _advance(camera, Vector2(640,360), Vector2.RIGHT)
	check(float(right.target.x) == -CameraFollow.HORIZONTAL_ANTICIPATION, "right movement looks ahead in the travel direction")
	check(is_equal_approx(float(right.offset.x), -CameraFollow.MAX_CATCH_UP_PER_TICK), "first response obeys the exact catch-up limit")
	for tick in range(20):
		_advance(camera, Vector2(640,360), Vector2.RIGHT)
	check(is_equal_approx(camera.offset.x, -CameraFollow.HORIZONTAL_ANTICIPATION), "camera settles at bounded horizontal anticipation")

	var prior_x := camera.offset.x
	var reversal := _advance(camera, Vector2(640,360), Vector2.LEFT)
	check(float(reversal.target.x) == CameraFollow.HORIZONTAL_ANTICIPATION, "rapid reversal flips the look-ahead target")
	check(absf(camera.offset.x - prior_x) <= CameraFollow.MAX_CATCH_UP_PER_TICK + 0.001, "rapid reversal cannot snap beyond catch-up")
	var previous_x := camera.offset.x
	for tick in range(30):
		_advance(camera, Vector2(640,360), Vector2.LEFT)
		check(camera.offset.x >= previous_x - 0.001, "reversal catch-up %02d is monotonic" % (tick + 1))
		previous_x = camera.offset.x
	check(camera.offset.x > 0.0, "reversal reaches the new framing side without oscillation")

	camera.reset()
	_advance(camera, Vector2(640,360), Vector2.RIGHT, 0.0, 0.0, 1.0)
	check(camera.target_offset.x == -24.0 and camera.target_offset.y == -4.0, "boost burst adds bounded forward and vertical context")
	camera.reset()
	_advance(camera, Vector2(640,360), Vector2.ZERO, 52.0)
	check(is_equal_approx(camera.target_offset.y, -9.36), "leap apex adds exact authored vertical framing")
	camera.reset()
	_advance(camera, Vector2(640,360), Vector2.ZERO, 0.0, 1.0)
	check(camera.target_offset.y == 8.0, "underwater band adds exact depth bias")
	camera.reset()
	_advance(camera, Vector2(640,360), Vector2.ZERO, 0.0, 0.0, 0.0, Vector2(150,-80), true)
	check(camera.target_offset.x < 0.0 and camera.target_offset.y > 0.0, "active tongue frames the selected target direction")
	camera.reset()
	_advance(camera, Vector2(640,360), Vector2.ZERO, 52.0, 1.0, 1.0, Vector2(190,0), true)
	check(absf(camera.target_offset.x) <= CameraFollow.MAX_OFFSET.x and absf(camera.target_offset.y) <= CameraFollow.MAX_OFFSET.y, "simultaneous traversal cues remain globally bounded")

	camera.reset()
	var left_edge: Dictionary = camera.snap(Vector2(55,360), Vector2.LEFT, 0, 0, 0, Vector2.ZERO, false, false, Vector2i(1280,720))
	check(float(left_edge.framed_focus.x) >= CameraFollow.SAFE_FRAME.position.x, "left world clamp keeps Fred in the safe frame")
	var right_edge: Dictionary = camera.snap(Vector2(1225,360), Vector2.RIGHT, 0, 0, 0, Vector2.ZERO, false, false, Vector2i(1280,720))
	check(float(right_edge.framed_focus.x) <= CameraFollow.SAFE_FRAME.end.x, "right world clamp keeps Fred in the safe frame")
	var top_edge: Dictionary = camera.snap(Vector2(640,105), Vector2.UP, 52, 0, 1, Vector2.ZERO, false, false, Vector2i(1280,720))
	check(float(top_edge.framed_focus.y) >= CameraFollow.SAFE_FRAME.position.y, "top world clamp keeps Fred in the safe frame")
	var bottom_edge: Dictionary = camera.snap(Vector2(640,665), Vector2.DOWN, 0, 1, 0, Vector2.ZERO, false, false, Vector2i(1280,720))
	check(float(bottom_edge.framed_focus.y) <= CameraFollow.SAFE_FRAME.end.y, "bottom world clamp keeps Fred above the HUD context line")

	camera.reset()
	var normal_size: Dictionary = camera.snap(Vector2(640,360), Vector2.RIGHT, 0, 0, 0, Vector2.ZERO, false, false, Vector2i(1280,720))
	var normal_x := absf(float(normal_size.offset.x))
	var medium_size: Dictionary = camera.snap(Vector2(640,360), Vector2.RIGHT, 0, 0, 0, Vector2.ZERO, false, false, Vector2i(960,540))
	check(is_equal_approx(float(medium_size.viewport_scale), 0.75), "960x540 uses the exact three-quarter response scale")
	check(absf(float(medium_size.offset.x)) < normal_x, "smaller window reduces anticipation")
	var constrained: Dictionary = camera.snap(Vector2(640,360), Vector2.RIGHT, 0, 0, 0, Vector2.ZERO, false, false, Vector2i(640,360))
	check(is_equal_approx(float(constrained.viewport_scale), 0.5), "640x360 uses the minimum child-usable response scale")
	check(is_equal_approx(absf(float(constrained.offset.x)), 9.0), "constrained response remains exactly bounded")
	var resized: Dictionary = _advance(camera, Vector2(640,360), Vector2.LEFT, 0, 0, 0, Vector2.ZERO, false, false, Vector2i(1280,720))
	check(float(resized.viewport_scale) == 1.0 and absf(float(resized.offset.x)) <= CameraFollow.MAX_OFFSET.x, "resize reflow keeps a valid bounded offset")

	var frozen_before := camera.offset
	_advance(camera, Vector2(640,360), Vector2.LEFT, 52, 1, 1, Vector2(190,0), true, false, Vector2i(1280,720), true)
	check(camera.offset == frozen_before, "countdown or pause freeze retains the exact camera state")
	var reduced: Dictionary = _advance(camera, Vector2(1225,665), Vector2.RIGHT, 52, 1, 1, Vector2(190,0), true, true)
	check(Vector2(reduced.offset) == Vector2.ZERO and Vector2(reduced.target) == Vector2.ZERO, "reduced motion removes anticipation and interpolation")
	camera.reset()
	check(camera.offset == Vector2.ZERO and camera.target_offset == Vector2.ZERO, "explicit reset snaps camera home")

	var reference_trace := _trace()
	for scenario in range(100):
		check(_trace() == reference_trace, "deterministic camera traversal trace %03d is stable" % (scenario + 1))

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.device_intent_adapter_enabled = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.predator = Vector2(1200,650)
	check(game.camera_offset == Vector2.ZERO and game.camera_response_y == 0.0, "start snaps transient camera state")

	game.fred = Vector2(500,400)
	Input.action_press("move_right")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	check(game.camera_offset.x < 0.0, "synthetic platform movement drives shared camera anticipation")
	var paused_offset: Vector2 = game.camera_offset
	game.session.paused = true
	game._process(0.5)
	check(game.camera_offset == paused_offset, "pause freezes integrated camera state")
	game.session.paused = false
	game.countdown_enabled = true
	game.countdown_seconds = 2.0
	game._fixed_tick(1.0 / 60.0)
	check(game.camera_offset == paused_offset, "countdown freezes integrated camera state")
	game.countdown_enabled = false
	game.countdown_seconds = 0.0

	game.camera_follow.reset()
	game.camera_offset = Vector2.ZERO
	game.fred = Vector2(500,400)
	game.leap.reset()
	game._request_leap(Vector2.RIGHT)
	for tick in range(22):
		game._fixed_tick(1.0 / 60.0)
	check(game.leap.visual_height > 45.0 and game.camera_offset.y < 0.0, "leap apex produces bounded upward camera response")
	game.leap.reset()
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	for tick in range(12):
		game._fixed_tick(1.0 / 60.0)
	check(game.camera_offset.y > 0.0, "underwater state settles toward depth framing")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.boost.reset()
	game.session.boost_energy = 100
	Input.action_press("move_right")
	Input.action_press("boost")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("boost")
	check(
		game.boost.is_active()
		and is_equal_approx(game.camera_follow.target_offset.x, -24.0 * game.camera_follow.viewport_scale),
		"boost burst strengthens look-ahead once per fixed tick"
	)
	game.boost.reset()
	game.collected.assign([0,1,2])
	game.tongue.reset()
	game._request_tongue(Vector2.RIGHT)
	game._fixed_tick(1.0 / 60.0)
	check(game.tongue.is_busy() and game.camera_follow.target_offset.x < 0.0, "tongue extension adds target context")

	var controller := InputEventAction.new()
	controller.action = "move_right"
	controller.pressed = true
	controller.device = 1
	var touch := InputEventAction.new()
	touch.action = "move_right"
	touch.pressed = true
	touch.device = 2
	check(FredInputIntent.event_to_intent(controller) == FredInputIntent.Intent.MOVE_RIGHT, "synthetic controller maps to the shared movement intent")
	check(FredInputIntent.event_to_intent(touch) == FredInputIntent.Intent.MOVE_RIGHT, "synthetic touch maps to the shared movement intent")
	game.camera_follow.reset()
	game.camera_offset = Vector2.ZERO
	Input.parse_input_event(controller.duplicate())
	Input.parse_input_event(touch.duplicate())
	Input.parse_input_event(controller.duplicate())
	await process_frame
	game._fixed_tick(1.0 / 60.0)
	check(
		is_equal_approx(game.camera_offset.x, -CameraFollow.MAX_CATCH_UP_PER_TICK * game.camera_follow.viewport_scale),
		"simultaneous adapters produce one camera advance per fixed tick"
	)
	var release := InputEventAction.new()
	release.action = "move_right"
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not stable_save.has("camera") and not stable_save.has("camera_offset") and not stable_save.has("camera_state"), "save v1 excludes all transient camera fields")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "schema-v1 save succeeds after camera traversal")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false), "schema-v1 reload succeeds without camera data")
	check(restored.to_save("2000-01-01T00:00:00Z") == stable_save, "camera traversal does not drift canonical session state")

	game.camera_follow.offset = Vector2(12,-7)
	game.camera_offset = game.camera_follow.offset
	game.session.health = 2
	game._apply_danger_hit("[DANGER] Camera reset test.")
	check(game.camera_offset == Vector2.ZERO and game.camera_follow.offset == Vector2.ZERO, "damage snaps camera before safe recovery")
	game.camera_follow.offset = Vector2(7,5)
	game._retry()
	check(game.camera_offset == Vector2.ZERO and game.screen == game.Screen.PLAYING, "retry resets camera and starts level one")
	game.camera_follow.offset = Vector2(7,5)
	game._go_home()
	check(game.camera_offset == Vector2.ZERO and game.screen == game.Screen.TITLE, "home resets camera")
	game.camera_follow.offset = Vector2(7,5)
	game.screen = game.Screen.COMPLETE
	game._advance_level()
	check(game.camera_offset == Vector2.ZERO and game.level_number == 2, "level transition resets camera")
	game.reduced_motion = true
	game._fixed_tick(1.0 / 60.0)
	check(game.camera_offset == Vector2.ZERO and not game.depth.cue().is_empty() and not game.boost.cue().is_empty(), "reduced motion preserves explicit traversal information")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started_ms := Time.get_ticks_msec()
	var stress := CameraFollow.new()
	for iteration in range(10000):
		var focus := Vector2(55 + (iteration % 1171), 105 + (iteration % 561))
		var movement := Vector2.RIGHT.rotated(float(iteration % 32) * TAU / 32.0)
		_advance(stress, focus, movement, float(iteration % 53), float(iteration % 101) / 100.0, float(iteration % 3) * 0.5, Vector2(120,-40), iteration % 5 == 0, false, Vector2i(1280,720))
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 1400, "10,000 camera cycles remain time-bounded")
	check(memory_growth < 2 * 1024 * 1024, "10,000 camera cycles remain memory-bounded")
	print("MEASURE camera_cycles=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed_ms, memory_growth])

	game.queue_free()
	await process_frame
	_clean_files()
	print("RESULT camera_follow_passed=%d camera_follow_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
