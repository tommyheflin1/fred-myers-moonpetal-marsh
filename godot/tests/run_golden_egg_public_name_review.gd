extends SceneTree

# Deterministic fake transport/native boundaries: no Apple or production calls.
const Service = preload("res://scripts/golden_egg_service.gd")

class MemoryStore:
	extends RefCounted
	var values: Dictionary = {}
	func get_secret(key: String) -> String: return str(values.get(key, ""))
	func set_secret(key: String, value: String) -> bool: values[key] = value; return true
	func erase_secret(key: String) -> bool: values.erase(key); return true

class FakeNetwork:
	extends Node
	var operations: Array[String] = []
	var busy := false
	func is_busy() -> bool: return busy
	func start_identity_review(_service: RefCounted) -> bool: operations.append("identity_review"); return true
	func start_retry(_service: RefCounted) -> bool: operations.append("retry"); return true
	func start_privacy(_service: RefCounted, make_public: bool, _name: String) -> bool:
		operations.append("privacy_public" if make_public else "privacy_anonymous")
		return true

class FakeAdapter:
	extends Node
	var starts := 0
	func is_available() -> bool: return true
	func authentication_state() -> String: return "ready"
	func begin_sign_in() -> bool: starts += 1; return true
	func is_authenticated() -> bool: return true

var passed := 0
var failed := 0
var requests: Array[Dictionary] = []
var server_name := "Fictional Marsh Frog"
var server_source := "game_center_reported"
var cancel_during_exchange := false
var active_service: RefCounted
var signature_sequence := 0
var duplicate_privacy := ""
var privacy_http_status := 200

func _init() -> void:
	call_deferred("_run")

func _identity(name: String = "Fictional Marsh Frog", team: String = "fictional-original-team", age_msec: int = 0) -> Dictionary:
	signature_sequence += 1
	return {"ok": true, "verified_signature": true, "display_name": name, "game_center_identity": {
		"team_player_id": team, "game_player_id": "fictional-game-player", "bundle_id": Service.EXPECTED_BUNDLE_ID,
		"public_key_url": "https://static.gc.apple.com/fictional-test-key", "signature": "fictional-proof-%d" % signature_sequence,
		"salt": "fictional-salt", "timestamp": int(Time.get_unix_time_from_system() * 1000.0) - age_msec,
	}}

func _new_service(store: MemoryStore) -> RefCounted:
	var service := Service.new()
	service.configure(_transport, store)
	active_service = service
	return service

func _restore_fixture(service: RefCounted) -> void:
	service.restore_public_snapshot({"status": "accepted", "privacy_status": "PENDING_PRIVACY_CHOICE", "result": {
		"success": true, "discovery_id": "fictional-discovery", "public_reference": "fictional-reference",
		"public_discovery_url": Service.BASE_URL + "/golden-eggs/discovery/fictional-reference",
		"privacy_status": "PENDING_PRIVACY_CHOICE", "overall_rank": 12, "game_rank": 3,
	}})

