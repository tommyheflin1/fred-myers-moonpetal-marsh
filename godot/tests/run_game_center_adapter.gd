extends SceneTree

const Adapter = preload("res://scripts/game_center_adapter.gd")

class FakeGameCenter:
	extends RefCounted

	var authenticated := false
	var authenticate_error := OK
	var events: Array[Dictionary] = []
	var posts: Array[Dictionary] = []

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
	check(not adapter.submit_personal_records(100, 1), "unavailable Game Center cannot submit a score")

	var plugin := FakeGameCenter.new()
	check(adapter.configure(plugin), "an injected complete Game Center interface is accepted")
	check(adapter.state == "ready", "native interface begins in the ready state")
	check(adapter.begin_sign_in(), "Game Center authentication can begin")
	check(adapter.state == "authenticating", "authentication enters an explicit pending state")
	plugin.authenticated = true
	plugin.events.append({"type": "authentication", "result": "ok", "displayName": "Marsh Hero"})
	adapter.poll()
	check(adapter.state == "authenticated", "successful native authentication is observed")
	check(adapter.display_name == "Marsh Hero", "safe platform display name is retained for status only")
	check(adapter.submit_personal_records(12345, 12), "authenticated Game Center accepts both personal records")
	check(plugin.posts.size() == 2, "one completion emits exactly two leaderboard records")
	check(str(plugin.posts[0].category) == Adapter.SCORE_LEADERBOARD_ID, "adventure score uses the permanent Fred leaderboard ID")
	check(int(plugin.posts[0].score) == 12345, "adventure score is preserved")
	check(str(plugin.posts[1].category) == Adapter.LEVEL_LEADERBOARD_ID, "highest level uses the permanent Fred leaderboard ID")
	check(int(plugin.posts[1].score) == 12, "highest level is preserved")
	plugin.posts.clear()
	check(adapter.submit_personal_records(-5, 999), "record submission safely clamps invalid values")
	check(int(plugin.posts[0].score) == 0 and int(plugin.posts[1].score) == 100, "score and campaign level remain bounded")

	var incomplete := RefCounted.new()
	check(not adapter.configure(incomplete), "partial native interfaces fail closed")
	check(adapter.state == "unavailable", "invalid native interface returns to unavailable")
	adapter.queue_free()
	await process_frame
	print("RESULT game_center_passed=%d game_center_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
