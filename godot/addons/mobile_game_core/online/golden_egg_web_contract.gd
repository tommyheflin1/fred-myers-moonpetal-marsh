class_name GoldenEggWebContract
extends RefCounted

const AUTHORITATIVE_ORIGIN := "https://theflinsappvaultllc.com"
const HUNT_URL := AUTHORITATIVE_ORIGIN + "/golden-eggs"
const RETRY_SECONDS: Array[int] = [8, 16, 32, 60]

var game_id := ""
var egg_id := ""

func configure(configured_game_id: String, configured_egg_id: String) -> bool:
    game_id = configured_game_id.strip_edges()
    egg_id = configured_egg_id.strip_edges()
    return _valid_slug(game_id) and _valid_slug(egg_id)

func discovery_path() -> String:
    return "/api/golden-eggs/discoveries"

func identity_exchange_path() -> String:
    return "/api/game-center/identity/exchange"

func identity_exchange_body(platform_result: Dictionary, bundle_id: String, public_name_consent: bool) -> Dictionary:
    if not bool(platform_result.get("ok", false)) or not bool(platform_result.get("verified_signature", false)):
        return {}
    var token_text := str(platform_result.get("identity_token", ""))
    var token: Variant = JSON.parse_string(token_text)
    if not token is Dictionary or bundle_id.strip_edges().is_empty():
        return {}
    for field: String in ["team_player_id", "game_player_id", "public_key_url", "signature", "salt", "timestamp"]:
        if not token.has(field) or str(token.get(field, "")).is_empty():
            return {}
    return {
        "game_id": game_id,
        "bundle_id": bundle_id.strip_edges(),
        "team_player_id": str(token.team_player_id),
        "game_player_id": str(token.game_player_id),
        "signed_player_id_scope": "team_player_id",
        "public_key_url": str(token.public_key_url),
        "signature": str(token.signature),
        "salt": str(token.salt),
        "timestamp": int(token.timestamp),
        "provider_display_name": str(platform_result.get("display_name", "")),
        "provider_display_name_source": "game_center_reported",
        "public_name_consent": public_name_consent,
    }

func request_headers(protocol: String, timestamp: int, nonce: String, idempotency_key: String) -> Dictionary:
    if protocol not in ["bearer-v2", "hmac-v1"] or timestamp <= 0 or not _valid_token(nonce) or not _valid_token(idempotency_key): return {}
    return {"Accept":"application/json", "Accept-Encoding":"identity", "Content-Type":"application/json", "X-Golden-Egg-Game-Id":game_id, "X-Golden-Egg-Protocol":protocol, "X-Golden-Egg-Timestamp":str(timestamp), "X-Golden-Egg-Nonce":nonce.to_lower(), "Idempotency-Key":idempotency_key.to_lower()}

func validate_discovery_response(result: Dictionary) -> bool:
    var required: Array[String] = ["discovery_id", "public_reference", "public_secret_code", "discovered_at", "overall_rank", "game_rank", "first_for_game", "privacy_status", "public_identity_source", "golden_egg_hunt_url", "public_discovery_url"]
    for field: String in required:
        if not result.has(field): return false
    var reference := str(result.get("public_reference", ""))
    if not _valid_token(reference) or str(result.get("golden_egg_hunt_url", "")) != HUNT_URL: return false
    if str(result.get("public_discovery_url", "")) != "%s/golden-eggs/discovery/%s" % [AUTHORITATIVE_ORIGIN, reference]: return false
    return int(result.get("overall_rank", 0)) >= 1 and int(result.get("game_rank", 0)) >= 1 and not str(result.get("discovery_id", "")).is_empty() and str(result.get("privacy_status", "")) in ["PENDING_PRIVACY_CHOICE", "ANONYMOUS", "PUBLIC"] and str(result.get("public_identity_source", "")) in ["anonymous", "game_center_reported"]

func public_snapshot(result: Dictionary) -> Dictionary:
    if not validate_discovery_response(result): return {}
    var allowed: Array[String] = ["discovery_id", "public_reference", "public_secret_code", "discovered_at", "overall_rank", "game_rank", "first_for_game", "privacy_status", "public_identity_source", "public_player", "golden_egg_hunt_url", "public_discovery_url"]
    var snapshot := {}
    for field: String in allowed:
        if result.has(field): snapshot[field] = result[field]
    return snapshot

func is_safe_website_url(candidate: String) -> bool:
    return candidate == HUNT_URL or candidate.begins_with(AUTHORITATIVE_ORIGIN + "/golden-eggs/discovery/")

func _valid_slug(value: String) -> bool:
    if value.length() < 3 or value.length() > 64: return false
    for character: String in value:
        if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character != "-": return false
    return true

func _valid_token(value: String) -> bool:
    if value.length() < 8 or value.length() > 128: return false
    for character: String in value:
        if not (character >= "a" and character <= "z") and not (character >= "A" and character <= "Z") and not (character >= "0" and character <= "9") and character not in ["-", "_"]: return false
    return true