func _run() -> void:
	var store := MemoryStore.new()
	var service := _new_service(store)
	service.set_verified_game_center_identity(_identity())
	_restore_fixture(service)
	check(service.submit_privacy_choice(true).error == "FRESH_PUBLIC_NAME_REVIEW_REQUIRED" and requests.is_empty(), "cached identity alone cannot publish a name")
	service.set_verified_game_center_identity(_identity("Old Frog", "fictional-original-team", Service.IDENTITY_FRESHNESS_MSEC + 5000))
	check(service.prepare_public_name().error == "FRESH_GAME_CENTER_SIGNATURE_REQUIRED" and requests.is_empty(), "stale proof is rejected before network publication")
	service.set_verified_game_center_identity(_identity("Provider Raw Name"))
	check(bool(service.prepare_public_name().success), "fresh identity uses existing server exchange for a review")
	check(service.public_name_for_review() == server_name, "read-only name is exactly server-confirmed, not cached or client-normalized")
	check(service.privacy_status == "PENDING_PRIVACY_CHOICE" and _public_request_count() == 0, "name review alone never publishes")
	var first_review_key: String = requests.back().headers["Idempotency-Key"]
	check(bool(service.submit_privacy_choice(true).success), "separate explicit consent publishes the reviewed name")
	var consent: Dictionary = requests.back().payload
	check(consent.expected_provider_display_name == server_name and not consent.has("public_display_name") and not consent.has("display_name"), "consent compares the reviewed name and cannot override provider identity")
	var count_before := requests.size()
	check(not bool(service.submit_privacy_choice(true).success) and requests.size() == count_before, "one review cannot silently authorize repeated publication")
	var reopened := _new_service(store)
	check(reopened.has_canonical_discovery() and reopened.privacy_status == "PUBLIC", "server-confirmed discovery and privacy survive reopening")
	check(reopened.public_name_for_review().is_empty() and not bool(reopened.submit_privacy_choice(true).success), "reopened discovery requires a new review rather than saved consent")
	check(bool(reopened.submit_privacy_choice(false).success), "Anonymous revocation needs no name review or fresh Apple proof")
	service = reopened
	server_name = "Fictional Renamed Frog"
	service.set_verified_game_center_identity(_identity("Fictional Renamed Frog"))
	check(bool(service.prepare_public_name().success) and service.public_name_for_review() == server_name, "fresh name changes are visible before new consent")
	check(requests.back().headers["Idempotency-Key"] != first_review_key, "each new name review uses its own identity exchange idempotency key")
	service.clear_public_name_review()
	count_before = requests.size()
	check(not bool(service.submit_privacy_choice(true).success) and requests.size() == count_before, "cancel clears consent readiness with no public request")
	check(service.prepare_public_name().error == "NEW_GAME_CENTER_SIGNATURE_REQUIRED", "cancelled proof cannot be replayed as a fresh review")
	service.set_verified_game_center_identity(_identity())
	cancel_during_exchange = true
	check(service.prepare_public_name().error == "PUBLIC_NAME_REVIEW_CANCELLED", "cancelling during exchange defeats late completion")
	check(service.public_name_for_review().is_empty(), "late identity exchange cannot reopen a cancelled consent")
	service.set_verified_game_center_identity(_identity())
	check(bool(service.prepare_public_name().success), "another deliberate review can recover after cancellation")
	server_name = "Fictional Changed Elsewhere"
	check(not bool(service.submit_privacy_choice(true).success), "server name change between review and consent is rejected")
	check(service.privacy_status == "ANONYMOUS" and service.public_name_for_review().is_empty(), "name race leaves the saved Anonymous choice and requires a new review")
	service.set_verified_game_center_identity(_identity(server_name))
	check(bool(service.prepare_public_name().success) and bool(service.submit_privacy_choice(true).success), "fresh review recovers from name change without a new authentication protocol")
	service.set_verified_game_center_identity(_identity(server_name))
	service.prepare_public_name()
	service._public_name_review["expires_ticks"] = Time.get_ticks_msec() - 1
	check(service.public_name_for_review().is_empty() and not bool(service.submit_privacy_choice(true).success), "expired review cannot grant public consent")
	service.set_verified_game_center_identity(_identity(server_name, "fictional-other-team"))
	count_before = requests.size()
	check(service.prepare_public_name().error == "DISCOVERY_ACCOUNT_MISMATCH" and requests.size() == count_before, "same-name account switch cannot transfer a canonical discovery")
	check(bool(service.submit_privacy_choice(false).success), "account mismatch still permits Anonymous revocation")
	service.set_verified_game_center_identity(_identity())
	server_source = "unverified"
	check(service.prepare_public_name().error == "SERVER_CONFIRMED_NAME_UNAVAILABLE", "missing trusted provider source fails closed")
	server_source = "game_center_reported"
	var offline_store := MemoryStore.new()
	var offline := _new_service(offline_store)
	count_before = requests.size()
	offline.stage_discovery("fictional-offline-integrity-evidence")
	check(requests.size() == count_before and offline.has_pending_discovery(), "offline discovery is saved before any networking")
	offline.set_verified_game_center_identity(_identity())
	check(offline.prepare_public_name().error == "EXPLICIT_IDENTITY_LINK_REQUIRED" and offline.has_pending_discovery(), "review cannot silently attach an unlinked offline discovery")
	check(offline.authorize_pending_identity_link(), "explicit review can authorize the original pending account")
	offline.set_verified_game_center_identity(_identity())
	check(bool(offline.prepare_public_name().success), "pending find reviews identity without registering a discovery")
	check(offline.has_pending_discovery() and not offline.has_canonical_discovery() and not offline.public_name_for_review().is_empty(), "review waits locally for a separate posting confirmation")
	count_before = requests.size()
	offline.keep_discovery_local()
	var local_only := _new_service(offline_store)
	check(local_only.retry_pending_discovery().error == "EXPLICIT_PUBLICATION_CHOICE_REQUIRED" and requests.size() == count_before, "do not post survives restart and refuses a later automatic retry")
	local_only.set_verified_game_center_identity(_identity())
	check(bool(local_only.prepare_public_name().success) and bool(local_only.submit_privacy_choice(true).success), "a later explicit reviewed Public choice can post the retained find")
	check(local_only.privacy_status == "PUBLIC" and not local_only.has_pending_discovery(), "explicit Public registers without Anonymous fallback")
	var mismatch_store := MemoryStore.new()
	var mismatch := _new_service(mismatch_store)
	mismatch.set_verified_game_center_identity(_identity())
	mismatch.stage_discovery("fictional-lost-response-retry-evidence")
	mismatch.choose_pending_publication("ANONYMOUS")
	duplicate_privacy = "PUBLIC"
	privacy_http_status = 503
	check(not bool(mismatch.retry_pending_discovery().get("success", false)), "duplicate Public record plus failed Anonymous PATCH is not reported as consent success")
	check(mismatch.privacy_status == "PUBLIC" and mismatch.has_pending_discovery() and mismatch.status == "pending", "original public record and unsent Anonymous choice remain distinct and durable")
	count_before = requests.size()
	var restarted_mismatch := _new_service(mismatch_store)
	check(restarted_mismatch.has_pending_discovery() and restarted_mismatch.status == "pending" and requests.size() == count_before, "restart retains requested privacy retry without automatic traffic")
	privacy_http_status = 200
	check(bool(restarted_mismatch.submit_privacy_choice(false).get("success", false)) and restarted_mismatch.privacy_status == "ANONYMOUS" and not restarted_mismatch.has_pending_discovery(), "explicit retry acknowledges Anonymous and clears pending without another rank")
	check(restarted_mismatch.public_result.overall_rank == 12 and restarted_mismatch.public_result.game_rank == 3, "privacy retry preserves original server ranks")
	duplicate_privacy = ""
	await _test_ui_flow()
	call_deferred("_finish")

