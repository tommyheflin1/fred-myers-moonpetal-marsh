extends SceneTree

const REVIEW_SAVE_PREFIX := "user://m2_tongue_review"
const REVIEW_BOARD_PATH := "user://m2_tongue_review_board.json"

func _init() -> void:
    _prepare.call_deferred()

func _prepare() -> void:
    var scenario := OS.get_environment("FRED_TONGUE_REVIEW").strip_edges().to_lower()
    if scenario.is_empty():
        scenario = "bug"
    var game: Node2D = load("res://scripts/main.gd").new()
    game.saver = FredSaveAdapter.new(REVIEW_SAVE_PREFIX)
    game.leaderboard = FredLocalLeaderboard.new(REVIEW_BOARD_PATH)
    game.hazards_enabled = false
    game.countdown_enabled = false
    root.add_child(game)
    await process_frame
    game._start()
    game.predator = Vector2(1200, 650)
    game.countdown_seconds = 0.0
    match scenario:
        "miss":
            game.collected.assign([0, 1, 2])
            game.fred = Vector2(620, 420)
            game.last_aim_direction = Vector2.UP
            game._set_feedback("[OWNER REVIEW] Press F to verify an out-of-range miss.")
        "fairy-life":
            game.level_number = 10
            game.level_profile = FredLevelIntensity.profile(10)
            game.collected.assign([0, 1, 2])
            game.session.health = 2
            game.fairy_collected = false
            game.fred = game._fairy_position() - Vector2(100, 0)
            game.last_aim_direction = Vector2.RIGHT
            game._set_feedback("[OWNER REVIEW] Press F to eat the level-ten fairy.")
        "fairy-cap":
            game.level_number = 10
            game.level_profile = FredLevelIntensity.profile(10)
            game.collected.assign([0, 1, 2])
            game.session.health = 3
            game.fairy_collected = false
            game.fred = game._fairy_position() - Vector2(100, 0)
            game.last_aim_direction = Vector2.RIGHT
            game._set_feedback("[OWNER REVIEW] Press F to verify the three-life cap.")
        "failure":
            game.session.health = 1
            game._apply_danger_hit("[DANGER] Owner-review predator contact.")
        _:
            var bug_position: Vector2 = game._bug_position(0)
            game.fred = bug_position - Vector2(110, 0)
            game.last_aim_direction = Vector2.RIGHT
            game._set_feedback("[OWNER REVIEW] Press F or right-click the nearby bug.")
    game.queue_redraw()
