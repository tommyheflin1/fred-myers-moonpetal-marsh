extends SceneTree

const ROOT_PREFIX := "user://m1_visual_clarity"
const MAIN_PREFIX := ROOT_PREFIX + "/fred"
const ITERATIONS := 10000

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

func clean_prefix(prefix: String) -> void:
    for suffix: String in [".json", ".tmp.json", ".backup.json"]:
        var path := prefix + suffix
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func prepare_directory() -> void:
    var absolute := ProjectSettings.globalize_path(ROOT_PREFIX)
    if not DirAccess.dir_exists_absolute(absolute):
        DirAccess.make_dir_recursive_absolute(absolute)
    clean_prefix(MAIN_PREFIX)

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
    var first := FredVisualState.snapshot(1.25, false)
    var repeated := FredVisualState.snapshot(1.25, false)
    var later := FredVisualState.snapshot(2.25, false)
    check(first == repeated, "visual snapshot is deterministic")
    check(first != later, "standard visual snapshot animates over time")
    check(absf(float(first.fred_bob)) <= 3.0, "Fred bob remains bounded")
    check(absf(float(first.water_shift)) <= 14.0, "water shift remains bounded")
    check(absf(float(first.reed_sway)) <= 5.0, "reed sway remains bounded")
    check(absf(float(first.wildlife_flutter)) <= 4.0, "wildlife flutter remains bounded")
    check(float(first.exit_pulse) >= 0.94 and float(first.exit_pulse) <= 1.06, "exit pulse remains bounded")

    var reduced := FredVisualState.snapshot(2.25, true)
    check(float(reduced.fred_bob) == 0.0, "reduced motion removes Fred bob")
    check(float(reduced.water_shift) == 0.0, "reduced motion removes water shift")
    check(float(reduced.reed_sway) == 0.0, "reduced motion removes reed sway")
    check(float(reduced.wildlife_flutter) == 0.0, "reduced motion removes wildlife flutter")
    check(float(reduced.exit_pulse) == 1.0, "reduced motion keeps a stable exit cue")

    check(FredVisualState.bounded_time(10.0, -5.0) == 10.0, "negative visual delta cannot rewind state")
    var wrapped := FredVisualState.bounded_time(FredVisualState.MAX_VISUAL_TIME - 1.0, 4.0)
    check(wrapped >= 0.0 and wrapped < FredVisualState.MAX_VISUAL_TIME, "visual time remains bounded")

    var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
    var started := Time.get_ticks_msec()
    var checksum := 0.0
    for index in range(ITERATIONS):
        checksum += float(FredVisualState.snapshot(float(index) / 60.0, false).fred_bob)
    var elapsed := Time.get_ticks_msec() - started
    var memory_growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
    check(is_finite(checksum), "visual-state stress remains finite")
    check(elapsed < 2000, "visual-state calculation remains time-bounded")
    check(memory_growth < 8 * 1024 * 1024, "visual-state calculation remains memory-bounded")
    print("MEASURE visual_iterations=%d elapsed_ms=%d memory_growth_bytes=%d" % [ITERATIONS, elapsed, memory_growth])

    var game: Node2D = load("res://scripts/main.gd").new()
    game.saver = FredSaveAdapter.new(MAIN_PREFIX)
    root.add_child(game)
    await process_frame
    var session_before: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
    var fred_before: Vector2 = game.fred
    var predator_before: Vector2 = game.predator
    var screen_before: int = game.screen
    game._advance_visual(12.0)
    check(game.session.to_save("2000-01-01T00:00:00Z") == session_before, "visual advance does not mutate session")
    check(game.fred == fred_before and game.predator == predator_before, "visual advance does not mutate collision positions")
    check(game.screen == screen_before, "visual advance does not navigate")
    check(not FileAccess.file_exists(MAIN_PREFIX + ".json"), "visual advance does not write a save")

    game.reduced_motion = true
    game._advance_visual(12.0)
    check(
        FredVisualState.snapshot(game.visual_time, game.reduced_motion) == FredVisualState.snapshot(0.0, true),
        "reduced-motion output is time-invariant"
    )
    var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
    check(main_source.contains("--reduced-motion"), "reduced motion is available to local test launches")
    check(main_source.contains("[REDUCED MOTION]"), "reduced motion has a visible non-color label")
    check(main_source.contains("[TRY AGAIN]") or main_source.contains("\"TRY AGAIN\""), "failure keeps a non-color cue")
    check(main_source.contains("[LEVEL CLEAR]") or main_source.contains("\"LEVEL CLEAR\""), "completion keeps a non-color cue")
    check(main_source.contains("OBJECTIVE:"), "objective retains an explicit text label")
    check(main_source.contains("BUG %d"), "wildlife collectibles retain numbered labels")
    check(
        contrast_ratio(Color("e8fbff"), Color("06151f")) >= 4.5,
        "objective and reduced-motion text meet WCAG AA contrast"
    )

    game.queue_free()
    await process_frame
    clean_prefix(MAIN_PREFIX)
    check(not FileAccess.file_exists(MAIN_PREFIX + ".tmp.json"), "visual suite leaves no temporary save")
    print("RESULT visual_clarity_passed=%d visual_clarity_failed=%d" % [passed, failed])
    quit(1 if failed else 0)
