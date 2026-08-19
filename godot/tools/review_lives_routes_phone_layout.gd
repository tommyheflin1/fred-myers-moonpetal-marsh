extends SceneTree

const Layout = preload("res://scripts/marsh_route_layout.gd")
const SAVE_PREFIX := "user://lives_routes_phone_review"
const BOARD_PATH := "user://lives_routes_phone_review_board.json"

func _init() -> void:
	_review.call_deferred()

func _review() -> void:
	_clean()
	var scenario := OS.get_environment("FRED_PHONE_REVIEW").strip_edges().to_lower()
	if scenario.is_empty():
		scenario = "level2"
	var requested_size := OS.get_environment("FRED_PHONE_REVIEW_SIZE").strip_edges().to_lower()
	var window_size := Vector2i(1280,720)
	if requested_size == "960x540":
		window_size = Vector2i(960,540)
	elif requested_size == "640x360":
		window_size = Vector2i(640,360)
	root.get_window().size = window_size
	root.get_window().title = "Fred Myers - Phone Layout Review - %s - %s" % [scenario, requested_size if not requested_size.is_empty() else "1280x720"]

	var game: Node2D = load("res://scripts/main.gd").new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.touch_controls_visible = true
	root.add_child(game)
	await process_frame
	game._start()
	if scenario == "level1":
		game.level_number = 1
	elif scenario == "predators":
		game.level_number = 100
	else:
		game.level_number = 2
	game.level_profile = FredLevelIntensity.profile(game.level_number)
	game.session = AdventureSession.new(1337 + game.level_number)
	game.session.health = 2 if scenario == "lives" else 3
	game.fred = game._level_start_position()
	game.predator = game._route_point(game.PREDATOR_START)
	game.predator_direction = -1.0 if Layout.is_reversed(game.level_number) else 1.0
	game.last_aim_direction = Layout.route_direction(game.level_number)
	game._set_feedback(
		"[PHONE REVIEW] Two lives remain after one hit."
		if scenario == "lives"
		else (
			"[SPECIES REVIEW] Bass, pike, heron, snake and muskie use distinct anatomy."
			if scenario == "predators"
			else "[PHONE REVIEW] %s route with touch controls." % Layout.route_label(game.level_number)
		)
	)
	game.queue_redraw()

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
