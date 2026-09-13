class_name UpdatePolicyService
extends RefCounted

var current_version := "0.0.0"
var current_build := 1
var app_store_url := ""
var bundle_id := ""
var platform := ""

func configure(version: String, build: int, configured_app_store_url: String, configured_bundle_id: String, configured_platform: String) -> bool:
    if version.strip_edges().is_empty() or build < 1 or not configured_app_store_url.begins_with("https://apps.apple.com/"):
        return false
    if configured_bundle_id.strip_edges().is_empty() or configured_platform.strip_edges().to_lower() != "ios":
        return false
    current_version = version.strip_edges()
    current_build = build
    app_store_url = configured_app_store_url
    bundle_id = configured_bundle_id.strip_edges()
    platform = configured_platform.strip_edges().to_lower()
    return true

func evaluate(update_response: Dictionary, signature_verified: bool, now_unix: int) -> Dictionary:
    if not signature_verified:
        return {"allow_play": false, "must_update": false, "reason": "policy_unverified", "app_store_url": app_store_url}
    if str(update_response.get("bundle_id", "")) != bundle_id or str(update_response.get("platform", "")).to_lower() != platform:
        return {"allow_play": false, "must_update": false, "reason": "policy_wrong_app", "app_store_url": app_store_url}
    if str(update_response.get("policy_id", "")).strip_edges().is_empty():
        return {"allow_play": false, "must_update": false, "reason": "policy_invalid", "app_store_url": app_store_url}
    var issued_at := int(update_response.get("issued_at", 0))
    var expires_at := int(update_response.get("expires_at", 0))
    if now_unix < 1 or issued_at < 1 or expires_at <= issued_at or issued_at > now_unix or expires_at <= now_unix:
        return {"allow_play": false, "must_update": false, "reason": "policy_expired_or_not_yet_valid", "app_store_url": app_store_url}
    var minimum_build := int(update_response.get("minimum_supported_build", 0))
    if minimum_build < 1:
        return {"allow_play": false, "must_update": false, "reason": "policy_invalid", "app_store_url": app_store_url}
    var must_update := current_build < minimum_build
    return {
        "allow_play": not must_update,
        "must_update": must_update,
        "minimum_supported_build": minimum_build,
        "notice": "Update required to continue." if must_update else "",
        "reason": "below_minimum_build" if must_update else "supported",
        "app_store_url": app_store_url,
    }
