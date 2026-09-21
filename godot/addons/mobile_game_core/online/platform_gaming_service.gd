class_name PlatformGamingService
extends Node

signal sign_in_completed(result: Dictionary)
signal leaderboard_closed

const SIGN_IN_TIMEOUT_SECONDS := 30.0
const EventPump = preload("res://addons/mobile_game_core/online/native_event_pump.gd")
const SUPPORTED_PROVIDERS: Array[String] = ["apple_game_center", "google_play_games"]

var plugin: Object
var provider := ""
var leaderboard_ids: Dictionary = {}
var achievement_id_prefix := ""
var state := "unavailable"
var elapsed_seconds := 0.0
var player_id := ""
var team_player_id := ""
var game_player_id := ""
var display_name := ""
var score_submission_allowed := false
var leaderboard_presenting := false


func configure(configured_provider: String, configured_leaderboards: Dictionary, configured_achievement_prefix: String, plugin_override: Object = null) -> bool:
    if configured_provider not in SUPPORTED_PROVIDERS or configured_leaderboards.is_empty():
        return false
    for value: Variant in configured_leaderboards.values():
        if str(value).strip_edges().is_empty():
            return false
    provider = configured_provider
    leaderboard_ids = configured_leaderboards.duplicate(true)
    achievement_id_prefix = configured_achievement_prefix.strip_edges()
    plugin = plugin_override
    if plugin == null and configured_provider == "apple_game_center" and Engine.has_singleton("GameCenter"):
        plugin = Engine.get_singleton("GameCenter")
    if not _has_required_interface(plugin):
        plugin = null
        state = "unavailable"
        return false
    score_submission_allowed = plugin_override != null or not OS.is_debug_build()
    leaderboard_presenting = false
    state = "ready"
    return true


func is_available() -> bool:
    return plugin != null and state != "unavailable"


func submit_score(board: String, score: int) -> bool:
    if not score_submission_allowed or not is_available() or not leaderboard_ids.has(board) or not bool(plugin.call("is_authenticated")) or not plugin.has_method("post_score"):
        return false
    return int(plugin.call("post_score", {"score": maxi(0, score), "category": str(leaderboard_ids[board])})) == OK


func open_leaderboard(board: String) -> bool:
    if not can_open_leaderboard(board):
        return false
    var error := int(plugin.call("show_game_center", {"view": "leaderboards", "leaderboard_name": str(leaderboard_ids[board])}))
    if error != OK:
        return false
    leaderboard_presenting = true
    return true


func can_open_leaderboard(board: String) -> bool:
    return is_available() and leaderboard_ids.has(board) and bool(plugin.call("is_authenticated")) and plugin.has_method("show_game_center") and not leaderboard_presenting


func submit_achievement(achievement_id: String, progress: float = 100.0, show_banner: bool = true) -> bool:
    if achievement_id.is_empty() or not is_available() or not bool(plugin.call("is_authenticated")) or not plugin.has_method("award_achievement"):
        return false
    return int(plugin.call("award_achievement", {
        "name": achievement_id_prefix + achievement_id,
        "progress": clampf(progress, 0.0, 100.0),
        "show_completion_banner": show_banner,
    })) == OK


func begin_sign_in() -> bool:
    if not is_available() or state in ["authenticating", "awaiting_signature"]:
        return false
    elapsed_seconds = 0.0
    player_id = ""
    team_player_id = ""
    game_player_id = ""
    display_name = ""
    if bool(plugin.call("is_authenticated")):
        state = "awaiting_signature"
        return _request_signature_or_finish_local()
    state = "authenticating"
    var error := int(plugin.call("authenticate"))
    if error != OK:
        _finish({"ok": false, "error": "platform_auth_start_failed", "error_code": error})
        return false
    return true


func poll() -> void:
    if not is_available():
        return
    EventPump.drain(plugin, _handle_event)


func _process(delta: float) -> void:
    poll()
    if state not in ["authenticating", "awaiting_signature"]:
        return
    elapsed_seconds += delta
    if elapsed_seconds >= SIGN_IN_TIMEOUT_SECONDS and state in ["authenticating", "awaiting_signature"]:
        _finish({"ok": false, "error": "platform_auth_timeout"})


func _handle_event(event: Dictionary) -> void:
    var event_type := str(event.get("type", ""))
    if event_type == "show_game_center":
        if leaderboard_presenting:
            leaderboard_presenting = false
            leaderboard_closed.emit()
        return
    if event_type == "authentication" and state == "authenticating":
        if str(event.get("result", "")) != "ok" or str(event.get("player_id", "")).is_empty():
            _finish({"ok": false, "error": "platform_auth_failed", "error_code": int(event.get("error_code", 0))})
            return
        player_id = str(event.get("player_id", ""))
        team_player_id = str(event.get("team_player_id", event.get("teamPlayerID", "")))
        game_player_id = str(event.get("game_player_id", event.get("gamePlayerID", "")))
        display_name = str(event.get("displayName", event.get("alias", "")))
        state = "awaiting_signature"
        _request_signature_or_finish_local()
    elif event_type == "identity_verification_signature" and state == "awaiting_signature":
        if str(event.get("result", "")) != "ok":
            _finish_local_identity()
            return
        var signature_payload := {
            "player_id": str(event.get("player_id", player_id)),
            "team_player_id": str(event.get("team_player_id", event.get("teamPlayerID", team_player_id))),
            "game_player_id": str(event.get("game_player_id", event.get("gamePlayerID", game_player_id))),
            "public_key_url": str(event.get("public_key_url", "")),
            "signature": str(event.get("signature", "")),
            "salt": str(event.get("salt", "")),
            "timestamp": int(event.get("timestamp", 0)),
        }
        if str(signature_payload.player_id).is_empty() or str(signature_payload.public_key_url).is_empty() or str(signature_payload.signature).is_empty() or str(signature_payload.salt).is_empty() or int(signature_payload.timestamp) <= 0:
            _finish_local_identity()
            return
        _finish({"ok": true, "player_id": signature_payload.player_id, "display_name": display_name, "identity_token": JSON.stringify(signature_payload), "verified_signature": true})


func _request_signature_or_finish_local() -> bool:
    if player_id.is_empty() and bool(plugin.call("is_authenticated")):
        state = "authenticating"
        var error := int(plugin.call("authenticate"))
        if error != OK:
            _finish({"ok": false, "error": "platform_auth_refresh_failed", "error_code": error})
            return false
        return true
    var error := int(plugin.call("request_identity_verification_signature"))
    if error != OK:
        _finish_local_identity()
        return false
    return true


func _finish_local_identity() -> void:
    if player_id.is_empty():
        _finish({"ok": false, "error": "platform_player_missing"})
        return
    _finish({"ok": true, "player_id": player_id, "display_name": display_name, "identity_token": "", "verified_signature": false})


func _finish(result: Dictionary) -> void:
    state = "authenticated" if bool(result.get("ok", false)) else "ready"
    elapsed_seconds = 0.0
    sign_in_completed.emit(result.duplicate(true))


func _has_required_interface(candidate: Object) -> bool:
    if candidate == null:
        return false
    for method_name in ["authenticate", "is_authenticated", "request_identity_verification_signature", "get_pending_event_count", "pop_pending_event"]:
        if not candidate.has_method(method_name):
            return false
    return true
