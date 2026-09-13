class_name GoldenEggPublicationContract
extends RefCounted

# Pure wire adapter: never authenticates, bootstraps, schedules, or sends HTTP.
const WebContract := preload("res://addons/mobile_game_core/online/golden_egg_web_contract.gd")
const CONTRACT := "golden-egg-publication-v2"
var _web := WebContract.new()
var _configured := false

func configure(game_id: String, egg_id: String) -> bool:
    _configured = _web.configure(game_id, egg_id)
    return _configured

func discovery_body(discovery: Dictionary, choice: String, exchange: Dictionary, reviewed_name: String, now_unix: int) -> Dictionary:
    if not _configured or choice not in ["PUBLIC", "ANONYMOUS"] or not _valid_exchange(exchange, now_unix):
        return {}
    if discovery.get("egg_id") != _web.egg_id:
        return {}
    for field: String in ["egg_version", "app_version", "build_version"]:
        if not discovery.get(field) is String or not _token(discovery[field], 80 if field == "build_version" else 40):
            return {}
    var evidence: Variant = discovery.get("verification_evidence")
    if not evidence is String or evidence.length() < 16 or evidence.length() > 2048:
        return {}
    if choice == "PUBLIC" and (reviewed_name.is_empty() or reviewed_name != exchange.get("provider_display_name")):
        return {}
    var body := {"egg_id":_web.egg_id, "egg_version":discovery.egg_version,
        "app_version":discovery.app_version, "build_version":discovery.build_version,
        "verification_evidence":evidence, "discovery_authorization":exchange.discovery_authorization,
        "consent_contract":CONTRACT, "privacy_status":choice}
    if choice == "PUBLIC":
        body["expected_provider_display_name"] = reviewed_name
    return body

func privacy_body(choice: String, exchange: Dictionary, reviewed_name: String, now_unix: int) -> Dictionary:
    if not _configured or choice not in ["PUBLIC", "ANONYMOUS"]:
        return {}
    var body := {"consent_contract":CONTRACT, "privacy_status":choice}
    if choice == "PUBLIC":
        if not _valid_exchange(exchange, now_unix) or reviewed_name.is_empty() or reviewed_name != exchange.get("provider_display_name"):
            return {}
        body["expected_provider_display_name"] = reviewed_name
    return body

func accepts_discovery(result: Dictionary, choice: String, reviewed_name: String) -> bool:
    if not _configured or choice not in ["PUBLIC", "ANONYMOUS"] or result.get("success") != true or not _web.validate_discovery_response(result):
        return false
    if result.get("privacy_status") != choice or result.get("next_action") != "VIEW_DISCOVERY" or not result.get("first_for_game") is bool:
        return false
    for field: String in ["overall_rank", "game_rank"]:
        var value: Variant = result.get(field)
        if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 1:
            return false
    if choice == "ANONYMOUS":
        return result.get("public_identity_source") == "anonymous" and result.get("public_player") == "Anonymous"
    return not reviewed_name.is_empty() and result.get("public_identity_source") == "game_center_reported" and result.get("public_player") == reviewed_name

func public_result(result: Dictionary, choice: String, reviewed_name: String) -> Dictionary:
    return _web.public_snapshot(result) if accepts_discovery(result, choice, reviewed_name) else {}

func _valid_exchange(exchange: Dictionary, now_unix: int) -> bool:
    if exchange.get("success") != true or exchange.get("next_action") != "SUBMIT_DISCOVERY" or exchange.get("provider_display_name_source") != "game_center_reported" or now_unix < 1:
        return false
    var token: Variant = exchange.get("discovery_authorization")
    if not token is String or token.length() < 40 or not _token(token, 128) or "." in token:
        return false
    var expiry: Variant = exchange.get("expires_at")
    if not expiry is String or not expiry.ends_with("Z"):
        return false
    var expires_at := Time.get_unix_time_from_datetime_string(expiry.trim_suffix("Z"))
    return expires_at > now_unix and expires_at <= now_unix + 300

func _token(value: String, maximum: int) -> bool:
    if value.is_empty() or value.length() > maximum:
        return false
    for character: String in value:
        if not (character >= "a" and character <= "z") and not (character >= "A" and character <= "Z") and not (character >= "0" and character <= "9") and character not in ["-", "_", "."]:
            return false
    return true
