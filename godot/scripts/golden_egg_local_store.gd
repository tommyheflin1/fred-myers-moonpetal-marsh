class_name GoldenEggLocalStore
extends RefCounted

const STORE_PATH := "user://fred_myers_golden_egg_credentials.json"
const MAX_VALUE_LENGTH := 8192

var values: Dictionary = {}


func _init() -> void:
    _load_values()


func get_secret(key: String) -> String:
    return str(values.get(key, ""))


func set_secret(key: String, value: String) -> bool:
    if not key.begins_with("golden_egg.") or value.length() > MAX_VALUE_LENGTH:
        return false
    values[key] = value
    return _save_values()


func erase_secret(key: String) -> bool:
    values.erase(key)
    return _save_values()


func _load_values() -> void:
    values.clear()
    if not FileAccess.file_exists(STORE_PATH):
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORE_PATH))
    if parsed is not Dictionary:
        return
    for key_value: Variant in parsed.keys():
        var key := str(key_value)
        var value := str(parsed[key_value])
        if key.begins_with("golden_egg.") and value.length() <= MAX_VALUE_LENGTH:
            values[key] = value


func _save_values() -> bool:
    var file := FileAccess.open(STORE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(values))
    file.flush()
    return file.get_error() == OK
