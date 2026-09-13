extends SceneTree

const Gate = preload("res://scripts/fred_update_gate.gd")
const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")

# Fictional transport exists only in this excluded test, never in player controls.
class FictionalGate extends "res://scripts/fred_update_gate.gd":
    var checks_started := 0
    func begin_check() -> void:
        if not required:
            return
        checks_started += 1
        generation += 1
        valid_until = 0
        _cancel_request()
        _set_state("checking" if configured else "check_failed")

var passed := 0
var failed := 0
var signing_key: CryptoKey

func check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("PASS ", label)
    else:
        failed += 1
        push_error("FAIL " + label)

func _init() -> void:
    _run.call_deferred()

func envelope(policy: Dictionary) -> PackedByteArray:
    var payload := JSON.stringify(policy)
    var signature := Crypto.new().sign(HashingContext.HASH_SHA256, payload.sha256_buffer(), signing_key)
    return JSON.stringify({"policy_payload": payload, "key_id": "fixture-only", "signature": Marshalls.raw_to_base64(signature)}).to_utf8_buffer()

func silent(player: AudioStreamPlayer) -> bool:
    # Godot does not retain stream_paused on a stream that has never played.
    return not player.playing or player.stream_paused

func _run() -> void:
    signing_key = Crypto.new().generate_rsa(2048)
    var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/game.json"))
    var gate := FictionalGate.new()
    root.add_child(gate)
    gate.configure(definition, "iOS")
    gate.begin_check()
    check(not gate.required and not gate.blocks_gameplay() and gate.checks_started == 0, "Fred explicitly disables startup policy traffic on iOS")
    # Preserve opt-in security coverage without enabling the capability in Fred.
    definition.updates.enabled = true
    gate.configure(definition, "Windows")
    check(not gate.blocks_gameplay(), "desktop owner review remains unchanged")
    gate.configure(definition, "iOS")
    check(gate.required and gate.configured and gate.blocks_gameplay(), "iOS starts blocked with the packaged public key")
    gate.verifier.configure(signing_key.save_to_string(true), "fixture-only")
    var now := int(Time.get_unix_time_from_system())
    var valid := {"schema_version": 1, "bundle_id": Gate.BUNDLE, "platform": "ios", "minimum_supported_build": 1, "issued_at": now - 1, "expires_at": now + 899, "policy_id": "fictional-fred-policy"}
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(valid), gate.generation, now)
    check(gate.state == "current" and not gate.blocks_gameplay(), "cryptographically verified supported build plays")
    var old := valid.duplicate(true)
    old.minimum_supported_build = int(definition.build_number) + 1
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(old), gate.generation, now)
    check(gate.state == "update_required" and gate.blocks_gameplay(), "below-minimum build is blocked")
    for mutation: Dictionary in [
        {"schema_version": 2}, {"bundle_id": "com.example.other"}, {"platform": "android"},
        {"minimum_supported_build": 0}, {"minimum_supported_build": 1.5}, {"minimum_supported_build": "1"},
        {"minimum_supported_build": true}, {"issued_at": now + 1}, {"expires_at": now},
        {"issued_at": 0}, {"expires_at": now + 901}, {"policy_id": ""}, {"policy_id": {}},
    ]:
        var candidate := valid.duplicate(true)
        candidate.merge(mutation, true)
        gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(candidate), gate.generation, now)
        check(gate.state == "check_failed" and gate.blocks_gameplay(), "invalid signed payload blocked: " + str(mutation.keys()))
    for field: String in ["policy_payload", "signature", "key_id"]:
        var outer: Dictionary = JSON.parse_string(envelope(valid).get_string_from_utf8())
        outer[field] = str(outer[field]) + "tampered"
        gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, JSON.stringify(outer).to_utf8_buffer(), gate.generation, now)
        check(gate.blocks_gameplay(), "tampered envelope blocked: " + field)
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, JSON.stringify(valid).to_utf8_buffer(), gate.generation, now)
    check(gate.blocks_gameplay(), "unsigned response cannot unlock gameplay")
    for status: int in [0, 301, 401, 404, 500, 503]:
        gate.apply_response(HTTPRequest.RESULT_SUCCESS, status, envelope(valid), gate.generation, now)
        check(gate.blocks_gameplay(), "HTTP failure blocks: %d" % status)
    gate.apply_response(HTTPRequest.RESULT_TIMEOUT, 200, envelope(valid), gate.generation, now)
    check(gate.blocks_gameplay(), "transport failure cannot unlock even with HTTP 200")
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, PackedByteArray([123]), gate.generation, now)
    check(gate.blocks_gameplay(), "malformed JSON is blocked")
    var oversized := PackedByteArray()
    oversized.resize(Gate.MAX_BODY_BYTES + 1)
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, oversized, gate.generation, now)
    check(gate.blocks_gameplay(), "oversized body is blocked")
    gate.begin_check()
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(valid), gate.generation - 1, now)
    check(gate.blocks_gameplay(), "stale response cannot unlock a newer check")
    gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(valid), gate.generation, now)
    check(not gate.blocks_gameplay(), "signed rollback policy restores access without a restart")
    gate.valid_until = now - 1
    check(gate.blocks_gameplay(), "expired policy cannot grant a frame before the child recheck runs")
    gate._process(0.0)
    check(gate.blocks_gameplay(), "expired active policy triggers a fail-closed recheck")
    gate.configure({}, "iOS")
    check(gate.blocks_gameplay() and not gate.configured, "missing iOS configuration fails closed")

    var game: Node2D = Main.new()
    game.saver = FredSaveAdapter.new("user://update_gate_fixture")
    game.leaderboard = FredLocalLeaderboard.new("user://update_gate_fixture_board.json")
    game.countdown_enabled = false
    game.hazards_enabled = false
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.update_gate.free()
    var scene_gate := FictionalGate.new()
    game.update_gate = scene_gate
    game.add_child(scene_gate)
    scene_gate.configure(definition, "iOS")
    scene_gate.verifier.configure(signing_key.save_to_string(true), "fixture-only")
    game._create_update_overlay()
    scene_gate.state_changed.connect(game._on_update_gate_state_changed)
    game._on_update_gate_state_changed("checking")
    check(game.update_overlay.visible and game.update_retry.disabled, "checking overlay blocks the real scene without a skip button")
    var original_screen: int = game.screen
    game._handle_click(Main.TITLE_START_RECT.get_center())
    var touch := InputEventScreenTouch.new()
    touch.position = Main.TITLE_START_RECT.get_center()
    touch.pressed = true
    game._unhandled_input(touch)
    game._handle_touch(1, Layout.TOUCH_CONTROL_PAD_CENTER, true)
    game._start()
    check(game.screen == original_screen and game.touch_contacts.is_empty(), "touch, pointer and direct start cannot enter before verification")
    check(game._handle_back_request() == "update_blocked", "Back cannot bypass update verification")
    check(silent(game.menu_music) and silent(game.chase_music) and silent(game.golden_chime), "all music and Golden Egg audio are stopped or paused by the gate")
    scene_gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(valid), scene_gate.generation, now)
    check(not game.update_overlay.visible and not game._update_blocks_play(), "verified policy dismisses only the update overlay")
    game._start()
    check(game.screen == Main.Screen.PLAYING, "verified scene can enter gameplay")
    game.session.paused = false
    game._process(0.1)
    check(game.simulation_time > 0.0, "verified game simulation advances")
    game._handle_touch(4, Layout.TOUCH_CONTROL_PAD_CENTER + Vector2(50, 0), true)
    var position_before: Vector2 = game.fred
    var simulation_before: float = game.simulation_time
    var saved_level: int = game.level_number
    game.golden_chime.play()
    game._handle_application_paused()
    game._handle_application_resumed()
    check(scene_gate.checks_started == 1 and game._update_blocks_play(), "foreground rechecks with fictional transport, never a production request")
    check(game.session.paused and game.touch_contacts.is_empty() and game.touch_movement == Vector2.ZERO, "foreground gate preserves Pause and clears held input")
    game._process(1.0)
    game._fixed_tick(1.0)
    game._return_to_level_five()
    game._set_gameplay_paused(false)
    check(game.fred == position_before and game.simulation_time == simulation_before and game.level_number == saved_level and game.session.paused, "blocked ticks, Golden Egg return and resume cannot bypass the gate")
    check(silent(game.menu_music) and silent(game.chase_music) and silent(game.golden_chime), "foreground keeps every audio player stopped or paused during verification")
    scene_gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(old), scene_gate.generation, now)
    check(game.update_title.text == "Update required" and not game.update_retry.disabled, "required update offers an actionable Retry and App Store path")
    if "--fred-update-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        var capture_path := "user://fred-update-overlay.png"
        check(root.get_texture().get_image().save_png(capture_path) == OK, "real renderer captures the blocking update overlay")
        print("UPDATE_OVERLAY_CAPTURE ", ProjectSettings.globalize_path(capture_path))
    scene_gate.apply_response(HTTPRequest.RESULT_SUCCESS, 200, envelope(valid), scene_gate.generation, now)
    check(game.session.paused and not game._update_blocks_play(), "successful recheck never silently resumes a player's paused run")
    game._set_gameplay_paused(false)
    game._process(0.1)
    check(game.simulation_time > simulation_before, "existing Resume works after verification")
    check(not game.menu_music.stream_paused and not game.chase_music.stream_paused and not game.golden_chime.stream_paused, "audio resumes after successful verification")
    check(Gate.STORE_URL == "https://apps.apple.com/app/id6803295872" and Gate.BUNDLE == "com.flinsvault.fredmyers", "App Store destination and bundle remain Fred-specific")
    var source := FileAccess.get_file_as_string("res://scripts/main.gd")
    check(not source.contains("Local play and scores always remain available"), "public copy no longer promises an offline update bypass")
    check(FileAccess.get_file_as_string("res://export_presets.cfg").count("include_filter=\"assets/security/update-policy-public.pub,game/game.json\"") == 2, "both export presets include the public key and app-owned policy configuration")
    root.remove_child(game)
    game.free()
    root.remove_child(gate)
    gate.free()
    await process_frame
    print("MANDATORY_UPDATE_GATE_RESULT passed=%d failed=%d fictional_transport=true live_service_verified=false" % [passed, failed])
    quit(1 if failed else 0)
