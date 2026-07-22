class_name PlayerSyncService
extends RefCounted
var transport: Callable
var game_id := ""
func configure(request_transport: Callable, configured_game_id: String) -> bool:
    if not request_transport.is_valid() or configured_game_id.strip_edges().is_empty(): return false
    transport = request_transport
    game_id = configured_game_id.strip_edges()
    return true
func sync_profile(nickname: String) -> Dictionary:
    var normalized := nickname.strip_edges()
    if normalized.length() < 3 or normalized.length() > 24 or not _valid_nickname(normalized): return {"ok": false, "error": "invalid_nickname"}
    return _response(transport.call("sync_player_profile", {"nickname": normalized}))
func sync_save(expected_revision: int, payload: Dictionary) -> Dictionary:
    if expected_revision < 0: return {"ok": false, "error": "invalid_revision"}
    var response := _response(transport.call("sync_player_save", {"game_id": game_id, "expected_revision": expected_revision, "payload": payload.duplicate(true)}))
    if str(response.get("status", "")) in ["synced", "unchanged"] and int(response.get("revision", -1)) < expected_revision: return {"ok": false, "error": "stale_server_revision"}
    return response
func resolve_conflict(local_revision: int, local_payload: Dictionary, response: Dictionary) -> Dictionary:
    if str(response.get("status", "")) != "conflict": return {"winner": "none", "revision": local_revision, "payload": local_payload.duplicate(true)}
    return CloudSyncService.resolve({"revision": local_revision, "payload": local_payload}, {"revision": int(response.get("revision", 0)), "payload": response.get("payload", {})})
func _valid_nickname(value: String) -> bool:
    for character in value:
        if not (character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789 _-"): return false
    return true
func _response(value: Variant) -> Dictionary: return value if value is Dictionary else {"ok": false, "error": "invalid_response"}
