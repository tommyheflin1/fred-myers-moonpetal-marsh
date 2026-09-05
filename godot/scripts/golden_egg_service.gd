class_name GoldenEggService
extends RefCounted

const BASE_URL := "https://theflinsappvaultllc.com"
const HUNT_URL := "https://theflinsappvaultllc.com/golden-eggs"
const BOOTSTRAP_PATH := "/api/golden-eggs/player/bootstrap"
const DISCOVERY_PATH := "/api/golden-eggs/discoveries"
const PRIVACY_PATH_TEMPLATE := "/api/golden-eggs/discoveries/%s/privacy"
const SESSION_PATH_TEMPLATE := "/api/golden-eggs/discovery/%s/session"
const GAME_ID := "fred-myers"
const EGG_ID := "moonpetal-golden-egg"
const EGG_VERSION := "1"
const APP_VERSION := "1.1"
const BUILD_VERSION := "8"
const AUTH_PROTOCOL := "bearer-v2"

const STORE_CLIENT_KEY := "golden_egg.client_player_key"
const STORE_ACCESS_TOKEN := "golden_egg.player_access_token"
const STORE_PENDING_OPERATION := "golden_egg.pending_operation"
const STORE_SESSION_TOKEN := "golden_egg.discovery_session_token"
const STORE_SECURE_URL := "golden_egg.secure_discovery_url"

var request_transport: Callable
var secure_store: Object
var status := "idle"
var public_result: Dictionary = {}
var privacy_status := "PENDING_PRIVACY_CHOICE"
var last_safe_error := ""


func configure(transport: Callable, platform_secure_store: Object, _legacy_signer: Callable = Callable()) -> bool:
    request_transport = transport
    secure_store = platform_secure_store
    return production_client_ready()


func production_client_ready() -> bool:
    return (
        request_transport.is_valid()
        and secure_store != null
        and secure_store.has_method("get_secret")
        and secure_store.has_method("set_secret")
        and secure_store.has_method("erase_secret")
    )


func trust_boundary_status() -> Dictionary:
    return {
        "production_ready": production_client_ready(),
        "shared_secret_embedded": false,
        "signer_required": false,
        "secure_store_required": true,
        "auth_protocol": AUTH_PROTOCOL,
        "block_reason": "CLIENT_RUNTIME_NOT_PROVISIONED" if not production_client_ready() else "",
    }


func submit_discovery(verification_evidence: String) -> Dictionary:
    if verification_evidence.length() < 16 or verification_evidence.length() > 2048:
        return _pending_failure("INVALID_LOCAL_INTEGRITY_EVIDENCE")
    var pending := _load_pending_operation()
    if pending.is_empty():
        pending = {
            "idempotency_key": _uuid_v4(),
            "payload": {
                "egg_id": EGG_ID,
                "egg_version": EGG_VERSION,
                "app_version": APP_VERSION,
                "build_version": BUILD_VERSION,
                "verification_evidence": verification_evidence,
            },
        }
        if not _store_json_secret(STORE_PENDING_OPERATION, pending):
            return _pending_failure("PLATFORM_SECURE_STORAGE_UNAVAILABLE")
    return _submit_pending(pending)


func retry_pending_discovery() -> Dictionary:
    var pending := _load_pending_operation()
    if pending.is_empty():
        return _pending_failure("NO_PENDING_DISCOVERY")
    return _submit_pending(pending)


func has_pending_discovery() -> bool:
    return not _load_pending_operation().is_empty()


func submit_privacy_choice(make_public: bool, display_name: String = "") -> Dictionary:
    if public_result.is_empty() or str(public_result.get("discovery_id", "")).is_empty():
        return _safe_failure("NO_ACCEPTED_DISCOVERY")
    var normalized_name := display_name.strip_edges()
    if make_public and (normalized_name.length() < 2 or normalized_name.length() > 30):
        return _safe_failure("DISPLAY_NAME_MUST_BE_2_TO_30_CHARACTERS")
    var payload := {"privacy_status": "PUBLIC", "display_name": normalized_name} if make_public else {"privacy_status": "ANONYMOUS"}
    var result := _authenticated_request(
        "PATCH",
        PRIVACY_PATH_TEMPLATE % str(public_result.discovery_id),
        payload,
        _uuid_v4()
    )
    if not bool(result.get("success", false)):
        return result
    privacy_status = str(result.get("privacy_status", payload["privacy_status"]))
    public_result["privacy_status"] = privacy_status
    if privacy_status == "PUBLIC":
        public_result["public_player"] = str(result.get("public_player", normalized_name))
    else:
        public_result["public_player"] = "Anonymous"
    status = "privacy_saved"
    return _public_response(result)


func public_snapshot() -> Dictionary:
    return {
        "status": status,
        "privacy_status": privacy_status,
        "result": _public_response(public_result),
    }


