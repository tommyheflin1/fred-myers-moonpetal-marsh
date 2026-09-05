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

func _init() -> void:
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
			"timestamp": 1700000000000,
		},
	}), "Fred stores only a complete signed Game Center identity")
	var discovery: Dictionary = service.submit_discovery("fred-build8-level5-proof-0123456789abcdef")
	check(bool(discovery.get("success", false)), "Fred registers the Golden Egg with the website service")
	check(str(discovery.get("public_reference", "")) == "fred-public-0008", "server public reference is retained")
	check(int(discovery.get("overall_rank", 0)) == 8 and int(discovery.get("game_rank", 0)) == 1, "server-owned ranks are retained")
	check(service.public_discovery_url() == "https://theflinsappvaultllc.com/golden-eggs/discovery/fred-public-0008", "website discovery URL stays on the approved origin")
	var privacy: Dictionary = service.submit_privacy_choice(true)
	check(bool(privacy.get("success", false)) and str(service.privacy_status) == "PUBLIC", "public marsh name choice reaches the website")
	check(str(service.public_result.get("public_player", "")) == "Marsh Player", "website-confirmed display name is retained")
	check(requests.size() == 4, "bootstrap, identity exchange, discovery and privacy use exactly four bounded requests")
	check(str(requests[0].headers.get("X-Golden-Egg-Protocol", "")) == "bearer-v2", "Fred uses the same client-safe bearer protocol as Snake Reactor")
	check(not requests[0].headers.has("X-Golden-Egg-Signature"), "Fred ships no shared signing secret")
	check(str(requests[1].headers.get("X-Golden-Egg-Protocol", "")) == "game-center-identity-v1", "identity exchange uses the signed Game Center protocol")
	var discovery_body: Dictionary = JSON.parse_string(str(requests[2].body))
	check(str(discovery_body.get("egg_id", "")) == "moonpetal-golden-egg", "Fred sends its own Golden Egg identity")
	check(str(discovery_body.get("build_version", "")) == "10", "website registration is bound to Build 10")
	check(str(discovery_body.get("discovery_authorization", "")) == "fictional-discovery-authorization", "discovery consumes the verified identity authorization")
	print("RESULT golden_egg_website_passed=%d golden_egg_website_failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _transport(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
	requests.append({"method": method, "url": url, "headers": headers.duplicate(true), "body": body})
	if url.ends_with("/player/bootstrap"):
		return {"status": 201, "body": {"success": true, "player_id": "fred-player-0008", "player_access_token": "abcdefghijklmnopqrstuvwxyzABCDEFGH1234567890_-", "token_type": "Bearer"}}
	if url.ends_with("/game-center/identity/exchange"):
		return {"status": 201, "body": {"success": true, "discovery_authorization": "fictional-discovery-authorization"}}
	if url.ends_with("/discoveries"):
		return {"status": 201, "body": {"success": true, "discovery_id": "fred-discovery-0008", "public_reference": "fred-public-0008", "public_secret_code": "FM-TEST-EGG8", "discovered_at": "2026-09-05T00:00:00.000Z", "overall_rank": 8, "game_rank": 1, "first_for_game": true, "privacy_status": "PENDING_PRIVACY_CHOICE", "golden_egg_hunt_url": "https://theflinsappvaultllc.com/golden-eggs", "public_discovery_url": "https://theflinsappvaultllc.com/golden-eggs/discovery/fred-public-0008", "secure_discovery_url": "https://theflinsappvaultllc.com/golden-eggs/discovery/fred-public-0008?session=fictional-session-token", "discovery_session_token": "fictional-session-token", "discovery_session_expires_at": "2026-09-05T00:15:00.000Z"}}
	return {"status": 200, "body": {"success": true, "privacy_status": "PUBLIC", "public_player": "Marsh Player"}}

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)
