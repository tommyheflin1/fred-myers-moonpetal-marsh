extends SceneTree

const Main = preload("res://scripts/main.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _run() -> void:
	for paused in [false, true]:
		var game := Main.new()
		root.add_child(game)
		await process_frame
		game.set_process(false)
		for player: AudioStreamPlayer in [game.menu_music, game.chase_music, game.golden_chime]:
			check(player.stream != null, "all game streams exist before teardown")
			player.play()
			player.stream_paused = paused
		root.remove_child(game)
		for player: AudioStreamPlayer in [game.menu_music, game.chase_music, game.golden_chime]:
			check(not player.playing and player.stream == null, "scene removal clears active and paused audio")
		game._exit_tree()
		game.free()
		await process_frame
	print("AUDIO_TEARDOWN: ", checks, " checks, ", failures, " failed")
	quit(1 if failures else 0)