func restore_public_snapshot(snapshot_value: Variant) -> void:
    if snapshot_value is not Dictionary:
        return
    var snapshot: Dictionary = snapshot_value
    var restored_result: Variant = snapshot.get("result", {})
    public_result = _public_response(restored_result if restored_result is Dictionary else {})
    privacy_status = str(snapshot.get("privacy_status", public_result.get("privacy_status", "PENDING_PRIVACY_CHOICE")))
    status = str(snapshot.get("status", "idle"))
    if status not in ["idle", "pending", "accepted", "privacy_saved"]:
        status = "idle"


func has_canonical_discovery() -> bool:
    return not str(public_result.get("discovery_id", "")).is_empty()


func hunt_url() -> String:
    return HUNT_URL


func public_discovery_url() -> String:
    var candidate := str(public_result.get("public_discovery_url", ""))
    return candidate if candidate.begins_with("%s/golden-eggs/discovery/" % BASE_URL) else ""


func secure_discovery_url() -> String:
    var candidate := _get_secret(STORE_SECURE_URL)
    var session_token := _get_secret(STORE_SESSION_TOKEN)
    var public_url := public_discovery_url()
    if public_url.is_empty() or session_token.is_empty():
        return ""
    return candidate if candidate == "%s?session=%s" % [public_url, session_token] else ""


func view_my_discovery_url() -> String:
    var secure_url := secure_discovery_url()
    return secure_url if not secure_url.is_empty() else public_discovery_url()


func exchange_discovery_session() -> Dictionary:
    if not has_canonical_discovery():
        return _safe_failure("NO_ACCEPTED_DISCOVERY")
    var public_reference := str(public_result.get("public_reference", ""))
    if not _is_safe_public_reference(public_reference):
        return _safe_failure("PUBLIC_REFERENCE_INVALID")
    var session_token := _get_secret(STORE_SESSION_TOKEN)
    if session_token.is_empty():
        return _safe_failure("DISCOVERY_SESSION_UNAVAILABLE")
    var result := _authenticated_request(
        "POST",
        SESSION_PATH_TEMPLATE % public_reference,
        {"discovery_session_token": session_token},
        _uuid_v4()
    )
    if not bool(result.get("success", false)):
        return result
    if str(result.get("discovery_id", "")) != str(public_result.get("discovery_id", "")):
        return _safe_failure("DISCOVERY_SESSION_OWNERSHIP_MISMATCH")
    _erase_secret(STORE_SESSION_TOKEN)
    _erase_secret(STORE_SECURE_URL)
    status = "accepted"
    return _public_response(result)


func _submit_pending(pending: Dictionary) -> Dictionary:
    if not production_client_ready():
        return _pending_failure("CLIENT_RUNTIME_NOT_PROVISIONED")
    var player_result := _ensure_player()
    if not bool(player_result.get("success", false)):
        return _pending_failure(str(player_result.get("error", "PLAYER_BOOTSTRAP_PENDING")))
    var payload: Variant = pending.get("payload", {})
    if payload is not Dictionary:
        return _pending_failure("PENDING_DISCOVERY_INVALID")
    var result := _authenticated_request("POST", DISCOVERY_PATH, payload, str(pending.get("idempotency_key", "")))
    if not bool(result.get("success", false)):
        return _pending_failure(str(result.get("error", "SECURE_REGISTRATION_PENDING")))
    if not _validate_discovery_response(result):
        return _pending_failure("BACKEND_RESPONSE_INVALID")
    public_result = _public_response(result)
    privacy_status = str(result.get("privacy_status", "PENDING_PRIVACY_CHOICE"))
    status = "accepted"
    _erase_secret(STORE_PENDING_OPERATION)
    _store_secret(STORE_SESSION_TOKEN, str(result.get("discovery_session_token", "")))
    _store_secret(STORE_SECURE_URL, str(result.get("secure_discovery_url", "")))
    last_safe_error = ""
    return _public_response(result)


func _ensure_player() -> Dictionary:
    var access_token := _get_secret(STORE_ACCESS_TOKEN)
    if not access_token.is_empty():
        return {"success": true}
    var client_key := _get_secret(STORE_CLIENT_KEY)
    if client_key.is_empty():
        client_key = _random_base64url(32)
        if not _store_secret(STORE_CLIENT_KEY, client_key):
            return _safe_failure("PLATFORM_SECURE_STORAGE_UNAVAILABLE")
    var bootstrap := _client_request(
        "POST",
        BOOTSTRAP_PATH,
        {"client_player_key": client_key},
        _uuid_v4(),
        ""
    )
    if not bool(bootstrap.get("success", false)):
        return bootstrap
    access_token = str(bootstrap.get("player_access_token", ""))
    if access_token.is_empty() or not _store_secret(STORE_ACCESS_TOKEN, access_token):
        return _safe_failure("PLAYER_CREDENTIAL_STORAGE_FAILED")
    return {"success": true}


func _authenticated_request(method: String, path: String, payload: Dictionary, idempotency_key: String) -> Dictionary:
    var access_token := _get_secret(STORE_ACCESS_TOKEN)
    if access_token.is_empty():
        return _safe_failure("PLAYER_ACCESS_UNAVAILABLE")
    return _client_request(method, path, payload, idempotency_key, access_token, 1)


