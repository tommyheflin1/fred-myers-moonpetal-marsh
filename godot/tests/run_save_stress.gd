extends SceneTree

const ROOT_PREFIX := "user://m1_save_stress"
const MAIN_PREFIX := ROOT_PREFIX + "/fred"
const ITERATIONS := 250

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

func remove_file(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func clean_prefix(prefix: String) -> void:
    for suffix: String in [".json", ".tmp.json", ".backup.json"]:
        remove_file(prefix + suffix)

func prepare_directory() -> void:
    var absolute := ProjectSettings.globalize_path(ROOT_PREFIX)
    if not DirAccess.dir_exists_absolute(absolute):
        DirAccess.make_dir_recursive_absolute(absolute)
    clean_prefix(MAIN_PREFIX)
    clean_prefix("user://escaped_save")

func write_text(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Unable to prepare fictional test file " + path)
        return
    file.store_string(text)
    file = null

func write_data(path: String, data: Dictionary) -> void:
    write_text(path, JSON.stringify(data, "  "))

func data_at(sequence: int, timestamp: String, energy: int = 100) -> Dictionary:
    var session := AdventureSession.new(77)
    if sequence >= 1:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1)
    if sequence >= 2:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[2], 2)
    session.boost_energy = energy
    return session.to_save(timestamp)

func file_size(path: String) -> int:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return -1
    return file.get_length()

