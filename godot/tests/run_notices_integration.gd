extends SceneTree

const Main = preload("res://scripts/main.gd")
const Notices = preload("res://scripts/third_party_notices.gd")
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.saver = FredSaveAdapter.new("user://notices_integration")
	game.leaderboard = FredLocalLeaderboard.new("user://notices_integration_board.json")
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var title_source := main_source.split("func _draw_title() -> void:")[1].split("\nfunc ")[0]
	check(not main_source.contains("TITLE_LICENSES_RECT"), "title exposes no license touch target")
	check(not title_source.contains("LICENSES"), "title draws no license button")
	check(not main_source.contains("third_party_notices.open()"), "gameplay exposes no license modal")
	check(Notices.runtime_notices().contains("MIT License"), "required notices remain packaged")
	game.golden_pending_review_available = true
	game._handle_click(Vector2(1110, 655))
	check(game.screen == Main.Screen.TITLE, "old saved discovery touch target cannot reopen closed event")
	game._handle_click(Main.TITLE_START_RECT.get_center())
	check(game.screen == Main.Screen.STORY, "normal title action remains available")
	game.queue_free()
	await process_frame
	print("NOTICES_INTEGRATION: ", checks, " checks, ", failures, " failed")
	quit(1 if failures else 0)
