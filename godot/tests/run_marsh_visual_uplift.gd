extends SceneTree

const Main = preload("res://scripts/main.gd")
const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")

const SAVE_PREFIX := "user://m2_marsh_uplift_test"
const BOARD_PATH := "user://m2_marsh_uplift_board.json"

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
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	clean_files()
	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()

	check(is_instance_valid(game.gameplay_art), "authored marsh background loads as a Godot texture")
	check(game.gameplay_art.resource_path.ends_with("moonpetal-gameplay-marsh-v1.png"), "gameplay uses the committed marsh art asset")
	check(game._ellipse_points(Vector2.ZERO, Vector2(10,5), 0.0).size() == 32, "dimensional ellipse fill has a stable vertex contract")
	check(game._ellipse_points(Vector2.ZERO, Vector2(10,5), 0.0, true).size() == 33, "dimensional ellipse outline closes deterministically")
	check(
		game._ellipse_points(Vector2(10,20), Vector2(8,4), 0.2)
		== game._ellipse_points(Vector2(10,20), Vector2(8,4), 0.2),
		"authored marsh geometry is deterministic"
	)

	var move_touch := InputEventScreenTouch.new()
	move_touch.index = 1
	move_touch.position = Vector2(248,565)
	move_touch.pressed = true
	game._unhandled_input(move_touch)
	check(game.touch_controls_visible and game.touch_movement == Vector2.RIGHT, "real screen touch holds the mobile movement control")
	move_touch.pressed = false
	game._unhandled_input(move_touch)
	check(game.touch_movement == Vector2.ZERO and game.touch_contacts.is_empty(), "touch release clears mobile movement without drift")

	var boost_touch := InputEventScreenTouch.new()
	boost_touch.index = 2
	boost_touch.position = Vector2(1175,625)
	boost_touch.pressed = true
	game._unhandled_input(boost_touch)
	check(game.touch_boost, "real screen touch holds the shared boost intent")
	boost_touch.pressed = false
	game._unhandled_input(boost_touch)
	check(not game.touch_boost, "releasing the boost control stops the held intent")

	game.fred = Vector2(550,300)
	var depth_touch := InputEventScreenTouch.new()
	depth_touch.index = 3
	depth_touch.position = Vector2(930,505)
	depth_touch.pressed = true
	game._unhandled_input(depth_touch)
	check(game.depth.state == DepthTraversal.State.DIVING, "real screen touch invokes the shared dive transition")
	depth_touch.pressed = false
	game._unhandled_input(depth_touch)
	game.depth.reset("surface")

	var origin := Vector2(400,300)
	var close_behind := {
		"id": "bug:close",
		"kind": "bug",
		"position": origin - Vector2(TongueTargeting.PROXIMITY_ASSIST_RANGE, 0),
		"eligible": true,
	}
	var target_hash := ""
	for trace in range(100):
		var trace_tongue := TongueTargeting.new()
		var result: Dictionary = trace_tongue.request(origin, Vector2.RIGHT, [close_behind])
		var current_hash := "%s|%s|%s" % [result.outcome, result.target_id, result.target_point]
		if trace == 0:
			target_hash = current_hash
		check(current_hash == target_hash, "close-assist deterministic trace %03d is identical" % (trace + 1))

	game.level_number = 10
	game.level_profile = FredLevelIntensity.profile(10)
	game.session.health = AdventureSession.STARTING_LIVES
	game.collected.assign([0,1,2])
	for bonus_level in range(10, 101, 10):
		game.level_number = bonus_level
		game.level_profile = FredLevelIntensity.profile(bonus_level)
		game.fairy_collected = false
		game.fred = game._fairy_position() - Vector2(80,0)
		game.tongue.reset()
		var fairy_result: Dictionary = game._request_tongue(Vector2.RIGHT)
		check(str(fairy_result.outcome) == "hit", "level %03d fairy can be eaten" % bonus_level)
		check(game.session.health == AdventureSession.STARTING_LIVES + int(bonus_level / 10), "level %03d adds exactly one stacking life" % bonus_level)
	check(game.session.health == AdventureSession.MAX_LIVES, "all ten milestone fairies can build the full 13-life campaign reserve")

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(int(stable_save.player_state.health) == AdventureSession.MAX_LIVES, "schema v1 stores earned lives in its existing health field")
	check(not stable_save.has("touch") and not stable_save.has("visual"), "touch and marsh presentation stay transient")
	var restored := AdventureSession.new()
	check(restored.restore(stable_save).get("ok", false) and restored.health == AdventureSession.MAX_LIVES, "schema v1 reload preserves the legitimate stacked-life maximum")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started := Time.get_ticks_msec()
	var geometry_hash := 0
	for iteration in range(10000):
		var points: PackedVector2Array = game._ellipse_points(Vector2(640,360), Vector2(48,29), float(iteration % 31) * 0.01)
		geometry_hash = hash([geometry_hash, points[iteration % points.size()]])
	var elapsed_ms := Time.get_ticks_msec() - started
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 2500, "10,000 marsh geometry updates remain time-bounded")
	check(memory_growth < 4 * 1024 * 1024, "10,000 marsh geometry updates remain memory-bounded")
	check(geometry_hash != 0, "geometry stress loop produces a non-empty deterministic observation")
	print("MEASURE marsh_geometry_updates=10000 elapsed_ms=%d memory_growth_bytes=%d hash=%d" % [elapsed_ms, memory_growth, geometry_hash])

	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT marsh_visual_uplift_passed=%d marsh_visual_uplift_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
