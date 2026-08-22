class_name FredGameCenterAdapter
extends Node

signal sign_in_completed(result: Dictionary)
signal score_submission_completed(result: Dictionary)

const SIGN_IN_TIMEOUT_SECONDS := 30.0
const SCORE_SUBMISSION_TIMEOUT_SECONDS := 20.0
const SCORE_RETRY_DELAY_SECONDS := 2.0
const MAX_SCORE_RETRIES := 2
const MAX_PENDING_RECORDS := 4
const DASHBOARD_REENTRY_GUARD_SECONDS := 1.25
const DASHBOARD_FAILSAFE_SECONDS := 4.0
const SCORE_LEADERBOARD_ID := "com.flinsvault.fredmyers.adventure_score"
const LEVEL_LEADERBOARD_ID := "com.flinsvault.fredmyers.highest_level"

var plugin: Object
var state := "unavailable"
var elapsed_seconds := 0.0
var display_name := ""
var pending_records: Array[Dictionary] = []
var in_flight_record: Dictionary = {}
var submission_elapsed_seconds := 0.0
var retry_delay_seconds := 0.0
var last_auth_error := ""
var last_auth_error_code := 0
var dashboard_state := "idle"
var dashboard_elapsed_seconds := 0.0


func configure(plugin_override: Object = null) -> bool:
	_reset_transient_state()
	plugin = plugin_override
	if plugin == null and OS.get_name() == "iOS" and Engine.has_singleton("GameCenter"):
		plugin = Engine.get_singleton("GameCenter")
	if not _has_required_interface(plugin):
		plugin = null
		state = "unavailable"
		set_process(false)
		return false
	state = "ready"
	set_process(true)
	return true


func is_available() -> bool:
	return plugin != null and state != "unavailable"


func is_authenticated() -> bool:
	return is_available() and bool(plugin.call("is_authenticated"))


func authentication_state() -> String:
	return state


func can_retry_sign_in() -> bool:
	return is_available() and state == "ready" and not is_authenticated()


func diagnostic_snapshot() -> Dictionary:
	return {
		"available": is_available(),
		"authenticated": is_authenticated(),
		"state": state,
		"last_auth_error": last_auth_error,
		"last_auth_error_code": last_auth_error_code,
		"pending_score_count": pending_score_count(),
		"dashboard_state": dashboard_state,
	}


func begin_sign_in() -> bool:
	if not is_available() or state == "authenticating":
		return false
	if is_authenticated():
		state = "authenticated"
		last_auth_error = ""
		last_auth_error_code = 0
		sign_in_completed.emit({"ok": true, "display_name": display_name})
		return true
	elapsed_seconds = 0.0
	state = "authenticating"
	var error := int(plugin.call("authenticate"))
	if error != OK:
		_finish_sign_in({"ok": false, "error": "game_center_auth_start_failed", "error_code": error})
		return false
	return true


func submit_personal_records(score: int, highest_level: int) -> bool:
	if not is_available():
		return false
	_queue_personal_record(SCORE_LEADERBOARD_ID, maxi(0, score))
	_queue_personal_record(LEVEL_LEADERBOARD_ID, clampi(highest_level, 1, 100))
	_try_submit_next()
	return true


func pending_score_count() -> int:
	return pending_records.size() + (0 if in_flight_record.is_empty() else 1)


func show_leaderboards() -> bool:
	if not can_show_leaderboards():
		return false
	var error := int(plugin.call("show_game_center", {
		"view": "leaderboards",
		"leaderboard_name": SCORE_LEADERBOARD_ID,
	}))
	if error != OK:
		return false
	dashboard_state = "presenting"
	dashboard_elapsed_seconds = 0.0
	return true


func can_show_leaderboards() -> bool:
	return is_authenticated() and plugin.has_method("show_game_center") and dashboard_state == "idle"


func notify_application_paused() -> void:
	if dashboard_state == "presenting":
		dashboard_state = "presented"


func notify_application_resumed() -> void:
	if dashboard_state in ["presenting", "presented"]:
		dashboard_state = "cooldown"
		dashboard_elapsed_seconds = 0.0


func poll() -> void:
	if not is_available():
		return
	while int(plugin.call("get_pending_event_count")) > 0:
		var event_value: Variant = plugin.call("pop_pending_event")
		if event_value is Dictionary:
			_handle_event(event_value)


