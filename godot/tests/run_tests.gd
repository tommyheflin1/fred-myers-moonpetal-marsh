extends SceneTree

var passed := 0
var failed := 0
var prefix := "user://m1_test_save"

func check(condition: bool, label: String) -> void:
    if condition:
        passed += 1; print("PASS ", label)
    else:
        failed += 1; push_error("FAIL " + label)

func _init() -> void:
    _run.call_deferred()

func fixture(name: String) -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + name + ".json"))
    return parsed if parsed is Dictionary else {}

func clean_files() -> void:
    for suffix in [".json", ".tmp.json", ".backup.json"]:
        var path: String = prefix + suffix
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func write(path: String, data: Variant) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data)); file = null

func _run() -> void:
    clean_files()
    var session := AdventureSession.new(42)
    check(session.current_level == "lily_leap" and session.health == 3 and session.boost_energy == 100, "AdventureSession initial state")
    var other := AdventureSession.new(42)
    check(session.rng.randi() == other.rng.randi(), "deterministic seeded session behavior")
    check(session.restore(fixture("new_game")).get("ok") and session.bug_count == 0, "new-game fixture")
    check(session.restore(fixture("mid_level_checkpoint")).get("ok") and session.current_checkpoint == "lily_leap_midpoint", "mid-level fixture")
    check(not session.restore(fixture("stale_checkpoint")).get("ok"), "stale checkpoint rejection")
    session = AdventureSession.new()
    check(session.reach_checkpoint("lily_leap_midpoint", 1), "sequential checkpoint increase")
    check(not session.reach_checkpoint("lily_leap_start", 1), "equal checkpoint sequence rejected")
    check(not session.reach_checkpoint("lily_leap_start", 0), "decreasing checkpoint sequence rejected")
    session.collect_bug(); session.collect_bug(); session.collect_bug()
    check(session.bug_count == 3 and session.active_objective == "lily_leap_reach_exit", "objective progression and bug collection")
    check(session.use_boost(100) and session.boost_energy == 0, "boost depletion")
    session.recharge_boost(15)
    check(session.boost_energy == 15, "boost recharge")
    check(not session.damage(1, true) and session.health == 3, "hiding behavior prevents predator damage")
    check(not session.damage() and session.health == 2, "predator damage")
    session.set_underwater(true); check(session.player_state == "underwater", "surface-to-underwater transition")
    session.set_underwater(false); check(session.player_state == "surface", "underwater-to-surface transition")
    session.damage(); check(session.damage() and session.health == 0, "failure state")
    session.retry_from_checkpoint(); check(session.health == 3 and session.retrying, "retry reset")
    check(session.complete_level() and session.completed and session.current_checkpoint == "lily_leap_complete", "Lily Leap completion")
    var adapter := FredSaveAdapter.new(prefix)
    check(adapter.save(session, "2000-01-05T00:00:00Z").get("ok"), "local atomic save creation")
    var restored := AdventureSession.new()
    check(adapter.load_session(restored).get("source") == "primary" and restored.completed, "save/load round trip and checkpoint restoration")
    var first_text := FileAccess.get_file_as_string(prefix + ".json")
    check(adapter.save(session, "2000-01-05T00:00:00Z").get("ok") and FileAccess.get_file_as_string(prefix + ".json") == first_text, "repeated-save idempotency")
    write(prefix + ".json", "malformed")
    restored = AdventureSession.new()
    check(adapter.load_session(restored).get("source") == "backup", "backup recovery from malformed primary")
    clean_files(); write(prefix + ".tmp.json", fixture("interrupted_write_recovery"))
    restored = AdventureSession.new()
    check(adapter.load_session(restored).get("source") == "temp" and restored.checkpoint_sequence == 1, "interrupted-write recovery")
    clean_files(); write(prefix + ".json", fixture("unsupported_save_version"))
    check(FredSaveAdapter.new(prefix).load_session(AdventureSession.new()).get("error") == "unsupported_schema", "unsupported schema rejection")
    clean_files(); write(prefix + ".json", fixture("core_version_incompatibility"))
    check(FredSaveAdapter.new(prefix).load_session(AdventureSession.new()).get("error") == "core_incompatible", "Core compatibility rejection")
    clean_files(); write(prefix + ".json", fixture("invalid_save"))
    check(FredSaveAdapter.new(prefix).load_session(AdventureSession.new()).get("source") == "default", "malformed data rejected to safe default")
    clean_files()
    check(FredSaveAdapter.new(prefix).load_session(AdventureSession.new()).get("source") == "default", "offline startup with no backend and no save")
    var game: Node2D = load("res://scripts/main.gd").new(); game.saver = FredSaveAdapter.new(prefix); root.add_child(game); await process_frame
    check(game.screen == game.Screen.TITLE, "level initializes at title")
    game._handle_click(Vector2(640,475)); check(game.screen == game.Screen.PLAYING, "desktop mouse starts game")
    game.session.collect_bug(); game.session.collect_bug(); game.session.collect_bug(); game.fred = game.EXIT; game._fixed_tick(0.0)
    check(game.screen == game.Screen.COMPLETE, "playable level completion condition")
    game._handle_click(Vector2(640,530))
    check(game.screen == game.Screen.PLAYING and game.level_number == 2, "completion advances directly to level two")
    check(game.level_profile.level == 2 and game.session.bug_count == 0, "next level starts with fresh deterministic objectives")
    game.queue_free(); await process_frame
    clean_files()
    print("RESULT passed=%d failed=%d" % [passed, failed])
    quit(1 if failed else 0)
