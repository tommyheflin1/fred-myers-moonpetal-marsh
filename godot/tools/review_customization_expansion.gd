extends SceneTree

const Customization = preload("res://scripts/frog_customization.gd")
const SAVE_PREFIX := "user://customization_expansion_review"
const BOARD_PATH := "user://customization_expansion_review_board.json"

func _init() -> void:
	_review.call_deferred()

func _review() -> void:
	var requested_index := clampi(int(OS.get_environment("FRED_CUSTOM_LOOK_INDEX")), 0, 4)
	var requested_size := OS.get_environment("FRED_CUSTOM_REVIEW_SIZE").strip_edges().to_lower()
	var window_size := Vector2i(1280,720)
	if requested_size == "960x540":
		window_size = Vector2i(960,540)
	elif requested_size == "640x360":
		window_size = Vector2i(640,360)
	root.get_window().size = window_size
	root.get_window().title = "Fred Customization Expansion - Look %d - %s" % [requested_index + 1, requested_size if not requested_size.is_empty() else "1280x720"]
	var game: Node2D = load("res://scripts/main.gd").new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.customization = Customization.new("")
	game.customization.coins = Customization.MAX_COINS
	for category: String in Customization.BUILD_2_EXPANSION_IDS:
		var all_ids: Array[String] = []
		for entry: Dictionary in Customization.CATALOG[category]:
			all_ids.append(str(entry.id))
		game.customization.owned[category] = all_ids
		game.customization.selected[category] = str(Customization.BUILD_2_EXPANSION_IDS[category][requested_index])
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.screen = game.Screen.CUSTOMIZE
	game._sync_fred_style()
	game.queue_redraw()
