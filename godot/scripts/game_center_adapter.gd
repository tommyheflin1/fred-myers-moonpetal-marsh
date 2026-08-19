class_name FredGameCenterAdapter
extends Node

signal sign_in_completed(result: Dictionary)

const SIGN_IN_TIMEOUT_SECONDS := 30.0
const SCORE_LEADERBOARD_ID := "com.flinsvault.fredmyers.adventure_score"
const LEVEL_LEADERBOARD_ID := "com.flinsvault.fredmyers.highest_level"

var plugin: Object
var state := "unavailable"
var elapsed_seconds := 0.0
var display_name := ""


func configure(plugin_override: Object = null) -> bool:
	plugin = plugin_override
	if plugin == null and OS.get_name() == "iOS" and Engine.has_singleton("GameCenter"):
		plugin = Engine.get_singleton("GameCenter")
	if not _has_required_interface(plugin):
		plugin = null
		state = "unavailable"
		return false
	state = "ready"
	return true


func is_available() -> bool:
	return plugin != null and state != "unavailable"


func is_authenticated() -> bool:
	return is_available() and bool(plugin.call("is_authenticated"))


func begin_sign_in() -> bool:
	if not is_available() or state == "authenticating":
		return false
	if is_authenticated():
		state = "authenticated"
		sign_in_completed.emit({"ok": true, "display_name": display_name})
		return true
	elapsed_seconds = 0.0
	state = "authenticating"
	var error := int(plugin.call("authenticate"))
	if error != OK:
		_finish({"ok": false, "error": "game_center_auth_start_failed", "error_code": error})
		return false
	return true


func submit_personal_records(score: int, highest_level: int) -> bool:
	if not is_authenticated() or not plugin.has_method("post_score"):
		return false
	var score_error := int(plugin.call("post_score", {
		"score": maxi(0, score),
		"category": SCORE_LEADERBOARD_ID,
	}))
	var level_error := int(plugin.call("post_score", {
		"score": clampi(highest_level, 1, 100),
		"category": LEVEL_LEADERBOARD_ID,
	}))
	return score_error == OK and level_error == OK


func poll() -> void:
	if not is_available():
		return
	while int(plugin.call("get_pending_event_count")) > 0:
		var event_value: Variant = plugin.call("pop_pending_event")
		if event_value is Dictionary:
			_handle_event(event_value)


func _process(delta: float) -> void:
	if state != "authenticating":
		return
	elapsed_seconds += delta
	poll()
	if elapsed_seconds >= SIGN_IN_TIMEOUT_SECONDS and state == "authenticating":
		_finish({"ok": false, "error": "game_center_timeout"})


func _handle_event(event: Dictionary) -> void:
	if str(event.get("type", "")) != "authentication" or state != "authenticating":
		return
	if str(event.get("result", "")) != "ok":
		_finish({
			"ok": false,
			"error": "game_center_auth_failed",
			"error_code": int(event.get("error_code", 0)),
		})
		return
	display_name = str(event.get("displayName", event.get("alias", ""))).strip_edges().left(32)
	_finish({"ok": true, "display_name": display_name})


func _finish(result: Dictionary) -> void:
	state = "authenticated" if bool(result.get("ok", false)) else "ready"
	elapsed_seconds = 0.0
	sign_in_completed.emit(result.duplicate(true))


func _has_required_interface(candidate: Object) -> bool:
	if candidate == null:
		return false
	for method_name in [
		"authenticate",
		"is_authenticated",
		"get_pending_event_count",
		"pop_pending_event",
		"post_score",
	]:
		if not candidate.has_method(method_name):
			return false
	return true
