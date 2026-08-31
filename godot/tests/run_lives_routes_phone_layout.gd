extends SceneTree

const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

const SAVE_PREFIX := "user://lives_routes_phone_layout"
const BOARD_PATH := "user://lives_routes_phone_layout_board.json"

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
	for rect: Rect2 in [Layout.OBJECTIVE_RECT,Layout.CAMPAIGN_TEXT_RECT,Layout.ROUTE_SUMMARY_RECT,Layout.LIVES_RECT,Layout.PAUSE_RECT,Layout.HOME_RECT,Layout.ENERGY_LABEL_RECT,Layout.ENERGY_RECT,Layout.TOUCH_ACTION_WHEEL_RECT,Layout.TOUCH_CONTROL_PAD_RECT]:
		check(not Layout.DEPTH_STATUS_RECT.intersects(rect), "depth status owns a separate HUD area")
	for cue: String in ["DIVING", "UNDERWATER", "SURFACING"]:
		var text_size := ThemeDB.fallback_font.get_string_size("[%s] DEPTH 100%%" % cue, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		check(text_size.x <= Layout.DEPTH_STATUS_RECT.size.x - 16, cue + " text fits inside the depth status area")
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.level_number = 5
	game.level_profile = FredLevelIntensity.profile(5)
	game.session = AdventureSession.new(1342)
	game.screen = Main.Screen.PLAYING
	game.fred = game._level_start_position()

	game._apply_danger_hit("[DANGER] First test hit.")
	check(game.session.health == 2, "first danger hit consumes exactly one of three lives")
	check(game.screen == Main.Screen.PLAYING and game.level_number == 5, "first hit keeps the current level active")
	check(game.fred == game._level_start_position(), "first hit returns to this level's starting perch")
	check(is_equal_approx(game.danger_cooldown_seconds, float(game.level_profile.mistake_grace_seconds)), "first hit grants age-calibrated deterministic damage grace")
	check(is_equal_approx(game.countdown_seconds, Main.RESPAWN_COUNTDOWN_SECONDS), "first hit grants a readable respawn countdown")
	var first_restore := AdventureSession.new()
	check(
		bool(game.saver.load_session(first_restore).get("ok", false))
		and first_restore.health == 2,
		"first life loss is durably saved without resetting the run"
	)

	check(
		game.session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1),
		"midpoint fixture reaches the canonical checkpoint"
	)
	game.danger_cooldown_seconds = 0.0
	game.countdown_seconds = 0.0
	game.fred = Vector2(1000.0,500.0)
	game._apply_danger_hit("[DANGER] Second test hit.")
	check(game.session.health == 1, "second danger hit consumes exactly one additional life")
	check(game.screen == Main.Screen.PLAYING and game.level_number == 5, "second hit still cannot open failure or reset the level")
	check(game.fred == game._pad_position(3), "second hit resumes at the reached midpoint checkpoint")
	var second_restore := AdventureSession.new()
	check(
		bool(game.saver.load_session(second_restore).get("ok", false))
		and second_restore.health == 1
		and second_restore.checkpoint_sequence == 1,
		"second life loss and checkpoint remain recoverable in save v1"
	)

	game.danger_cooldown_seconds = 0.0
	game.countdown_seconds = 0.0
	game._apply_danger_hit("[DANGER] Final test hit.")
	check(game.session.health == 0 and game.screen == Main.Screen.FAILED, "failure opens only after the third life is consumed")
	game._retry()
	check(game.level_number == 1 and game.session.health == 3, "Try Again begins a fresh three-life run at level one")

	game.level_number = 1
	game.level_profile = FredLevelIntensity.profile(1)
	game.simulation_time = 0.0
	var odd_start: Vector2 = game._level_start_position()
	var odd_exit: Vector2 = game._level_exit_position()
	var odd_first_pad: Vector2 = game._pad_position(0)
	var odd_last_pad: Vector2 = game._pad_position(game.PADS.size() - 1)
	game.level_number = 2
	game.level_profile = FredLevelIntensity.profile(2)
	game.simulation_time = 0.0
	var even_start: Vector2 = game._level_start_position()
	var even_exit: Vector2 = game._level_exit_position()
	var even_first_pad: Vector2 = game._pad_position(0)
	var even_last_pad: Vector2 = game._pad_position(game.PADS.size() - 1)
	check(odd_start.x < odd_exit.x and odd_first_pad.x < odd_last_pad.x, "odd levels author a left-to-right lily route")
	check(even_start.x > even_exit.x and even_first_pad.x > even_last_pad.x, "even levels author a right-to-left lily route")
	check(Layout.route_label(1) == "LEFT TO RIGHT" and Layout.route_label(2) == "RIGHT TO LEFT", "HUD route labels match the playable direction")
	check(is_equal_approx(odd_start.x + even_start.x, Layout.CANVAS_SIZE.x), "alternating starts mirror across the logical phone canvas")
	check(is_equal_approx(odd_start.x, Layout.TOUCH_ACTION_WHEEL_CENTER.x), "odd-route Fred starts directly above the left action wheel")
	check(odd_start.y + Layout.TOUCH_ACTOR_CLEARANCE <= Layout.TOUCH_ACTION_WHEEL_RECT.position.y, "Fred starts clear above the action wheel")
	check(is_equal_approx(even_start.x, Layout.TOUCH_CONTROL_PAD_CENTER.x), "reversed-route Fred starts directly above the right movement pad")
	check(is_equal_approx(odd_exit.x + even_exit.x, Layout.CANVAS_SIZE.x), "alternating exits mirror without entering the top HUD")
	game.level_number = 4
	game.level_profile = FredLevelIntensity.profile(4)
	check(game._current_vector().x < 0.0, "the first gentle even-level current supports the reversed route")

	var labels: Array[String] = []
	for level in range(1, 7):
		labels.append(Layout.background_label(level))
	var unique_labels: Dictionary = {}
	for label in labels: unique_labels[label] = true
	check(unique_labels.size() == 6, "six consecutive levels expose distinct deterministic background treatments")
	check(Layout.background_variant(7) == Layout.background_variant(1), "background variety cycles deterministically after six levels")

	var hud := Layout.essential_rects(true)
	for key: String in hud:
		check(Layout.rect_inside_canvas(Rect2(hud[key]), 10.0), "%s stays inside the phone-safe logical canvas" % key)
	check(not Rect2(hud.objective).intersects(Rect2(hud.lives)), "objective and lives panels do not overlap")
	check(not Rect2(hud.lives).intersects(Rect2(hud.pause)), "lives and Pause panels do not overlap")
	check(not Rect2(hud.pause).intersects(Rect2(hud.home)), "Pause and Exit panels do not overlap")
	check(not Rect2(hud.objective).intersects(Rect2(hud.campaign)), "objective border clears the campaign metadata band")
	check(not Rect2(hud.lives).intersects(Rect2(hud.campaign)), "lives border clears the campaign metadata band")
	check(not Rect2(hud.energy).intersects(Rect2(hud.route_summary)), "energy meter and route/threat words own separate layout bands")
	check(not Rect2(hud.energy_label).intersects(Rect2(hud.route_summary)), "energy words and route/threat words own separate layout bands")
	check(Rect2(hud.energy_label).end.x + 5.0 <= Rect2(hud.energy).position.x, "energy words sit beside rather than on top of the fill bar")
	check(Rect2(hud.objective).end.y + 3.0 <= Rect2(hud.campaign).position.y, "top panels keep a visible gap above metadata words")
	check(not Rect2(hud.energy).intersects(Rect2(hud.status)), "energy and status panels remain separated")
	check(Rect2(hud.energy).end.y + 7.0 <= Layout.PLAYFIELD_RECT.position.y, "compact energy panel stays clear of the marsh playfield")

	var centers := Layout.touch_centers()
	var radii := Layout.touch_radii()
	var actions: Array[String] = ["tongue", "leap", "depth", "boost"]
	check(Layout.TOUCH_ACTION_WHEEL_RECT.position.x <= 50.0, "action wheel occupies the easy-reach left thumb edge")
	for action: String in actions:
		var center := Vector2(centers[action])
		var radius := float(radii[action])
		check(Layout.rect_inside_canvas(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), 10.0), "%s touch target stays inside the canvas" % action)
		check(Layout.touch_action_at(center) == action, "%s visual and hit target share one layout contract" % action)
	for first in range(actions.size()):
		for second in range(first + 1, actions.size()):
			check(
				not Layout.circles_overlap(
					Vector2(centers[actions[first]]),
					float(radii[actions[first]]),
					Vector2(centers[actions[second]]),
					float(radii[actions[second]])
				),
				"%s and %s touch targets do not overlap" % [actions[first], actions[second]]
			)
	var minimum_phone_dp := float(radii.depth) * 2.0 * 1.5 / (420.0 / 160.0)
	check(minimum_phone_dp >= 48.0, "smallest action target remains at least 48 dp on the tested 420-dpi profile")

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(
		not stable_save.has("route")
		and not stable_save.has("background")
		and not stable_save.has("layout")
		and not stable_save.has("touch"),
		"route, background and phone layout remain transient outside save v1"
	)

	game.menu_music.stop()
	game.chase_music.stop()
	await process_frame
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	await process_frame
	clean_files()
	print("RESULT lives_routes_phone_layout_passed=%d lives_routes_phone_layout_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
