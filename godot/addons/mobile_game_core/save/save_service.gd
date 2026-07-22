class_name SaveService
extends RefCounted

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.backup.json"
var _pending: Dictionary = {}

func stage(data: Dictionary) -> void:
    _pending = data.duplicate(true)

func flush() -> bool:
    if _pending.is_empty(): return true
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(_pending))
    file.flush()
    return file.get_error() == OK

func load_data(defaults: Dictionary = {}) -> Dictionary:
    var loaded := _read_json(SAVE_PATH)
    if loaded.is_empty(): loaded = _read_json(BACKUP_PATH)
    return defaults.merged(loaded, true)

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

