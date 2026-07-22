class_name FredSaveAdapter
extends RefCounted

var save_path := "user://fred_save.json"
var temp_path := "user://fred_save.tmp.json"
var backup_path := "user://fred_save.backup.json"
var core_save_service: SaveService

func _init(prefix: String = "user://fred_save") -> void:
    save_path = prefix + ".json"
    temp_path = prefix + ".tmp.json"
    backup_path = prefix + ".backup.json"
    core_save_service = SaveService.new()

func save(session: AdventureSession, timestamp: String = "2000-01-01T00:00:00Z") -> Dictionary:
    var data := session.to_save(timestamp)
    var existing := _read(save_path)
    if not existing.is_empty() and int(existing.get("checkpoint_sequence", -1)) > session.checkpoint_sequence:
        return {"ok":false, "error":"stale_checkpoint"}
    var encoded := JSON.stringify(data, "  ")
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null: return {"ok":false, "error":"temp_open_failed"}
    file.store_string(encoded)
    file.flush()
    if file.get_error() != OK: return {"ok":false, "error":"temp_write_failed"}
    file = null
    if not _read(temp_path).has("schema_version"): return {"ok":false, "error":"temp_verify_failed"}
    if FileAccess.file_exists(save_path):
        if FileAccess.file_exists(backup_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
        if DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(backup_path)) != OK:
            return {"ok":false, "error":"backup_failed"}
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path)) != OK:
        return {"ok":false, "error":"replace_failed"}
    core_save_service.stage(data)
    return {"ok":true, "data":data}

func load_session(session: AdventureSession) -> Dictionary:
    var source := "default"
    var data := _read(save_path)
    var primary_result := session.restore(data) if not data.is_empty() else {"ok":false, "error":"missing"}
    if primary_result.get("ok", false): return {"ok":true, "source":"primary"}
    data = _read(backup_path)
    var backup_result := session.restore(data) if not data.is_empty() else {"ok":false, "error":"missing"}
    if backup_result.get("ok", false): return {"ok":true, "source":"backup"}
    if FileAccess.file_exists(temp_path):
        data = _read(temp_path)
        var temp_result := session.restore(data) if not data.is_empty() else {"ok":false, "error":"malformed"}
        if temp_result.get("ok", false): return {"ok":true, "source":"temp"}
    if primary_result.error in ["unsupported_schema", "core_incompatible"]: return primary_result
    return {"ok":true, "source":source}

func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}