func _client_request(method: String, path: String, payload: Dictionary, idempotency_key: String, bearer: String, retry_remaining: int = 1) -> Dictionary:
    if not production_client_ready():
        return _safe_failure("CLIENT_RUNTIME_NOT_PROVISIONED")
    var body := JSON.stringify(payload)
    var timestamp := str(int(Time.get_unix_time_from_system()))
    var nonce := _uuid_v4().to_lower()
    var stable_idempotency := idempotency_key.to_lower()
    var headers := {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Accept-Encoding": "identity",
        "X-Golden-Egg-Game-Id": GAME_ID,
        "X-Golden-Egg-Protocol": AUTH_PROTOCOL,
        "X-Golden-Egg-Timestamp": timestamp,
        "X-Golden-Egg-Nonce": nonce,
        "Idempotency-Key": stable_idempotency,
    }
    if not bearer.is_empty():
        headers["Authorization"] = "Bearer %s" % bearer
    var response_value: Variant = request_transport.call(method.to_upper(), "%s%s" % [BASE_URL, path], headers, body)
    if response_value is not Dictionary:
        return _safe_failure("SECURE_REGISTRATION_PENDING")
    var response: Dictionary = response_value
    if int(response.get("status", 0)) == 409 and retry_remaining > 0:
        # The nonce is per-attempt. A single bounded retry keeps the logical
        # idempotency key and payload while rebuilding freshness.
        return _client_request(method, path, payload, idempotency_key, bearer, retry_remaining - 1)
    if int(response.get("status", 0)) == 409:
        return _safe_failure("ANTI_REPLAY_REJECTED")
    var response_body: Variant = response.get("body", response)
    if response_body is not Dictionary:
        return _safe_failure("BACKEND_RESPONSE_INVALID")
    return response_body


func _validate_discovery_response(result: Dictionary) -> bool:
    var required := ["discovery_id", "public_reference", "public_secret_code", "discovered_at", "overall_rank", "game_rank", "first_for_game", "privacy_status", "golden_egg_hunt_url", "public_discovery_url", "secure_discovery_url", "discovery_session_token", "discovery_session_expires_at"]
    for field: String in required:
        if not result.has(field):
            return false
    if str(result["golden_egg_hunt_url"]) != HUNT_URL:
        return false
    var public_reference := str(result["public_reference"])
    if not _is_safe_public_reference(public_reference):
        return false
    var expected_public_url := "%s/golden-eggs/discovery/%s" % [BASE_URL, public_reference]
    if str(result["public_discovery_url"]) != expected_public_url:
        return false
    var session_token := str(result["discovery_session_token"])
    if session_token.is_empty() or str(result["secure_discovery_url"]) != "%s?session=%s" % [expected_public_url, session_token]:
        return false
    if int(result["overall_rank"]) < 1 or int(result["game_rank"]) < 1:
        return false
    return not str(result["discovery_id"]).is_empty() and not str(result["discovered_at"]).is_empty() and not str(result["public_secret_code"]).is_empty()


func _public_response(value: Dictionary) -> Dictionary:
    var allowed := [
        "success", "discovery_id", "public_reference", "public_secret_code",
        "discovered_at", "overall_rank", "game_rank", "first_for_game",
        "privacy_status", "golden_egg_hunt_url", "public_discovery_url",
        "public_player", "next_action", "error",
    ]
    var result: Dictionary = {}
    for key: String in allowed:
        if value.has(key):
            result[key] = value[key]
    return result


func _is_safe_public_reference(value: String) -> bool:
    if value.is_empty() or value.length() > 128:
        return false
    for character: String in value:
        if not "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".contains(character):
            return false
    return true


func _load_pending_operation() -> Dictionary:
    if secure_store == null or not secure_store.has_method("get_secret"):
        return {}
    var encoded := _get_secret(STORE_PENDING_OPERATION)
    if encoded.is_empty():
        return {}
    var value: Variant = JSON.parse_string(encoded)
    return value if value is Dictionary else {}


func _store_json_secret(key: String, value: Dictionary) -> bool:
    return _store_secret(key, JSON.stringify(value))


func _get_secret(key: String) -> String:
    if secure_store == null or not secure_store.has_method("get_secret"):
        return ""
    return str(secure_store.call("get_secret", key))


func _store_secret(key: String, value: String) -> bool:
    if secure_store == null or not secure_store.has_method("set_secret"):
        return false
    return bool(secure_store.call("set_secret", key, value))


func _erase_secret(key: String) -> void:
    if secure_store != null and secure_store.has_method("erase_secret"):
        secure_store.call("erase_secret", key)


func _pending_failure(reason: String) -> Dictionary:
    status = "pending"
    last_safe_error = reason
    return {"success": false, "pending": true, "error": reason}


func _safe_failure(reason: String) -> Dictionary:
    last_safe_error = reason
    return {"success": false, "error": reason}


func _random_base64url(byte_count: int) -> String:
    var bytes := Crypto.new().generate_random_bytes(byte_count)
    return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")


func _uuid_v4() -> String:
    var bytes := Crypto.new().generate_random_bytes(16)
    bytes[6] = (bytes[6] & 0x0f) | 0x40
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    var hex := bytes.hex_encode()
    return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
