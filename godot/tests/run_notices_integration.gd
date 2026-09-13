extends SceneTree

const Main = preload("res://scripts/main.gd")
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
	check(not game.third_party_notices.visible, "notices start hidden")
	check(not Main.TITLE_LICENSES_RECT.intersects(Main.TITLE_PENDING_EGG_RECT), "licenses never overlap saved discovery")
	game.golden_pending_review_available = true
	game._handle_click(Vector2(1110, 655))
	check(game.screen == Main.Screen.TITLE, "old saved discovery touch target cannot reopen closed event")
	check(not game.third_party_notices.visible, "saved discovery touch never opens notices")
	game.screen = Main.Screen.TITLE
	game._handle_click(Main.TITLE_LICENSES_RECT.get_center())
	check(game.third_party_notices.visible, "title opens readable notices")
	check(game.third_party_notices.notice_text.text.contains("MIT License"), "actual notices populated")
	game._handle_click(Main.TITLE_START_RECT.get_center())
	check(game.screen == Main.Screen.TITLE, "click cannot pass through notices")
	game._handle_touch(0, Main.TITLE_START_RECT.get_center(), true)
	check(game.screen == Main.Screen.TITLE, "touch cannot pass through notices")
	check(game._handle_back_request() == "licenses_closed", "back closes notices instead of quitting")
	check(not game.third_party_notices.visible, "notices closed")
	game._handle_click(Main.TITLE_START_RECT.get_center())
	check(game.screen == Main.Screen.STORY, "normal title action resumes after close")
	game.queue_free()
	await process_frame
	print("NOTICES_INTEGRATION: ", checks, " checks, ", failures, " failed")
	quit(1 if failures else 0)
