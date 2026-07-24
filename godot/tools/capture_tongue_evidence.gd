extends SceneTree

const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const SAVE_PREFIX := "user://m2_tongue_capture"
const BOARD_PATH := "user://m2_tongue_capture_board.json"

func _init() -> void:
    _capture.call_deferred()

func _capture() -> void:
    for suffix: String in [".json", ".backup.json", ".tmp.json"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
    var game: Node2D = load("res://scripts/main.gd").new()
    game.saver = FredSaveAdapter.new(SAVE_PREFIX)
    game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
    game.hazards_enabled = false
    game.countdown_enabled = false
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game._start()
    game.predator = Vector2(1200, 650)

    var bug_position: Vector2 = game._bug_position(0)
    game.fred = bug_position - Vector2(120, 0)
    game._request_tongue(Vector2.RIGHT)
    game.tongue.advance(TongueTargeting.EXTEND_SECONDS * 0.72)
    game.queue_redraw()
    await process_frame
    _save("res://docs/evidence/m2-tongue-bug-hit.png")

    game.tongue.reset()
    game.collected.assign([0, 1, 2])
    game.fred = Vector2(620, 420)
    game._request_tongue(Vector2.UP)
    game.tongue.advance(TongueTargeting.EXTEND_SECONDS * 0.72)
    game.queue_redraw()
    await process_frame
    _save("res://docs/evidence/m2-tongue-miss.png")

    game.tongue.reset()
    game.level_number = 10
    game.level_profile = FredLevelIntensity.profile(10)
    game.session.health = 2
    game.fairy_collected = false
    game.fred = game._fairy_position() - Vector2(100, 0)
    game._request_tongue(Vector2.RIGHT)
    game.tongue.advance(TongueTargeting.EXTEND_SECONDS * 0.72)
    game.queue_redraw()
    await process_frame
    _save("res://docs/evidence/m2-tongue-fairy-life.png")

    game.tongue.reset()
    game.session.health = 3
    game.fairy_collected = false
    game._request_tongue(Vector2.RIGHT)
    game.tongue.advance(TongueTargeting.EXTEND_SECONDS * 0.72)
    game.queue_redraw()
    await process_frame
    _save("res://docs/evidence/m2-tongue-fairy-cap.png")

    game.session.health = 1
    game._apply_danger_hit("[DANGER] A marsh predator caught Fred!")
    game.queue_redraw()
    await process_frame
    _save("res://docs/evidence/m2-tongue-failure.png")
    game._retry()
    game.countdown_seconds = 0.0
    game.queue_redraw()
    await process_frame
    _save("res://docs/evidence/m2-tongue-retry.png")

    game.queue_free()
    await process_frame
    for suffix: String in [".json", ".backup.json", ".tmp.json"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
    print("CAPTURED 6 M2 tongue screenshots")
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
