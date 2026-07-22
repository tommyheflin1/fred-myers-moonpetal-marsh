class_name LeaderboardPresenter
extends RefCounted

signal state_changed(state: String)
const SCOPES: Array[String] = ["global", "around_me", "daily", "weekly", "personal_best", "campaign_completions"]
var state := "idle"
var scope := "global"
var rows: Array[Dictionary] = []
var message := ""
var client: RefCounted

func configure(verified_client: RefCounted) -> bool:
    if verified_client == null or not verified_client.has_method("leaderboard"): return false
    client = verified_client
    return true

func refresh(requested_scope: String, level_id: int = 0, limit: int = 50) -> bool:
    if client == null or requested_scope not in SCOPES:
        _set_failure("error", "Leaderboard unavailable.")
        return false
    scope = requested_scope
    state = "loading"
    message = "Loading leaderboard..."
    rows.clear()
    state_changed.emit(state)
    var response: Variant = client.leaderboard(scope, level_id, limit)
    if response is Dictionary and not bool(response.get("ok", true)):
        _set_failure("offline" if str(response.get("error", "")) == "offline" else "error", "Play offline or try again.")
        return false
    var data: Variant = response.get("data", []) if response is Dictionary else response
    if not data is Array:
        _set_failure("error", "Leaderboard response was invalid.")
        return false
    for value: Variant in data:
        if value is Dictionary: rows.append(_normalized_row(value))
    state = "empty" if rows.is_empty() else "ready"
    message = "No verified scores yet." if rows.is_empty() else "%d verified players" % rows.size()
    state_changed.emit(state)
    return true

func scope_label() -> String: return scope.replace("_", " ").capitalize()
func show_offline(offline_message: String = "Sign in to view verified rankings.") -> void: _set_failure("offline", offline_message)
func _normalized_row(value: Dictionary) -> Dictionary:
    var nickname := str(value.get("nickname", "PLAYER")).strip_edges().left(24)
    return {"rank": maxi(1, int(value.get("rank", 1))), "nickname": nickname if not nickname.is_empty() else "PLAYER", "score": maxi(0, int(value.get("score", 0))), "elapsed_ms": maxi(0, int(value.get("elapsed_ms", 0))), "campaign_completions": maxi(0, int(value.get("campaign_completions", 0))), "gold_snake": bool(value.get("gold_snake", false)), "prestige_rank": maxi(0, int(value.get("prestige_rank", 0)))}
func _set_failure(failure_state: String, failure_message: String) -> void:
    state = failure_state
    message = failure_message
    rows.clear()
    state_changed.emit(state)
