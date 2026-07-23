class_name FredPlayerIdentity
extends RefCounted

enum State { GUEST, LINK_AVAILABLE, LINKING, LINKED, OFFLINE, ERROR }
enum Provider { NONE, APPLE_GAME_CENTER, SIGN_IN_WITH_APPLE, GOOGLE_PLAY_GAMES }

var state := State.GUEST
var provider := Provider.NONE
var profile_label := "Guest adventurer"
var opaque_profile_id := ""

func offer(provider_value: Provider) -> bool:
	if provider_value == Provider.NONE or state == State.LINKING:
		return false
	provider = provider_value
	state = State.LINK_AVAILABLE
	return true

func begin_link(consent: bool) -> bool:
	if not consent or state != State.LINK_AVAILABLE:
		return false
	state = State.LINKING
	return true

func complete_link(server_profile_id: String, safe_label: String) -> bool:
	if state != State.LINKING or not _valid_opaque_id(server_profile_id):
		state = State.ERROR
		return false
	opaque_profile_id = server_profile_id
	var trimmed_label := safe_label.strip_edges()
	profile_label = trimmed_label.left(32) if not trimmed_label.is_empty() else "Marsh adventurer"
	state = State.LINKED
	return true

func continue_offline() -> void:
	state = State.OFFLINE
	provider = Provider.NONE
	opaque_profile_id = ""
	profile_label = "Guest adventurer"

func unlink_local() -> void:
	state = State.GUEST
	provider = Provider.NONE
	opaque_profile_id = ""
	profile_label = "Guest adventurer"

func status_message() -> String:
	match state:
		State.LINK_AVAILABLE:
			return "Platform sign-in is ready when you are."
		State.LINKING:
			return "Connecting your game profile..."
		State.LINKED:
			return "Progress linked to %s." % profile_label
		State.OFFLINE:
			return "Playing offline as a guest."
		State.ERROR:
			return "Sign-in did not finish. Your local progress is safe."
		_:
			return "Play now as a guest. Link an account later."

func to_local_preferences() -> Dictionary:
	return {
		"identity_state": State.LINKED if state == State.LINKED else State.GUEST,
		"provider": provider if state == State.LINKED else Provider.NONE,
		"opaque_profile_id": opaque_profile_id if state == State.LINKED else "",
		"profile_label": profile_label if state == State.LINKED else "Guest adventurer",
	}

static func _valid_opaque_id(value: String) -> bool:
	if value.length() < 8 or value.length() > 96:
		return false
	for character in value:
		if not character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return true
