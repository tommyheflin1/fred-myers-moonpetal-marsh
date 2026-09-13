class_name FredThirdPartyNotices
extends Control

## Offline, runtime-sourced legal notices. The host owns gameplay pause/state.
signal closed

const GAME_CENTER_SOURCE_COMMIT := "fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"
# Verbatim LICENCE fetched from the already-pinned plugin source on 2026-09-10.
# This is a notice for an existing dependency, not an additional dependency.
const GAME_CENTER_LICENSE := """MIT License

Copyright (c) 2021 Godot Engine

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

var scroll: ScrollContainer
var notice_text: RichTextLabel
var close_button: Button
var _return_focus: WeakRef


static func runtime_notices() -> String:
    return compose_notices(Engine.get_license_text(), Engine.get_copyright_info(), Engine.get_license_info())


static func compose_notices(engine_license: String, components: Array[Dictionary], licenses: Dictionary) -> String:
    var sections := PackedStringArray(["ENGINE LICENSE", engine_license.strip_edges(), "GAME CENTER PLUGIN LICENSE", GAME_CENTER_LICENSE.strip_edges(), "ENGINE THIRD-PARTY COPYRIGHTS"])
    for component: Dictionary in components:
        sections.append(str(component.get("name", "Component")))
        var parts: Variant = component.get("parts", [])
        if parts is Array:
            for part_value: Variant in parts:
                if not part_value is Dictionary:
                    continue
                var part: Dictionary = part_value
                var copyrights: Variant = part.get("copyright", [])
                if copyrights is Array or copyrights is PackedStringArray:
                    for statement: Variant in copyrights:
                        sections.append(str(statement))
                elif copyrights is String:
                    sections.append(copyrights)
                sections.append("License: " + str(part.get("license", "See license text below")))
    sections.append("ENGINE THIRD-PARTY LICENSE TEXTS")
    var names: Array = licenses.keys()
    names.sort()
    for license_name: Variant in names:
        sections.append(str(license_name))
        sections.append(str(licenses[license_name]))
    return "\n\n".join(sections)


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color(0.015, 0.045, 0.04, 0.97)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    var panel := PanelContainer.new()
    add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.anchor_left = 0.035
    panel.anchor_top = 0.04
    panel.anchor_right = 0.965
    panel.anchor_bottom = 0.96
    var style := StyleBoxFlat.new()
    style.bg_color = Color("122922")
    style.set_content_margin_all(20.0)
    panel.add_theme_stylebox_override("panel", style)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    panel.add_child(column)
    var title := Label.new()
    title.text = "THIRD-PARTY LICENSES"
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("fff6d9"))
    column.add_child(title)
    scroll = ScrollContainer.new()
    scroll.name = "LicenseScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    scroll.focus_mode = Control.FOCUS_ALL
    scroll.get_v_scroll_bar().custom_minimum_size.x = 24
    column.add_child(scroll)
    notice_text = RichTextLabel.new()
    notice_text.name = "LicenseText"
    notice_text.bbcode_enabled = false
    notice_text.fit_content = true
    notice_text.scroll_active = false
    notice_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    notice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notice_text.mouse_filter = Control.MOUSE_FILTER_PASS
    notice_text.add_theme_font_size_override("normal_font_size", 22)
    notice_text.add_theme_color_override("default_color", Color("f5f7ed"))
    notice_text.text = runtime_notices()
    scroll.add_child(notice_text)
    close_button = Button.new()
    close_button.name = "CloseLicenses"
    close_button.text = "CLOSE"
    close_button.custom_minimum_size.y = 64
    close_button.add_theme_font_size_override("font_size", 24)
    close_button.pressed.connect(close)
    column.add_child(close_button)
    get_window().focus_entered.connect(_restore_panel_focus)
    hide()


func open(focus_after_close: Control = null) -> void:
    if not is_node_ready():
        await ready
    _return_focus = weakref(focus_after_close) if is_instance_valid(focus_after_close) else null
    scroll.scroll_vertical = 0
    show()
    close_button.grab_focus()


func _restore_panel_focus() -> void:
    if not visible:
        return
    var focused: Control = get_viewport().gui_get_focus_owner()
    if focused == null or not is_ancestor_of(focused):
        close_button.grab_focus.call_deferred()


func close() -> void:
    if not visible:
        return
    hide()
    if _return_focus != null:
        var control: Control = _return_focus.get_ref() as Control
        if is_instance_valid(control) and control.is_visible_in_tree():
            control.grab_focus()
    _return_focus = null
    closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        close()
