extends SceneTree

# Real packaged streams with the dummy audio driver; not a device listening test.
const Main = preload("res://scripts/main.gd")
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new("user://soundtrack_test")
	game.leaderboard = FredLocalLeaderboard.new("user://soundtrack_board.json")
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for player: AudioStreamPlayer in [game.menu_music, game.chase_music]:
		check(player.stream is AudioStreamMP3, "packaged MP3 loads")
		check(player.stream != null and player.stream.get_length() > 1.0, "track has decoded duration")
		check(player.stream is AudioStreamMP3 and player.stream.loop, "track looping enabled")
		if player.stream != null:
			player.play(player.stream.get_length() - 0.05)
			await create_timer(0.35).timeout
			check(player.playing and player.get_playback_position() < 1.0, "packaged track wraps at its end without stopping")
			player.stop()
	game._sync_music()
	await process_frame
	check(game.menu_music.playing and not game.chase_music.playing, "title plays only menu track")
	game._start()
	await process_frame
	check(game.chase_music.playing and not game.menu_music.playing, "gameplay switches to chase without overlap")
	game._set_gameplay_paused(true)
	check(game.session.paused, "gameplay pause still works with audio enabled")
	check(game.chase_music.playing and not game.menu_music.playing, "pause preserves single gameplay track")
	game.golden_chime.play()
	await process_frame
	game._handle_application_paused()
	check(game.chase_music.stream_paused and not game.menu_music.playing, "background suspends active music and leaves stopped music silent")
	check(game.golden_chime.stream_paused, "background suspends discovery chime")
	game._handle_application_resumed()
	check(not game.menu_music.stream_paused and not game.chase_music.stream_paused, "foreground restores stream state")
	check(not game.golden_chime.stream_paused, "foreground restores discovery chime state")
	check(game.session.paused, "foreground does not resume gameplay automatically")
	for screen: int in Main.Screen.values():
		game.screen = screen
		game._sync_music()
		await process_frame
		var menu_expected: bool = screen in [Main.Screen.TITLE, Main.Screen.STORY, Main.Screen.INSTRUCTIONS, Main.Screen.LEADERBOARD, Main.Screen.CUSTOMIZE]
		check(game.menu_music.playing == menu_expected and game.chase_music.playing != menu_expected, "exclusive soundtrack route for screen %d" % screen)
	game.audio_enabled = false
	game._sync_music()
	check(not game.menu_music.playing and not game.chase_music.playing, "audio disabled stops both tracks")
	game.audio_enabled = true
	game._go_home()
	await process_frame
	check(game.menu_music.playing and not game.chase_music.playing, "home restores menu soundtrack")
	game.queue_free()
	await process_frame
	# Give the audio mixer a callback after deferred scene destruction before exit.
	await create_timer(0.1).timeout
	print("SOUNDTRACK_LIFECYCLE: ", passed, " passed, ", failed, " failed; device mix and audible loop seams not assessed")
	quit(1 if failed else 0)