func _process(delta: float) -> void:
	if not is_available():
		return
	poll()
	if dashboard_state in ["presenting", "cooldown"]:
		dashboard_elapsed_seconds += maxf(0.0, delta)
		var release_after := DASHBOARD_FAILSAFE_SECONDS if dashboard_state == "presenting" else DASHBOARD_REENTRY_GUARD_SECONDS
		if dashboard_elapsed_seconds >= release_after:
			dashboard_state = "idle"
			dashboard_elapsed_seconds = 0.0
	if state == "authenticating":
		elapsed_seconds += maxf(0.0, delta)
		if elapsed_seconds >= SIGN_IN_TIMEOUT_SECONDS:
			_finish_sign_in({"ok": false, "error": "game_center_timeout"})
	if not in_flight_record.is_empty():
		submission_elapsed_seconds += maxf(0.0, delta)
		if submission_elapsed_seconds >= SCORE_SUBMISSION_TIMEOUT_SECONDS:
			_finish_score_submission(false, "game_center_score_timeout", 0)
	elif retry_delay_seconds > 0.0:
		retry_delay_seconds = maxf(0.0, retry_delay_seconds - maxf(0.0, delta))
		if retry_delay_seconds <= 0.0:
			_try_submit_next()
	else:
		_try_submit_next()


func _handle_event(event: Dictionary) -> void:
	var event_type := str(event.get("type", ""))
	if event_type == "authentication" and state == "authenticating":
		if str(event.get("result", "")) != "ok":
			_finish_sign_in({
				"ok": false,
				"error": "game_center_auth_failed",
				"error_code": int(event.get("error_code", 0)),
			})
			return
		display_name = str(event.get("displayName", event.get("alias", ""))).strip_edges().left(32)
		_finish_sign_in({"ok": true, "display_name": display_name})
		return
	if event_type == "post_score" and not in_flight_record.is_empty():
		var event_category := str(event.get("category", ""))
		var event_score := int(event.get("score", -1))
		if (
			event_category != str(in_flight_record.get("category", ""))
			or event_score != int(in_flight_record.get("score", 0))
		):
			return
		if str(event.get("result", "")) == "ok":
			_finish_score_submission(true, "", 0)
		else:
			_finish_score_submission(
				false,
				"game_center_score_failed",
				int(event.get("error_code", 0))
			)


func _finish_sign_in(result: Dictionary) -> void:
	state = "authenticated" if bool(result.get("ok", false)) else "ready"
	if state == "authenticated":
		last_auth_error = ""
		last_auth_error_code = 0
	else:
		last_auth_error = str(result.get("error", "game_center_auth_failed"))
		last_auth_error_code = int(result.get("error_code", 0))
	elapsed_seconds = 0.0
	sign_in_completed.emit(result.duplicate(true))
	if state == "authenticated":
		_try_submit_next()


func _queue_personal_record(category: String, score: int) -> void:
	if not in_flight_record.is_empty() and str(in_flight_record.get("category", "")) == category:
		if int(in_flight_record.get("score", 0)) >= score:
			return
	for index in pending_records.size():
		if str(pending_records[index].get("category", "")) == category:
			if score > int(pending_records[index].get("score", 0)):
				pending_records[index].score = score
			return
	pending_records.append({"category": category, "score": score, "attempts": 0})
	while pending_records.size() > MAX_PENDING_RECORDS:
		pending_records.pop_front()


func _try_submit_next() -> void:
	if not is_authenticated() or not in_flight_record.is_empty() or retry_delay_seconds > 0.0:
		return
	if pending_records.is_empty():
		return
	in_flight_record = pending_records.pop_front()
	submission_elapsed_seconds = 0.0
	var error := int(plugin.call("post_score", {
		"score": int(in_flight_record.score),
		"category": str(in_flight_record.category),
	}))
	if error != OK:
		_finish_score_submission(false, "game_center_score_start_failed", error)


func _finish_score_submission(ok: bool, error: String, error_code: int) -> void:
	if in_flight_record.is_empty():
		return
	var completed := in_flight_record.duplicate(true)
	in_flight_record.clear()
	submission_elapsed_seconds = 0.0
	if not ok:
		completed.attempts = int(completed.get("attempts", 0)) + 1
		if int(completed.attempts) <= MAX_SCORE_RETRIES:
			pending_records.push_front(completed)
			retry_delay_seconds = SCORE_RETRY_DELAY_SECONDS
	var result := {
		"ok": ok,
		"category": str(completed.get("category", "")),
		"score": int(completed.get("score", 0)),
		"error": error,
		"error_code": error_code,
		"retry_pending": not ok and int(completed.get("attempts", 0)) <= MAX_SCORE_RETRIES,
		"pending_count": pending_score_count(),
	}
	score_submission_completed.emit(result)
	if ok:
		_try_submit_next()


func _has_required_interface(candidate: Object) -> bool:
	if candidate == null:
		return false
	for method_name in [
		"authenticate",
		"is_authenticated",
		"get_pending_event_count",
		"pop_pending_event",
		"post_score",
		"show_game_center",
	]:
		if not candidate.has_method(method_name):
			return false
	return true


func _reset_transient_state() -> void:
	elapsed_seconds = 0.0
	pending_records.clear()
	in_flight_record.clear()
	submission_elapsed_seconds = 0.0
	retry_delay_seconds = 0.0
	display_name = ""
	last_auth_error = ""
	last_auth_error_code = 0
	dashboard_state = "idle"
	dashboard_elapsed_seconds = 0.0
