class_name FredGoldenEggClient
extends RefCounted

const BASE_URL := "https://theflinsappvaultllc.com"
const HUNT_PATH := "/golden-eggs"
const BOOTSTRAP_PATH := "/api/golden-eggs/player/bootstrap"
const DISCOVERY_PATH := "/api/golden-eggs/discoveries"
const LEADERBOARD_PATH := "/api/golden-eggs/leaderboard?game=fred-myers"
const MAX_RESPONSE_BYTES := 32768

var _signing_key := PackedByteArray()
var _player_bearer := ""

func configure_ephemeral_signer(signing_key: PackedByteArray, player_bearer: String = "") -> bool:
	# The key is accepted only from a platform secure provider at runtime. It is
	# never serialized by this class and is intentionally absent from the repo.
	if signing_key.size() < 32:
		return false
	_signing_key = signing_key.duplicate()
	_player_bearer = player_bearer
	return true

func clear_credentials() -> void:
	_signing_key.fill(0)
	_signing_key.clear()
	_player_bearer = ""

func is_configured() -> bool:
	return _signing_key.size() >= 32

func bootstrap_request(client_key: String, idempotency_key: String, timestamp: int, nonce: String) -> Dictionary:
	return build_request("POST", BOOTSTRAP_PATH, {"client_key": client_key}, idempotency_key, timestamp, nonce, false)

func discovery_request(evidence: Dictionary, app_version: String, build: String, idempotency_key: String, timestamp: int, nonce: String) -> Dictionary:
	var body := {
		"egg_id": FredGoldenEggRunState.EGG_ID,
		"egg_version": "1",
		"app_version": app_version,
		"build_version": build,
		"verification_evidence": JSON.stringify(evidence),
	}
	return build_request("POST", DISCOVERY_PATH, body, idempotency_key, timestamp, nonce, true)

func privacy_request(discovery_id: String, privacy: String, display_name: String, idempotency_key: String, timestamp: int, nonce: String) -> Dictionary:
	if not _safe_identifier(discovery_id) or privacy not in ["PUBLIC", "ANONYMOUS"]:
		return {"ok": false, "error": "invalid_privacy_request"}
	var body := {"privacy_status": privacy}
	if privacy == "PUBLIC":
		body["display_name"] = display_name.left(30)
	return build_request("PATCH", "/api/golden-eggs/discoveries/%s/privacy" % discovery_id, body, idempotency_key, timestamp, nonce, true)

func session_exchange_request(public_ref: String, idempotency_key: String, timestamp: int, nonce: String) -> Dictionary:
	if not _safe_identifier(public_ref):
		return {"ok": false, "error": "invalid_public_reference"}
	return build_request("POST", "/api/golden-eggs/discovery/%s/session" % public_ref, {}, idempotency_key, timestamp, nonce, true)

func build_request(method: String, path: String, body: Dictionary, idempotency_key: String, timestamp: int, nonce: String, require_player: bool) -> Dictionary:
	if not is_configured():
		return {"ok": false, "error": "secure_signer_unavailable"}
	if not _uuid(idempotency_key) or not _uuid(nonce) or timestamp < 1000000000 or timestamp > 9999999999:
		return {"ok": false, "error": "invalid_auth_input"}
	if require_player and _player_bearer.length() < 32:
		return {"ok": false, "error": "player_bearer_unavailable"}
	var normalized_method := method.to_upper()
	if normalized_method not in ["POST", "PATCH"] or not path.begins_with("/api/golden-eggs/") or "?" in path:
		return {"ok": false, "error": "unsafe_endpoint"}
	var body_text := JSON.stringify(body)
	var body_hash := body_text.sha256_text()
	var canonical := "\n".join([normalized_method,path,str(timestamp),nonce.to_lower(),idempotency_key.to_lower(),body_hash])
	var hmac := HMACContext.new()
	if hmac.start(HashingContext.HASH_SHA256, _signing_key) != OK:
		return {"ok": false, "error": "signing_failed"}
	hmac.update(canonical.to_utf8_buffer())
	var signature := hmac.finish().hex_encode()
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"X-Golden-Egg-Game-Id: %s" % FredGoldenEggRunState.GAME_ID,
		"X-Golden-Egg-Timestamp: %d" % timestamp,
		"X-Golden-Egg-Nonce: %s" % nonce.to_lower(),
		"Idempotency-Key: %s" % idempotency_key.to_lower(),
		"X-Golden-Egg-Signature: v1=%s" % signature,
	])
	if require_player:
		headers.append("Authorization: Bearer %s" % _player_bearer)
	return {"ok": true, "url": BASE_URL + path, "method": normalized_method, "path": path, "headers": headers, "body": body_text, "canonical_hash": canonical.sha256_text()}

func validate_server_discovery(payload: Dictionary) -> Dictionary:
	if not bool(payload.get("success", false)):
		return {"ok": false, "error": "server_rejected"}
	for field: String in ["discovery_id", "public_reference", "overall_rank", "discovered_at", "public_secret_code"]:
		if not payload.has(field):
			return {"ok": false, "error": "missing_server_field"}
	if int(payload.overall_rank) < 1 or not _safe_identifier(str(payload.discovery_id)) or not _safe_identifier(str(payload.public_reference)):
		return {"ok": false, "error": "invalid_server_field"}
	return {
		"ok": true,
		"discovery_id": str(payload.discovery_id),
		"public_ref": str(payload.public_reference),
		"server_rank": int(payload.overall_rank),
		"server_time": str(payload.discovered_at),
		"secret_code": str(payload.public_secret_code),
	}

func _uuid(value: String) -> bool:
	if value.length() != 36:
		return false
	for index in value.length():
		var character := value[index]
		if index in [8,13,18,23]:
			if character != "-": return false
		elif character.to_lower() not in "0123456789abcdef":
			return false
	return true

func _safe_identifier(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	for character: String in value:
		if character.to_lower() not in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return true