func _run() -> void:
    prepare_directory()
    var adapter := FredSaveAdapter.new(MAIN_PREFIX)
    var session := AdventureSession.new(77)
    var timestamp := "2000-01-01T00:00:00Z"
    check(adapter.save(session, timestamp).get("ok"), "initial fictional atomic save")
    var stable_bytes := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json")
    var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
    var started := Time.get_ticks_msec()
    var repeated_ok := true
    for index in range(ITERATIONS):
        if not adapter.save(session, timestamp).get("ok"):
            repeated_ok = false
            break
        if FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json") != stable_bytes:
            repeated_ok = false
            break
    var elapsed := Time.get_ticks_msec() - started
    var memory_growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
    check(repeated_ok, "250 repeated saves are byte-stable and successful")
    check(not FileAccess.file_exists(MAIN_PREFIX + ".tmp.json"), "repeated saves leave no temporary file")
    check(file_size(MAIN_PREFIX + ".json") < 65536 and file_size(MAIN_PREFIX + ".backup.json") < 65536, "save files remain size-bounded")
    check(elapsed < 10000, "250-save runtime remains bounded")
    check(memory_growth < 32 * 1024 * 1024, "250-save static-memory growth remains bounded")
    print("MEASURE iterations=%d elapsed_ms=%d memory_growth_bytes=%d primary_bytes=%d" % [
        ITERATIONS, elapsed, memory_growth, file_size(MAIN_PREFIX + ".json")
    ])
    var before_reentrant_guard := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json")
    adapter._save_in_progress = true
    check(adapter.save(session, timestamp).get("error") == "save_in_progress", "reentrant save attempt is rejected")
    adapter._save_in_progress = false
    check(
        FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json") == before_reentrant_guard,
        "reentrant save attempt leaves recovery bytes unchanged"
    )

    session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1)
    session.boost_energy = 61
    var prior_primary := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json")
    check(adapter.save(session, "2000-01-01T01:00:00+01:00").get("ok"), "timezone-offset timestamp saves")
    check(FileAccess.get_file_as_bytes(MAIN_PREFIX + ".backup.json") == prior_primary, "backup rotation preserves previous primary bytes")

    write_data(MAIN_PREFIX + ".json", data_at(0, "2000-01-01T00:00:00Z", 80))
    write_data(MAIN_PREFIX + ".backup.json", data_at(1, "1999-12-31T19:00:00-05:00", 70))
    var restored := AdventureSession.new()
    var load_result := adapter.load_session(restored)
    check(load_result.get("source") == "backup" and restored.checkpoint_sequence == 1, "newer monotonic backup wins over older valid primary")

    write_data(MAIN_PREFIX + ".json", data_at(1, "2000-01-02T00:00:00Z", 60))
    write_data(MAIN_PREFIX + ".backup.json", data_at(0, "2000-01-03T00:00:00Z", 90))
    restored = AdventureSession.new()
    load_result = adapter.load_session(restored)
    check(load_result.get("source") == "primary" and restored.checkpoint_sequence == 1, "checkpoint order outranks timestamp variation")

    write_data(MAIN_PREFIX + ".json", data_at(0, "2000-01-01T00:00:00Z"))
    write_data(MAIN_PREFIX + ".tmp.json", data_at(1, "2000-01-01T00:00:01Z"))
    restored = AdventureSession.new()
    load_result = adapter.load_session(restored)
    check(load_result.get("source") == "temp" and restored.checkpoint_sequence == 1, "newer interrupted temporary save is recovered")

    write_text(MAIN_PREFIX + ".json", "{\"schema_version\":1")
    write_data(MAIN_PREFIX + ".backup.json", data_at(1, "2000-01-01T00:00:00Z"))
    restored = AdventureSession.new()
    load_result = adapter.load_session(restored)
    check(load_result.get("source") == "backup" and restored.checkpoint_sequence == 1, "truncated primary falls back to valid backup")

    var oversized := "{\"padding\":\"" + "x".repeat(70000) + "\"}"
    write_text(MAIN_PREFIX + ".json", oversized)
    write_data(MAIN_PREFIX + ".backup.json", data_at(1, "2000-01-01T00:00:00Z"))
    restored = AdventureSession.new()
    load_result = adapter.load_session(restored)
    check(load_result.get("source") == "backup", "oversized primary falls back without loading as a save")

    write_text(MAIN_PREFIX + ".json", "malformed")
    var recovery_bytes := JSON.stringify(data_at(1, "2000-01-01T00:00:00Z"), "  ").to_utf8_buffer()
    write_text(MAIN_PREFIX + ".backup.json", recovery_bytes.get_string_from_utf8())
    session = AdventureSession.new()
    session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1)
    check(adapter.save(session, "2000-01-02T00:00:00Z").get("ok"), "save can replace malformed primary")
    check(FileAccess.get_file_as_bytes(MAIN_PREFIX + ".backup.json") == recovery_bytes, "malformed primary never overwrites last valid backup")

    write_data(MAIN_PREFIX + ".backup.json", data_at(2, "2000-01-03T00:00:00Z"))
    write_text(MAIN_PREFIX + ".json", "malformed")
    session = AdventureSession.new()
    session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1)
    check(adapter.save(session).get("error") == "stale_checkpoint", "newer backup rejects stale save")

    var future := data_at(1, "2000-01-01T00:00:00Z")
    future["schema_version"] = 99
    write_data(MAIN_PREFIX + ".json", future)
    var future_bytes := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json")
    check(adapter.save(session).get("error") == "unsupported_schema", "future schema refuses overwrite")
    check(FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json") == future_bytes, "future schema bytes remain untouched")

    var incompatible := data_at(1, "2000-01-01T00:00:00Z")
    incompatible["core_version"] = "9.9.9"
    write_data(MAIN_PREFIX + ".json", incompatible)
    var incompatible_bytes := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json")
    check(adapter.save(session).get("error") == "core_incompatible", "incompatible Core save refuses overwrite")
    check(FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json") == incompatible_bytes, "incompatible Core bytes remain untouched")

    write_data(MAIN_PREFIX + ".json", data_at(1, "2000-01-01T00:00:00Z"))
    write_data(MAIN_PREFIX + ".backup.json", future)
    var future_backup_bytes := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".backup.json")
    check(adapter.save(session).get("error") == "unsupported_schema", "future-schema backup refuses rotation")
    check(FileAccess.get_file_as_bytes(MAIN_PREFIX + ".backup.json") == future_backup_bytes, "future-schema backup bytes remain untouched")

    write_data(MAIN_PREFIX + ".backup.json", data_at(1, "2000-01-01T00:00:00Z"))
    write_data(MAIN_PREFIX + ".tmp.json", incompatible)
    var incompatible_temp_bytes := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".tmp.json")
    check(adapter.save(session).get("error") == "core_incompatible", "incompatible interrupted save refuses overwrite")
    check(FileAccess.get_file_as_bytes(MAIN_PREFIX + ".tmp.json") == incompatible_temp_bytes, "incompatible interrupted bytes remain untouched")

    clean_prefix(MAIN_PREFIX)
    var invalid_path_adapter := FredSaveAdapter.new(ROOT_PREFIX + "/../escaped_save")
    check(invalid_path_adapter.save(AdventureSession.new()).get("error") == "invalid_path", "path traversal prefix is rejected")
    check(not FileAccess.file_exists("user://escaped_save.json"), "path traversal creates no escaped file")
    check(FredSaveAdapter.new("res://unsafe").save(AdventureSession.new()).get("error") == "invalid_path", "non-user save prefix is rejected")
    check(
        FredSaveAdapter.new(ROOT_PREFIX + "/missing/child/save").save(AdventureSession.new()).get("error") == "temp_open_failed",
        "missing parent path fails without partial files"
    )

    clean_prefix(MAIN_PREFIX)
    clean_prefix("user://escaped_save")
    check(not FileAccess.file_exists(MAIN_PREFIX + ".tmp.json"), "stress cleanup removes temporary artifacts")
    print("RESULT save_stress_passed=%d save_stress_failed=%d" % [passed, failed])
    quit(1 if failed else 0)
