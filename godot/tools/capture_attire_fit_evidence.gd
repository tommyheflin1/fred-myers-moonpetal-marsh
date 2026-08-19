extends SceneTree

const Customization = preload("res://scripts/frog_customization.gd")
const SAVE_PREFIX := "user://m2_attire_fit_capture"
const BOARD_PATH := "user://m2_attire_fit_capture_board.json"
const ATTIRE_IDS: Array[String] = [
	"marsh_runner",
	"trail_scout",
	"moon_champion",
	"firefly_hero",
]

var game: Node2D

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	_clean()
	root.get_window().title = "Fred Attire Fit Evidence"
	root.get_window().size = Vector2i(1280, 720)
	game = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.customization = Customization.new("")
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.screen = game.Screen.CUSTOMIZE
	game.customization.coins = 999
	game.customization.owned.attire = ATTIRE_IDS.duplicate()
	for attire_id: String in ATTIRE_IDS:
		game.customization.selected.attire = attire_id
		game._sync_fred_style()
		game.queue_redraw()
		await process_frame
		await process_frame
		await _save("res://docs/evidence/app-build-1-r16-attire-%s.png" % attire_id)
	game.queue_free()
	await process_frame
	_clean()
	print("CAPTURED 4 tailored, mouth-clear Fred attire screenshots")
	quit()

func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		push_error("Screenshot image unavailable: " + path)
		quit(1)
		return
	var error := image.save_png(path)
	if error != OK:
		push_error("Screenshot save failed: " + path)
		quit(1)

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
