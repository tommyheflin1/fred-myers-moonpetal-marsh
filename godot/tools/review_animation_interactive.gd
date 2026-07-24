extends SceneTree

const SAVE_PREFIX := "user://m2_animation_interactive_review"
const BOARD_PATH := "user://m2_animation_interactive_review_board.json"
var game: Node2D

func _init() -> void:
	_review.call_deferred()

func _review() -> void:
	_clean()
	root.get_window().title = "Fred M2 Animation Interactive Review"
	game = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	root.add_child(game)
	await process_frame
	game.menu_music.volume_db = -80.0
	game.chase_music.volume_db = -80.0
	game._set_feedback("[LOCAL REVIEW] Isolated save; audio muted.")

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