func _finish() -> void:
	active_service = null
	await process_frame
	print("RESULT golden_public_name_review_passed=%d golden_public_name_review_failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_ui_flow() -> void:
	var game = load("res://scripts/main.gd").new()
	root.add_child(game)
	game.audio_enabled = false
	game._sync_music()
	await process_frame
	game.golden_network.queue_free()
	game.game_center.queue_free()
	var network := FakeNetwork.new()
	var adapter := FakeAdapter.new()
	game.add_child(network)
	game.add_child(adapter)
	game.golden_network = network
	game.game_center = adapter
	game.golden_production_network_enabled = true
	var store := MemoryStore.new()
	game.golden_service = _new_service(store)
	game.golden_service.set_verified_game_center_identity(_identity())
	_restore_fixture(game.golden_service)
	game.screen = game.Screen.GOLDEN_EGG
	game._handle_click(game.GOLDEN_EGG_PUBLIC_RECT.get_center())
	check(adapter.starts == 1 and network.operations.is_empty() and game.golden_public_review_requested, "first public button asks for a fresh Game Center proof, not publication")
	game._on_game_center_sign_in_completed(_identity())
	check(network.operations == ["identity_review"], "login completion requests only read-only server review")
	game.golden_service.prepare_public_name()
	game._on_golden_network_operation_completed("identity_review", {"success": true})
	check(network.operations == ["identity_review"] and game.golden_discovery_status == "name_reviewed", "server exchange completion exposes the name and waits for a second tap")
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--capture-public-review"):
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		var capture_dir := ProjectSettings.globalize_path("res://builds/public-name-review")
		DirAccess.make_dir_recursive_absolute(capture_dir)
		check(root.get_texture().get_image().save_png(capture_dir.path_join("name-review.png")) == OK, "real renderer captures read-only reviewed-name consent screen")
	game._handle_click(game.GOLDEN_EGG_PUBLIC_RECT.get_center())
	check(network.operations == ["identity_review", "privacy_public"], "only separate Share this name tap requests public publication")
	game.golden_public_review_requested = true
	game._return_to_level_five()
	game._on_game_center_sign_in_completed(_identity())
	check(network.operations.size() == 2 and not game.golden_public_review_requested, "return to Level 5 cancels pending review before a late login callback")
	check(game.level_number == 5 and game.fred == game._level_start_position() and not game.session.paused, "return retains a clean playable Level 5 start")
	game.screen = game.Screen.GOLDEN_EGG
	game.golden_public_review_requested = true
	game.golden_service.set_verified_game_center_identity(_identity())
	game.golden_service.prepare_public_name()
	network.busy = true
	game._handle_click(game.GOLDEN_EGG_PRIVATE_RECT.get_center())
	check(game.golden_service.public_name_for_review().is_empty() and game.golden_anonymous_requested, "Anonymous cancels reviewed name even during another request")
	network.busy = false
	game._on_golden_network_operation_completed("identity_review", {"success": true})
	check(network.operations.back() == "privacy_anonymous" and network.operations.count("privacy_public") == 1, "late cancelled review queues only Anonymous, never public consent")
	game.golden_privacy = "public"
	game._on_golden_network_operation_completed("retry", {"success": true})
	check(network.operations.count("privacy_public") == 1, "discovery retry cannot auto-publish an earlier local public flag")
	game.golden_service.privacy_status = "PUBLIC"
	game.screen = game.Screen.TITLE
	game.golden_pending_review_available = true
	game._handle_click(game.TITLE_PENDING_EGG_RECT.get_center())
	check(game.screen == game.Screen.TITLE and game.golden_privacy == "public", "public record stays private to storage and cannot reopen from title")
	game.screen = game.Screen.GOLDEN_EGG
	game.golden_public_review_requested = true
	game._on_game_center_sign_in_completed({"ok": false, "error": "game_center_auth_failed"})
	check(game.golden_discovery_status == "name_check_failed" and not game.golden_public_review_requested, "cancelled sign-in gives a visible name-check status without public consent")
	game.golden_service = _new_service(MemoryStore.new())
	game.golden_service.stage_discovery("fictional-late-review-return")
	game.screen = game.Screen.GOLDEN_EGG
	game.golden_public_review_requested = true
	network.busy = true
	game._return_to_level_five()
	network.busy = false
	game._on_golden_network_operation_completed("identity_review", {"success": false})
	check(game.golden_service._load_pending_operation().get("publication_choice") == "LOCAL_ONLY", "return during an identity lookup durably declines posting after its late completion")
	game.queue_free()
	await process_frame

func _public_request_count() -> int:
	var total := 0
	for request: Dictionary in requests:
		if request.method == "PATCH" and request.payload.get("privacy_status", "") == "PUBLIC": total += 1
	return total

func _transport(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
	var payload: Dictionary = JSON.parse_string(body)
	requests.append({"method": method, "url": url, "headers": headers.duplicate(true), "payload": payload})
	if url.ends_with("/player/bootstrap"):
		return {"status": 201, "body": {"success": true, "player_access_token": "fictional-token-for-offline-test"}}
	if url.ends_with("/game-center/identity/exchange"):
		if cancel_during_exchange:
			cancel_during_exchange = false
			active_service.clear_public_name_review()
		return {"status": 201, "body": {"success": true, "discovery_authorization": "fictional-discovery-authorization-0123456789012345", "next_action": "SUBMIT_DISCOVERY", "expires_at": Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 240) + "Z", "provider_display_name": server_name, "provider_display_name_source": server_source}}
	if url.ends_with("/discoveries"):
		if not duplicate_privacy.is_empty(): payload["privacy_status"] = duplicate_privacy
		return {"status": 201, "body": {"success": true, "discovery_id": "fictional-discovery", "public_reference": "fictional-reference", "public_secret_code": "FICTIONAL-EGG", "discovered_at": "2026-09-10T00:00:00Z", "overall_rank": 12, "game_rank": 3, "first_for_game": false, "privacy_status": payload.get("privacy_status", "PENDING_PRIVACY_CHOICE"), "next_action": "VIEW_DISCOVERY", "public_identity_source": "game_center_reported" if payload.get("privacy_status") == "PUBLIC" else "anonymous", "public_player": server_name if payload.get("privacy_status") == "PUBLIC" else "Anonymous", "golden_egg_hunt_url": Service.HUNT_URL, "public_discovery_url": Service.BASE_URL + "/golden-eggs/discovery/fictional-reference", "secure_discovery_url": Service.BASE_URL + "/golden-eggs/discovery/fictional-reference?session=fictional-session", "discovery_session_token": "fictional-session", "discovery_session_expires_at": "2026-09-10T00:15:00Z"}}
	var make_public: bool = payload.get("privacy_status", "") == "PUBLIC"
	if make_public and payload.get("expected_provider_display_name", "") != server_name:
		return {"status": 409, "body": {"success": false, "error": "PUBLIC_NAME_REVIEW_REQUIRED"}}
	return {"status": privacy_http_status, "body": {"success": true, "discovery_id": "fictional-discovery", "public_identity_source": "game_center_reported" if make_public else "anonymous", "privacy_status": "PUBLIC" if make_public else "ANONYMOUS", "public_player": server_name if make_public else "Anonymous"}}

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
