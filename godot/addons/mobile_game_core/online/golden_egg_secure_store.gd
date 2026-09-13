class_name GoldenEggSecureStore
extends RefCounted

# Uses the existing app-bundle-scoped, device-only Flins Keychain bridge.
# No plaintext fallback and no writes during ordinary initialization.
const MAX_BYTES := 8192
var _bridge: Object
var _key := ""

func configure(game_id: String, egg_id: String, bridge: Object = null) -> bool:
    if game_id.is_empty() or egg_id.is_empty():
        return false
    _key = "golden_egg.discovery." + (game_id + ":" + egg_id).sha256_text().left(40)
    _bridge = bridge
    if _bridge == null and OS.has_feature("ios") and Engine.has_singleton("GameCenter"):
        _bridge = Engine.get_singleton("GameCenter")
    return _available()

func load_record() -> Dictionary:
    if not _available():
        return {"ok": false}
    var response: Dictionary = _bridge.call("flins_keychain_read", _key)
    if not bool(response.get("ok", false)):
        return {"ok": false}
    if not bool(response.get("found", false)):
        return {"ok": true, "found": false}
    var encoded := str(response.get("value", ""))
    if encoded.to_utf8_buffer().size() > MAX_BYTES:
        return {"ok": false}
    var parsed: Variant = JSON.parse_string(encoded)
    if not parsed is Dictionary:
        return {"ok": false}
    return {"ok": true, "found": true, "record": parsed}

func save_record(record: Dictionary) -> bool:
    if not _available():
        return false
    var encoded := JSON.stringify(record)
    if encoded.to_utf8_buffer().size() > MAX_BYTES:
        return false
    if int(_bridge.call("flins_keychain_write", _key, encoded)) != OK:
        return false
    var verified: Dictionary = _bridge.call("flins_keychain_read", _key)
    return bool(verified.get("ok", false)) and bool(verified.get("found", false)) and str(verified.get("value", "")) == encoded

func _available() -> bool:
    return _bridge != null and not _key.is_empty() and _bridge.has_method("flins_keychain_read") and _bridge.has_method("flins_keychain_write")
