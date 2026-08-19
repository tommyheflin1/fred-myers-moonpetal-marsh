extends SceneTree

const ROOT_PREFIX := "user://m1_save_feedback"
const MAIN_PREFIX := ROOT_PREFIX + "/fred"

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

func write_text(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Unable to prepare fictional feedback fixture")
        return
    file.store_string(text)
    file = null

func save_data(sequence: int = 0) -> Dictionary:
    var session := AdventureSession.new(91)
    if sequence > 0:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1)
    return session.to_save("2000-01-01T00:00:00Z")

func load_result(prefix: String) -> Dictionary:
    return FredSaveAdapter.new(prefix).load_session(AdventureSession.new())

func contrast_ratio(foreground: Color, background: Color) -> float:
    var fg := foreground.srgb_to_linear()
    var bg := background.srgb_to_linear()
    var fg_luminance := 0.2126 * fg.r + 0.7152 * fg.g + 0.0722 * fg.b
    var bg_luminance := 0.2126 * bg.r + 0.7152 * bg.g + 0.0722 * bg.b
    var lighter := maxf(fg_luminance, bg_luminance)
    var darker := minf(fg_luminance, bg_luminance)
    return (lighter + 0.05) / (darker + 0.05)

func _run() -> void:
    prepare_directory()
    var result := load_result(MAIN_PREFIX)
    check(result.get("reason") == "missing", "missing save is identified as a new game")
    check(FredSaveFeedback.load_message(result) == "[NEW GAME] No saved adventure yet.", "new-game message is truthful")

    var adapter := FredSaveAdapter.new(MAIN_PREFIX)
    check(adapter.save(AdventureSession.new(91)).get("ok"), "fictional primary save prepared")
    result = load_result(MAIN_PREFIX)
    check(result.get("source") == "primary", "primary recovery outcome prepared")
    check(FredSaveFeedback.load_message(result) == "[RESTORED] Your saved adventure is ready.", "primary restore message is truthful")

    write_text(MAIN_PREFIX + ".json", "malformed")
    write_text(MAIN_PREFIX + ".backup.json", JSON.stringify(save_data(1), "  "))
    result = load_result(MAIN_PREFIX)
    check(result.get("source") == "backup", "backup recovery outcome prepared")
    check(FredSaveFeedback.load_message(result) == "[RECOVERED] We found your safe backup.", "backup recovery message is truthful")

    clean_prefix(MAIN_PREFIX)
    write_text(MAIN_PREFIX + ".tmp.json", JSON.stringify(save_data(1), "  "))
    result = load_result(MAIN_PREFIX)
    check(result.get("source") == "temp", "interrupted recovery outcome prepared")
    check(FredSaveFeedback.load_message(result) == "[RECOVERED] We finished your interrupted save.", "interrupted recovery message is truthful")

    clean_prefix(MAIN_PREFIX)
    write_text(MAIN_PREFIX + ".json", "damaged")
    result = load_result(MAIN_PREFIX)
    check(result.get("source") == "default" and result.get("reason") == "corrupt", "damaged save uses explicit safe default")
    check(
        FredSaveFeedback.load_message(result) == "[SAFE START] The old save was damaged, so we started safely.",
        "safe-default message never masquerades as restored progress"
    )

    var future := save_data(1)
    future["schema_version"] = 99
    write_text(MAIN_PREFIX + ".json", JSON.stringify(future, "  "))
    result = load_result(MAIN_PREFIX)
    check(not result.get("ok") and result.get("error") == "unsupported_schema", "blocked save outcome prepared")
    check(
        FredSaveFeedback.load_message(result) == "[SAVE BLOCKED] This adventure uses a different game version.",
        "blocked-save message is child-friendly"
    )

    check(
        FredSaveFeedback.save_message({"ok":true}, "Midpoint is safe.") == "[SAVED] Midpoint is safe.",
        "successful save message uses a non-color cue"
    )
    check(
        FredSaveFeedback.save_message({"ok":false, "error":"stale_checkpoint"}, "") == "[SAVE BLOCKED] A newer checkpoint is already safe.",
        "stale-save message explains preserved progress"
    )
    var generic_failure := FredSaveFeedback.save_message({"ok":false, "error":"temp_open_failed"}, "")
    check(generic_failure == "[SAVE BLOCKED] Progress was not changed. Try again soon.", "generic save failure avoids internal details")

    var visible_messages := [
        FredSaveFeedback.load_message({"ok":true, "source":"default", "reason":"missing"}),
        FredSaveFeedback.load_message({"ok":true, "source":"primary"}),
        FredSaveFeedback.load_message({"ok":true, "source":"backup"}),
        FredSaveFeedback.load_message({"ok":true, "source":"temp"}),
        FredSaveFeedback.load_message({"ok":true, "source":"default", "reason":"corrupt"}),
        FredSaveFeedback.load_message({"ok":false, "error":"core_incompatible"}),
        generic_failure,
    ]
    var all_have_text_cues := true
    var leaks_internal_data := false
    for message: String in visible_messages:
        all_have_text_cues = all_have_text_cues and message.begins_with("[") and message.contains("]")
        leaks_internal_data = leaks_internal_data or message.contains("user://") or message.contains("temp_open_failed")
    check(all_have_text_cues, "all save states include non-color text cues")
    check(not leaks_internal_data, "visible messages reveal no path or internal error")
    check(
        contrast_ratio(FredSaveFeedback.PANEL_TEXT, FredSaveFeedback.PANEL_BACKGROUND) >= 4.5,
        "status panel text meets WCAG AA contrast"
    )
    check(FredSaveFeedback.DISPLAY_SECONDS == 15.0, "status timing is deterministic and bounded")

    clean_prefix(MAIN_PREFIX)
    var game: Node2D = load("res://scripts/main.gd").new()
    game.saver = FredSaveAdapter.new(MAIN_PREFIX)
    game.countdown_enabled = false
    root.add_child(game)
    await process_frame
    check(game.save_feedback == "[NEW GAME] No saved adventure yet.", "title displays the mapped new-game state")
    game._process(14.9)
    check(game.save_feedback.begins_with("[NEW GAME]"), "status remains readable during its display window")
    game._process(0.2)
    check(game.save_feedback == FredSaveFeedback.NEUTRAL, "status returns to a bounded neutral message")

    var enter := InputEventKey.new()
    enter.keycode = KEY_ENTER
    enter.pressed = true
    game._unhandled_input(enter)
    game._unhandled_input(enter)
    game._unhandled_input(enter)
    game.fred = Vector2(500, 500)
    game._unhandled_input(enter)
    check(game.screen == game.Screen.PLAYING and game.fred == Vector2(500, 500), "repeated confirm does not restart navigation")
    check(not FileAccess.file_exists(MAIN_PREFIX + ".json"), "repeated confirm does not create a duplicate save")

    game.fred = Vector2(630, 390)
    game._fixed_tick(0.0)
    var first_checkpoint_bytes := FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json")
    game._fixed_tick(0.0)
    check(
        FileAccess.get_file_as_bytes(MAIN_PREFIX + ".json") == first_checkpoint_bytes,
        "repeated checkpoint contact does not duplicate writes"
    )
    check(game.save_feedback == "[SAVED] Midpoint is safe.", "gameplay displays the mapped save confirmation")
    game.queue_free()
    await process_frame

    clean_prefix(MAIN_PREFIX)
    check(not FileAccess.file_exists(MAIN_PREFIX + ".tmp.json"), "feedback suite leaves no temporary save")
    print("RESULT save_feedback_passed=%d save_feedback_failed=%d" % [passed, failed])
    quit(1 if failed else 0)
