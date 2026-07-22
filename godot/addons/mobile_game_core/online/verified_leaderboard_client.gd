class_name VerifiedLeaderboardClient
extends RefCounted

const READ_SCOPES: Array[String] = ["global", "around_me", "daily", "weekly", "personal_best", "campaign_completions"]

var transport: Callable
var game_id := ""

func configure(request_transport: Callable, configured_game_id: String) -> bool:
    if not request_transport.is_valid() or configured_game_id.strip_edges().is_empty():
        return false
    transport = request_transport
    game_id = configured_game_id.strip_edges()
    return true

func leaderboard(scope: String, level_id: int = 0, limit: int = 50) -> Variant:
    if scope not in READ_SCOPES or level_id < 0 or limit < 1 or limit > 100 or not transport.is_valid():
        return {"ok": false, "error": "invalid_request"}
    return transport.call("leaderboard_query", {"game_id": game_id, "scope": scope, "level_id": level_id, "limit": limit})

func issue_session(level_id: int) -> Variant:
    if game_id.is_empty() or level_id < 1 or not transport.is_valid():
        return {"ok": false, "error": "invalid_request"}
    return transport.call("issue_score_session", {"game_id": game_id, "level_id": level_id})

func submit_score(evidence: Dictionary) -> Variant:
    var required := ["session_id", "nonce", "submission_key", "score", "elapsed_ms", "movement_count", "targets", "campaign_completion"]
    for field in required:
        if not evidence.has(field):
            return {"ok": false, "error": "missing_evidence"}
    if not transport.is_valid():
        return {"ok": false, "error": "offline"}
    return transport.call("submit_verified_score", evidence.duplicate(true))
