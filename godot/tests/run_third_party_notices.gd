extends SceneTree

const Notices = preload("res://scripts/third_party_notices.gd")
var passed := 0
var failed := 0
var close_count := 0


func check(condition: bool, description: String) -> void:
    if condition:
        passed += 1
        print("PASS ", description)
    else:
        failed += 1
        push_error("FAIL " + description)


func _init() -> void:
    _run.call_deferred()


func _run() -> void:
    var fixtures: Array[Dictionary] = [{"name": "Fictional library", "parts": [{"copyright": PackedStringArray(["Copyright Fictional Author"]), "license": "FixtureLicense"}]}]
    var composed: String = Notices.compose_notices("Fictional engine license", fixtures, {"FixtureLicense": "Full fictional license text [url] remains plain text"})
    check(composed.contains("Fictional engine license"), "engine license is retained")
    check(composed.contains("Fictional library") and composed.contains("Copyright Fictional Author"), "component name and complete copyright are retained")
    check(composed.contains("Full fictional license text [url] remains plain text"), "complete dependency license is retained")
    check(composed.contains(Notices.GAME_CENTER_LICENSE.strip_edges()), "verified pinned plugin license is included verbatim")
    var runtime_text: String = Notices.runtime_notices()
    check(runtime_text.contains(Engine.get_license_text().strip_edges()), "actual runtime engine license is used")
    var all_runtime_licenses: bool = true
    for value: Variant in Engine.get_license_info().values():
        if not runtime_text.contains(str(value)):
            all_runtime_licenses = false
    check(all_runtime_licenses and Engine.get_license_info().size() > 0, "all actual runtime dependency licenses are included")
    var all_runtime_copyrights: bool = true
    for component: Dictionary in Engine.get_copyright_info():
        for part: Dictionary in component.get("parts", []):
            for statement: String in part.get("copyright", []):
                if not runtime_text.contains(statement):
                    all_runtime_copyrights = false
    check(all_runtime_copyrights and Engine.get_copyright_info().size() > 0, "all actual runtime component copyrights are included")
    var host := Control.new()
    host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(host)
    var opener := Button.new()
    opener.text = "Legal notices"
    host.add_child(opener)
    var panel: Control = Notices.new()
    host.add_child(panel)
    panel.closed.connect(func() -> void: close_count += 1)
    await process_frame
    check(not panel.visible, "construction does not interrupt gameplay or expose overlay")
    panel.open(opener)
    await process_frame
    await process_frame
    print("NOTICE_LAYOUT visible=", panel.visible, " size=", panel.size, " close_rect=", panel.close_button.get_global_rect(), " focus=", panel.close_button.has_focus(), " close_count=", close_count)
    check(panel.visible and panel.close_button.has_focus(), "open shows panel and focuses close control")
    check(panel.mouse_filter == Control.MOUSE_FILTER_STOP, "overlay stops pointer passthrough")
    check(not panel.notice_text.bbcode_enabled, "license text cannot become active markup or links")
    check(panel.close_button.size.y >= 64, "close button has a touch-sized target")
    check(panel.scroll.get_v_scroll_bar().max_value > panel.scroll.get_v_scroll_bar().page, "full notice text is scrollable")
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        DirAccess.make_dir_recursive_absolute("res://builds/notices-review")
        var captured: Error = root.get_texture().get_image().save_png("res://builds/notices-review/third-party-notices.png")
        check(captured == OK, "real-renderer notices screenshot saved")
    panel.scroll.scroll_vertical = 500
    await process_frame
    check(panel.scroll.scroll_vertical > 0, "reader can reach content beyond first screen")
    panel.close_button.pressed.emit()
    check(not panel.visible and close_count == 1 and opener.has_focus(), "close restores the caller focus and emits once")
    panel.close()
    check(close_count == 1, "repeated close is idempotent")
    panel.open(opener)
    await process_frame
    check(panel.scroll.scroll_vertical == 0, "reopening starts at top")
    paused = true
    check(panel.can_process(), "panel remains operable while gameplay tree is paused")
    var cancel := InputEventAction.new()
    cancel.action = "ui_cancel"
    cancel.pressed = true
    panel._unhandled_key_input(cancel)
    check(not panel.visible and close_count == 2 and paused, "cancel closes without changing the host pause state")
    paused = false
    host.queue_free()
    await process_frame
    print("THIRD_PARTY_NOTICES: ", passed, " passed, ", failed, " failed; native SDK binary and device accessibility not certified")
    quit(1 if failed else 0)
