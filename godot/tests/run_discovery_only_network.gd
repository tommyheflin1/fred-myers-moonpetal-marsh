extends SceneTree

const Main = preload("res://scripts/main.gd")
const ReviewFixtures = preload("res://tests/run_golden_egg_public_name_review.gd")
const AdapterFixtures = preload("res://tests/run_game_center_adapter.gd")

class OfflineNetwork:
    extends "res://scripts/golden_egg_network_bridge.gd"
    var requests := 0
    var status_code := 404
    var discovery_posts := 0
    func request_json(_method: String, _url: String, _headers: Dictionary, _body: String) -> Dictionary:
        requests += 1
        if _url.ends_with("/discoveries"): discovery_posts += 1
        return {"success": false, "status_code": status_code, "error": "FICTIONAL_SERVICE_UNAVAILABLE"}
    func _start(operation: String, service: RefCounted, argument: String) -> bool:
        var result := _run_operation(operation, service, argument)
        operation_completed.emit(operation, result)
        return true

var passed := 0
var failed := 0
func check(value: bool, label: String) -> void:
    if value: passed += 1
    else:
        failed += 1
        push_error(label)

func _init() -> void: _run.call_deferred()
func _run() -> void:
    for response in [0, 404, 503]:
        var network := OfflineNetwork.new()
        network.status_code = response
        var game := Main.new()
        game.golden_network.free()
        game.golden_network = network
        game.golden_secure_store = ReviewFixtures.MemoryStore.new()
        game.audio_enabled = false
        game.hazards_enabled = false
        game.countdown_enabled = false
        game.saver = FredSaveAdapter.new("user://discovery_only_%d" % response)
        root.add_child(game)
        await process_frame
        game.golden_production_network_enabled = true
        var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/game.json"))
        game.update_gate.configure(definition, "iOS")
        game.update_gate.begin_check()
        check(not game.update_gate.required and game.update_gate.request == null, "iOS product configuration makes no policy request")
        check(network.requests == 0 and game.screen == Main.Screen.TITLE, "offline/404/503 cannot affect menu because no request occurs")
        var native := AdapterFixtures.FakeGameCenter.new()
        game.game_center.configure(native)
        check(game._request_game_center_connection(), "normal Game Center sign-in starts independently")
        native.authenticated = true
        native.events.append({"type":"authentication", "result":"ok", "displayName":"Fictional Frog", "team_player_id":"fictional-team", "game_player_id":"fictional-game"})
        native.events.append({"type":"identity_verification_signature", "result":"error"})
        game.game_center.poll()
        check(game.game_center.is_authenticated() and network.requests == 0, "Game Center callback does not exchange website identity")
        check(game.game_center.show_leaderboards() and network.requests == 0, "native leaderboard opens without website")
        game._start()
        game._process(0.1)
        check(game.screen == Main.Screen.PLAYING and game.simulation_time > 0, "core gameplay advances with website unavailable")
        game._handle_application_paused()
        game._handle_application_resumed()
        check(network.requests == 0 and game.update_gate.request == null and not game._update_blocks_play(), "foreground is independent of website")
        game._reveal_golden_egg()
        check(network.requests == 0, "reveal stages evidence but waits for publication choice")
        check(game.golden_service.has_pending_discovery(), "local find is preserved for retry")
        game._return_to_level_five()
        check(network.requests == 0 and game.golden_service.retry_pending_discovery().error == "EXPLICIT_PUBLICATION_CHOICE_REQUIRED", "do not post blocks unsent retry and sends nothing")
        var restored := preload("res://scripts/golden_egg_service.gd").new()
        restored.configure(network.request_json, game.golden_secure_store)
        check(restored.retry_pending_discovery().error == "EXPLICIT_PUBLICATION_CHOICE_REQUIRED" and network.requests == 0, "local-only survives restoration without submission")
        game.screen = Main.Screen.GOLDEN_EGG
        game.golden_public_review_requested = true
        game._on_game_center_sign_in_completed({"ok":true,"verified_signature":true,"display_name":"Fictional Frog","game_center_identity":{
            "team_player_id":"fictional-team", "game_player_id":"fictional-game", "bundle_id":"com.flinsvault.fredmyers", "public_key_url":"https://static.gc.apple.com/fictional", "signature":"fictional-review", "salt":"fictional-salt", "timestamp":int(Time.get_unix_time_from_system()*1000)}})
        check(network.discovery_posts == 0 and not game.golden_anonymous_requested, "failed Public review never posts or silently chooses Anonymous")
        game._handle_click(Main.GOLDEN_EGG_PRIVATE_RECT.get_center())
        game._on_game_center_sign_in_completed({"ok":true,"verified_signature":true,"display_name":"Fictional Frog","game_center_identity":{
            "team_player_id":"fictional-team", "game_player_id":"fictional-game", "bundle_id":"com.flinsvault.fredmyers", "public_key_url":"https://static.gc.apple.com/fictional", "signature":"fictional-proof", "salt":"fictional-salt", "timestamp":int(Time.get_unix_time_from_system()*1000)}})
        check(network.requests > 0, "only discovered player choice contacts the fictional unavailable service")
        check(not game.golden_service.has_canonical_discovery() and game.golden_service.has_pending_discovery(), "failed submission remains pending without fake acceptance")
        check(game.golden_privacy == "anonymous", "No preserves approved Anonymous handling")
        game._return_to_level_five()
        check(game.level_number == 5 and game.screen == Main.Screen.PLAYING and not game.session.paused, "failed website never prevents Level 5 return")
        game.queue_free()
        await process_frame
    print("DISCOVERY_ONLY_NETWORK passed=%d failed=%d fictional_transport=true" % [passed, failed])
    quit(1 if failed else 0)
