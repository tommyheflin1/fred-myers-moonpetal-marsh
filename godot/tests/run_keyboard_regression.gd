extends SceneTree

var passed := 0
var failed := 0
var prefix := "user://m1_keyboard_regression"

func check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("PASS ", label)
    else:
        failed += 1
        push_error("FAIL " + label)

func _init() -> void:
    _run.call_deferred()

func clean_files() -> void:
    for suffix: String in [".json", ".tmp.json", ".backup.json"]:
        var path := prefix + suffix
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var leaderboard_path := prefix + "_leaderboard.json"
    if FileAccess.file_exists(leaderboard_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(leaderboard_path))

func send_key(keycode: int, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = keycode
    event.physical_keycode = keycode
    event.pressed = pressed
    event.echo = false
    Input.parse_input_event(event)
    await process_frame

func tap_key(keycode: int) -> void:
    await send_key(keycode, true)
    await send_key(keycode, false)

func tick_with_key(game: Node2D, keycode: int, delta: float = 1.0 / 60.0) -> void:
    await send_key(keycode, true)
    game._fixed_tick(delta)
    await send_key(keycode, false)

func create_game() -> Node2D:
    var game: Node2D = load("res://scripts/main.gd").new()
    game.saver = FredSaveAdapter.new(prefix)
    game.leaderboard = FredLocalLeaderboard.new(prefix + "_leaderboard.json")
    game.hazards_enabled = false
    game.countdown_enabled = false
    root.add_child(game)
    game.set_process(false)
    return game

func _run() -> void:
    clean_files()
    var game := create_game()
    await process_frame
    check(game.screen == game.Screen.TITLE, "keyboard harness starts at title")

    await tap_key(KEY_ENTER)
    check(game.screen == game.Screen.PLAYING, "Enter starts the accepted M1 level")

    game.predator = Vector2(1200, 650)
    game.fred = Vector2(400, 400)
    var before: Vector2 = game.fred
    await tick_with_key(game, KEY_D)
    check(game.fred.x > before.x, "D keyboard event moves Fred right")

    before = game.fred
    await tick_with_key(game, KEY_LEFT)
    check(game.fred.x < before.x, "Left-arrow keyboard event moves Fred left")

    before = game.fred
    await tick_with_key(game, KEY_W)
    check(game.fred.y < before.y, "W keyboard event moves Fred up")

    before = game.fred
    await tick_with_key(game, KEY_DOWN)
    check(game.fred.y > before.y, "Down-arrow keyboard event moves Fred down")

    await tick_with_key(game, KEY_SPACE)
    check(game.leap.is_airborne(), "Space keyboard event launches Fred")
    game.leap.reset()

    game.fred = Vector2(400, 400)
    var energy_before: int = game.session.boost_energy
    await send_key(KEY_D, true)
    await send_key(KEY_SHIFT, true)
    game._fixed_tick(1.0 / 60.0)
    await send_key(KEY_SHIFT, false)
    await send_key(KEY_D, false)
    check(game.session.boost_energy == energy_before - 1, "Shift keyboard event consumes boost")

    game.fred = Vector2(550, 300)
    await tap_key(KEY_Q)
    check(game.depth.is_transitioning(), "Q keyboard event begins a dive")
    for frame in range(48): game._fixed_tick(1.0 / 60.0)
    check(game.session.player_state == "underwater", "Q keyboard transition reaches underwater")
    await tap_key(KEY_E)
    check(game.depth.is_transitioning(), "E keyboard event begins surfacing")
    for frame in range(48): game._fixed_tick(1.0 / 60.0)
    check(game.session.player_state == "surface", "E keyboard transition reaches the surface")

    await tap_key(KEY_P)
    check(game.session.paused, "P keyboard event pauses")
    await tap_key(KEY_ESCAPE)
    check(not game.session.paused, "Escape keyboard event resumes")

    game.session.health = 1
    game.predator = Vector2(500, 500)
    game.fred = game.predator
    game._fixed_tick(0.0)
    check(game.screen == game.Screen.FAILED and game.session.health == 0, "predator collision reaches accepted failure state")
    await tap_key(KEY_R)
    check(game.screen == game.Screen.PLAYING and game.session.health == 3, "R keyboard event retries from failure")

    game.predator = Vector2(1200, 650)
    game.fred = Vector2(630, 390)
    game._fixed_tick(0.0)
    check(
        game.session.current_checkpoint == AdventureSession.CHECKPOINTS[1]
        and FileAccess.file_exists(prefix + ".json"),
        "midpoint collision saves the accepted checkpoint"
    )

    game.queue_free()
    await process_frame
    game = create_game()
    await process_frame
    check(
        game.screen == game.Screen.TITLE
        and game.session.current_checkpoint == AdventureSession.CHECKPOINTS[1],
        "new runtime restores midpoint save"
    )
    await tap_key(KEY_ENTER)
    check(game.screen == game.Screen.PLAYING and game.fred == Vector2(630, 390), "Enter resumes at restored checkpoint")

    game.predator = Vector2(1200, 650)
    for index in game.BUGS.size():
        var bug: Vector2 = game._bug_position(index)
        game.fred = bug + Vector2(-110, 0)
        game.last_aim_direction = Vector2.RIGHT
        await tick_with_key(game, KEY_F)
        game.tongue.advance(1.0)
    check(game.session.bug_count == 3, "F keyboard events aim and eat all three bugs")
    check(game.tongue.shot_serial == 3, "keyboard interaction produces one tongue shot per press")

    game.fred = game.EXIT + Vector2(-24, 0)
    await tick_with_key(game, KEY_D, 0.1)
    check(
        game.screen == game.Screen.COMPLETE
        and game.session.completed
        and game.session.current_checkpoint == AdventureSession.CHECKPOINTS[2],
        "keyboard traversal completes Lily Leap"
    )
    check(FileAccess.file_exists(prefix + ".json"), "keyboard completion persists the accepted save")

    game.queue_free()
    await process_frame
    clean_files()
    print("RESULT keyboard_passed=%d keyboard_failed=%d" % [passed, failed])
    quit(1 if failed else 0)
