extends SceneTree

const Service = preload("res://addons/mobile_game_core/online/golden_egg_discovery_service.gd")

func platform_result() -> Dictionary:
    return {"ok":true,"verified_signature":true,"display_name":"FICTIONAL PLAYER","identity_token":JSON.stringify({"team_player_id":"fictional-team-player","game_player_id":"fictional-game-player","public_key_url":"https://static.gc.apple.com/key","signature":"fictional-signature","salt":"fictional-salt","timestamp":123456})}

func discovery() -> Dictionary:
    return {"idempotency_key":"fictional-idempotency-key","egg_id":"fictional-egg","evidence":"fictional-evidence"}

func configured() -> RefCounted:
    var service: RefCounted = Service.new()
    service.configure("fictional-game", "fictional-egg")
    return service

func _init() -> void:
    var failures: Array[String] = []
    var pre: RefCounted = configured()
    # Tests 1-5: offline/404 are never observed because ordinary paths make no request.
    for event: String in ["offline_launch","would_be_404","no_internet","game_center_authenticated","native_leaderboard","achievement","menu","gameplay"]:
        pre.ordinary_activity(event)
    if pre.website_request_count != 0: failures.append("tests 1-5: pre-discovery request count must be zero")

    # Test 6: reveal and consent occur without networking.
    if not pre.verified_local_discovery(true) or pre.state != Service.State.AWAITING_CONSENT or pre.website_request_count != 0:
        failures.append("test 6: verified discovery must reveal consent before networking")

    # Test 7: YES carries verified provider metadata and activates only now.
    if not pre.choose_publication(true, platform_result(), "com.flinsvault.fictional", discovery()): failures.append("test 7: YES rejected")
    var yes_request: Dictionary = pre.begin_submission()
    if yes_request.get("public_name_consent") != true or yes_request.get("identity",{}).get("provider_display_name") != "FICTIONAL PLAYER": failures.append("test 7: YES identity/consent missing")

    # Test 8: NO preserves the discovery while preventing public-name consent.
    var no_service: RefCounted = configured(); no_service.verified_local_discovery(true)
    if not no_service.choose_publication(false, platform_result(), "com.flinsvault.fictional", discovery()) or no_service.pending_snapshot().get("public_name_consent") != false:
        failures.append("test 8: NO must preserve anonymous pending discovery")

    # Test 9: failure stays pending and never fabricates a server result.
    no_service.begin_submission(); no_service.submission_failed()
    if no_service.state != Service.State.PENDING_SUBMISSION or not no_service.server_result().is_empty(): failures.append("test 9: backend failure fabricated success or lost pending state")

    # Test 10: repeated consent taps cannot create another logical discovery.
    if no_service.choose_publication(true, platform_result(), "com.flinsvault.fictional", {"idempotency_key":"different-key"}): failures.append("test 10: repeated tap replaced pending discovery")
    if no_service.pending_snapshot().get("idempotency_key") != "fictional-idempotency-key": failures.append("test 10: idempotency key changed")

    # Test 11: restart restores the same safe pending submission.
    var restored: RefCounted = configured()
    if not restored.restore_pending(no_service.pending_snapshot()) or restored.pending_snapshot().get("idempotency_key") != "fictional-idempotency-key": failures.append("test 11: pending restart restore failed")

    # Test 12 is configuration-gated in Python: updates disabled + Golden Egg enabled.
    if restored.website_request_count != 0: failures.append("test 12: restored service performed an implicit version/website request")

    if not pre.take_reveal() or pre.take_reveal(): failures.append("reveal permit must be one-shot")
    if not pre.begin_submission().is_empty(): failures.append("concurrent duplicate submission")
    if not restored.begin_submission(100).is_empty(): failures.append("restored Apple proof reused")
    var malformed: RefCounted = configured()
    if malformed.restore_pending({"idempotency_key":"fictional-key"}): failures.append("malformed pending snapshot accepted")
    var foreign: Dictionary = no_service.pending_snapshot()
    foreign["game_id"] = "different-game"
    if malformed.restore_pending(foreign): failures.append("foreign game snapshot accepted")
    var switched := platform_result()
    var token: Dictionary = JSON.parse_string(switched.identity_token)
    token["team_player_id"] = "another-fictional-player"
    switched["identity_token"] = JSON.stringify(token)
    if restored.refresh_pending_identity(switched, "com.flinsvault.fictional"): failures.append("account switch rebound pending discovery")
    if not restored.refresh_pending_identity(platform_result(), "com.flinsvault.fictional"): failures.append("same-account fresh proof rejected")
    if restored.begin_submission(100).is_empty(): failures.append("restored explicit attempt unavailable")
    restored.poll_timeout(30100)
    if not restored.server_result().is_empty(): failures.append("timeout fabricated server success")
    if not restored.begin_submission(100000).is_empty(): failures.append("timeout reused stale proof")
    if not restored.refresh_pending_identity(platform_result(), "com.flinsvault.fictional"): failures.append("fresh retry identity rejected")
    if not restored.begin_submission(30101).is_empty(): failures.append("retry cooldown bypassed")
    var retry: Dictionary = restored.begin_submission(38100)
    if retry.get("idempotency_key") != "fictional-idempotency-key": failures.append("retry changed logical discovery")
    if not restored.begin_submission(38101).is_empty(): failures.append("retry double tap launched twice")
    if not restored.pending_snapshot().get("identity", {}).is_empty(): failures.append("snapshot persisted a reusable Apple proof")
    var response := {"discovery_id":"fictional-discovery","public_reference":"fictional-reference","public_secret_code":"fictional-code","discovered_at":"2026-01-01T00:00:00Z","overall_rank":1,"game_rank":1,"first_for_game":true,"privacy_status":"PUBLIC","public_identity_source":"game_center_reported","public_player":"FICTIONAL PLAYER","golden_egg_hunt_url":"https://theflinsappvaultllc.com/golden-eggs","public_discovery_url":"https://theflinsappvaultllc.com/golden-eggs/discovery/fictional-reference"}
    if restored.accept_server_result(response): failures.append("NO accepted public-name result")
    response["privacy_status"] = "ANONYMOUS"
    response["public_identity_source"] = "anonymous"
    response["public_player"] = "Anonymous"
    if not restored.accept_server_result(response): failures.append("valid anonymous result rejected")
    if restored.restore_pending(no_service.pending_snapshot()): failures.append("completed state replaced by pending replay")
    if not restored.begin_submission(100000).is_empty(): failures.append("completed discovery submitted twice")

    print("GOLDEN_EGG_EVENT_CONTRACT failures=%d pre_discovery_requests=%d" % [failures.size(), pre.website_request_count - 1])
    for failure: String in failures: push_error(failure)
    quit(1 if not failures.is_empty() else 0)
