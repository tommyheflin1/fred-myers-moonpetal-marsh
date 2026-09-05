extends SceneTree

const Adapter = preload("res://scripts/game_center_adapter.gd")

class FakeGameCenter:
	extends RefCounted

	var authenticated := false
	var authenticate_error := OK
	var post_error := OK
	var events: Array[Dictionary] = []
	var posts: Array[Dictionary] = []
	var presented: Array[Dictionary] = []
	var identity_signature_requests := 0
	var presentation_error := OK

	func authenticate() -> int:
		return authenticate_error

	func is_authenticated() -> bool:
		return authenticated

	func get_pending_event_count() -> int:
		return events.size()

	func pop_pending_event() -> Dictionary:
		return events.pop_front()

	func post_score(payload: Dictionary) -> int:
		posts.append(payload.duplicate(true))
		return post_error

	func show_game_center(payload: Dictionary) -> int:
		presented.append(payload.duplicate(true))
		return presentation_error

	func request_identity_verification_signature() -> int:
		identity_signature_requests += 1
		return OK


var passed := 0
var failed := 0


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var adapter := Adapter.new()
	root.add_child(adapter)
	check(not adapter.configure(), "desktop configuration fails closed without a native singleton")
	check(not adapter.begin_sign_in(), "unavailable Game Center cannot start authentication")
	check(not adapter.submit_personal_records(100, 1), "unavailable Game Center cannot queue a score")

	var plugin := FakeGameCenter.new()
	check(adapter.configure(plugin), "an injected complete Game Center interface is accepted")
	check(adapter.state == "ready", "native interface begins in the ready state")
	check(adapter.submit_personal_records(12000, 12), "records queue safely before authentication")
	check(adapter.pending_score_count() == 2 and plugin.posts.is_empty(), "unauthenticated records wait without false delivery")
	check(adapter.begin_sign_in(), "Game Center authentication can begin")
	check(adapter.state == "authenticating", "authentication enters an explicit pending state")
	plugin.events.append({"type": "authentication", "result": "error", "error_code": 6})
	adapter.poll()
	check(adapter.authentication_state() == "ready", "failed native authentication returns to a retryable ready state")
	check(adapter.can_retry_sign_in(), "a failed Apple sign-in exposes a safe retry path")
	check(adapter.last_auth_error == "game_center_auth_failed" and adapter.last_auth_error_code == 6, "authentication diagnostic retains only bounded error metadata")
	check(adapter.begin_sign_in(), "Game Center authentication can be retried without relaunching the app")
	plugin.authenticated = true
	plugin.events.append({"type": "authentication", "result": "ok", "displayName": "Marsh Hero", "team_player_id": "fictional-team-player", "game_player_id": "fictional-game-player"})
	adapter.poll()
	check(adapter.state == "awaiting_signature" and plugin.identity_signature_requests == 1, "successful authentication requests one signed Game Center identity")
	plugin.events.append({
		"type": "identity_verification_signature",
		"result": "ok",
		"team_player_id": "fictional-team-player",
		"game_player_id": "fictional-game-player",
		"public_key_url": "https://static.gc.apple.com/public-key",
		"signature": "fictional-signature",
		"salt": "fictional-salt",
		"timestamp": 1700000000000,
	})
	adapter.poll()
	check(adapter.state == "authenticated", "successful native authentication is observed")
	check(adapter.display_name == "Marsh Hero", "safe platform display name is retained for status only")
	check(plugin.posts.size() == 1, "successful authentication starts exactly one score request")
	check(str(plugin.posts[0].category) == Adapter.SCORE_LEADERBOARD_ID, "adventure score uses the permanent Fred leaderboard ID")
	check(int(plugin.posts[0].score) == 12000, "adventure score is preserved")

	var completions: Array[Dictionary] = []
	adapter.score_submission_completed.connect(func(result: Dictionary) -> void: completions.append(result.duplicate(true)))
	plugin.events.append({"type": "post_score", "result": "ok"})
	adapter.poll()
	check(plugin.posts.size() == 2, "canonical generic score acknowledgement advances to the level record")
	check(str(plugin.posts[1].category) == Adapter.LEVEL_LEADERBOARD_ID, "highest level uses the permanent Fred leaderboard ID")
	check(int(plugin.posts[1].score) == 12, "highest level is preserved")
	plugin.events.append({"type": "post_score", "result": "ok", "category": Adapter.LEVEL_LEADERBOARD_ID, "score": 12})
	adapter.poll()
	check(completions.size() == 2 and bool(completions[0].ok) and bool(completions[1].ok), "both native acknowledgements are observed")
	check(adapter.pending_score_count() == 0, "acknowledged personal records leave no false pending state")

	check(adapter.submit_personal_records(-5, 999), "record submission safely clamps invalid values")
	check(int(plugin.posts[2].score) == 0, "negative adventure scores clamp to zero")
	plugin.events.append({"type": "post_score", "result": "ok", "category": Adapter.SCORE_LEADERBOARD_ID, "score": 0})
	adapter.poll()
	check(int(plugin.posts[3].score) == 100, "campaign level clamps to 100")
	plugin.events.append({"type": "post_score", "result": "ok", "category": Adapter.LEVEL_LEADERBOARD_ID, "score": 99})
	adapter.poll()
	check(adapter.pending_score_count() == 1, "mismatched native acknowledgement cannot complete the current record")
	plugin.events.append({"type": "post_score", "result": "ok", "category": Adapter.LEVEL_LEADERBOARD_ID, "score": 100})
	adapter.poll()

	check(adapter.show_leaderboards(), "authenticated player can open the native leaderboard")
	check(
		plugin.presented.size() == 1
		and str(plugin.presented[0].get("view", "")) == "leaderboards"
		and str(plugin.presented[0].get("leaderboard_name", "")) == Adapter.SCORE_LEADERBOARD_ID,
		"native presentation targets Fred's adventure leaderboard"
	)
	check(not adapter.show_leaderboards() and plugin.presented.size() == 1, "repeated dashboard tap cannot present a second native controller")
	adapter.notify_application_paused()
	check(adapter.dashboard_state == "presented", "native dashboard pause marks the presentation active")
	adapter.notify_application_resumed()
	check(adapter.dashboard_state == "cooldown" and not adapter.show_leaderboards(), "foreground return blocks immediate dashboard re-entry")
	adapter._process(Adapter.DASHBOARD_REENTRY_GUARD_SECONDS + 0.01)
	check(adapter.dashboard_state == "idle" and adapter.show_leaderboards() and plugin.presented.size() == 2, "dashboard becomes safely reusable after the bounded return guard")
	adapter.notify_application_paused()
	adapter.notify_application_resumed()
	adapter._process(Adapter.DASHBOARD_REENTRY_GUARD_SECONDS + 0.01)
	plugin.presentation_error = ERR_UNAVAILABLE
	check(not adapter.show_leaderboards(), "native dashboard presentation failure is reported instead of masquerading as open")
	plugin.presentation_error = OK
	var diagnostic := adapter.diagnostic_snapshot()
	check(bool(diagnostic.available) and bool(diagnostic.authenticated), "diagnostic snapshot reports the authenticated provider boundary")
	check(not "Marsh Hero" in JSON.stringify(diagnostic), "diagnostic snapshot excludes the player's Game Center display name")

	plugin.post_error = ERR_UNAVAILABLE
	check(adapter.submit_personal_records(15000, 15), "synchronous native score failure remains queued")
	check(not completions.back().ok and bool(completions.back().retry_pending), "native failure is reported as retry pending")
	check(adapter.pending_score_count() == 2, "failed score request does not silently disappear")

	var incomplete := RefCounted.new()
	check(not adapter.configure(incomplete), "partial native interfaces fail closed")
	check(adapter.state == "unavailable", "invalid native interface returns to unavailable")
	check(adapter.pending_score_count() == 0, "reconfiguration clears transient score state")
	adapter.queue_free()
	await process_frame
	print("RESULT game_center_passed=%d game_center_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
