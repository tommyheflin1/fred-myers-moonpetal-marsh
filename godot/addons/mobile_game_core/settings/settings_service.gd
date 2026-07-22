class_name SettingsService
extends RefCounted

signal changed(key: StringName, value: Variant)
var values := {
    &"master_volume": 0.8, &"music_volume": 0.7, &"sfx_volume": 0.8,
    &"haptics": true, &"reduced_motion": false, &"reduced_flashing": false,
    &"screen_shake": 0.7, &"effect_intensity": 0.8, &"high_contrast": false,
    &"large_text": false, &"left_handed_controls": false
}

func set_value(key: StringName, value: Variant) -> void:
    if not values.has(key): return
    values[key] = value
    changed.emit(key, value)

func get_value(key: StringName, fallback: Variant = null) -> Variant:
    return values.get(key, fallback)

