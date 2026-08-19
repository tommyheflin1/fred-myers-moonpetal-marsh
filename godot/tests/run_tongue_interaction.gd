extends SceneTree

const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

const SAVE_PREFIX := "user://m2_tongue_test"
const BOARD_PATH := "user://m2_tongue_board.json"

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("PASS ", label)
    else:
        failed += 1
        push_error("FAIL " + label)

func clean_files() -> void:
    for suffix: String in [".json", ".backup.json", ".tmp.json"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))

func candidate(id: String, position: Vector2, eligible: bool = true, reason: String = "") -> Dictionary:
    return {
        "id": id,
        "kind": "bug",
        "position": position,
        "eligible": eligible,
        "blocked_reason": reason,
    }

func _init() -> void:
    _run.call_deferred()

func _run() -> void:
    clean_files()
    var origin := Vector2(100, 100)
    var tongue := TongueTargeting.new()
    check(tongue.is_ready() and tongue.cue() == "TONGUE READY", "tongue starts ready with an explicit cue")

    var ordered: Array[Dictionary] = [
        candidate("bug:far", origin + Vector2(170, 0)),
        candidate("bug:near", origin + Vector2(90, 0)),
        candidate("bug:angled", origin + Vector2(80, 20)),
    ]
    var selected := tongue.request(origin, Vector2.RIGHT, ordered)
    check(bool(selected.accepted) and str(selected.target_id) == "bug:near", "smallest aim angle wins before distance")
    check(tongue.state == TongueTargeting.State.EXTENDING and tongue.shot_serial == 1, "accepted input starts one extension")
    var rejected := tongue.request(origin, Vector2.RIGHT, ordered)
    check(not bool(rejected.accepted) and str(rejected.outcome) == "cooldown", "cooldown spam is rejected")
    check(tongue.shot_serial == 1, "cooldown spam cannot double-trigger")
    tongue.advance(TongueTargeting.EXTEND_SECONDS)
    check(tongue.state == TongueTargeting.State.RECOVERING, "extension enters deterministic recovery")
    tongue.advance(TongueTargeting.RECOVERY_SECONDS)
    check(tongue.is_ready() and tongue.cue() == "TONGUE READY", "recovery returns to an explicit ready cue at the documented cooldown")

    var tie_a := candidate("bug:a", origin + Vector2(100, 0))
    var tie_b := candidate("bug:b", origin + Vector2(100, 0))
    selected = tongue.request(origin, Vector2.RIGHT, [tie_b, tie_a])
    check(str(selected.target_id) == "bug:a", "stable identifier breaks exact geometry ties")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [tie_a, tie_b])
    check(str(selected.target_id) == "bug:a", "candidate input order cannot change an exact tie")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)

    var cone_edge := origin + Vector2.from_angle(deg_to_rad(TongueTargeting.CONE_HALF_ANGLE_DEGREES)) * 150.0
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:edge", cone_edge)])
    check(str(selected.target_id) == "bug:edge", "documented cone boundary remains eligible")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    var outside_cone := origin + Vector2.from_angle(deg_to_rad(TongueTargeting.CONE_HALF_ANGLE_DEGREES + 0.2)) * 150.0
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:outside", outside_cone)])
    check(str(selected.outcome) == "miss", "target beyond cone boundary is a miss")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:close-behind", origin + Vector2(-TongueTargeting.PROXIMITY_ASSIST_RANGE, 0))])
    check(str(selected.target_id) == "bug:close-behind", "close prey at the assist boundary is captured regardless of aim cone")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:outside-assist", origin + Vector2(-TongueTargeting.PROXIMITY_ASSIST_RANGE - 0.1, 0))])
    check(str(selected.outcome) == "miss", "prey behind Fred and beyond close assist still requires aiming")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [
        candidate("bug:aimed-far", origin + Vector2(160, 0)),
        candidate("bug:close-side", origin + Vector2(0, 75)),
    ])
    check(str(selected.target_id) == "bug:close-side", "close assist consistently prioritizes nearby prey over a distant cone target")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:max", origin + Vector2(TongueTargeting.MAX_RANGE, 0))])
    check(str(selected.target_id) == "bug:max", "maximum-range boundary remains eligible")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:farther", origin + Vector2(TongueTargeting.MAX_RANGE + 0.1, 0))])
    check(str(selected.outcome) == "miss", "target beyond maximum range is rejected")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.RIGHT, [candidate("bug:gone", origin + Vector2(80, 0), false, "despawned")])
    check(str(selected.outcome) == "blocked" and str(selected.reason) == "despawned", "despawned candidate is safely blocked")
    tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    selected = tongue.request(origin, Vector2.ZERO, [candidate("bug:fallback", origin + Vector2(80, 0))])
    check(str(selected.target_id) == "bug:fallback", "neutral aim uses the last deterministic direction")
    tongue.reset()
    check(tongue.is_ready() and tongue.target_id.is_empty(), "reset clears transient target state")

    var repeated_id := ""
    for scenario in range(20):
        var repeat := TongueTargeting.new()
        var scenario_candidates: Array[Dictionary] = []
        if scenario % 2 == 0:
            scenario_candidates.assign([tie_b, tie_a])
        else:
            scenario_candidates.assign([tie_a, tie_b])
        var repeat_result := repeat.request(origin, Vector2.RIGHT, scenario_candidates)
        if scenario == 0:
            repeated_id = str(repeat_result.target_id)
        check(str(repeat_result.target_id) == repeated_id, "seeded target selection %02d is repeatable" % (scenario + 1))

    var game: Node2D = Main.new()
    game.saver = FredSaveAdapter.new(SAVE_PREFIX)
    game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
    game.hazards_enabled = false
    game.countdown_enabled = false
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game._start()
    game.predator = Vector2(1200, 650)
    check(game.screen == game.Screen.PLAYING, "focused game enters playable state")

    var bug_zero: Vector2 = game._bug_position(0)
    game.fred = bug_zero - Vector2(120, 0)
    var first_hit: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(str(first_hit.outcome) == "hit" and str(first_hit.target_id) == "bug:000", "aimed surface tongue captures the intended bug")
    check(game.session.bug_count == 1 and 0 in game.collected, "successful bug hit advances the existing objective once")
    check(game.save_feedback.begins_with("[MUNCH!]"), "successful capture has non-color readable feedback")
    check(game.eat_effect_seconds > 0.0 and game.eat_target == bug_zero, "successful capture retains Fred's eating presentation")
    var serial_after_hit: int = game.tongue.shot_serial
    var count_after_hit: int = game.session.bug_count
    var cooldown_result: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(not bool(cooldown_result.accepted) and game.session.bug_count == count_after_hit, "cooldown input cannot duplicate a bug")
    check(game.tongue.shot_serial == serial_after_hit, "cooldown rejection preserves one input to one shot")
    game.tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    check(not game._consume_tongue_target("bug:000", "bug"), "already-consumed bug is rejected as stale")

    game.collected.assign([0, 1, 2])
    game.tongue.reset()
    var miss_result: Dictionary = game._request_tongue(Vector2.UP)
    check(str(miss_result.outcome) == "miss" and game.save_feedback.begins_with("[TONGUE MISS]"), "empty aim cone produces explicit miss feedback")
    game.tongue.reset()
    game.session.paused = true
    var paused_result: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(not bool(paused_result.accepted) and not game.tongue.is_busy(), "pause takes precedence over tongue input")
    game.session.paused = false

    game.collected.clear()
    game.fred = game._bug_position(1) - Vector2(110, 0)
    game.tongue.reset()
    game._request_tongue(Vector2.RIGHT)
    var elapsed_before_pause: float = game.tongue.elapsed
    game.session.paused = true
    game._process(0.25)
    check(game.tongue.elapsed == elapsed_before_pause, "pause freezes active tongue recovery")
    game.session.paused = false
    game.tongue.reset()

    game.leap.request(Vector2.RIGHT)
    var airborne_result: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(not bool(airborne_result.accepted) and str(airborne_result.reason) == "airborne", "leap takes precedence over tongue")
    game.leap.reset()
    game.depth.reset("underwater")
    game.session.set_underwater(true)
    var underwater_result: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(not bool(underwater_result.accepted) and str(underwater_result.reason) == "depth", "underwater state blocks surface-prey tongue")
    game.depth.reset("surface")
    game.session.set_underwater(false)
    game.fred = Vector2(550, 300)
    game.depth.request_dive(true)
    var diving_result: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(not bool(diving_result.accepted) and str(diving_result.reason) == "depth", "dive transition takes precedence over tongue")
    game.depth.reset("surface")

    game.level_number = 9
    game.level_profile = FredLevelIntensity.profile(9)
    game.fairy_collected = false
    check(not game._fairy_available(), "non-tenth level exposes no fairy target")
    var no_fairy_candidates: Array[Dictionary] = game._tongue_candidates()
    var contains_fairy := false
    for item: Dictionary in no_fairy_candidates:
        contains_fairy = contains_fairy or str(item.kind) == "fairy"
    check(not contains_fairy, "non-tenth candidate list contains no hidden fairy")

    game.level_number = 10
    game.level_profile = FredLevelIntensity.profile(10)
    game.collected.assign([0, 1, 2])
    game.fairy_collected = false
    game.session.health = 3
    game.fred = game._fairy_position() - Vector2(100, 0)
    game.tongue.reset()
    var stacking_fairy: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(str(stacking_fairy.outcome) == "hit" and str(stacking_fairy.target_kind) == "fairy", "level-ten fairy remains eligible at three lives")
    check(game.fairy_collected and game.session.health == 4, "level-ten fairy stacks a fourth life")
    check(game.save_feedback.begins_with("[FAIRY FEAST]"), "fairy capture has child-friendly explicit feedback")
    game.tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    var fairy_hit: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(str(fairy_hit.outcome) == "miss" and game.fairy_collected, "collected fairy disappears from the tongue target list")
    check(game.session.health == 4, "fairy tongue capture grants exactly one stacking life")
    game.tongue.advance(TongueTargeting.COOLDOWN_SECONDS)
    var fairy_repeat: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(str(fairy_repeat.outcome) == "miss" and game.session.health == 4, "single-use fairy cannot grant a duplicate life")
    game.fairy_collected = false
    game.session.health = AdventureSession.MAX_LIVES
    game.tongue.reset()
    var campaign_cap: Dictionary = game._request_tongue(Vector2.RIGHT)
    check(str(campaign_cap.outcome) == "blocked" and str(campaign_cap.reason) == "campaign_life_limit", "only the bounded campaign maximum blocks a fairy")

    game.level_number = 1
    game.level_profile = FredLevelIntensity.profile(1)
    game.collected.clear()
    game.fairy_collected = false
    game.tongue.reset()
    game.fred = game._bug_position(0) - Vector2(100, 0)
    var adapter_event := InputEventAction.new()
    adapter_event.action = "interact"
    adapter_event.pressed = true
    adapter_event.device = 1
    check(FredInputIntent.event_to_intent(adapter_event) == FredInputIntent.Intent.INTERACT, "synthetic controller action maps to interact intent")
    var adapter_count_before: int = game.session.bug_count
    game._unhandled_input(adapter_event)
    check(game.session.bug_count == adapter_count_before + 1 and game.tongue.shot_serial > 0, "synthetic controller adapter invokes the shared tongue mechanic")
    var adapter_count: int = game.session.bug_count
    game._unhandled_input(adapter_event)
    check(game.session.bug_count == adapter_count, "repeated controller adapter event cannot double-trigger during recovery")

    game.tongue.reset()
    game.fred = game._bug_position(1) - Vector2(100, 0)
    var touch_event := InputEventAction.new()
    touch_event.action = "interact"
    touch_event.pressed = true
    touch_event.device = 2
    check(FredInputIntent.event_to_intent(touch_event) == FredInputIntent.Intent.INTERACT, "synthetic touch action maps to interact intent")
    game._unhandled_input(touch_event)
    check(1 in game.collected, "synthetic touch adapter invokes the shared tongue mechanic")

    game.tongue.reset()
    game.collected.erase(1)
    game.fred = game._bug_position(1) + Vector2(TongueTargeting.PROXIMITY_ASSIST_RANGE - 1.0, 0)
    var screen_touch := InputEventScreenTouch.new()
    screen_touch.index = 7
    screen_touch.position = Rect2(Layout.touch_action_rects().tongue).get_center()
    screen_touch.pressed = true
    game._unhandled_input(screen_touch)
    check(1 in game.collected and game.touch_controls_visible, "real screen-touch MUNCH control uses close-range tongue assist")
    screen_touch.pressed = false
    game._unhandled_input(screen_touch)
    check(game.touch_contacts.is_empty(), "screen-touch release clears held mobile input state")

    game.tongue.reset()
    game.fred = game._bug_position(2) - Vector2(100, 0)
    var mouse_event := InputEventMouseButton.new()
    mouse_event.button_index = MOUSE_BUTTON_RIGHT
    mouse_event.position = game._bug_position(2)
    mouse_event.pressed = true
    game._unhandled_input(mouse_event)
    check(2 in game.collected, "right-click pointer aim captures the selected bug")

    var save_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
    game.tongue.reset()
    game._request_tongue(Vector2.UP)
    check(game.session.to_save("2000-01-01T00:00:00Z") == save_before, "miss and recovery do not drift stable save state")
    check(not save_before.has("tongue") and not save_before.has("aim"), "save v1 contains no transient tongue fields")
    check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "stable session saves while tongue presentation is transient")
    var restored := AdventureSession.new(1337)
    check(game.saver.load_session(restored).get("ok", false), "schema-v1 session reloads after tongue interaction")
    check(restored.to_save("2000-01-01T00:00:00Z") == save_before, "reload restores canonical state without tongue cooldown")

    game.reduced_motion = true
    check(not game.tongue.cue().is_empty(), "reduced motion retains a non-motion tongue state cue")
    check(game.tongue.target_point != Vector2.ZERO, "reduced motion retains exact target position feedback")

    game.tongue.reset()
    game.collected.clear()
    game.session.health = 1
    game.predator = game.fred
    game.danger_cooldown_seconds = 0.0
    game.hazards_enabled = true
    game._request_tongue(Vector2.RIGHT)
    game._fixed_tick(0.0)
    check(game.screen == game.Screen.FAILED and game.tongue.is_ready(), "failure clears tongue state safely")
    game._retry()
    check(game.screen == game.Screen.PLAYING and game.session.health == 3 and game.tongue.is_ready(), "retry restores ready tongue with three lives")
    var empty_candidates: Array[Dictionary] = []
    game.tongue.request(game.fred, Vector2.RIGHT, empty_candidates)
    game.screen = game.Screen.COMPLETE
    game._advance_level()
    check(game.screen == game.Screen.PLAYING and game.tongue.is_ready(), "level transition clears transient tongue state")

    var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
    var started := Time.get_ticks_msec()
    for iteration in range(10000):
        var stress := TongueTargeting.new()
        stress.request(origin, Vector2.RIGHT, ordered)
        stress.advance(TongueTargeting.COOLDOWN_SECONDS)
    var elapsed_ms := Time.get_ticks_msec() - started
    var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
    check(elapsed_ms < 1500, "10,000 target calculations remain time-bounded")
    check(memory_growth < 2 * 1024 * 1024, "10,000 target calculations remain memory-bounded")
    print("MEASURE tongue_iterations=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed_ms, memory_growth])

    game.queue_free()
    await process_frame
    clean_files()
    print("RESULT tongue_interaction_passed=%d tongue_interaction_failed=%d" % [passed, failed])
    quit(1 if failed else 0)
