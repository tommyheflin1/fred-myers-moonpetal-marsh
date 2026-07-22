class_name IdentityFlowService
extends RefCounted
const PLATFORM_PROVIDERS: Array[String] = ["apple_game_center", "google_play_games"]
var transport: Callable
var identity: RefCounted
func configure(request_transport: Callable, identity_service: RefCounted) -> bool:
    if not request_transport.is_valid() or identity_service == null or not identity_service.has_method("authenticate"): return false
    transport = request_transport
    identity = identity_service
    return true
func authenticate_anonymous() -> Dictionary: return _accept_identity("anonymous", _response(transport.call("authenticate_anonymous", {})))
func authenticate_platform(provider: String, platform_sign_in: Callable) -> Dictionary:
    if provider not in PLATFORM_PROVIDERS or not platform_sign_in.is_valid(): return {"ok": false, "error": "unsupported_provider"}
    var platform_response: Variant = platform_sign_in.call()
    if not platform_response is Dictionary or not bool(platform_response.get("ok", false)) or str(platform_response.get("identity_token", "")).is_empty(): return {"ok": false, "error": "platform_auth_failed"}
    return _accept_identity(provider, _response(transport.call("exchange_platform_identity", {"provider": provider, "identity_token": str(platform_response.identity_token)})))
func link_platform(provider: String, platform_sign_in: Callable) -> Dictionary:
    if identity == null or not identity.is_online_identity() or provider not in PLATFORM_PROVIDERS or not platform_sign_in.is_valid(): return {"ok": false, "error": "link_unavailable"}
    var platform_response: Variant = platform_sign_in.call()
    if not platform_response is Dictionary or not bool(platform_response.get("ok", false)) or str(platform_response.get("identity_token", "")).is_empty(): return {"ok": false, "error": "platform_auth_failed"}
    var response := _response(transport.call("link_platform_identity", {"provider": provider, "identity_token": str(platform_response.identity_token)}))
    if bool(response.get("ok", false)): identity.link_provider(provider)
    return response
func _accept_identity(provider: String, response: Dictionary) -> Dictionary:
    if not bool(response.get("ok", false)) or str(response.get("account_id", "")).is_empty(): return response
    if not identity.authenticate(provider, str(response.account_id)): return {"ok": false, "error": "identity_rejected"}
    return {"ok": true, "provider": provider}
func _response(value: Variant) -> Dictionary: return value if value is Dictionary else {"ok": false, "error": "invalid_response"}
