class_name FredAppleGameScoring
extends RefCounted

const CONTRACT_VERSION := "1.0.0"
const LOCAL_LEADERBOARD_KEY := "fred_marsh_adventure_progress"
const MAX_PENDING_EVENTS := 100

var platform_name := OS.get_name()
var provider_identifier := ""
var native_bridge_available := false
var pending_events: Array[Dictionary] = []

func configure(platform: String, game_center_id: String = "", bridge_available: bool = false) -> void:
	platform_name = platform
	provider_identifier = game_center_id.strip_edges()
	native_bridge_available = bridge_available

func record_level_completion(level: int, bugs: int, lives: int, coins: int) -> Dictionary:
	var safe_level := clampi(level, 1, 100)
	var safe_bugs := clampi(bugs, 0, 3)
	var safe_lives := clampi(lives, 0, AdventureSession.MAX_LIVES)
	var safe_coins := clampi(coins, 0, FredFrogCustomization.MAX_COINS)
	var score := safe_level * 1000 + safe_bugs * 100 + safe_lives * 25 + mini(999, safe_coins)
	var event := {
		"contract_version": CONTRACT_VERSION,
		"event_id": "level_%03d_score_%07d" % [safe_level, score],
		"leaderboard_key": LOCAL_LEADERBOARD_KEY,
		"level": safe_level,
		"score": score,
		"verification": "local_candidate",
	}
	if pending_events.is_empty() or str(pending_events.back().event_id) != str(event.event_id):
		pending_events.append(event)
		if pending_events.size() > MAX_PENDING_EVENTS:
			pending_events.pop_front()
	return {
		"ok": true,
		"status": submission_status(),
		"event": event.duplicate(true),
	}

func submission_status() -> String:
	if platform_name != "iOS":
		return "LOCAL_ONLY_PLATFORM_ADAPTER_READY"
	if provider_identifier.is_empty() or not native_bridge_available:
		return "APPLE_CONFIGURATION_REQUIRED"
	return "READY_FOR_NATIVE_GAME_CENTER_SUBMISSION"

func can_submit_to_game_center() -> bool:
	return submission_status() == "READY_FOR_NATIVE_GAME_CENTER_SUBMISSION"

func engine_contract() -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"platform_neutral_key": LOCAL_LEADERBOARD_KEY,
		"provider": "apple_game_center",
		"server_verification_required": true,
		"offline_queue_bounded": MAX_PENDING_EVENTS,
		"status": submission_status(),
	}
