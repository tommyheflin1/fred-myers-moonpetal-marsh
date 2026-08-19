extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")
const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")

const SAVE_PREFIX := "user://touch_first_controls"
const BOARD_PATH := "user://touch_first_controls_board.json"

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
		var path := ProjectSettings.globalize_path(SAVE_PREFIX + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var board_path := ProjectSettings.globalize_path(BOARD_PATH)
	if FileAccess.file_exists(board_path):
		DirAccess.remove_absolute(board_path)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	clean_files()
	check(Layout.rect_inside_canvas(Layout.TOUCH_MOVEMENT_RECT, 10.0), "touch steering surface stays inside the logical canvas")
	check(Layout.TOUCH_MOVEMENT_RECT.end.y <= Layout.TOUCH_ACTION_BAR_RECT.position.y, "touch steering surface ends above the bottom action bar")
	check(Layout.TOUCH_GUIDE_RECT.position.y >= 610.0 and Layout.TOUCH_ACTION_BAR_RECT.position.y >= 610.0, "touch guidance and actions occupy the phone-friendly bottom edge")
	check(not Layout.TOUCH_GUIDE_RECT.intersects(Layout.TOUCH_ACTION_BAR_RECT), "touch steering guide does not overlap the action bar")
	check(not Layout.STATUS_TOUCH_RECT.intersects(Layout.TOUCH_ACTION_BAR_RECT), "touch status feedback does not overlap action buttons")

	var action_rects := Layout.touch_action_rects()
	var actions: Array[String] = ["tongue", "leap", "boost", "depth"]
	check(action_rects.size() == actions.size(), "the bottom bar exposes exactly four core gameplay actions")
	for action: String in actions:
		var rect := Rect2(action_rects[action])
		check(Layout.rect_inside_canvas(rect, 10.0), "%s button stays inside the safe canvas" % action)
		check(rect.size.y >= 84.0, "%s button preserves the 48 dp minimum target" % action)
		check(Layout.touch_action_at(rect.get_center()) == action, "%s visible button and hit target agree" % action)
		check(rect.position.y >= 610.0, "%s remains in the bottom action row" % action)
	for first in range(actions.size()):
		for second in range(first + 1, actions.size()):
			check(not Rect2(action_rects[actions[first]]).intersects(Rect2(action_rects[actions[second]])), "%s and %s buttons never overlap" % [actions[first], actions[second]])

	check(Layout.touch_action_at(Vector2(640.0,330.0)) == "steer", "open gameplay surface resolves to direct touch steering")
	check(Layout.touch_action_at(Layout.OBJECTIVE_RECT.get_center()) == "", "top objective HUD cannot accidentally steer Fred")
	check(Layout.touch_action_at(Layout.TOUCH_GUIDE_RECT.get_center()) == "", "bottom steering guide is not a hidden movement button")
	check(Layout.clamp_touch_target(Vector2(-500.0,2000.0)) == Vector2(Layout.TOUCH_MOVEMENT_RECT.position.x, Layout.TOUCH_MOVEMENT_RECT.end.y - 1.0), "drag targets clamp deterministically to the playable surface")

	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.touch_controls_visible = true
	game.fred = Vector2(300.0,420.0)

	var first_target := Vector2(620.0,300.0)
	game._handle_touch(7, first_target, true)
	check(str(game.touch_contacts.get(7,"")) == "steer", "touching the playfield begins a steering contact")
	check(Vector2(game.touch_positions.get(7,Vector2.ZERO)) == first_target, "steering contact records its target")
	check(game.touch_movement.is_equal_approx((first_target - game.fred).normalized()), "Fred moves toward the touched point")
	check(game._active_touch_target() == first_target, "active steering target drives visible touch feedback")

	var drag_target := Vector2(760.0,520.0)
	game._move_touch(7, drag_target)
	check(Vector2(game.touch_positions.get(7,Vector2.ZERO)) == drag_target, "dragging updates the steering target")
	check(game.touch_movement.is_equal_approx((drag_target - game.fred).normalized()), "dragging continuously redirects Fred")

	game._handle_touch(8, Rect2(action_rects.boost).get_center(), true)
	check(game.touch_boost, "a second finger can hold Boost while the first finger steers")
	check(game.touch_movement.is_equal_approx((drag_target - game.fred).normalized()), "action contacts do not disrupt touch steering")
	game._move_touch(8, Vector2(640.0,330.0))
	check(not game.touch_boost, "sliding away from Boost safely releases the held action")
	check(game.touch_movement != Vector2.ZERO, "releasing an action leaves the steering finger active")
	game._handle_touch(8, Vector2.ZERO, false)

	game._move_touch(7, Vector2(5000.0,-5000.0))
	check(Vector2(game.touch_positions[7]) == Vector2(Layout.TOUCH_MOVEMENT_RECT.end.x - 1.0, Layout.TOUCH_MOVEMENT_RECT.position.y), "off-screen drag remains bounded inside the playfield")
	game._handle_touch(7, Vector2.ZERO, false)
	check(game.touch_movement == Vector2.ZERO and game.touch_contacts.is_empty() and game.touch_positions.is_empty(), "lifting the steering finger clears movement with no stale contact")

	game.fred = Vector2(500.0,400.0)
	game._handle_touch(4, game.fred + Vector2(8.0,4.0), true)
	check(game.touch_movement == Vector2.ZERO, "small finger jitter inside the dead zone cannot move Fred")
	game._handle_touch(4, Vector2.ZERO, false)

	game.leap.reset()
	game._handle_touch(10, Rect2(action_rects.leap).get_center(), true)
	check(game.leap.state != LeapTraversal.State.GROUNDED, "bottom Leap button triggers the canonical leap mechanic")
	game._handle_touch(10, Vector2.ZERO, false)
	game.leap.reset()
	game.fred = Vector2(640.0,330.0)
	game.depth.reset("surface")
	game._handle_touch(11, Rect2(action_rects.depth).get_center(), true)
	check(game.depth.state != DepthTraversal.State.SURFACE, "bottom Dive button triggers the canonical depth transition")
	game._handle_touch(11, Vector2.ZERO, false)

	game.session.paused = true
	game._handle_touch(12, Vector2(700.0,350.0), true)
	check(not game.touch_contacts.has(12) and game.touch_movement == Vector2.ZERO, "paused play rejects new movement contacts")
	game._handle_touch(13, Layout.PAUSE_RECT.get_center(), true)
	check(not game.session.paused, "top Pause control resumes play by touch")
	game._handle_touch(13, Vector2.ZERO, false)

	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(720.0,360.0)
	game._unhandled_input(mouse_down)
	check(game.pointer_touch_active and str(game.touch_contacts.get(-1,"")) == "steer", "desktop pointer emulates the same touch steering path for owner review")
	var mouse_drag := InputEventMouseMotion.new()
	mouse_drag.position = Vector2(800.0,300.0)
	game._unhandled_input(mouse_drag)
	check(Vector2(game.touch_positions.get(-1,Vector2.ZERO)) == mouse_drag.position, "desktop owner drag updates the exact mobile steering target")
	var mouse_up := InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	mouse_up.position = mouse_drag.position
	game._unhandled_input(mouse_up)
	check(not game.pointer_touch_active and game.touch_movement == Vector2.ZERO, "desktop owner pointer release cannot leave stale mobile movement")

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not stable_save.has("touch") and not stable_save.has("touch_positions") and not stable_save.has("touch_movement"), "touch state remains transient outside fred_save v1")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("TOUCH + DRAG") and main_source.contains("TO STEER FRED"), "touch-first steering instructions are visible in gameplay")
	check(not main_source.contains("_draw_touch_button"), "the legacy directional-pad drawing path is removed")

	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT touch_first_controls_passed=%d touch_first_controls_failed=%d" % [passed,failed])
	quit(1 if failed else 0)
