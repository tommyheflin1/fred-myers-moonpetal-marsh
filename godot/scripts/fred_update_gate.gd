class_name FredUpdateGate
extends Node

signal state_changed(state: String)

const Policy := preload("res://addons/mobile_game_core/lifecycle/update_policy_service.gd")
const SignatureVerifier := preload("res://addons/mobile_game_core/lifecycle/update_policy_signature_verifier.gd")
const ENDPOINT := "https://theflinsappvaultllc.com/api/app-updates/policy"
const STORE_URL := "https://apps.apple.com/app/id6803295872"
const BUNDLE := "com.flinsvault.fredmyers"
const MAX_BODY_BYTES := 16384

var state := "not_required"
var required := false
var configured := false
var generation := 0
var valid_until := 0
var issued_at := 0
var service: RefCounted = Policy.new()
var verifier: RefCounted = SignatureVerifier.new()
var request: HTTPRequest

func configure(definition: Dictionary, runtime_name: String = OS.get_name()) -> void:
    # Explicit product capability, independent of discovery-triggered Golden Egg traffic.
    _cancel_request()
    generation += 1
    valid_until = 0
    if definition.get("updates", {}).get("enabled") == false:
        required = false
        configured = false
        _set_state("not_required")
        return
    # Missing/malformed configuration still fails closed for an opted-in iOS app.
    required = OS.get_name().to_lower() == "ios" or runtime_name.to_lower() == "ios"
    configured = false
    if not required:
        _set_state("not_required")
        return
    var updates: Dictionary = definition.get("updates", {})
    var key_path := str(updates.get("public_key_path", ""))
    if str(definition.get("bundle_id", "")) != BUNDLE \
        or str(updates.get("policy_origin", "")) + str(updates.get("policy_path", "")) != ENDPOINT \
        or str(updates.get("app_store_url", "")) != STORE_URL \
        or updates.get("mode") != "mandatory_minimum_build" or updates.get("fail_closed") != true \
        or not key_path.begins_with("res://assets/security/") or not FileAccess.file_exists(key_path):
        _set_state("check_failed")
        return
    configured = service.configure(str(definition.get("marketing_version", "")), int(definition.get("build_number", 0)), STORE_URL, BUNDLE, "ios") \
        and verifier.configure(FileAccess.get_file_as_string(key_path), str(updates.get("trusted_key_id", "")))
    _set_state("checking" if configured else "check_failed")

func blocks_gameplay() -> bool:
    if not required:
        return false
    if state != "current":
        return true
    # The scene may tick before this child: never grant even one expired frame.
    var now := int(Time.get_unix_time_from_system())
    return now >= valid_until or now < issued_at

func begin_check() -> void:
    if not required: return
    generation += 1
    valid_until = 0
    _cancel_request()
    _set_state("checking" if configured else "check_failed")
    if not configured: return
    request = HTTPRequest.new()
    request.timeout = 12.0
    request.body_size_limit = MAX_BODY_BYTES
    request.max_redirects = 0
    add_child(request)
    request.request_completed.connect(_request_completed.bind(generation))
    var error := request.request(ENDPOINT + "?bundle_id=" + BUNDLE.uri_encode() + "&platform=ios", PackedStringArray(["Accept: application/json"]))
    if error != OK:
        _cancel_request()
        _set_state("check_failed")

func _request_completed(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray, request_generation: int) -> void:
    if request_generation != generation: return
    _cancel_request()
    apply_response(result, status, body, request_generation, int(Time.get_unix_time_from_system()))

func apply_response(result: int, status: int, body: PackedByteArray, request_generation: int, now: int) -> void:
    # A canceled request must never unlock a newer foreground check.
    if request_generation != generation or not required: return
    valid_until = 0
    if not configured or result != HTTPRequest.RESULT_SUCCESS or status != 200 or body.size() > MAX_BODY_BYTES:
        _set_state("check_failed")
        return
    var envelope: Variant = _parse_json(body.get_string_from_utf8())
    if not envelope is Dictionary or not envelope.get("policy_payload") is String \
        or not envelope.get("signature") is String or not envelope.get("key_id") is String:
        _set_state("check_failed")
        return
    var raw: String = envelope.policy_payload
    if not verifier.verify(raw, envelope.signature, envelope.key_id):
        _set_state("check_failed")
        return
    var payload: Variant = _parse_json(raw)
    if not payload is Dictionary or payload.get("schema_version") != 1 \
        or payload.get("bundle_id") != BUNDLE or payload.get("platform") != "ios" \
        or not payload.get("policy_id") is String or payload.policy_id.strip_edges().is_empty():
        _set_state("check_failed")
        return
    for field: String in ["minimum_supported_build", "issued_at", "expires_at"]:
        var value: Variant = payload.get(field)
        if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 1.0 or float(value) > 9007199254740991.0:
            _set_state("check_failed")
            return
    if int(payload.expires_at) - int(payload.issued_at) > 900:
        _set_state("check_failed")
        return
    var decision: Dictionary = service.evaluate(payload, true, now)
    if bool(decision.get("allow_play", false)):
        issued_at = int(payload.issued_at)
        valid_until = int(payload.expires_at)
        _set_state("current")
    else:
        _set_state("update_required" if bool(decision.get("must_update", false)) else "check_failed")

func _process(_delta: float) -> void:
    if required and state == "current":
        var now := int(Time.get_unix_time_from_system())
        if now >= valid_until or now < issued_at: begin_check()

func _parse_json(raw: String) -> Variant:
    # Invalid service data is a normal fail-closed result, not an engine error.
    var json := JSON.new()
    if json.parse(raw) != OK:
        return null
    return json.data

func open_store() -> void:
    if required: OS.shell_open(STORE_URL)

func _cancel_request() -> void:
    if is_instance_valid(request):
        request.cancel_request()
        request.queue_free()
    request = null

func _set_state(value: String) -> void:
    state = value
    state_changed.emit(state)
