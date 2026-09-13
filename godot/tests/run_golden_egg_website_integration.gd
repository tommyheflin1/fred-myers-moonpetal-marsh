extends SceneTree

const Service = preload("res://scripts/golden_egg_service.gd")

class MemoryStore:
	extends RefCounted
	var values: Dictionary = {}
	func get_secret(key: String) -> String: return str(values.get(key, ""))
	func set_secret(key: String, value: String) -> bool: values[key] = value; return true
	func erase_secret(key: String) -> bool: values.erase(key); return true

var passed := 0
var failed := 0
var requests: Array[Dictionary] = []
var discovery_http_status := 201

func _init() -> void:
	var release_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/game.json"))
	check(Service.BUILD_VERSION == str(int(release_config.build_number)), "website build identity matches the active release configuration")
	check(Service.APP_VERSION == str(release_config.marketing_version), "website marketing version matches the active release configuration")
	var service := Service.new()
	var store := MemoryStore.new()
	check(service.configure(_transport, store), "Fred production service accepts the bounded HTTPS transport and private store")
	check(service.set_verified_game_center_identity({
		"verified_signature": true,
		"display_name": "Marsh Player",
		"game_center_identity": {
			"team_player_id": "fictional-team-player",
			"game_player_id": "fictional-game-player",
			"bundle_id": "com.flinsvault.fredmyers",
			"public_key_url": "https://static.gc.apple.com/public-key",
			"signature": "fictional-signature",
			"salt": "fictional-salt",
			"timestamp": int(Time.get_unix_time_from_system() * 1000.0),
		},
	}), "Fred stores only a complete signed Game Center identity")
	service.stage_discovery("fred-build8-level5-proof-0123456789abcdef")
	service.choose_pending_publication("ANONYMOUS")
	var discovery: Dictionary = service.retry_pending_discovery()
	check(bool(discovery.get("success", false)), "Fred registers the Golden Egg with the website service")
	check(str(discovery.get("public_reference", "")) == "fred-public-0008", "server public reference is retained")
	check(int(discovery.get("overall_rank", 0)) == 8 and int(discovery.get("game_rank", 0)) == 1, "server-owned ranks are retained")
	check(service.public_discovery_url() == "https://theflinsappvaultllc.com/golden-eggs/discovery/fred-public-0008", "website discovery URL stays on the approved origin")
	var refreshed_identity: Dictionary = JSON.parse_string(str(store.values[Service.STORE_GAME_CENTER_IDENTITY]))
	refreshed_identity["signature"] = "fictional-fresh-review-signature"
	service.set_verified_game_center_identity({"verified_signature": true, "display_name": "Marsh Player", "game_center_identity": refreshed_identity})
	check(bool(service.prepare_public_name().get("success", false)) and service.public_name_for_review() == "Marsh Player", "fresh identity exchange provides the read-only name before explicit public consent")
	var privacy: Dictionary = service.submit_privacy_choice(true)
	check(bool(privacy.get("success", false)) and str(service.privacy_status) == "PUBLIC", "public marsh name choice reaches the website")
	check(str(service.public_result.get("public_player", "")) == "Marsh Player", "website-confirmed display name is retained")
	check(requests.size() == 5, "registration, fresh name review and explicit privacy choice use five bounded requests")
	var public_body: Dictionary = JSON.parse_string(str(requests[4].body))
	check(public_body.get("expected_provider_display_name", "") == "Marsh Player" and not public_body.has("public_display_name"), "public consent compares the reviewed name without sending a name override")
	check(str(requests[0].headers.get("X-Golden-Egg-Protocol", "")) == "bearer-v2", "Fred uses the same client-safe bearer protocol as Snake Reactor")
	check(not requests[0].headers.has("X-Golden-Egg-Signature"), "Fred ships no shared signing secret")
	check(str(requests[1].headers.get("X-Golden-Egg-Protocol", "")) == "game-center-identity-v1", "identity exchange uses the signed Game Center protocol")
	var discovery_body: Dictionary = JSON.parse_string(str(requests[2].body))
	check(str(discovery_body.get("egg_id", "")) == "moonpetal-golden-egg", "Fred sends its own Golden Egg identity")
	check(str(discovery_body.get("build_version", "")) == str(int(release_config.build_number)), "website registration is bound to the active build")
	check(str(discovery_body.get("discovery_authorization", "")) == "fictional-discovery-authorization-0123456789012345", "discovery consumes the verified identity authorization")
	var resumed := Service.new()
	var request_count := requests.size()
	resumed.configure(_transport, store)
	check(resumed.has_canonical_discovery(), "accepted discovery survives app restart")
	check(resumed.public_discovery_url() == service.public_discovery_url(), "restart restores the same server-owned discovery link")
	check(resumed.privacy_status == "PUBLIC", "restart restores the last confirmed privacy choice")
	check(requests.size() == request_count, "restoring discovery never publishes or changes consent automatically")
	check(bool(resumed.submit_privacy_choice(false).get("success", false)) and resumed.privacy_status == "ANONYMOUS", "player can revoke public display after restart")
	var resumed_again := Service.new()
	resumed_again.configure(_transport, store)
	check(resumed_again.privacy_status == "ANONYMOUS", "Anonymous choice survives another restart")
	var offline_store := MemoryStore.new()
	var offline_service := Service.new()
	offline_service.configure(_transport, offline_store)
	check(bool(offline_service.stage_discovery("fictional-offline-evidence-only").get("success", false)), "offline discovery is staged without a network request")
	var identity: Dictionary = JSON.parse_string(str(store.values[Service.STORE_GAME_CENTER_IDENTITY]))
	check(offline_service.set_verified_game_center_identity({"verified_signature": true, "display_name": "Marsh Player", "game_center_identity": identity}), "returning identity can be refreshed without automatically linking a find")
	check(offline_service.retry_pending_discovery().error == "EXPLICIT_PUBLICATION_CHOICE_REQUIRED", "no-choice cannot be retried as implicit Anonymous consent")
	offline_service.choose_pending_publication("ANONYMOUS")
	check(str(offline_service.retry_pending_discovery().get("error", "")) == "EXPLICIT_IDENTITY_LINK_REQUIRED", "offline find cannot silently bind during sign-in")
	check(offline_service.has_pending_discovery(), "unlinked offline find remains recoverable")
	check(offline_service.authorize_pending_identity_link(), "explicit player action can bind the pending find to its current account")
	identity["team_player_id"] = "fictional-different-team"
	offline_service.set_verified_game_center_identity({"verified_signature": true, "display_name": "Other Frog", "game_center_identity": identity})
	check(not offline_service.authorize_pending_identity_link(), "account switch cannot transfer a staged find")
	check(str(offline_service.retry_pending_discovery().get("error", "")) == "DISCOVERY_ACCOUNT_MISMATCH", "retry rejects the wrong signed account context")
	check(offline_service.has_pending_discovery(), "account mismatch preserves the original discovery")
	var misleading := Service.new()
	misleading.configure(_transport, MemoryStore.new())
	identity["team_player_id"] = "fictional-http-error-team"
	misleading.set_verified_game_center_identity({"verified_signature": true, "display_name": "Marsh Player", "game_center_identity": identity})
	misleading.stage_discovery("fictional-http-error-evidence")
	misleading.choose_pending_publication("ANONYMOUS")
	discovery_http_status = 503
	check(not bool(misleading.retry_pending_discovery().get("success", false)) and not misleading.has_canonical_discovery() and misleading.has_pending_discovery(), "HTTP failure cannot become accepted even with a success-looking JSON body")
	discovery_http_status = 201
	print("RESULT golden_egg_website_passed=%d golden_egg_website_failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _transport(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
	requests.append({"method": method, "url": url, "headers": headers.duplicate(true), "body": body})
	if url.ends_with("/player/bootstrap"):
		return {"status": 201, "body": {"success": true, "player_id": "fred-player-0008", "player_access_token": "abcdefghijklmnopqrstuvwxyzABCDEFGH1234567890_-", "token_type": "Bearer"}}
	if url.ends_with("/game-center/identity/exchange"):
		return {"status": 201, "body": {"success": true, "discovery_authorization": "fictional-discovery-authorization-0123456789012345", "next_action": "SUBMIT_DISCOVERY", "expires_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 240) + "Z", "provider_display_name": "Marsh Player", "provider_display_name_source": "game_center_reported"}}
	if url.ends_with("/discoveries"):
		return {"status": discovery_http_status, "body": {"success": true, "discovery_id": "fred-discovery-0008", "public_reference": "fred-public-0008", "public_secret_code": "FM-TEST-EGG8", "discovered_at": "2026-09-05T00:00:00.000Z", "overall_rank": 8, "game_rank": 1, "first_for_game": true, "privacy_status": "ANONYMOUS", "public_player": "Anonymous", "public_identity_source": "anonymous", "next_action": "VIEW_DISCOVERY", "golden_egg_hunt_url": "https://theflinsappvaultllc.com/golden-eggs", "public_discovery_url": "https://theflinsappvaultllc.com/golden-eggs/discovery/fred-public-0008", "secure_discovery_url": "https://theflinsappvaultllc.com/golden-eggs/discovery/fred-public-0008?session=fictional-session-token", "discovery_session_token": "fictional-session-token", "discovery_session_expires_at": "2026-09-05T00:15:00.000Z"}}
	var choice: Dictionary = JSON.parse_string(body)
	var is_public := str(choice.get("privacy_status", "")) == "PUBLIC"
	return {"status": 200, "body": {"success": true, "discovery_id": "fred-discovery-0008", "public_identity_source": "game_center_reported" if is_public else "anonymous", "privacy_status": "PUBLIC" if is_public else "ANONYMOUS", "public_player": "Marsh Player" if is_public else "Anonymous"}}

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)
