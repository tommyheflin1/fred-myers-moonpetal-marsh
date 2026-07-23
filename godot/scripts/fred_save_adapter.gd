class_name FredSaveAdapter
extends RefCounted

const MAX_SAVE_BYTES := 65536

var save_path := "user://fred_save.json"
var temp_path := "user://fred_save.tmp.json"
var backup_path := "user://fred_save.backup.json"
var core_save_service: SaveService
var _path_valid := true
var _save_in_progress := false

func _init(prefix: String = "user://fred_save") -> void:
    _path_valid = _is_safe_prefix(prefix)
    if not _path_valid:
        return
    save_path = prefix + ".json"
    temp_path = prefix + ".tmp.json"
    backup_path = prefix + ".backup.json"
    core_save_service = SaveService.new()

func save(session: AdventureSession, timestamp: String = "2000-01-01T00:00:00Z") -> Dictionary:
    if not _path_valid:
        return {"ok":false, "error":"invalid_path"}
    if _save_in_progress:
        return {"ok":false, "error":"save_in_progress"}
    _save_in_progress = true
    var result := _save_internal(session, timestamp)
    _save_in_progress = false
    return result

func _save_internal(session: AdventureSession, timestamp: String) -> Dictionary:
    var data := session.to_save(timestamp)
    var encoded := JSON.stringify(data, "  ")
    if encoded.to_utf8_buffer().size() > MAX_SAVE_BYTES:
        return {"ok":false, "error":"save_too_large"}
    var primary := _candidate(save_path, "primary")
    var backup := _candidate(backup_path, "backup")
    var interrupted := _candidate(temp_path, "temp")
    for candidate: Dictionary in [primary, backup, interrupted]:
        if candidate.get("error") in ["unsupported_schema", "core_incompatible"]:
            return {"ok":false, "error":candidate.error}
        if candidate.get("ok", false) and int(candidate.get("sequence", -1)) > session.checkpoint_sequence:
            return {"ok":false, "error":"stale_checkpoint"}
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null: return {"ok":false, "error":"temp_open_failed"}
    file.store_string(encoded)
    file.flush()
    if file.get_error() != OK: return {"ok":false, "error":"temp_write_failed"}
    file = null
    var verified_temp := _candidate(temp_path, "temp")
    if not verified_temp.get("ok", false):
        return {"ok":false, "error":"temp_verify_failed"}
    if FileAccess.file_exists(save_path):
        if primary.get("ok", false):
            if FileAccess.file_exists(backup_path):
                if DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path)) != OK:
                    return {"ok":false, "error":"backup_remove_failed"}
            if DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(backup_path)) != OK:
                return {"ok":false, "error":"backup_failed"}
        elif DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path)) != OK:
            return {"ok":false, "error":"invalid_primary_remove_failed"}
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path)) != OK:
        return {"ok":false, "error":"replace_failed"}
    core_save_service.stage(data)
    return {"ok":true, "data":data}

func load_session(session: AdventureSession) -> Dictionary:
    if not _path_valid:
        return {"ok":false, "error":"invalid_path"}
    var candidates: Array[Dictionary] = [
        _candidate(save_path, "primary"),
        _candidate(backup_path, "backup"),
        _candidate(temp_path, "temp"),
    ]
    var best: Dictionary = {}
    for candidate: Dictionary in candidates:
        if not candidate.get("ok", false):
            continue
        if best.is_empty() or int(candidate.get("sequence", -1)) > int(best.get("sequence", -1)):
            best = candidate
    if not best.is_empty():
        var restore_result := session.restore(best.data)
        if restore_result.get("ok", false):
            return {"ok":true, "source":best.source}
    for candidate: Dictionary in candidates:
        if candidate.get("error") in ["unsupported_schema", "core_incompatible"]:
            return {"ok":false, "error":candidate.error}
    var invalid_save_exists := false
    for candidate: Dictionary in candidates:
        if candidate.get("exists", false):
            invalid_save_exists = true
            break
    return {
        "ok":true,
        "source":"default",
        "reason":"corrupt" if invalid_save_exists else "missing",
    }

func _candidate(path: String, source: String) -> Dictionary:
    var read_result := _read_result(path)
    if not read_result.get("ok", false):
        return {
            "exists":read_result.get("exists", false),
            "ok":false,
            "error":read_result.get("error", "malformed"),
            "source":source,
        }
    var probe := AdventureSession.new()
    var validation := probe.restore(read_result.data)
    if not validation.get("ok", false):
        return {
            "exists":true,
            "ok":false,
            "error":validation.get("error", "malformed"),
            "source":source,
        }
    return {
        "exists":true,
        "ok":true,
        "error":"",
        "source":source,
        "sequence":probe.checkpoint_sequence,
        "data":read_result.data,
    }

func _read_result(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {"exists":false, "ok":false, "error":"missing", "data":{}}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"exists":true, "ok":false, "error":"read_failed", "data":{}}
    if file.get_length() > MAX_SAVE_BYTES:
        return {"exists":true, "ok":false, "error":"save_too_large", "data":{}}
    var text := file.get_as_text()
    file = null
    var parser := JSON.new()
    if parser.parse(text) != OK or parser.data is not Dictionary:
        return {"exists":true, "ok":false, "error":"malformed", "data":{}}
    return {"exists":true, "ok":true, "error":"", "data":parser.data}

func _is_safe_prefix(prefix: String) -> bool:
    if not prefix.begins_with("user://"):
        return false
    var relative := prefix.trim_prefix("user://")
    if relative.is_empty() or relative.begins_with("/") or relative.ends_with("/"):
        return false
    for component: String in relative.split("/", false):
        if component in ["", ".", ".."]:
            return false
        for character: String in component:
            if character.to_lower() not in "abcdefghijklmnopqrstuvwxyz0123456789_-":
                return false
    return true
