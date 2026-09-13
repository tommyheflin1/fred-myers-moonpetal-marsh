class_name GoldenEggLocalStore
extends RefCounted

const STORE_PATH := "user://fred_myers_golden_egg_credentials.json"
const MAX_VALUE_LENGTH := 8192

var values: Dictionary = {}
var keychain: Object = null
var production_keychain_required := false


func _init(backend: Object = null, platform_name: String = "") -> void:
    var platform := OS.get_name() if platform_name.is_empty() else platform_name
    production_keychain_required = platform == "iOS"
    if production_keychain_required:
        var candidate: Object = backend
        if candidate == null and Engine.has_singleton("GameCenter"):
            candidate = Engine.get_singleton("GameCenter")
        if candidate != null and candidate.has_method("flins_keychain_read") and candidate.has_method("flins_keychain_write") and candidate.has_method("flins_keychain_erase"):
            keychain = candidate
            _migrate_legacy_values_to_keychain()
    else:
        _load_values()


func get_secret(key: String) -> String:
    if not _valid_key(key):
        return ""
    if keychain != null:
        var result: Variant = keychain.call("flins_keychain_read", key)
        if result is Dictionary and bool(result.get("ok", false)) and bool(result.get("found", false)):
            return str(result.get("value", ""))
        return ""
    if production_keychain_required:
        return ""
    return str(values.get(key, ""))


func set_secret(key: String, value: String) -> bool:
    if not _valid_key(key) or value.length() > MAX_VALUE_LENGTH:
        return false
    if keychain != null:
        return int(keychain.call("flins_keychain_write", key, value)) == 0
    if production_keychain_required:
        return false
    values[key] = value
    return _save_values()


func erase_secret(key: String) -> bool:
    if not _valid_key(key):
        return false
    if keychain != null:
        return int(keychain.call("flins_keychain_erase", key)) == 0
    if production_keychain_required:
        return false
    values.erase(key)
    return _save_values()


func _valid_key(key: String) -> bool:
    return key.begins_with("golden_egg.") and key.length() <= 128


func _migrate_legacy_values_to_keychain() -> void:
    _load_values()
    if values.is_empty():
        return
    var verified := true
    for key_value: Variant in values.keys():
        var key := str(key_value)
        var existing: Variant = keychain.call("flins_keychain_read", key)
        if existing is not Dictionary or not bool(existing.get("ok", false)):
            verified = false
            continue
        if bool(existing.get("found", false)):
            continue
        if int(keychain.call("flins_keychain_write", key, str(values[key_value]))) != 0:
            verified = false
            continue
        var readback: Variant = keychain.call("flins_keychain_read", key)
        if readback is not Dictionary or not bool(readback.get("ok", false)) or not bool(readback.get("found", false)) or str(readback.get("value", "")) != str(values[key_value]):
            verified = false
    values.clear()
    # Remove the old credential file only after every value is secured. A failed
    # migration remains retryable without falling back to plaintext on iOS.
    if verified and FileAccess.file_exists(STORE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(STORE_PATH))


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
