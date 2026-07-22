class_name OnlineIdentityService
extends RefCounted

signal identity_changed(state: String, provider: String)

const PROVIDERS: Array[String] = ["guest", "anonymous", "apple_game_center", "google_play_games"]

var state := "offline"
var provider := "guest"
var account_id := ""
var linked_providers: Array[String] = []

func continue_as_guest() -> void:
    state = "guest"
    provider = "guest"
    account_id = ""
    identity_changed.emit(state, provider)

func authenticate(provider_name: String, opaque_account_id: String) -> bool:
    if provider_name not in PROVIDERS or provider_name == "guest" or opaque_account_id.strip_edges().is_empty():
        return false
    state = "authenticated"
    provider = provider_name
    account_id = opaque_account_id.strip_edges()
    if provider_name not in linked_providers:
        linked_providers.append(provider_name)
        linked_providers.sort()
    identity_changed.emit(state, provider)
    return true

func link_provider(provider_name: String) -> bool:
    if state != "authenticated" or provider_name not in PROVIDERS or provider_name == "guest" or provider_name in linked_providers:
        return false
    linked_providers.append(provider_name)
    linked_providers.sort()
    return true

func sign_out() -> void:
    state = "offline"
    provider = "guest"
    account_id = ""
    linked_providers.clear()
    identity_changed.emit(state, provider)

func is_online_identity() -> bool:
    return state == "authenticated"

func snapshot() -> Dictionary:
    return {"state": state, "provider": provider, "linked_providers": linked_providers.duplicate()}

