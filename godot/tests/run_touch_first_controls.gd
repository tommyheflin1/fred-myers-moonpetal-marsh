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
	check(Layout.rect_inside_canvas(Layout.TOUCH_ACTION_WHEEL_RECT, 10.0), "left action wheel stays inside the logical canvas")
	check(Layout.rect_inside_canvas(Layout.TOUCH_CONTROL_PAD_RECT, 10.0), "right control pad stays inside the logical canvas")
	check(Layout.TOUCH_ACTION_WHEEL_CENTER.x < Layout.CANVAS_SIZE.x * 0.5, "action wheel occupies the left half of the phone")
	check(Layout.TOUCH_CONTROL_PAD_CENTER.x > Layout.CANVAS_SIZE.x * 0.5, "movement control pad occupies the right half of the phone")
	check(Layout.TOUCH_ACTION_WHEEL_RECT.end.y <= Layout.CANVAS_SIZE.y - Layout.TOUCH_SAFE_EDGE_MARGIN, "action wheel clears the phone bottom safe area")
	check(Layout.TOUCH_CONTROL_PAD_RECT.end.y <= Layout.CANVAS_SIZE.y - Layout.TOUCH_SAFE_EDGE_MARGIN, "control pad clears the phone bottom safe area")
	check(Layout.TOUCH_OVERLAY_ALPHA < Layout.TOUCH_CONTROL_ALPHA and Layout.TOUCH_CONTROL_ALPHA < Layout.TOUCH_CONTROL_ACTIVE_ALPHA, "transparent controls gain contrast only while pressed")
	check(not Layout.TOUCH_CONTROL_PAD_RECT.intersects(Layout.TOUCH_ACTION_WHEEL_RECT), "action wheel and movement pad never overlap")
	check(not Layout.STATUS_TOUCH_RECT.intersects(Layout.TOUCH_ACTION_WHEEL_RECT), "status feedback does not overlap the action wheel")
	check(not Layout.STATUS_TOUCH_RECT.intersects(Layout.TOUCH_CONTROL_PAD_RECT), "status feedback does not overlap the movement pad")

	var action_rects := Layout.touch_action_rects()
	var actions: Array[String] = ["tongue", "leap", "boost", "depth"]
	check(action_rects.size() == actions.size(), "the left action wheel exposes exactly four core gameplay actions")
	for action: String in actions:
		var rect := Rect2(action_rects[action])
		check(Layout.rect_inside_canvas(rect, 10.0), "%s button stays inside the safe canvas" % action)
		check(rect.size.x >= 84.0 and rect.size.y >= 84.0, "%s circular button preserves the 48 dp minimum target" % action)
		check(Layout.touch_action_at(rect.get_center()) == action, "%s visible button and hit target agree" % action)
		check(rect.get_center().x < Layout.CANVAS_SIZE.x * 0.5, "%s remains in the left action cluster" % action)
		check(Layout.touch_action_at(rect.position) != action, "%s bounding-box corner cannot trigger its circular hit target" % action)
	for first in range(actions.size()):
		for second in range(first + 1, actions.size()):
			check(not Rect2(action_rects[actions[first]]).intersects(Rect2(action_rects[actions[second]])), "%s and %s buttons never overlap" % [actions[first], actions[second]])

	check(Layout.touch_action_at(Vector2(640.0,330.0)) == "", "open gameplay surface cannot accidentally steer Fred")
	check(Layout.touch_action_at(Layout.TOUCH_CONTROL_PAD_CENTER) == "steer", "right control pad owns movement input")
	check(Layout.touch_action_at(Layout.OBJECTIVE_RECT.get_center()) == "", "top objective HUD cannot accidentally steer Fred")
	check(Layout.touch_action_at(Layout.TOUCH_ACTION_WHEEL_CENTER) == "", "action-wheel center is a safe gap between the four buttons")
	var extreme := Vector2(-500.0,2000.0)
	var expected_clamp := Layout.TOUCH_CONTROL_PAD_CENTER + (extreme - Layout.TOUCH_CONTROL_PAD_CENTER).normalized() * Layout.TOUCH_CONTROL_PAD_RADIUS
	check(Layout.clamp_touch_target(extreme).is_equal_approx(expected_clamp), "drag targets clamp deterministically to the circular movement pad")

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

	var first_target := Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(60.0,0.0)
	game._handle_touch(7, first_target, true)
	check(str(game.touch_contacts.get(7,"")) == "steer", "touching the right control pad begins a steering contact")
	check(Vector2(game.touch_positions.get(7,Vector2.ZERO)) == first_target, "steering contact records its target")
	check(game.touch_movement == Vector2.RIGHT, "right control-pad pressure moves Fred right")
	check(game._active_touch_target() == first_target, "active steering target drives visible touch feedback")

	var drag_target := Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(-60.0,-50.0)
	game._move_touch(7, drag_target)
	check(Vector2(game.touch_positions.get(7,Vector2.ZERO)) == drag_target, "dragging updates the steering target")
	check(game.touch_movement.is_equal_approx(Layout.touch_movement_vector(drag_target)), "dragging continuously redirects Fred from the pad center")

	game._handle_touch(8, Rect2(action_rects.boost).get_center(), true)
	check(game.touch_boost, "a second finger can hold Boost while the first finger steers")
	check(game.touch_movement.is_equal_approx(Layout.touch_movement_vector(drag_target)), "action contacts do not disrupt touch steering")
	game._move_touch(8, Vector2(640.0,330.0))
	check(not game.touch_boost, "sliding away from Boost safely releases the held action")
	check(game.touch_movement != Vector2.ZERO, "releasing an action leaves the steering finger active")
	game._handle_touch(8, Vector2.ZERO, false)

	game._move_touch(7, Vector2(5000.0,-5000.0))
	var expected_drag_clamp := Layout.clamp_touch_target(Vector2(5000.0,-5000.0))
	check(Vector2(game.touch_positions[7]).is_equal_approx(expected_drag_clamp), "off-screen drag remains bounded inside the control pad")
	game._handle_touch(7, Vector2.ZERO, false)
	check(game.touch_movement == Vector2.ZERO and game.touch_contacts.is_empty() and game.touch_positions.is_empty(), "lifting the steering finger clears movement with no stale contact")

	game._handle_touch(4, Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(8.0,4.0), true)
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
	game._handle_touch(13, Layout.PAUSED_RESUME_RECT.get_center(), true)
	check(not game.session.paused, "foreground Resume overlay resumes play by touch")
	game._handle_touch(13, Vector2.ZERO, false)

	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(55.0,0.0)
	game._unhandled_input(mouse_down)
	check(game.pointer_touch_active and str(game.touch_contacts.get(-1,"")) == "steer", "desktop pointer emulates the phone control-pad path for owner review")
	var mouse_drag := InputEventMouseMotion.new()
	mouse_drag.position = Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(0.0,-70.0)
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
	check(main_source.contains("ACTIONS") and main_source.contains("MOVE"), "controller-like action and movement groups are visible in gameplay")
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
