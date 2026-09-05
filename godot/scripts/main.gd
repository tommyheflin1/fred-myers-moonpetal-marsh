extends Node2D

const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")
const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const CameraFollow = preload("res://scripts/camera_follow.gd")
const AnimationCoordinator = preload("res://scripts/fred_animation_coordinator.gd")
const FredRigScene = preload("res://scenes/fred_rig.tscn")
const CharacterSurface = preload("res://scripts/character_surface.gd")
const BotanicalArt = preload("res://scripts/botanical_art.gd")
const CollectibleWildlifeArt = preload("res://scripts/collectible_wildlife_art.gd")
const WhirlpoolArt = preload("res://scripts/whirlpool_art.gd")
const MarshLabelLayout = preload("res://scripts/marsh_label_layout.gd")
const PredatorFishArt = preload("res://scripts/predator_fish_art.gd")
const WaterContactArt = preload("res://scripts/water_contact_art.gd")
const MarshRouteLayout = preload("res://scripts/marsh_route_layout.gd")
const FrogCustomization = preload("res://scripts/frog_customization.gd")
const Wardrobe = preload("res://scripts/wardrobe_layout.gd")
const AppleGameScoring = preload("res://scripts/apple_game_scoring.gd")
const GameCenterAdapter = preload("res://scripts/game_center_adapter.gd")
const PredatorDepth = preload("res://scripts/predator_depth.gd")
const WildlifeAnimationRig = preload("res://scripts/wildlife_animation_rig.gd")
const GoldenEggRunState = preload("res://scripts/golden_egg_run_state.gd")
const GoldenEggDiscoveryStore = preload("res://scripts/golden_egg_discovery_store.gd")
const GoldenEggClient = preload("res://scripts/golden_egg_client.gd")
const GoldenEggService = preload("res://scripts/golden_egg_service.gd")
const GoldenEggLocalStore = preload("res://scripts/golden_egg_local_store.gd")
const GoldenEggNetworkBridge = preload("res://scripts/golden_egg_network_bridge.gd")

enum Screen { TITLE, STORY, INSTRUCTIONS, PLAYING, FAILED, COMPLETE, LEADERBOARD, CUSTOMIZE, GOLDEN_EGG }
const START := Vector2(135, 560)
const EXIT := Vector2(1150, 165)
const PADS := [Vector2(220,500), Vector2(350,420), Vector2(490,500), Vector2(630,390), Vector2(760,300), Vector2(900,225), Vector2(1040,165)]
const BUGS := [Vector2(350,390), Vector2(625,360), Vector2(900,195)]
const SAFE_LOCATION := Vector2(720,570)
const PREDATOR_START := Vector2(850,520)
const WHIRLPOOLS := [Vector2(500,405), Vector2(790,315), Vector2(960,500)]
const FAIRY_POSITIONS := [Vector2(455,205), Vector2(835,545), Vector2(1080,365)]
const PREDATOR_SPECIES: Array[String] = ["BASS", "PIKE", "HERON", "SNAKE", "MUSKIE"]
const RESPAWN_COUNTDOWN_SECONDS := 2.0
const MENU_MUSIC_PATH := "res://assets/audio/the_marshland_march.mp3"
const GAMEPLAY_MUSIC_PATH := "res://assets/audio/marshland_chase.mp3"
const TITLE_START_RECT := Rect2(90,405,390,68)
const TITLE_CUSTOMIZE_RECT := Rect2(90,490,390,58)
const TITLE_LEADERBOARD_RECT := Rect2(90,565,390,58)
const LEADERBOARD_GAME_CENTER_RECT := Rect2(260,620,300,55)
const LEADERBOARD_HOME_SPLIT_RECT := Rect2(720,620,300,55)
const LEADERBOARD_HOME_CENTER_RECT := Rect2(490,620,300,55)
const STORY_HOME_RECT := Rect2(85,630,250,60)
const STORY_CONTINUE_RECT := Rect2(815,630,380,60)
const INSTRUCTIONS_HOME_RECT := Rect2(85,630,250,60)
const INSTRUCTIONS_PLAY_RECT := Rect2(815,630,380,60)
const CUSTOM_HOME_RECT := Wardrobe.HOME
const CUSTOM_PREVIEW_ORIGIN := Wardrobe.PREVIEW_ORIGIN
const CUSTOM_PREVIEW_SCALE := Wardrobe.PREVIEW_SCALE
const CUSTOM_PREVIEW_RECT := Wardrobe.PREVIEW_RECT
const GOLDEN_EGG_PRIVATE_RECT := Rect2(175,555,400,48)
const GOLDEN_EGG_PUBLIC_RECT := Rect2(705,555,400,48)
const GOLDEN_EGG_HUNT_RECT := Rect2(265,625,340,50)
const GOLDEN_EGG_RETURN_RECT := Rect2(675,625,340,50)
const CUSTOM_CARDS := Wardrobe.TABS

var session := AdventureSession.new(1337)
var saver := FredSaveAdapter.new()
var screen := Screen.TITLE
var fred := START
var predator := PREDATOR_START
var collected: Array[int] = []
var in_safe_location := false
var save_feedback := FredSaveFeedback.NEUTRAL
var save_feedback_seconds := 0.0
var predator_direction := 1.0
var _fixed_accumulator := 0.0
var visual_time := 0.0
var reduced_motion := bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
var level_profile := FredLevelIntensity.profile(1)
var identity := FredPlayerIdentity.new()
var level_number := 1
var eat_effect_seconds := 0.0
var eat_target := Vector2.ZERO
var secondary_predators: Array[Vector2] = [Vector2(500,245), Vector2(1030,360), Vector2(770,175), Vector2(405,575)]
var simulation_time := 0.0
var danger_cooldown_seconds := 0.0
var hazards_enabled := true
var impact_burst_seconds := 0.0
var impact_burst_origin := Vector2.ZERO
var impact_burst_kind := "SPLASH"
var leap: RefCounted = LeapTraversal.new()
var depth: RefCounted = DepthTraversal.new()
var camera_response_y := 0.0
var camera_offset := Vector2.ZERO
var camera_follow: RefCounted = CameraFollow.new()
var leaderboard := FredLocalLeaderboard.new()
var customization: RefCounted = FrogCustomization.new()
var wardrobe_category := "hero"
var wardrobe_page := 0
var wardrobe_owned_only := false
var wardrobe_item := ""
var game_scoring: RefCounted = AppleGameScoring.new()
var game_center: Node
var game_center_status := "OFFLINE MARSH BOARD"
var menu_music: AudioStreamPlayer
var chase_music: AudioStreamPlayer
var audio_enabled := true
var countdown_seconds := 0.0
var countdown_enabled := true
var fairy_collected := false
var title_art: Texture2D
var gameplay_art: Texture2D
var tongue: RefCounted = TongueTargeting.new()
var last_aim_direction := Vector2.RIGHT
var boost: RefCounted = BoostLocomotion.new()
var animation: RefCounted = AnimationCoordinator.new()
var fred_rig: Node2D
var touch_controls_visible := true
var device_intent_adapter_enabled := false
var touch_contacts: Dictionary = {}
var touch_positions: Dictionary = {}
var touch_movement := Vector2.ZERO
var touch_boost := false
var pointer_touch_active := false
var application_backgrounded := false
var golden_run: RefCounted = GoldenEggRunState.new()
var golden_discovery: RefCounted = GoldenEggDiscoveryStore.new()
var golden_client: RefCounted = GoldenEggClient.new()
var golden_service: RefCounted = GoldenEggService.new()
var golden_secure_store: RefCounted = GoldenEggLocalStore.new()
var golden_network: Node = GoldenEggNetworkBridge.new()
var golden_production_network_enabled := true
var golden_reveal_seconds := 0.0
var golden_discovery_status := "pending"
var golden_privacy := "anonymous"
var _world_labels_key := ""
var _cached_world_labels: Array[Dictionary] = []
var golden_chime: AudioStreamPlayer
var golden_room_open := false
const GOLDEN_ROOM_EGG := Vector2(640, 360)
const GOLDEN_ROOM_EGG_RADIUS := 78.0

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            _handle_application_paused()
        NOTIFICATION_APPLICATION_RESUMED:
            _handle_application_resumed()
        NOTIFICATION_WM_GO_BACK_REQUEST:
            if _handle_back_request() == "quit" and get_tree() != null:
                get_tree().quit()

func _handle_application_paused() -> void:
    if application_backgrounded:
        return
    application_backgrounded = true
    if is_instance_valid(game_center) and game_center.has_method("notify_application_paused"):
        game_center.notify_application_paused()
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    _fixed_accumulator = 0.0
    if is_instance_valid(menu_music):
        menu_music.stream_paused = true
    if is_instance_valid(chase_music):
        chase_music.stream_paused = true
    if screen == Screen.PLAYING:
        golden_run.note_pause(level_number)
        session.paused = true
        _save("[PAUSED] Fred is safe while the app is in the background.")

func _handle_application_resumed() -> void:
    if not application_backgrounded:
        return
    application_backgrounded = false
    if is_instance_valid(game_center) and game_center.has_method("notify_application_resumed"):
        game_center.notify_application_resumed()
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    _fixed_accumulator = 0.0
    if is_instance_valid(menu_music):
        menu_music.stream_paused = false
    if is_instance_valid(chase_music):
        chase_music.stream_paused = false
    if screen == Screen.PLAYING:
        session.paused = true
        _set_feedback("[PAUSED] Fred is safe. Tap RESUME when you are ready.")
    _sync_music()

func _handle_back_request() -> String:
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    if screen == Screen.PLAYING:
        if session.paused:
            _go_home()
            return "home"
        session.paused = true
        _save("[PAUSED] Press Back again to return home.")
        return "paused"
    if screen == Screen.TITLE:
        return "quit"
    _go_home()
    return "home"

func _ready() -> void:
    if DisplayServer.get_name() == "headless" and str(customization.path) == FrogCustomization.DEFAULT_PATH:
        golden_production_network_enabled = false
        customization = FrogCustomization.new("")
        golden_run = GoldenEggRunState.new("user://headless_fred_golden_egg_guard.json")
        golden_discovery = GoldenEggDiscoveryStore.new("user://headless_fred_golden_egg_discovery.json")
    if "--reduced-motion" in OS.get_cmdline_user_args():
        reduced_motion = true
    if DisplayServer.is_touchscreen_available() or "--show-touch-controls" in OS.get_cmdline_user_args():
        touch_controls_visible = true
    if "--owner-review-medium" in OS.get_cmdline_user_args():
        get_window().title = "Fred Myers - Marsh Uplift 960 Review"
    elif "--owner-review-build" in OS.get_cmdline_user_args():
        get_window().title = "Fred Myers - Marsh Uplift Owner Review"
    fred_rig = FredRigScene.instantiate()
    add_child(fred_rig)
    if not fred_rig.validate_contract():
        push_warning("Fred rig is using its safe fallback: %s" % fred_rig.last_error)
    var result := saver.load_session(session)
    game_center = GameCenterAdapter.new()
    add_child(game_center)
    add_child(golden_network)
    golden_network.operation_completed.connect(_on_golden_network_operation_completed)
    golden_service.configure(golden_network.request_json, golden_secure_store)
    if golden_production_network_enabled and golden_service.has_pending_discovery():
        golden_network.start_retry(golden_service)
    var game_center_available := bool(game_center.configure())
    game_scoring.configure(
        OS.get_name(),
        GameCenterAdapter.SCORE_LEADERBOARD_ID if game_center_available else "",
        game_center_available
    )
    if game_center_available:
        game_center.sign_in_completed.connect(_on_game_center_sign_in_completed)
        game_center.score_submission_completed.connect(_on_game_center_score_submission_completed)
        _request_game_center_connection()
    boost.reset()
    _set_feedback(FredSaveFeedback.load_message(result))
    menu_music = AudioStreamPlayer.new()
    chase_music = AudioStreamPlayer.new()
    golden_chime = AudioStreamPlayer.new()
    if audio_enabled:
        menu_music.stream = _load_looping_music(MENU_MUSIC_PATH, "Menu music")
        chase_music.stream = _load_looping_music(GAMEPLAY_MUSIC_PATH, "Gameplay music")
    title_art = load("res://assets/art/moonpetal-title-fred-v4-sport.png")
    gameplay_art = load("res://assets/art/moonpetal-gameplay-marsh-v1.png")
    menu_music.volume_db = -8.0
    chase_music.volume_db = -7.0
    golden_chime.volume_db = -5.0
    golden_chime.stream = _build_golden_chime()
    add_child(menu_music)
    add_child(chase_music)
    add_child(golden_chime)
    _sync_fred_style()
    _sync_music()
    set_process(true)

func _on_game_center_sign_in_completed(result: Dictionary) -> void:
    if bool(result.get("ok", false)):
        if golden_service.set_verified_game_center_identity(result):
            game_center_status = "GAME CENTER IDENTITY READY"
            if golden_production_network_enabled and golden_service.has_pending_discovery() and not golden_network.is_busy():
                golden_network.start_retry(golden_service)
        else:
            game_center_status = "GAME CENTER CONNECTED — DISCOVERY SAFE FOR RETRY"
    else:
        var error := str(result.get("error", ""))
        if error == "game_center_timeout":
            game_center_status = "GAME CENTER TIMED OUT — TAP CONNECT TO RETRY"
        elif error in ["game_center_auth_failed", "game_center_auth_start_failed"]:
            game_center_status = "GAME CENTER SIGN-IN NEEDED — TAP CONNECT"
        else:
            game_center_status = "GAME CENTER UNAVAILABLE — LOCAL SCORES ARE SAFE"
    queue_redraw()

func _game_center_available() -> bool:
    return is_instance_valid(game_center) and game_center.has_method("is_available") and bool(game_center.is_available())

func _game_center_auth_state() -> String:
    if not _game_center_available() or not game_center.has_method("authentication_state"):
        return "unavailable"
    return str(game_center.authentication_state())

func _request_game_center_connection() -> bool:
    if not _game_center_available():
        game_center_status = "APPLE GAME CENTER IS NOT AVAILABLE ON THIS DEVICE"
        queue_redraw()
        return false
    if game_center.is_authenticated():
        game_center_status = "GAME CENTER CONNECTED"
        queue_redraw()
        return true
    if _game_center_auth_state() == "authenticating":
        game_center_status = "CONNECTING TO GAME CENTER"
        queue_redraw()
        return false
    var started := bool(game_center.begin_sign_in())
    game_center_status = "CONNECTING TO GAME CENTER" if started else "GAME CENTER SIGN-IN NEEDED — TAP CONNECT"
    queue_redraw()
    return started

func _on_game_center_score_submission_completed(result: Dictionary) -> void:
    if bool(result.get("ok", false)):
        game_center_status = "GAME CENTER SCORE SYNCED"
    elif bool(result.get("retry_pending", false)):
        game_center_status = "GAME CENTER RETRYING SCORE"
    else:
        game_center_status = "GAME CENTER SCORE PENDING"
    queue_redraw()

func _process(delta: float) -> void:
    _advance_visual(delta)
    _tick_feedback(delta)
    if screen != Screen.PLAYING or session.paused: return
    _fixed_accumulator += delta
    while _fixed_accumulator >= 1.0 / 60.0:
        _fixed_tick(1.0 / 60.0)
        _fixed_accumulator -= 1.0 / 60.0
    queue_redraw()

func _advance_visual(delta: float) -> void:
    visual_time = FredVisualState.bounded_time(visual_time, delta)
    if not session.paused:
        eat_effect_seconds = maxf(0.0, eat_effect_seconds - maxf(0.0, delta))
    impact_burst_seconds = maxf(0.0, impact_burst_seconds - maxf(0.0, delta))
    if screen == Screen.GOLDEN_EGG:
        golden_reveal_seconds = minf(12.0, golden_reveal_seconds + maxf(0.0, delta))
    queue_redraw()

func _fixed_tick(delta: float) -> void:
    simulation_time += maxf(0.0, delta)
    danger_cooldown_seconds = maxf(0.0, danger_cooldown_seconds - maxf(0.0, delta))
    if countdown_enabled and countdown_seconds > 0.0:
        countdown_seconds = maxf(0.0, countdown_seconds - maxf(0.0, delta))
        if countdown_seconds > 0.0:
            return
        _set_feedback("[GO!] Leap into the marsh!")
    tongue.advance(delta)
    var direction := touch_movement
    if device_intent_adapter_enabled:
        direction += FredInputIntent.movement()
    direction = direction.normalized()
    if golden_room_open:
        if direction != Vector2.ZERO:
            last_aim_direction = direction
        fred = (fred + direction * 170.0 * delta).clamp(Vector2(90,145),Vector2(1190,615))
        if fred.distance_to(GOLDEN_ROOM_EGG) <= GOLDEN_ROOM_EGG_RADIUS and golden_run.touch_egg():
            _reveal_golden_egg()
        _update_animation(direction)
        return
    if direction != Vector2.ZERO:
        last_aim_direction = direction
    if device_intent_adapter_enabled and FredInputIntent.pressed(FredInputIntent.Intent.LEAP):
        _request_leap(direction)
    if device_intent_adapter_enabled and FredInputIntent.pressed(FredInputIntent.Intent.INTERACT):
        _request_tongue(last_aim_direction)
    var boost_allowed: bool = not depth.is_transitioning() and not tongue.is_busy() and leap.state != LeapTraversal.State.LANDING
    var boost_moving: bool = direction != Vector2.ZERO or leap.state == LeapTraversal.State.AIRBORNE
    var boost_step: Dictionary = boost.advance(
        touch_boost or (device_intent_adapter_enabled and FredInputIntent.held(FredInputIntent.Intent.BOOST)),
        boost_moving,
        boost_allowed,
        session.boost_energy
    )
    session.boost_energy = int(boost_step.energy)
    _apply_boost_event(str(boost_step.event))
    var depth_step: Dictionary = depth.advance(delta)
    if bool(depth_step.completed):
        session.set_underwater(str(depth_step.mode) == "underwater")
        if str(depth_step.mode) == "surface":
            golden_run.note_surface_complete(level_number, fred, last_aim_direction)
        _set_feedback("[DEPTH] Fred reached the %s." % str(depth_step.mode))
    var current := _current_vector()
    if leap.state == LeapTraversal.State.AIRBORNE:
        var leap_step: Dictionary = leap.advance(delta)
        fred = (fred + Vector2(leap_step.movement) * float(boost_step.leap_multiplier) + current * delta * 0.35).clamp(Vector2(55,105), Vector2(1225,665))
        if bool(leap_step.landed):
            _resolve_landing()
    else:
        leap.advance(delta)
        var speed := 210.0 * float(depth.movement_scale())
        if depth.is_transitioning():
            speed *= 0.55
        elif bool(boost_step.active):
            speed = 210.0 * float(boost_step.speed_multiplier)
            if depth.is_underwater_band():
                speed *= DepthTraversal.UNDERWATER_BOOST_SCALE
        fred = (fred + (direction * speed + current) * delta).clamp(Vector2(55,105), Vector2(1225,665))
    golden_run.observe_position(level_number, fred, last_aim_direction)
    if level_number == GoldenEggRunState.TARGET_LEVEL and boost.is_active() and fred.y <= 108.0:
        if golden_run.try_upward_wall_boost(level_number, fred, last_aim_direction):
            golden_room_open = true
            fred = Vector2(640,560)
            boost.cancel(session.boost_energy)
            _set_feedback("[SECRET DOOR] Ancient reeds part beyond the wall.")
    _update_animation(direction)
    _update_camera(direction, bool(boost_step.active))
    predator.x += predator_direction * 110.0 * float(level_profile.predator_speed_scale) * delta
    if bool(level_profile.weaving_patrol):
        predator.y = PREDATOR_START.y + sin(visual_time * float(level_profile.predator_weave_speed)) * float(level_profile.predator_weave_amplitude)
    var predator_bounds := Vector2(160.0,520.0) if MarshRouteLayout.is_reversed(level_number) else Vector2(760.0,1120.0)
    if predator.x > predator_bounds.y or predator.x < predator_bounds.x:
        predator_direction *= -1.0
    _update_secondary_predators()
    in_safe_location = fred.distance_to(_level_safe_position()) < float(level_profile.safe_radius)
    if fred.distance_to(_pad_position(3)) < 42 and session.checkpoint_sequence < 1:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1); _save("Midpoint is safe.")
    if _check_danger_collision():
        return
    var golden_sequence_blocks_exit: bool = golden_run.blocks_ordinary_level_completion(level_number)
    if not golden_sequence_blocks_exit and fred.distance_to(_level_exit_position()) < 55 and session.complete_level():
        leaderboard.submit(identity.profile_label, level_number, session.bug_count, session.health)
        customization.earn_coins(15 + mini(10, level_number / 10))
        var score_result: Dictionary = game_scoring.record_level_completion(
            level_number, session.bug_count, session.health, customization.coins
        )
        if is_instance_valid(game_center):
            game_center.submit_personal_records(int(score_result.event.score), level_number)
        _sync_fred_style()
        screen = Screen.COMPLETE; _save("Lily Leap is complete.")

func _sync_music() -> void:
    if not is_instance_valid(menu_music) or not is_instance_valid(chase_music):
        return
    if not audio_enabled:
        menu_music.stop()
        chase_music.stop()
        return
    var wants_menu := _music_route() == "menu"
    if wants_menu:
        if chase_music.playing: chase_music.stop()
        if menu_music.stream != null and not menu_music.playing: menu_music.play()
    else:
        if menu_music.playing: menu_music.stop()
        if chase_music.stream != null and not chase_music.playing: chase_music.play()

func _music_route() -> String:
    return "menu" if screen in [Screen.TITLE, Screen.STORY, Screen.INSTRUCTIONS, Screen.LEADERBOARD, Screen.CUSTOMIZE] else "gameplay"

func _load_looping_music(path: String, label: String) -> AudioStream:
    var stream: AudioStream = load(path)
    if stream == null:
        push_warning("%s could not be loaded from the packaged game." % label)
        return null
    if stream is AudioStreamMP3:
        (stream as AudioStreamMP3).loop = true
    return stream

func _build_golden_chime() -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.mix_rate = 22050
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.stereo = false
    var duration := 0.92
    var sample_count := int(float(stream.mix_rate) * duration)
    var pcm := PackedByteArray()
    pcm.resize(sample_count * 2)
    var notes: Array[float] = [523.25,659.25,783.99]
    for sample_index in sample_count:
        var seconds := float(sample_index) / float(stream.mix_rate)
        var envelope := pow(maxf(0.0,1.0-seconds/duration),1.65)
        var value := 0.0
        for note_index in notes.size():
            var entry := float(note_index) * 0.12
            if seconds >= entry:
                value += sin(TAU * notes[note_index] * (seconds-entry)) * exp(-(seconds-entry)*3.1)
        pcm.encode_s16(sample_index*2,clampi(roundi(value*envelope*7200.0),-32767,32767))
    stream.data = pcm
    return stream

func _route_point(point: Vector2) -> Vector2:
    return MarshRouteLayout.route_point(point, level_number)

func _level_start_position() -> Vector2:
    return MarshRouteLayout.start_point(START, level_number)

func _level_exit_position() -> Vector2:
    return _route_point(EXIT)

func _level_safe_position() -> Vector2:
    return MarshRouteLayout.safe_point(SAFE_LOCATION, level_number)

func _whirlpool_position(index: int) -> Vector2:
    return _route_point(WHIRLPOOLS[index])

func _checkpoint_respawn_position() -> Vector2:
    if (
        session.checkpoint_sequence > 0
        and session.current_checkpoint == AdventureSession.CHECKPOINTS[1]
    ):
        return _pad_position(3)
    return _level_start_position()

func _fairy_position() -> Vector2:
    return _route_point(FAIRY_POSITIONS[(level_number - 1) % FAIRY_POSITIONS.size()])

func _fairy_available() -> bool:
    return level_number % 10 == 0 and not fairy_collected

func _tongue_candidates() -> Array[Dictionary]:
    var candidates: Array[Dictionary] = []
    for index in BUGS.size():
        if index in collected:
            continue
        candidates.append({
            "id": "bug:%03d" % index,
            "kind": "bug",
            "position": _bug_position(index),
            "eligible": true,
        })
    if _fairy_available():
        candidates.append({
            "id": "fairy:%03d" % level_number,
            "kind": "fairy",
            "position": _fairy_position(),
            "eligible": session.health < AdventureSession.MAX_LIVES,
            "blocked_reason": "campaign_life_limit",
        })
    return candidates

func _request_tongue(requested_aim: Vector2) -> Dictionary:
    if screen != Screen.PLAYING:
        return {"accepted": false, "outcome": "blocked", "reason": "screen"}
    if session.paused:
        return {"accepted": false, "outcome": "blocked", "reason": "paused"}
    if countdown_seconds > 0.0:
        _set_feedback("[TONGUE WAIT] Get ready for the level to begin.")
        return {"accepted": false, "outcome": "blocked", "reason": "countdown"}
    if leap.state != LeapTraversal.State.GROUNDED:
        _set_feedback("[TONGUE BLOCKED] Land before snapping at prey.")
        return {"accepted": false, "outcome": "blocked", "reason": "airborne"}
    if depth.state != DepthTraversal.State.SURFACE:
        _set_feedback("[TONGUE BLOCKED] Surface before snapping at flying prey.")
        return {"accepted": false, "outcome": "blocked", "reason": "depth"}
    if requested_aim.length_squared() > 0.0001:
        last_aim_direction = requested_aim.normalized()
    var result: Dictionary = tongue.request(fred, last_aim_direction, _tongue_candidates())
    if not bool(result.get("accepted", false)):
        _set_feedback("[TONGUE RECOVERING] Wait for Fred's tongue to return.")
        return result
    golden_run.note_tongue_complete(level_number, fred, last_aim_direction)
    eat_target = Vector2(result.get("target_point", fred + last_aim_direction * TongueTargeting.MAX_RANGE))
    match str(result.get("outcome", "miss")):
        "hit":
            if not _consume_tongue_target(str(result.get("target_id", "")), str(result.get("target_kind", ""))):
                tongue.outcome = "blocked"
                tongue.blocked_reason = "stale_target"
                _set_feedback("[TONGUE BLOCKED] That target already moved away.")
        "blocked":
            if str(result.get("reason", "")) == "campaign_life_limit":
                _set_feedback("[LIVES FULL] Fred reached the campaign life limit.")
            else:
                _set_feedback("[TONGUE BLOCKED] That target cannot be eaten now.")
        _:
            _set_feedback("[TONGUE MISS] Move within the glow or aim toward edible prey.")
    return result

func _consume_tongue_target(target_id: String, target_kind: String) -> bool:
    if target_kind == "bug" and target_id.begins_with("bug:"):
        var index := int(target_id.trim_prefix("bug:"))
        if index < 0 or index >= BUGS.size() or index in collected:
            return false
        collected.append(index)
        golden_run.note_food_collected(level_number)
        session.collect_bug()
        customization.earn_coins(3)
        _sync_fred_style()
        eat_effect_seconds = TongueTargeting.COOLDOWN_SECONDS
        _set_feedback("[MUNCH!] Fred ate marsh bug %d and earned 3 coins!" % (index + 1))
        return true
    if target_kind == "fairy" and target_id == "fairy:%03d" % level_number:
        if not _fairy_available() or not session.gain_life():
            return false
        fairy_collected = true
        eat_effect_seconds = TongueTargeting.COOLDOWN_SECONDS
        _set_feedback("[FAIRY FEAST] Extra life! Fred has %d lives." % session.health)
        return true
    return false

func _current_vector() -> Vector2:
    var strength := float(level_profile.current_strength)
    if is_zero_approx(strength):
        return Vector2.ZERO
    var route_direction := -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    var direction := route_direction
    if bool(level_profile.reversing_current):
        var frequency := float(level_profile.current_reversal_frequency)
        direction = route_direction if sin(visual_time * frequency) >= 0.0 else -route_direction
    var vertical := 0.0
    if level_number >= 7 and depth.is_underwater_band():
        vertical = sin(visual_time * 0.9) * strength * 0.55
    return Vector2(strength * direction, vertical)

func _update_secondary_predators() -> void:
    var pressure := float(level_profile.predator_speed_scale)
    secondary_predators[0] = _route_point(Vector2(505 + sin(simulation_time * 1.15 * pressure) * 190, 250 + cos(simulation_time * 0.75) * 55))
    secondary_predators[1] = _route_point(Vector2(1030 + cos(simulation_time * 0.62 * pressure) * 105, 350 + sin(simulation_time * 0.94) * 125))
    secondary_predators[2] = _route_point(Vector2(770 + sin(simulation_time * 0.82) * 135, 175 + absf(sin(simulation_time * 1.28)) * 125))
    secondary_predators[3] = _route_point(Vector2(405 + cos(simulation_time * 1.05) * 150, 575 + sin(simulation_time * 0.65) * 55))

func _pad_position(index: int) -> Vector2:
    var base: Vector2 = MarshRouteLayout.pad_point(PADS[index], index, level_number)
    var route_sign := -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    var level_phase := float(level_number * 17 + index * 31)
    var level_offset := Vector2(
        sin(level_phase * 0.19) * minf(34.0, 8.0 + float(level_number) * 0.28) * route_sign,
        cos(level_phase * 0.13) * minf(26.0, 6.0 + float(level_number) * 0.20)
    )
    var drift := float(level_profile.lily_drift)
    var motion := Vector2(
        sin(simulation_time * (0.22 + float(index % 3) * 0.035) + float(index)) * drift,
        cos(simulation_time * (0.18 + float(index % 2) * 0.04) + float(index) * 0.7) * drift * 0.55
    )
    return (base + level_offset + motion).clamp(Vector2(90, 155), Vector2(1190, 590))

func _bug_position(index: int) -> Vector2:
    var base: Vector2 = MarshRouteLayout.bug_point(BUGS[index], index, level_number)
    var route_sign := -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    var radius := float(level_profile.bug_flight_radius)
    var speed := float(level_profile.bug_flight_speed)
    var level_phase := float(level_number * 23 + index * 41)
    var level_offset := Vector2(sin(level_phase * 0.17) * 38.0 * route_sign, cos(level_phase * 0.11) * 25.0)
    var angle := simulation_time * speed * (1.0 if index % 2 == 0 else -1.0) * route_sign + float(index) * 2.1
    var flight := Vector2(cos(angle) * radius, sin(angle * 1.35) * radius * 0.72)
    return (base + level_offset + flight).clamp(Vector2(80, 145), Vector2(1200, 585))

func _active_predator_positions() -> Array[Vector2]:
    var positions: Array[Vector2] = [predator]
    var extra_count := maxi(0, int(level_profile.predator_count) - 1)
    for index in range(mini(extra_count, secondary_predators.size())):
        positions.append(secondary_predators[index])
    return positions

func _predator_depth_snapshot(index: int) -> Dictionary:
    if index < 0 or index >= PREDATOR_SPECIES.size():
        return PredatorDepth.snapshot("HERON", index, level_number, simulation_time)
    return PredatorDepth.snapshot(PREDATOR_SPECIES[index], index, level_number, simulation_time)

func _predator_can_hit(index: int) -> bool:
    return PredatorDepth.shares_depth(float(depth.depth), _predator_depth_snapshot(index))

func _predator_danger_message(index: int) -> String:
    var species := PREDATOR_SPECIES[index] if index >= 0 and index < PREDATOR_SPECIES.size() else "PREDATOR"
    var predator_snapshot := _predator_depth_snapshot(index)
    var location := "underwater" if float(predator_snapshot.depth) > 0.5 else "at the surface"
    return "[DANGER] A %s met Fred %s!" % [species.to_lower(), location]

func _leap_clears_predators() -> bool:
    # Leap is traversal, not a respawn action. While the arc is airborne Fred is
    # above surface predators; landing on one is still dangerous because the
    # traversal state has already changed to LANDING before collision checks.
    return leap.state == LeapTraversal.State.AIRBORNE

func _check_danger_collision() -> bool:
    if danger_cooldown_seconds > 0.0 or in_safe_location:
        return false
    var clears_predators := _leap_clears_predators()
    if not clears_predators and _predator_can_hit(0) and fred.distance_to(predator) < float(level_profile.danger_radius):
        if _try_golden_egg_predator_event():
            return true
        _apply_danger_hit(_predator_danger_message(0))
        return true
    if not hazards_enabled:
        return false
    var active_positions := _active_predator_positions()
    for index in range(1, active_positions.size()):
        var position: Vector2 = active_positions[index]
        if not clears_predators and _predator_can_hit(index) and fred.distance_to(position) < float(level_profile.danger_radius):
            if _try_golden_egg_predator_event():
                return true
            _apply_danger_hit(_predator_danger_message(index))
            return true
    for index in range(mini(int(level_profile.whirlpool_count), WHIRLPOOLS.size())):
        if fred.distance_to(_whirlpool_position(index)) < 50.0:
            _apply_danger_hit("[WHIRLPOOL] The current swept Fred back!")
            return true
    return false

func _apply_danger_hit(message: String) -> void:
    golden_run.note_death(message)
    impact_burst_origin = fred
    impact_burst_seconds = 0.62
    impact_burst_kind = "CURRENT BURST" if message.begins_with("[WHIRLPOOL]") else ("LANDING SPLASH" if message.begins_with("[LANDING]") else "PREDATOR BUMP")
    leap.reset()
    depth.reset("surface")
    tongue.reset()
    boost.cancel(session.boost_energy)
    session.set_underwater(false)
    var failed := session.damage()
    animation.trigger_damage(failed)
    if failed:
        danger_cooldown_seconds = 0.0
        countdown_seconds = 0.0
        touch_contacts.clear()
        touch_positions.clear()
        pointer_touch_active = false
        _refresh_touch_holds()
        _set_feedback("[OUT OF LIVES] " + message)
        screen = Screen.FAILED
        return
    fred = _checkpoint_respawn_position()
    _reset_camera()
    danger_cooldown_seconds = float(level_profile.mistake_grace_seconds)
    countdown_seconds = RESPAWN_COUNTDOWN_SECONDS if countdown_enabled else 0.0
    var recovery_point := "the midpoint checkpoint" if session.checkpoint_sequence > 0 else "this level's starting perch"
    _save("[LIFE LOST] %d lives remain. Fred returns to %s." % [session.health, recovery_point])

func direct_route_has_danger() -> bool:
    for step in range(1, 20):
        var point := _level_start_position().lerp(_level_exit_position(), float(step) / 20.0)
        for index in range(mini(int(level_profile.whirlpool_count), WHIRLPOOLS.size())):
            if point.distance_to(_whirlpool_position(index)) < 58.0:
                return true
    return false

func _request_leap(requested_direction: Vector2) -> bool:
    if screen != Screen.PLAYING or session.paused or depth.state != DepthTraversal.State.SURFACE:
        return false
    var accepted: bool = leap.request(requested_direction)
    if accepted:
        golden_run.note_valid_surface_jump(level_number, fred, last_aim_direction)
        _set_feedback("[LEAP] Fred sprang over the marsh!")
    return accepted

func _can_dive_here(position: Vector2) -> bool:
    if position.distance_to(_level_start_position()) < 62.0 or position.distance_to(_level_safe_position()) < float(level_profile.safe_radius) + 8.0:
        return false
    if position.distance_to(_level_exit_position()) < 52.0:
        return false
    for index in PADS.size():
        if position.distance_to(_pad_position(index)) < 44.0:
            return false
    return true

func _request_dive() -> bool:
    if screen != Screen.PLAYING or session.paused or leap.state != LeapTraversal.State.GROUNDED:
        return false
    var allowed := _can_dive_here(fred)
    var accepted: bool = depth.request_dive(allowed)
    if accepted:
        boost.cancel(session.boost_energy)
        golden_run.note_dive_started(level_number, fred, last_aim_direction)
        _set_feedback("[DIVING] Hold your course while Fred descends.")
    elif depth.state == DepthTraversal.State.SURFACE and not allowed:
        _set_feedback("[DIVE BLOCKED] Move into open water.")
    return accepted

func _request_surface() -> bool:
    if screen != Screen.PLAYING or session.paused or leap.state != LeapTraversal.State.GROUNDED:
        return false
    var accepted: bool = depth.request_surface(true)
    if accepted:
        boost.cancel(session.boost_energy)
        _set_feedback("[SURFACING] Fred is swimming toward the light.")
    return accepted

func _is_valid_landing(position: Vector2) -> bool:
    if position.distance_to(_level_start_position()) <= 78.0 or position.distance_to(_level_safe_position()) <= float(level_profile.safe_radius) + 16.0:
        return true
    if position.distance_to(_level_exit_position()) <= 58.0:
        return true
    for index in PADS.size():
        if position.distance_to(_pad_position(index)) <= 64.0:
            return true
    return false

func _resolve_landing() -> bool:
    if _is_valid_landing(fred):
        _set_feedback("[LANDING] Fred found a safe perch.")
    else:
        _set_feedback("[LANDING] Fred kept moving through the marsh.")
    return true

func _reveal_golden_egg() -> void:
    leap.reset()
    depth.reset("surface")
    tongue.reset()
    boost.cancel(session.boost_energy)
    session.set_underwater(false)
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    impact_burst_origin = fred
    impact_burst_seconds = 1.2
    impact_burst_kind = "MOONPETAL DISCOVERY"
    golden_reveal_seconds = 0.0
    golden_discovery_status = "pending"
    golden_privacy = "anonymous"
    var raw_id := Crypto.new().generate_random_bytes(16).hex_encode()
    var idempotency_key := "%s-%s-%s-%s-%s" % [raw_id.substr(0,8), raw_id.substr(8,4), raw_id.substr(12,4), raw_id.substr(16,4), raw_id.substr(20,12)]
    var staged: Dictionary = golden_discovery.stage_pending(golden_run.evidence(), idempotency_key)
    if not bool(staged.get("ok", false)):
        golden_discovery_status = "local_recovery_required"
    elif golden_production_network_enabled and golden_service.production_client_ready():
        var evidence_text := JSON.stringify(golden_run.evidence())
        if golden_network.start_submit(golden_service, evidence_text):
            golden_discovery_status = "submitting"
        else:
            golden_discovery_status = "pending"
    screen = Screen.GOLDEN_EGG
    if audio_enabled and is_instance_valid(golden_chime):
        golden_chime.play()
    _set_feedback("[GOLDEN DISCOVERY] Moonpetal magic has awakened!")
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    # Native touch and the desktop pointer already share one Fred input path.
    # Godot compatibility events would otherwise execute the same tap twice
    # (Pause immediately unpauses). Keep this guard even if an export overrides
    # the project's disabled mouse/touch emulation settings.
    if event.device == InputEvent.DEVICE_ID_EMULATION and (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag):
        return
    if event is InputEventScreenTouch:
        _handle_touch(event.index, event.position, event.pressed)
        return
    if event is InputEventScreenDrag:
        _move_touch(event.index, event.position)
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if touch_controls_visible:
            pointer_touch_active = event.pressed
            _handle_touch(-1, event.position, event.pressed)
        elif event.pressed:
            _handle_click(event.position)
        return
    if event is InputEventMouseMotion and pointer_touch_active and touch_controls_visible:
        _move_touch(-1, event.position)
        return
    if event is InputEventKey:
        return
    if device_intent_adapter_enabled and event.is_action_pressed("pause") and screen == Screen.PLAYING:
        _set_gameplay_paused(not session.paused)
    if device_intent_adapter_enabled and event.is_action_pressed("dive") and screen == Screen.PLAYING:
        _request_dive()
    if device_intent_adapter_enabled and event.is_action_pressed("surface") and screen == Screen.PLAYING:
        _request_surface()
    if device_intent_adapter_enabled and event.is_action_pressed("leap") and screen == Screen.PLAYING:
        _request_leap(FredInputIntent.movement())
    if device_intent_adapter_enabled and event.is_action_pressed("interact") and screen == Screen.PLAYING:
        _request_tongue(last_aim_direction)
    if device_intent_adapter_enabled and event.is_action_pressed("retry") and screen == Screen.FAILED: _retry()
    if device_intent_adapter_enabled and event.is_action_pressed("confirm"):
        if screen == Screen.TITLE: _open_story()
        elif screen == Screen.STORY: _open_instructions()
        elif screen == Screen.INSTRUCTIONS: _start()

func _set_gameplay_paused(paused: bool) -> void:
    if paused:
        golden_run.note_pause(level_number)
    session.paused = paused
    # Resuming must never revive a direction or Boost held before the overlay.
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    _fixed_accumulator = 0.0
    _set_feedback("[PAUSED] Your last checkpoint is safe." if paused else "[PLAYING] Adventure resumed.")

func _handle_touch(index: int, position: Vector2, pressed: bool) -> void:
    touch_controls_visible = true
    if not pressed:
        touch_contacts.erase(index)
        touch_positions.erase(index)
        _refresh_touch_holds()
        return
    if screen != Screen.PLAYING:
        _handle_click(position)
        return
    var action := _touch_action_at(position)
    if action.is_empty():
        return
    if session.paused and action not in ["pause", "home"]:
        return
    touch_contacts[index] = action
    if action == "steer":
        touch_positions[index] = MarshRouteLayout.clamp_touch_target(position)
    _refresh_touch_holds()
    match action:
        "tongue":
            _request_tongue(last_aim_direction)
        "leap":
            _request_leap(touch_movement if touch_movement != Vector2.ZERO else last_aim_direction)
        "depth":
            if depth.state == DepthTraversal.State.SURFACE:
                _request_dive()
            else:
                _request_surface()
        "pause":
            _set_gameplay_paused(not session.paused)
        "home":
            _go_home()

func _move_touch(index: int, position: Vector2) -> void:
    if not touch_contacts.has(index):
        return
    var original_action := str(touch_contacts[index])
    if original_action == "steer":
        touch_positions[index] = MarshRouteLayout.clamp_touch_target(position)
    else:
        touch_contacts[index] = original_action if _touch_action_at(position) == original_action else ""
    _refresh_touch_holds()

func _touch_action_at(position: Vector2) -> String:
    return MarshRouteLayout.touch_action_at(position, screen == Screen.PLAYING and session.paused)

func _refresh_touch_holds() -> void:
    touch_movement = Vector2.ZERO
    touch_boost = false
    var steering_index := 2147483647
    for raw_index: Variant in touch_contacts:
        var value := str(touch_contacts[raw_index])
        if value == "boost":
            touch_boost = true
        elif value == "steer" and int(raw_index) < steering_index and touch_positions.has(raw_index):
            steering_index = int(raw_index)
    if steering_index != 2147483647:
        var target := Vector2(touch_positions[steering_index])
        touch_movement = MarshRouteLayout.touch_movement_vector(target)

func _handle_click(position: Vector2) -> void:
    if screen == Screen.TITLE and TITLE_START_RECT.has_point(position): _open_story()
    elif screen == Screen.TITLE and TITLE_CUSTOMIZE_RECT.has_point(position):
        _reset_wardrobe_selection()
        screen = Screen.CUSTOMIZE; _sync_music(); queue_redraw()
    elif screen == Screen.TITLE and TITLE_LEADERBOARD_RECT.has_point(position):
        screen = Screen.LEADERBOARD; _sync_music(); queue_redraw()
    elif screen == Screen.STORY and STORY_HOME_RECT.has_point(position): _go_home()
    elif screen == Screen.STORY and STORY_CONTINUE_RECT.has_point(position): _open_instructions()
    elif screen == Screen.INSTRUCTIONS and INSTRUCTIONS_HOME_RECT.has_point(position): _go_home()
    elif screen == Screen.INSTRUCTIONS and INSTRUCTIONS_PLAY_RECT.has_point(position): _start()
    elif screen == Screen.CUSTOMIZE and CUSTOM_HOME_RECT.has_point(position): _go_home()
    elif screen == Screen.CUSTOMIZE:
        _handle_wardrobe_click(position)
    elif screen == Screen.PLAYING and MarshRouteLayout.PAUSE_RECT.has_point(position):
        _set_gameplay_paused(not session.paused)
    elif screen == Screen.PLAYING and MarshRouteLayout.HOME_RECT.has_point(position):
        _go_home()
    elif screen == Screen.PLAYING and session.paused and MarshRouteLayout.PAUSED_RESUME_RECT.has_point(position):
        _set_gameplay_paused(false)
    elif screen == Screen.PLAYING:
        _request_leap(position - fred)
    elif screen == Screen.FAILED and Rect2(365,500,250,64).has_point(position): _retry()
    elif screen == Screen.FAILED and Rect2(665,500,250,64).has_point(position): _go_home()
    elif screen == Screen.LEADERBOARD and LEADERBOARD_GAME_CENTER_RECT.has_point(position) and _game_center_available():
        if game_center.is_authenticated():
            if game_center.has_method("can_show_leaderboards") and not game_center.can_show_leaderboards():
                game_center_status = "GAME CENTER IS ALREADY OPEN — PLEASE WAIT"
                queue_redraw()
            elif not game_center.show_leaderboards():
                game_center_status = "GAME CENTER COULD NOT OPEN — TAP TO RETRY"
                queue_redraw()
            else:
                game_center_status = "OPENING GAME CENTER"
                queue_redraw()
        else:
            _request_game_center_connection()
    elif screen == Screen.LEADERBOARD and (LEADERBOARD_HOME_SPLIT_RECT if _game_center_available() else LEADERBOARD_HOME_CENTER_RECT).has_point(position): _go_home()
    elif screen == Screen.COMPLETE and Rect2(490,500,300,60).has_point(position):
        _advance_level()
    elif screen == Screen.GOLDEN_EGG and GOLDEN_EGG_PRIVATE_RECT.has_point(position):
        golden_privacy = "anonymous"
        golden_discovery.set_privacy("anonymous")
        if golden_service.has_canonical_discovery() and not golden_network.is_busy():
            golden_network.start_privacy(golden_service, false, "")
            golden_discovery_status = "saving_privacy"
        _set_feedback("[PRIVATE] Your discovery stays anonymous.")
    elif screen == Screen.GOLDEN_EGG and GOLDEN_EGG_PUBLIC_RECT.has_point(position):
        var game_center_name: String = str(golden_service.game_center_display_name())
        if game_center_name.is_empty():
            golden_privacy = "anonymous"
            _request_game_center_connection()
            _set_feedback("[DISCOVERY SAFE] Sign in to Game Center to show your Game Center name, or stay Anonymous.")
        else:
            golden_privacy = "public"
            golden_discovery.set_privacy("public", game_center_name)
            if golden_service.has_canonical_discovery() and not golden_network.is_busy():
                golden_network.start_privacy(golden_service, true, "")
                golden_discovery_status = "saving_privacy"
            _set_feedback("[SHARE READY] Your Game Center name may appear after secure confirmation.")
    elif screen == Screen.GOLDEN_EGG and GOLDEN_EGG_HUNT_RECT.has_point(position):
        _open_golden_egg_hunt()
    elif screen == Screen.GOLDEN_EGG and GOLDEN_EGG_RETURN_RECT.has_point(position):
        _return_to_level_five()

func _golden_egg_hunt_url() -> String:
    return GoldenEggClient.BASE_URL + GoldenEggClient.HUNT_PATH

func _open_golden_egg_hunt() -> void:
    var open_result := OS.shell_open(_golden_egg_hunt_url())
    if open_result == OK:
        _set_feedback("[GOLDEN EGG HUNT] The official App Vault hunt opened in your browser.")
    else:
        _set_feedback("[HUNT LINK] Visit theflinsappvaultllc.com/golden-eggs.")

func _on_golden_network_operation_completed(operation: String, result: Dictionary) -> void:
    if operation in ["submit", "retry"]:
        if bool(result.get("success", false)):
            golden_discovery_status = "accepted"
            if golden_privacy == "public":
                if golden_network.start_privacy(golden_service, true, ""):
                    golden_discovery_status = "saving_privacy"
            elif golden_network.start_privacy(golden_service, false, ""):
                golden_discovery_status = "saving_privacy"
        else:
            golden_discovery_status = "pending"
    elif operation.begins_with("privacy_"):
        golden_discovery_status = "privacy_saved" if bool(result.get("success", false)) else "pending"
    queue_redraw()

func _return_to_level_five() -> void:
    level_number = GoldenEggRunState.TARGET_LEVEL
    level_profile = FredLevelIntensity.profile(level_number)
    session = AdventureSession.new(1337 + level_number)
    fred = _level_start_position()
    predator = _route_point(PREDATOR_START)
    predator_direction = -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    collected.clear()
    fairy_collected = false
    golden_room_open = false
    leap.reset()
    depth.reset("surface")
    tongue.reset()
    boost.reset()
    animation.reset()
    session.set_underwater(false)
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    simulation_time = 0.0
    danger_cooldown_seconds = 0.0
    impact_burst_seconds = 0.0
    countdown_seconds = 5.0 if countdown_enabled else 0.0
    last_aim_direction = MarshRouteLayout.route_direction(level_number)
    _reset_camera()
    screen = Screen.PLAYING
    _sync_music()
    _set_feedback("[LEVEL 5] Fred returned to the beginning of the marsh route.")
    queue_redraw()

func _open_story() -> void:
    screen = Screen.STORY
    _sync_music()
    _set_feedback("[HERO STORY] Learn why Fred must cross Moonpetal Marsh.")
    queue_redraw()

func _open_instructions() -> void:
    screen = Screen.INSTRUCTIONS
    _sync_music()
    _set_feedback("[HOW TO PLAY] Learn the hero moves, then begin.")
    queue_redraw()

func _start() -> void:
    if session.completed:
        level_number = 1
        level_profile = FredLevelIntensity.profile(1)
        session = AdventureSession.new(1337)
        _set_feedback("[NEW GAME] A fresh Lily Leap run is ready.")
    screen = Screen.PLAYING
    if level_number == 1:
        golden_run.begin_level_one()
    countdown_seconds = 5.0 if countdown_enabled else 0.0
    fairy_collected = false
    tongue.reset()
    boost.reset()
    animation.reset()
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    _sync_music()
    fred = _checkpoint_respawn_position()
    last_aim_direction = MarshRouteLayout.route_direction(level_number)
    _reset_camera()
    collected.clear()
    for index in range(mini(session.bug_count, BUGS.size())): collected.append(index)
    queue_redraw()

func _retry() -> void:
    level_number = 1
    level_profile = FredLevelIntensity.profile(1)
    session = AdventureSession.new(1337)
    leap.reset()
    depth.reset("surface")
    tongue.reset()
    boost.reset()
    animation.reset()
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    session.set_underwater(false)
    fred = _level_start_position()
    last_aim_direction = MarshRouteLayout.route_direction(level_number)
    _reset_camera()
    predator = _route_point(PREDATOR_START)
    predator_direction = -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    collected.clear()
    fairy_collected = false
    countdown_seconds = 5.0 if countdown_enabled else 0.0
    screen = Screen.PLAYING
    golden_run.begin_level_one()
    _sync_music()
    _set_feedback("[TRY AGAIN] Level 1 is ready.")

func _go_home() -> void:
    var leaving_gameplay := screen in [Screen.PLAYING, Screen.FAILED, Screen.COMPLETE, Screen.GOLDEN_EGG]
    leap.reset()
    depth.reset("surface")
    tongue.reset()
    boost.reset()
    animation.reset()
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    countdown_seconds = 0.0
    if leaving_gameplay:
        golden_run.note_run_abandoned()
        level_number = 1
        level_profile = FredLevelIntensity.profile(1)
        session = AdventureSession.new(1337)
        fred = _level_start_position()
        predator = _route_point(PREDATOR_START)
        collected.clear()
        fairy_collected = false
        danger_cooldown_seconds = 0.0
        simulation_time = 0.0
        saver.save(session, Time.get_datetime_string_from_system(true, true))
    screen = Screen.TITLE
    _reset_camera()
    _sync_music()
    _set_feedback("[HOME] Welcome back to Moonpetal Marsh.")

func _sync_fred_style() -> void:
    if is_instance_valid(fred_rig) and fred_rig.has_method("apply_style"):
        fred_rig.apply_style(customization.current_style())

func _reset_wardrobe_selection() -> void:
    wardrobe_item = str(customization.selected[wardrobe_category])
    wardrobe_page = 0
    var entries := Wardrobe.entries(customization,wardrobe_category,wardrobe_owned_only)
    for index in entries.size():
        if str(entries[index].id) == wardrobe_item:
            wardrobe_page = index / Wardrobe.PAGE_SIZE

func _handle_wardrobe_click(position: Vector2) -> void:
    for category: String in Wardrobe.TABS:
        if Rect2(Wardrobe.TABS[category]).has_point(position):
            wardrobe_category = category
            _reset_wardrobe_selection()
            queue_redraw()
            return
    if Wardrobe.FILTER.has_point(position):
        wardrobe_owned_only = not wardrobe_owned_only
        _reset_wardrobe_selection()
    elif Wardrobe.PREVIOUS.has_point(position) or Wardrobe.NEXT.has_point(position):
        var entries := Wardrobe.entries(customization,wardrobe_category,wardrobe_owned_only)
        var direction := -1 if Wardrobe.PREVIOUS.has_point(position) else 1
        wardrobe_page = posmod(wardrobe_page+direction,Wardrobe.pages(entries.size()))
    elif Wardrobe.APPLY.has_point(position):
        var item_id := wardrobe_item if not wardrobe_item.is_empty() else str(customization.selected[wardrobe_category])
        var result: Dictionary = customization.purchase_and_equip(wardrobe_category,item_id)
        if bool(result.get("ok",false)):
            _sync_fred_style()
            _set_feedback("[EQUIPPED] %s. Yours to wear anytime!" % str(result.label))
        elif str(result.get("reason","")) == "need_coins":
            _set_feedback("[NEED %d MORE COINS] Preview is free. Your outfit has not changed." % maxi(0,int(result.cost)-int(customization.coins)))
        else:
            _set_feedback("[NOT SAVED] No coins spent. Please try again.")
    else:
        var entries := Wardrobe.entries(customization,wardrobe_category,wardrobe_owned_only)
        for slot in Wardrobe.PAGE_SIZE:
            var index := wardrobe_page*Wardrobe.PAGE_SIZE+slot
            if index < entries.size() and Wardrobe.card(slot).has_point(position):
                wardrobe_item = str(entries[index].id)
                break
    queue_redraw()

func _try_golden_egg_predator_event() -> bool:
    return false

func _advance_level() -> void:
    if level_number >= FredLevelIntensity.MAX_LEVEL:
        _go_home()
        _set_feedback("[CAMPAIGN 1 COMPLETE] Fred is the hero in every little frog's dreams!")
        return
    var carried_lives := session.health
    var carried_energy := session.boost_energy
    golden_run.advance_level(level_number, level_number + 1)
    golden_room_open = false
    level_number = mini(FredLevelIntensity.MAX_LEVEL, level_number + 1)
    level_profile = FredLevelIntensity.profile(level_number)
    session = AdventureSession.new(1337 + level_number)
    session.health = clampi(carried_lives, 1, AdventureSession.MAX_LIVES)
    session.boost_energy = clampi(carried_energy, 0, 100)
    fred = _level_start_position()
    last_aim_direction = MarshRouteLayout.route_direction(level_number)
    predator = _route_point(PREDATOR_START + Vector2(-25.0 * float((level_number - 1) % 4), 0))
    predator_direction = -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    collected.clear()
    eat_effect_seconds = 0.0
    simulation_time = 0.0
    danger_cooldown_seconds = 0.0
    impact_burst_seconds = 0.0
    leap.reset()
    depth.reset("surface")
    tongue.reset()
    boost.reset()
    animation.reset()
    touch_contacts.clear()
    touch_positions.clear()
    pointer_touch_active = false
    _refresh_touch_holds()
    fairy_collected = false
    countdown_seconds = 5.0 if countdown_enabled else 0.0
    _reset_camera()
    screen = Screen.PLAYING
    depth.reset(session.player_state)
    _sync_music()
    _set_feedback("[NEW TWIST] %s" % str(level_profile.new_twist))

func _save(message: String) -> void:
    var timestamp := Time.get_datetime_string_from_system(true, true)
    var result := saver.save(session, timestamp)
    _set_feedback(FredSaveFeedback.save_message(result, message))

func _set_feedback(message: String) -> void:
    save_feedback = message
    save_feedback_seconds = FredSaveFeedback.DISPLAY_SECONDS
    queue_redraw()

func _apply_boost_event(event: String) -> void:
    match event:
        "started":
            _set_feedback("[BOOST BURST] Fred surges forward!")
        "sustain":
            _set_feedback("[BOOST] Hold your course while energy drains.")
        "exhausted":
            _set_feedback("[BOOST EXHAUSTED] Let Fred catch his breath, then boost again.")
        "ready":
            _set_feedback("[BOOST READY] Fred has full marsh energy.")

func _update_camera(direction: Vector2, boost_active: bool) -> void:
    var tongue_vector := Vector2.ZERO
    if tongue.is_busy():
        tongue_vector = tongue.target_point - fred
    var boost_strength := 0.0
    if boost_active:
        boost_strength = 1.0 if boost.state == BoostLocomotion.State.BURST else 0.65
    var viewport_size := Vector2i(1280,720)
    if is_inside_tree():
        viewport_size = get_window().size
    var camera_step: Dictionary = camera_follow.advance(
        fred,
        direction,
        leap.visual_height,
        depth.depth,
        boost_strength,
        tongue_vector,
        tongue.is_busy(),
        reduced_motion,
        viewport_size
    )
    camera_offset = Vector2(camera_step.offset)
    camera_response_y = camera_offset.y

func _update_animation(direction: Vector2) -> void:
    animation.advance({
        "movement": direction,
        "moving": direction != Vector2.ZERO,
        "on_perch": _is_valid_landing(fred),
        "leap_state": leap.state,
        "leap_elapsed": leap.elapsed,
        "depth_state": depth.state,
        "depth_amount": depth.depth,
        "tongue_state": tongue.state,
        "tongue_elapsed": tongue.elapsed,
        "boost_state": boost.state,
        "invulnerable": danger_cooldown_seconds > 0.0,
        "failed": screen == Screen.FAILED,
    }, false, reduced_motion)

func _reset_camera() -> void:
    camera_follow.reset()
    camera_offset = Vector2.ZERO
    camera_response_y = 0.0

func _tick_feedback(delta: float) -> void:
    if save_feedback_seconds <= 0.0:
        return
    save_feedback_seconds = maxf(0.0, save_feedback_seconds - delta)
    if is_zero_approx(save_feedback_seconds):
        save_feedback = FredSaveFeedback.NEUTRAL
        queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720), Color("071d2d"))
    if screen == Screen.TITLE: _draw_title(); return
    if screen == Screen.STORY: _draw_story(); return
    if screen == Screen.INSTRUCTIONS: _draw_instructions(); return
    if screen == Screen.LEADERBOARD: _draw_leaderboard(); return
    if screen == Screen.CUSTOMIZE: _draw_customizer(); return
    if screen == Screen.GOLDEN_EGG: _draw_golden_egg_reveal(); return
    _draw_level()
    if screen == Screen.FAILED: _draw_failure()
    elif screen == Screen.COMPLETE:
        if level_number >= FredLevelIntensity.MAX_LEVEL:
            _draw_overlay("Campaign 1 Complete!", "Fred is the hero in every little frog's dreams!", "Celebrate at Home", Rect2(490,500,300,60), "100 / 100")
        else:
            _draw_overlay("Lily Leap Complete!", "Level %03d is ready." % (level_number + 1), "Next Level", Rect2(490,500,300,60), "LEVEL CLEAR")
    elif session.paused: _draw_overlay("Marsh Paused", "Your checkpoint is safe.", "Resume", MarshRouteLayout.PAUSED_RESUME_RECT, "PAUSED")
    elif countdown_seconds > 0.0: _draw_countdown()

func _draw_golden_egg_reveal() -> void:
    var pulse := 0.0 if reduced_motion else sin(golden_reveal_seconds * 2.4) * 5.0
    draw_texture_rect(gameplay_art, Rect2(0,0,1280,720), false, Color(0.36,0.44,0.38,1.0))
    draw_rect(Rect2(0,0,1280,720), Color(0.005,0.018,0.035,0.82), true)
    for ring in range(6):
        var radius := 88.0 + float(ring) * 34.0 + pulse
        draw_arc(Vector2(640,330), radius, 0.0, TAU, 72, Color(1.0,0.78,0.24,0.19-float(ring)*0.022), 4.0)
    for index in range(30):
        var angle := float(index) * TAU / 30.0 + (0.0 if reduced_motion else golden_reveal_seconds * (0.06 + float(index % 3) * 0.02))
        var distance := 125.0 + float((index * 37) % 150)
        var sparkle := Vector2(640,330) + Vector2.from_angle(angle) * distance
        draw_circle(sparkle, 2.5 + float(index % 4), Color(1.0,0.84,0.34,0.48 + float(index % 3) * 0.12))
    _draw_canonical_golden_egg(Vector2(640,330),1.0+pulse/350.0)
    _text(Vector2(640,60),"A SECRET OF MOONPETAL MARSH!",36,Color("ffe184"),HORIZONTAL_ALIGNMENT_CENTER,1080)
    _text(Vector2(640,108),"You found one of the hidden Golden Eggs.",25,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,920)
    _text(Vector2(640,486),"Your place is confirmed only by the secure App Vault service.",17,Color("d9f4e2"),HORIZONTAL_ALIGNMENT_CENTER,880)
    var status_messages := {
        "submitting": "SECURELY REGISTERING YOUR DISCOVERY…",
        "accepted": "DISCOVERY REGISTERED ON THE APP VAULT LEADERBOARD",
        "saving_privacy": "SAVING YOUR LEADERBOARD DISPLAY CHOICE…",
        "privacy_saved": "LEADERBOARD DISPLAY CHOICE SAVED",
        "pending": "DISCOVERY SAFELY QUEUED — IT WILL RETRY AUTOMATICALLY",
    }
    var status_text := str(status_messages.get(golden_discovery_status, "DISCOVERY SAVED LOCALLY — SECURE CONNECTION REQUIRED"))
    _text(Vector2(640,516),status_text,14,Color("b9f5c7"),HORIZONTAL_ALIGNMENT_CENTER,960)
    _text(Vector2(640,542),"Choose whether your marsh name may appear publicly. Anonymous is the default.",14,Color("d9f4e2"),HORIZONTAL_ALIGNMENT_CENTER,980)
    _button(GOLDEN_EGG_PRIVATE_RECT,"KEEP ME ANONYMOUS" if golden_privacy != "anonymous" else "ANONYMOUS ✓")
    _button(GOLDEN_EGG_PUBLIC_RECT,"SHARE MY MARSH NAME" if golden_privacy != "public" else "PUBLIC NAME ✓")
    _button(GOLDEN_EGG_HUNT_RECT,"OPEN GOLDEN EGG HUNT")
    _button(GOLDEN_EGG_RETURN_RECT,"RETURN TO LEVEL 5")
    _text(Vector2(640,705),"The App Vault service records the official rank and time.",12,Color("9ec8cf"),HORIZONTAL_ALIGNMENT_CENTER,800)

func _draw_title() -> void:
    draw_texture_rect(title_art, Rect2(0,0,1280,720), false)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,0),Vector2(635,0),Vector2(555,720),Vector2(0,720)
    ]), Color(0.005,0.025,0.05,0.86))
    draw_line(Vector2(635,0),Vector2(555,720),Color(0.45,0.94,0.80,0.58),4)
    _text(Vector2(285,70), "FRED MYERS", 52, Color("ffe184"), HORIZONTAL_ALIGNMENT_CENTER, 500)
    _text(Vector2(285,120), "and the Moonpetal Marsh", 27, Color("edfdf5"), HORIZONTAL_ALIGNMENT_CENTER, 500)
    _text(Vector2(285,166), "CAMPAIGN 1  •  100 LEVELS  •  PG FAMILY ADVENTURE", 14, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_CENTER, 500)
    draw_rect(Rect2(72,205,426,155),Color(0.02,0.10,0.14,0.76),true)
    draw_rect(Rect2(72,205,426,155),Color("70d6c2"),false,3)
    _text(Vector2(285,242), "RUN • LEAP • DIVE", 23, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 390)
    _text(Vector2(285,281), "MUNCH • DODGE • POWER UP", 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 390)
    _text(Vector2(285,326), "Be the hero in every little frog's dreams.", 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 390)
    _button(TITLE_START_RECT, "BEGIN FRED'S STORY")
    _button(TITLE_CUSTOMIZE_RECT, "CUSTOMIZE FRED  •  %d COINS" % customization.coins)
    _button(TITLE_LEADERBOARD_RECT, "MARSH LEADERBOARDS")
    _status_panel(Rect2(70,640,440,42), 14)
    _text(Vector2(285,708), "THE MARSHLAND MARCH  •  PLAY INSTANTLY  •  ACCOUNT OPTIONAL", 11, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_CENTER, 520)

func _draw_story() -> void:
    draw_texture_rect(title_art, Rect2(0,0,1280,720), false, Color(0.42,0.58,0.54,1.0))
    draw_rect(Rect2(0,0,1280,720), Color(0.005,0.025,0.05,0.82), true)
    draw_circle(Vector2(1120,92), 68.0, Color(0.95,0.88,0.48,0.13))
    draw_circle(Vector2(1120,92), 45.0, Color(0.94,0.95,0.75,0.28))
    _text(Vector2(640,58), "THE MOONPETAL PROMISE", 40, Color("ffe184"), HORIZONTAL_ALIGNMENT_CENTER, 1050)
    _text(Vector2(640,98), "WHY FRED LEAPS, DIVES, MUNCHES, AND NEVER GIVES UP", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_CENTER, 1030)
    _draw_story_card(Rect2(55,125,360,380), "THE LITTLE FROGS' DREAM", [
        "Every little frog dreams of",
        "a safe, glowing marsh and the",
        "legendary Moonpetal beyond it.",
    ], Color("76dcb0"), 0)
    _draw_story_card(Rect2(460,125,360,380), "THE MARSH IN TROUBLE", [
        "Wild currents, sneaky predators,",
        "and scattered bugs have broken",
        "the safe lily paths apart.",
    ], Color("ef9b57"), 1)
    _draw_story_card(Rect2(865,125,360,380), "FRED'S HERO PROMISE", [
        "Fred will cross all 100 levels,",
        "protect the smaller frogs, and",
        "carry their hope to the Moonpetal.",
    ], Color("e7c65d"), 2)
    _text(Vector2(640,558), "BECOME THE FROG HERO OF EVERY LITTLE FROG'S DREAMS", 23, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 1110)
    _text(Vector2(640,595), "Gather bugs. Outsmart danger. Bring courage home.", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 900)
    _button(STORY_HOME_RECT, "HOME")
    _button(STORY_CONTINUE_RECT, "SHOW ME HOW TO PLAY")

func _draw_story_card(rect: Rect2, title: String, lines: Array[String], accent: Color, icon: int) -> void:
    draw_rect(Rect2(rect.position + Vector2(0,8),rect.size), Color(0,0,0,0.46), true)
    draw_rect(rect, Color(0.015,0.085,0.12,0.96), true)
    draw_rect(rect, accent, false, 3.0)
    var icon_center := Vector2(rect.get_center().x, rect.position.y + 64.0)
    draw_circle(icon_center, 35.0, Color(accent,0.16))
    draw_circle(icon_center, 24.0, Color(accent,0.34))
    match icon:
        0:
            draw_circle(icon_center, 10.0, Color("fff0ae"))
            for angle in range(0,360,72):
                var ray := Vector2.from_angle(deg_to_rad(float(angle)))
                draw_line(icon_center + ray * 15.0, icon_center + ray * 28.0, Color("fff0ae"), 3.0)
        1:
            for radius in [10.0,18.0,27.0]:
                draw_arc(icon_center, radius, 0.2, TAU - 0.4, 22, Color("d8f4ff"), 3.0)
        _:
            draw_circle(icon_center + Vector2(-11,-4), 10.0, Color("79c86c"))
            draw_circle(icon_center + Vector2(11,-4), 10.0, Color("79c86c"))
            draw_colored_polygon(PackedVector2Array([icon_center+Vector2(-20,2),icon_center+Vector2(20,2),icon_center+Vector2(13,22),icon_center+Vector2(-13,22)]),Color("59ad59"))
            draw_circle(icon_center + Vector2(-10,-6), 3.0, Color("071d2d"))
            draw_circle(icon_center + Vector2(10,-6), 3.0, Color("071d2d"))
    _text(Vector2(rect.get_center().x,rect.position.y+132),title,20,accent,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-24.0)
    for index in lines.size():
        _text(Vector2(rect.get_center().x,rect.position.y+190.0+float(index)*42.0),str(lines[index]),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-30.0)

func _draw_instructions() -> void:
    draw_texture_rect(gameplay_art, Rect2(0,0,1280,720), false, Color(0.56,0.68,0.64,1.0))
    draw_rect(Rect2(0,0,1280,720), Color(0.005,0.025,0.05,0.78), true)
    _text(Vector2(640,55), "HOW TO BE A MARSH HERO", 40, Color("ffe184"), HORIZONTAL_ALIGNMENT_CENTER, 1050)
    _text(Vector2(640,93), "Guide Fred with the right control pad. Use the left action wheel when he needs it.", 17, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 1050)
    _draw_instruction_card(Rect2(55,120,370,145), "RIGHT CONTROL PAD", ["Slide in any direction", "to guide Fred."], Color("70d6c2"))
    _draw_instruction_card(Rect2(455,120,370,145), "MUNCH", ["Eat nearby bugs.", "Fairies can add a life."], Color("e67b4a"))
    _draw_instruction_card(Rect2(855,120,370,145), "LEAP", ["Jump over predators.", "Land and keep moving."], Color("67c96f"))
    _draw_instruction_card(Rect2(55,295,370,145), "BOOST", ["Hold for a quick burst.", "Rest while energy refills."], Color("e4b943"))
    _draw_instruction_card(Rect2(455,295,370,145), "DIVE / SURFACE", ["Explore above and below", "the Moonpetal water."], Color("4d9fd8"))
    _draw_instruction_card(Rect2(855,295,370,145), "STAY SAFE", ["Dive under surface predators.", "Bubbles mean danger is underwater."], Color("d984ad"))
    draw_rect(Rect2(100,475,1080,112), Color(0.015,0.085,0.12,0.96), true)
    draw_rect(Rect2(100,475,1080,112), Color("fff0ae"), false, 3.0)
    _text(Vector2(640,510), "YOUR HERO MISSION", 19, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 900)
    _text(Vector2(640,544), "MUNCH 3 BUGS  •  REACH THE MOONPETAL  •  EARN COINS  •  CUSTOMIZE FRED", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1000)
    _text(Vector2(640,574), "Start with 3 lives. Every 10th level hides a fairy that can add one more.", 14, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 980)
    _button(INSTRUCTIONS_HOME_RECT, "HOME")
    _button(INSTRUCTIONS_PLAY_RECT, "I'M READY — START LEVEL 1")

func _draw_instruction_card(rect: Rect2, title: String, lines: Array[String], accent: Color) -> void:
    draw_rect(Rect2(rect.position + Vector2(0,6),rect.size),Color(0,0,0,0.42),true)
    draw_rect(rect,Color(0.015,0.085,0.12,0.95),true)
    draw_rect(rect,accent,false,3.0)
    draw_circle(rect.position + Vector2(32,32),10.0,accent)
    _text(Vector2(rect.get_center().x,rect.position.y+38),title,19,accent,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-28.0)
    for index in lines.size():
        _text(Vector2(rect.get_center().x,rect.position.y+88.0+float(index)*29.0),str(lines[index]),15,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-26.0)

func _draw_customizer() -> void:
    draw_texture_rect(title_art, Rect2(0,0,1280,720), false, Color(0.45,0.62,0.60,1.0))
    draw_rect(Rect2(0,0,1280,720), Color(0.005,0.025,0.05,0.84), true)
    _text(Vector2(52,58), "FRED'S HERO WARDROBE", 36, Color("ffe184"), HORIZONTAL_ALIGNMENT_LEFT, 880)
    _text(Vector2(52,102), "Preview freely. Buy once. Wear again anytime.", 19, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_LEFT, 680)
    _text(Vector2(Wardrobe.COINS.get_center().x,53), "%d COINS" % customization.coins, 24, Color("fff0ae"), HORIZONTAL_ALIGNMENT_RIGHT, Wardrobe.COINS.size.x)
    _button(Wardrobe.FILTER,"OWNED ONLY: " + ("ON" if wardrobe_owned_only else "OFF"))
    for category: String in Wardrobe.TABS:
        var tab := Rect2(Wardrobe.TABS[category])
        draw_rect(tab,Color("206052") if category == wardrobe_category else Color("102b38"))
        draw_rect(tab,Color("ffe184") if category == wardrobe_category else Color("568b8a"),false,2)
        _text(Vector2(tab.get_center().x,tab.position.y+32),str(Wardrobe.HEADINGS[category]),15,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,tab.size.x-12)
    var item_id := wardrobe_item if not wardrobe_item.is_empty() else str(customization.selected[wardrobe_category])
    var entries := Wardrobe.entries(customization,wardrobe_category,wardrobe_owned_only)
    for slot in Wardrobe.PAGE_SIZE:
        var index := wardrobe_page*Wardrobe.PAGE_SIZE+slot
        if index >= entries.size(): break
        var entry: Dictionary = entries[index]
        var card := Wardrobe.card(slot)
        var is_owned: bool = customization.owns(wardrobe_category,str(entry.id))
        var equipped := str(customization.selected[wardrobe_category]) == str(entry.id)
        var previewing := item_id == str(entry.id)
        draw_rect(card,Color("194c45") if previewing else Color("102b38"))
        draw_rect(card,Color("ffe184") if previewing else Color("467b79"),false,3 if previewing else 1)
        var swatch_center := card.position+Vector2(26,30)
        var swatch := Color(str(entry.value)) if wardrobe_category in ["body","tongue"] else Color("77c6a0")
        draw_circle(swatch_center,10,swatch)
        draw_circle(swatch_center,10,Color("fff0ae"),false,1.5)
        _text(card.position+Vector2(47,36),"EQUIPPED" if equipped else ("OWNED" if is_owned else "%d COINS" % int(entry.cost)),14,Color("fff0ae"),HORIZONTAL_ALIGNMENT_LEFT,card.size.x-56)
        _text(Vector2(card.get_center().x,card.position.y+78),str(entry.label),19,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,card.size.x-20)
        _text(Vector2(card.get_center().x,card.position.y+116),"PREVIEWING" if previewing else "TAP TO PREVIEW",13,Color("b9d7d4"),HORIZONTAL_ALIGNMENT_CENTER,card.size.x-18)
    _button(Wardrobe.PREVIOUS,"<")
    _button(Wardrobe.NEXT,">")
    _text(Vector2(856,562),"PAGE %d / %d   •   %d CHOICES" % [wardrobe_page+1,Wardrobe.pages(entries.size()),entries.size()],16,Color("d9f4e2"),HORIZONTAL_ALIGNMENT_CENTER,490)
    draw_circle(CUSTOM_PREVIEW_ORIGIN,150,Color(0.2,0.75,0.55,0.10))
    draw_circle(CUSTOM_PREVIEW_ORIGIN,120,Color(0.95,0.84,0.30,0.07))
    fred_rig.apply_style(customization.preview_style(wardrobe_category,item_id))
    fred_rig.apply_pose(animation.pose(),0.0)
    draw_set_transform(CUSTOM_PREVIEW_ORIGIN,0.0,Vector2.ONE*CUSTOM_PREVIEW_SCALE)
    fred_rig.render_to(self,Vector2.ZERO)
    draw_set_transform(Vector2.ZERO)
    var choice: Dictionary = customization.entry_for(wardrobe_category,item_id)
    _text(Vector2(258,566),str(choice.get("label","Fred")),24,Color("ffe184"),HORIZONTAL_ALIGNMENT_CENTER,410)
    _text(Vector2(258,596),"Mix any hero, build, color and outfit.",16,Color("d9f4e2"),HORIZONTAL_ALIGNMENT_CENTER,416)
    var owned_choice: bool = customization.owns(wardrobe_category,item_id)
    var wearing := str(customization.selected[wardrobe_category]) == item_id
    var action := "EQUIPPED" if wearing else ("EQUIP — FREE" if owned_choice else "BUY & EQUIP — %d COINS" % int(choice.get("cost",0)))
    _button(Wardrobe.APPLY,action)
    _text(Vector2(856,690),save_feedback if save_feedback_seconds > 0 else "Looks only: no changes to speed, collision or difficulty.",14,Color("d9f4e2"),HORIZONTAL_ALIGNMENT_CENTER,740)
    _button(CUSTOM_HOME_RECT,"RETURN HOME")
    # Restore the equipped look so a discarded preview cannot leak into gameplay.
    _sync_fred_style()

func _draw_title_legacy() -> void:
    var visual := FredVisualState.snapshot(visual_time, reduced_motion)
    draw_rect(Rect2(0,0,1280,720), Color("03141f"), true)
    draw_circle(Vector2(1030,135), 96, Color(0.86,0.93,0.72,0.12))
    draw_circle(Vector2(1030,135), 72, Color("d8e7bb"))
    draw_circle(Vector2(1005,115), 13, Color("b9c9a4"))
    draw_circle(Vector2(1055,153), 9, Color("b9c9a4"))
    for index in range(34):
        var firefly := Vector2(35 + (index * 137) % 1210, 85 + (index * 83) % 500)
        var glow := 2.0 + float(index % 3)
        draw_circle(firefly, glow * 3.0, Color(0.95,0.88,0.38,0.06))
        draw_circle(firefly, glow, Color("f8df67"))
    for x in range(0,1280,64):
        var height := 75.0 + float((x / 64) % 4) * 20.0
        draw_line(Vector2(x,720), Vector2(x + float(visual.reed_sway),720-height), Color("274d38"), 8)
        draw_line(Vector2(x+8,720), Vector2(x+28,680-height*0.35), Color("477a4b"), 5)
    for y in range(20, 720, 70):
        draw_rect(Rect2(0,y,1280,35), Color(0.02,0.12,0.17,0.18), true)
    draw_circle(Vector2(640,220), 155, Color("123e4a"))
    var title_center := Vector2(640,215 + float(visual.fred_bob))
    draw_circle(title_center + Vector2(-40,0), 65, Color("69c96b")); draw_circle(title_center + Vector2(40,0), 65, Color("69c96b"))
    draw_circle(title_center + Vector2(-25,-25), 13, Color.WHITE); draw_circle(title_center + Vector2(25,-25), 13, Color.WHITE)
    draw_circle(title_center + Vector2(-25,-25), 6, Color("13242a")); draw_circle(title_center + Vector2(25,-25), 6, Color("13242a"))
    draw_arc(title_center + Vector2(0,10), 27, 0.25, PI - 0.25, 18, Color("173128"), 4)
    _text(Vector2(640,70), "FRED MYERS", 46, Color("f7d36a"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _text(Vector2(640,120), "and the Moonpetal Marsh", 30, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _text(Vector2(640,380), "A 100-level marsh adventure", 19, Color("bfe7dc"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _button(Rect2(490,440,300,70), "PLAY AGAIN" if session.completed else ("CONTINUE" if session.checkpoint_sequence > 0 else "START ADVENTURE"))
    _button(Rect2(490,525,300,52), "LOCAL LEADERBOARD")
    _text(Vector2(640,22), "NOW PLAYING: THE MARSHLAND MARCH", 12, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_CENTER, 500)
    _status_panel(Rect2(280,584,720,42), 16)
    if reduced_motion:
        _text(Vector2(640,675), "[REDUCED MOTION] All gameplay cues remain visible.", 15, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _text(Vector2(640,650), "[GUEST] Play now. Platform account linking stays optional.", 15, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 900)
    _text(Vector2(640,620), "MOVE  •  LEAP  •  BOOST  •  DIVE  •  MUNCH  •  PAUSE", 17, Color("bfd8dc"), HORIZONTAL_ALIGNMENT_CENTER, 1100)

    draw_rect(Rect2(0,580,1280,140), Color(0.01,0.05,0.08,0.92), true)
    _status_panel(Rect2(280,584,720,42), 16)
    _text(Vector2(640,652), "MOVE  |  LEAP  |  BOOST  |  DIVE  |  MUNCH  |  PAUSE", 15, Color("bfd8dc"), HORIZONTAL_ALIGNMENT_CENTER, 1100)
    _text(Vector2(640,680), "[GUEST] Play now. Account linking remains optional.", 14, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 900)
    if reduced_motion:
        _text(Vector2(640,706), "[REDUCED MOTION] All gameplay cues remain visible.", 13, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 700)

func _draw_marsh_background(water: Color) -> void:
    var playfield: Rect2 = MarshRouteLayout.PLAYFIELD_RECT
    if is_instance_valid(gameplay_art):
        if MarshRouteLayout.is_reversed(level_number):
            draw_set_transform(Vector2(1280.0,0.0), 0.0, Vector2(-1.0,1.0))
            draw_texture_rect(gameplay_art, playfield, false, MarshRouteLayout.background_tint(level_number))
            draw_set_transform(Vector2.ZERO)
        else:
            draw_texture_rect(gameplay_art, playfield, false, MarshRouteLayout.background_tint(level_number))
    else:
        draw_rect(playfield, water, true)
    draw_rect(playfield, MarshRouteLayout.background_overlay(level_number), true)
    draw_rect(playfield, Color(water, 0.14 + float(depth.depth) * 0.26), true)
    var variant := MarshRouteLayout.background_variant(level_number)
    var accent_positions: Array[Vector2] = [
        Vector2(165,165), Vector2(465,310), Vector2(790,195), Vector2(1090,445)
    ]
    for index in range(mini(variant + 1, accent_positions.size())):
        var accent := _route_point(accent_positions[index])
        draw_circle(accent, 70.0 + float(index) * 18.0, Color(0.72,0.93,1.0,0.028 + float(variant) * 0.006))
    for layer in range(3):
        var mist_y := 180.0 + float(layer) * 155.0 + float(variant % 2) * 28.0
        var mist_shift := 0.0 if reduced_motion else sin(visual_time * (0.10 + float(layer) * 0.025) + float(variant)) * 42.0
        draw_colored_polygon(_ellipse_points(Vector2(260.0 + float(layer) * 390.0 + mist_shift,mist_y),Vector2(240.0,38.0),0.0),Color(0.72,0.94,1.0,0.025 + float(layer) * 0.008))
    for glint in range(18):
        var glint_position := _route_point(Vector2(70 + (glint * 193 + variant * 61) % 1160,150 + (glint * 97 + variant * 43) % 430))
        var glint_size := 1.5 + float(glint % 3)
        draw_circle(glint_position,glint_size * 3.0,Color(1.0,0.89,0.38,0.035))
        draw_circle(glint_position,glint_size,Color(1.0,0.91,0.45,0.68))
    draw_rect(playfield, Color("8be8e1"), false, 3)
    draw_rect(playfield.grow(-4.0), Color(0.01,0.08,0.11,0.20), false, 2)
    draw_rect(Rect2(playfield.position, Vector2(playfield.size.x,96.0)), Color(0.42,0.90,0.92,0.06), true)

func _draw_level() -> void:
    var visual := FredVisualState.snapshot(visual_time, reduced_motion)
    var water := Color("075c78").lerp(Color("07334f"), float(depth.depth))
    draw_rect(MarshRouteLayout.PLAYFIELD_RECT.grow(7.0), Color("020b12"), true)
    _draw_marsh_background(water)
    if golden_room_open:
        _draw_golden_room()
        return
    _draw_depth_cues()
    for glow in [Vector2(180,170), Vector2(530,270), Vector2(1020,420)]:
        draw_circle(_route_point(glow), 95, Color(0.2,0.85,0.78,0.035))
    draw_set_transform(camera_offset)
    _draw_water_current()
    _draw_reeds(float(visual.reed_sway))
    _draw_whirlpools()
    for index in PADS.size():
        var pad: Vector2 = _pad_position(index)
        var pad_bob := FredVisualState.wave(visual_time, float(index) * 0.65, 3.0, reduced_motion)
        var drawn_pad: Vector2 = pad + Vector2(0,pad_bob)
        _draw_lily_pad(drawn_pad, index)
    var safe_radius := float(level_profile.safe_radius)
    _draw_safe_island(_level_safe_position(), safe_radius, false)
    for index in BUGS.size():
        if index not in collected:
            _draw_bug(_bug_position(index), index, float(visual.wildlife_flutter), false)
    if _fairy_available():
        _draw_fairy(_fairy_position(), false)
    var assisted_target := _nearest_assisted_target()
    if not assisted_target.is_empty() and tongue.is_ready():
        var assisted_position := Vector2(assisted_target.position)
        draw_arc(assisted_position, 29, 0, TAU, 24, Color("ffe980"), 3)
        _text(assisted_position + Vector2(0,-35), "[MUNCH READY]", 12, Color("fff5b0"), HORIZONTAL_ALIGNMENT_CENTER, 125)
    var active_positions := _active_predator_positions()
    for index in active_positions.size():
        _draw_predator(active_positions[index], PREDATOR_SPECIES[index], _predator_depth_snapshot(index))
    var exit_radius := 45.0 * float(visual.exit_pulse)
    _draw_moonpetal_exit(_level_exit_position(), exit_radius, false)
    var fred_draw_position := fred - Vector2(0,leap.visual_height)
    var animation_pose: Dictionary = animation.pose()
    _sync_fred_style()
    fred_rig.apply_pose(animation_pose, float(depth.depth))
    var animation_origin := fred_draw_position + Vector2(animation_pose.body_offset)
    var tongue_origin: Vector2 = fred_draw_position + Vector2(fred_rig.tongue_anchor())
    _draw_fred_water_contact()
    fred_rig.render_to(self, fred_draw_position, simulation_time, reduced_motion, false)
    _draw_world_labels()
    if tongue.is_ready() and leap.state == LeapTraversal.State.GROUNDED and depth.state == DepthTraversal.State.SURFACE:
        _draw_tongue_aim(tongue_origin)
    if tongue.is_busy():
        _draw_eating_effect(tongue_origin, tongue.target_point)
    if boost.is_active():
        _draw_boost_cues(animation_origin)
    if impact_burst_seconds > 0.0:
        _draw_impact_burst()
    draw_set_transform(Vector2.ZERO)
    _draw_depth_status()

func _draw_golden_room() -> void:
    draw_rect(MarshRouteLayout.PLAYFIELD_RECT, Color("0a3c47"), true)
    for x in range(90,1240,85):
        draw_line(Vector2(x,620),Vector2(x+12,150),Color("39745b"),9.0)
    draw_circle(GOLDEN_ROOM_EGG,118.0,Color(1.0,0.78,0.18,0.10))
    var pulse := 0.0 if reduced_motion else sin(visual_time*2.0)*0.04
    _draw_canonical_golden_egg(GOLDEN_ROOM_EGG,0.62+pulse)
    fred_rig.render_to(self,fred,simulation_time,reduced_motion,false)

func _draw_canonical_golden_egg(center: Vector2, scale: float = 1.0) -> void:
    draw_colored_polygon(_ellipse_points(center+Vector2(0,18)*scale,Vector2(96,128)*scale,0.0),Color("f8c947"))
    draw_arc(center,76.0*scale,0.0,TAU,64,Color("fff3a6"),5.0)
    draw_circle(center+Vector2(-24,-12)*scale,17.0*scale,Color("72c96b"))
    draw_circle(center+Vector2(24,-12)*scale,17.0*scale,Color("72c96b"))
    draw_circle(center+Vector2(-24,-15)*scale,5.0*scale,Color("13242a"))
    draw_circle(center+Vector2(24,-15)*scale,5.0*scale,Color("13242a"))
    draw_arc(center+Vector2(0,12)*scale,25.0*scale,0.25,PI-0.25,18,Color("7d5609"),4.0)
    _text(Vector2(25,42), "LILY LEAP", 27, Color("f7d36a"), HORIZONTAL_ALIGNMENT_LEFT, 270)
    _text(MarshRouteLayout.CAMPAIGN_TEXT_RECT.position + Vector2(7.0,14.0), "CAMPAIGN 1  •  LEVEL %03d / 100  •  %s" % [level_profile.level, level_profile.label], 13, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_LEFT, MarshRouteLayout.CAMPAIGN_TEXT_RECT.size.x - 14.0)
    var route_summary := "%s  |  %s  |  %.1fx  |  THREATS %d  |  NEW: %s" % [
        MarshRouteLayout.formation_label(level_number).to_upper(),
        MarshRouteLayout.route_label(level_number),
        float(level_profile.challenge_multiplier),
        int(level_profile.predator_count),
        str(level_profile.new_twist).to_upper(),
    ]
    if reduced_motion:
        route_summary += "  |  STEADY VIEW"
    _text(MarshRouteLayout.ROUTE_SUMMARY_RECT.position + Vector2(7.0,15.0), route_summary, 12, Color("fff0ae"), HORIZONTAL_ALIGNMENT_LEFT, MarshRouteLayout.ROUTE_SUMMARY_RECT.size.x - 14.0)
    draw_rect(MarshRouteLayout.OBJECTIVE_RECT, Color("06151f"), true)
    draw_rect(MarshRouteLayout.OBJECTIVE_RECT, Color("e8fbff"), false, 2)
    _text(Vector2(295,42), "OBJECTIVE: " + ("Reach the moonpetal exit" if session.bug_count >= 3 else "Munch 3 marsh bugs"), 17, Color("e8fbff"), HORIZONTAL_ALIGNMENT_LEFT, 465)
    draw_rect(MarshRouteLayout.LIVES_RECT, Color("06151f"), true)
    draw_rect(MarshRouteLayout.LIVES_RECT, Color("f7d36a"), false, 3)
    _text(Vector2(MarshRouteLayout.LIVES_RECT.get_center().x,42), "LIVES %d  •  COINS %d" % [session.health, customization.coins], 14, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, MarshRouteLayout.LIVES_RECT.size.x - 10.0)
    if not touch_controls_visible:
        _text(MarshRouteLayout.TELEMETRY_ANCHOR, "BUGS %d/3   %s %d%%   %s   %s" % [session.bug_count, depth.cue(), roundi(float(depth.depth) * 100.0), tongue.cue(), boost.cue()], 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 810)
    _draw_energy_meter()
    _status_panel(MarshRouteLayout.status_rect(touch_controls_visible), 15)
    _button(MarshRouteLayout.PAUSE_RECT, "PAUSE")
    _button(MarshRouteLayout.HOME_RECT, "EXIT")
    if touch_controls_visible and screen == Screen.PLAYING and not session.paused and countdown_seconds <= 0.0:
        _draw_touch_controls()

func _ellipse_points(center: Vector2, radii: Vector2, rotation: float, close: bool = false) -> PackedVector2Array:
    var points := PackedVector2Array()
    var count := 33 if close else 32
    for step in range(count):
        var angle := float(step % 32) * TAU / 32.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation))
    return points

func _draw_fred_water_contact() -> void:
    var pose: Dictionary = animation.pose()
    var contact := WaterContactArt.frog({
        "height": leap.visual_height,
        "airborne": leap.is_airborne(),
        "depth": depth.depth,
        "perched": _is_valid_landing(fred),
        "landing": leap.elapsed / LeapTraversal.LANDING_SECONDS if leap.state == LeapTraversal.State.LANDING else -1.0,
        "size": float(fred_rig.style_snapshot().size_scale),
        "moving": str(pose.state_name) in ["SURFACE_SWIM", "UNDERWATER_SWIM", "BOOST_BURST", "BOOST_SUSTAIN"],
        "boosting": boost.is_active(),
        "direction": last_aim_direction,
    }, simulation_time, reduced_motion)
    WaterContactArt.draw_contact(self, fred, contact)

func _draw_volume_ellipse(center: Vector2, radii: Vector2, rotation: float, base: Color, surface: Dictionary, strength: float = 1.0) -> void:
    var key := clampf(float(surface.get("key_light",0.25))*strength,0.0,0.55)
    var underside := clampf(float(surface.get("underside_shadow",0.34))*strength,0.0,0.60)
    var rim := clampf(float(surface.get("rim_strength",0.38))*strength,0.0,0.70)
    var shift := float(surface.get("light_shift",0.0))*radii.x
    var shadow_offset := Vector2(radii.x*0.06,radii.y*0.14).rotated(rotation)
    var highlight_offset := Vector2(-radii.x*0.16+shift,-radii.y*0.19).rotated(rotation)
    var belly_offset := Vector2(radii.x*0.05,radii.y*0.30).rotated(rotation)
    draw_colored_polygon(_ellipse_points(center+shadow_offset,radii*Vector2(1.02,1.04),rotation),Color(base.darkened(0.58),0.52))
    CharacterSurface.draw_volume(self, CharacterSurface.ellipse(center,radii,rotation),base,float(surface.get("wet_specular",0.2))*strength)
    CharacterSurface.draw_volume(self,CharacterSurface.ellipse(center+highlight_offset,radii*Vector2(0.70,0.46),rotation),Color(base.lightened(key),0.28),0.0,true)
    CharacterSurface.draw_volume(self,CharacterSurface.ellipse(center+belly_offset,radii*Vector2(0.76,0.34),rotation),Color(base.darkened(underside),0.24),0.0,true)
    var rim_points := PackedVector2Array()
    var rim_center := center+highlight_offset*0.20
    for rim_step in range(15):
        var rim_angle := lerpf(3.38,5.95,float(rim_step)/14.0)
        rim_points.append(rim_center+Vector2(cos(rim_angle)*radii.x*0.78,sin(rim_angle)*radii.y*0.78).rotated(rotation))
    draw_polyline(rim_points,Color(base.lightened(0.48),rim),1.4+strength*0.7,true)

func _draw_lily_pad(position: Vector2, index: int) -> void:
    var rotation := sin(float(level_number * 7 + index * 19)) * 0.28
    BotanicalArt.draw_lily(self, position, index, rotation)

func _draw_safe_island(position: Vector2, radius: float, show_label: bool = true) -> void:
    BotanicalArt.draw_perch(self, position, radius)
    if show_label:
        _text(position + Vector2(0,8), "SAFE PERCH", 13, Color("e7ffd8"), HORIZONTAL_ALIGNMENT_CENTER, 120)

func _draw_moonpetal_exit(position: Vector2, radius: float, show_label: bool = true) -> void:
    BotanicalArt.draw_flower(self, position, radius)
    if show_label:
        _text(position + Vector2(0,radius + 30), "MOONPETAL EXIT", 12, Color("f7e7ff"), HORIZONTAL_ALIGNMENT_CENTER, 150)

func _label_request(id: String, text: String, size: int, center: Vector2, travel: Vector2, offset: Vector2, color: Color, fixed: bool = false) -> Dictionary:
    var font := ThemeDB.fallback_font
    return {"id":id,"text":text,"font_size":size,"center":center,"travel":travel,"offset":offset,"color":color,"fixed":fixed,
        "size":Vector2(ceilf(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x),ceilf(font.get_height(size))),"ascent":font.get_ascent(size),
        "options":PackedVector2Array([Vector2(0,-66),Vector2(0,80),Vector2(-100,5),Vector2(100,5),Vector2(-75,-51),Vector2(75,-51),Vector2(-75,64),Vector2(75,64),Vector2(0,100),Vector2(0,-90)])}

func _bug_label_region(index: int) -> Rect2:
    # Conservative envelope of the existing position formula, including hover.
    # Regression compares it with real positions; this does not drive movement.
    var base := MarshRouteLayout.bug_point(BUGS[index],index,level_number)
    var phase := float(level_number * 23 + index * 41)
    var sign := -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
    var middle := base + Vector2(sin(phase*0.17)*38.0*sign,cos(phase*0.11)*25.0)
    var extent := Vector2(1,0.72) * float(level_profile.bug_flight_radius)
    var low := (middle-extent).clamp(Vector2(80,145),Vector2(1200,585)) - Vector2(0,3)
    var high := (middle+extent).clamp(Vector2(80,145),Vector2(1200,585)) + Vector2(0,3)
    return Rect2(low,high-low)

func _world_label_inputs() -> Dictionary:
    var requests: Array[Dictionary] = []
    var scenery: Array[Dictionary] = []
    var reserved: Array[Rect2] = []
    var margin := CameraFollow.MAX_OFFSET.x + 5.0
    var allowed := MarshRouteLayout.PLAYFIELD_RECT.grow(-margin)
    if touch_controls_visible:
        reserved.append(MarshRouteLayout.TOUCH_ACTION_WHEEL_RECT.grow(margin))
        # Include the MOVE heading, which sits above the physical touch pad.
        reserved.append(MarshRouteLayout.TOUCH_CONTROL_PAD_RECT.grow_individual(margin,margin+34,margin,margin))
    reserved.append(MarshRouteLayout.DEPTH_STATUS_RECT.grow(margin))
    var safe := _level_safe_position()
    var safe_extent := Vector2(float(level_profile.safe_radius)+4,float(level_profile.safe_radius)*0.64+10)
    scenery.append({"id":"safe","rect":Rect2(safe-safe_extent,safe_extent*2)})
    requests.append(_label_request("safe","SAFE PERCH",13,safe,Vector2.ZERO,Vector2(0,8),Color("e7ffd8"),true))
    var exit_at := _level_exit_position()
    scenery.append({"id":"exit","rect":Rect2(exit_at-Vector2(49,49),Vector2(98,98))})
    requests.append(_label_request("exit","MOONPETAL EXIT",12,exit_at,Vector2(0,3),Vector2(0,75),Color("f7e7ff"),true))
    for index in PADS.size():
        var base := MarshRouteLayout.pad_point(PADS[index],index,level_number)
        var phase := float(level_number*17+index*31)
        var sign := -1.0 if MarshRouteLayout.is_reversed(level_number) else 1.0
        var middle := base+Vector2(sin(phase*0.19)*minf(34,8+level_number*0.28)*sign,cos(phase*0.13)*minf(26,6+level_number*0.20))
        var extent := Vector2(1,0.55)*float(level_profile.lily_drift)
        var low := (middle-extent).clamp(Vector2(90,155),Vector2(1190,590))-Vector2(58,48)
        var high := (middle+extent).clamp(Vector2(90,155),Vector2(1190,590))+Vector2(58,48)
        scenery.append({"id":"pad%d"%index,"rect":Rect2(low,high-low)})
    for index in mini(int(level_profile.whirlpool_count),WHIRLPOOLS.size()):
        var at := _whirlpool_position(index)
        var id := "whirlpool%d"%index
        scenery.append({"id":id,"rect":Rect2(at-Vector2(55,55),Vector2(110,110))})
        requests.append(_label_request(id,"WHIRLPOOL",11,at,Vector2.ZERO,Vector2(0,72),Color("cdefff")))
    if level_number % 10 == 0:
        var at := _fairy_position()
        scenery.append({"id":"fairy","rect":Rect2(at-Vector2(40,40),Vector2(80,73))})
        requests.append(_label_request("fairy",CollectibleWildlifeArt.FAIRY_LABEL,11,at,Vector2(0,4),Vector2(0,50),Color("fff0ae")))
    for index in BUGS.size():
        var region := _bug_label_region(index)
        var id := "bug%d"%index
        scenery.append({"id":id,"rect":region.grow_individual(35,36,35,27)})
        var request := _label_request(id,"BUG %d"%(index+1),11,region.get_center(),region.size*0.5,Vector2(0,CollectibleWildlifeArt.BUG_LABEL_Y),Color("fff7cb"))
        request.options = PackedVector2Array([Vector2(0,-39),Vector2(-60,5),Vector2(60,5),Vector2(-45,-35),Vector2(45,-35),Vector2(-50,50),Vector2(50,50),Vector2(0,64)])
        requests.append(request)
    return {"requests":requests,"scenery":scenery,"reserved":reserved,"allowed":allowed}

func _world_label_plan() -> Array[Dictionary]:
    var key := "%d:%s:%d" % [level_number,touch_controls_visible,ThemeDB.fallback_font.get_instance_id()]
    if key != _world_labels_key:
        var input := _world_label_inputs()
        _cached_world_labels = MarshLabelLayout.arrange(input.requests,input.scenery,input.reserved,input.allowed)
        _world_labels_key = key
    return _cached_world_labels

func _world_label_snapshot() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for planned in _world_label_plan():
        var label := planned.duplicate()
        var id := str(label.id)
        var at := Vector2(label.center)
        if id.begins_with("bug"):
            var index := int(id.trim_prefix("bug"))
            if index in collected:
                continue
            at = _bug_position(index) + Vector2(0,float(WildlifeAnimationRig.pose("BUG",index,simulation_time,reduced_motion).hover_lift))
        elif id == "fairy":
            if not _fairy_available():
                continue
            at = _fairy_position() + Vector2(0,float(WildlifeAnimationRig.pose("FAIRY",0,simulation_time,reduced_motion).hover_lift))
        elif id == "exit":
            at.y += 45.0*(FredVisualState.pulse(visual_time,0.4,reduced_motion)-1.0)
        label.origin = at
        label.anchor = at + Vector2(label.offset)
        label.rect = MarshLabelLayout.text_rect(label.anchor,label.size,label.ascent)
        result.append(label)
    return result

func _draw_world_labels() -> void:
    # Above scenery and actors, below action cues/HUD/overlays. No label boxes.
    for label in _world_label_snapshot():
        var anchor := Vector2(label.anchor)
        if bool(label.moved):
            var origin := Vector2(label.origin)
            var edge := origin.clamp(Vector2(label.rect.position),Vector2(label.rect.end))
            var direction := (edge-origin).normalized()
            var radius := 56.0 if str(label.id).begins_with("whirlpool") else 30.0
            if origin.distance_to(edge) > radius+8:
                draw_line(origin+direction*radius,edge-direction*3,Color(0.62,0.82,0.81,0.50),0.8,true)
        _text(anchor+Vector2.ONE,label.text,label.font_size,Color(0.01,0.04,0.05,0.90),HORIZONTAL_ALIGNMENT_CENTER,float(label.size.x))
        _text(anchor,label.text,label.font_size,label.color,HORIZONTAL_ALIGNMENT_CENTER,float(label.size.x))

func _nearest_assisted_target() -> Dictionary:
    var nearest: Dictionary = {}
    var nearest_distance := INF
    for candidate: Dictionary in _tongue_candidates():
        if not bool(candidate.get("eligible", true)):
            continue
        var position := Vector2(candidate.position)
        var distance := fred.distance_to(position)
        if distance <= TongueTargeting.PROXIMITY_ASSIST_RANGE and distance < nearest_distance:
            nearest = candidate
            nearest_distance = distance
    return nearest

func _draw_touch_controls() -> void:
    var held: Array = touch_contacts.values()
    var wheel_center := MarshRouteLayout.TOUCH_ACTION_WHEEL_CENTER
    var wheel_radius := MarshRouteLayout.TOUCH_ACTION_WHEEL_RADIUS
    draw_circle(wheel_center, wheel_radius, Color(0.01,0.06,0.09,MarshRouteLayout.TOUCH_OVERLAY_ALPHA))
    draw_arc(wheel_center, wheel_radius, 0.0, TAU, 48, Color(0.44,0.84,0.76,MarshRouteLayout.TOUCH_OUTLINE_ALPHA), 3.0)
    _text(wheel_center + Vector2(0.0, 4.0), "ACTIONS", 14, Color(1.0,0.94,0.68,0.88), HORIZONTAL_ALIGNMENT_CENTER, 96.0)
    var centers := MarshRouteLayout.touch_centers()
    var radii := MarshRouteLayout.touch_radii()
    _draw_touch_action_button(Vector2(centers.tongue), float(radii.tongue), "MUNCH", "tongue" in held, Color("e67b4a"))
    _draw_touch_action_button(Vector2(centers.leap), float(radii.leap), "LEAP", "leap" in held, Color("67c96f"))
    _draw_touch_action_button(Vector2(centers.boost), float(radii.boost), "BOOST", "boost" in held, Color("e4b943"))
    var depth_label := "SURFACE" if depth.state != DepthTraversal.State.SURFACE else "DIVE"
    _draw_touch_action_button(Vector2(centers.depth), float(radii.depth), depth_label, "depth" in held, Color("4d9fd8"))
    var pad_center := MarshRouteLayout.TOUCH_CONTROL_PAD_CENTER
    var pad_radius := MarshRouteLayout.TOUCH_CONTROL_PAD_RADIUS
    draw_circle(pad_center, pad_radius + 10.0, Color(0.01,0.06,0.09,MarshRouteLayout.TOUCH_OVERLAY_ALPHA))
    draw_circle(pad_center, pad_radius, Color(0.05,0.18,0.21,MarshRouteLayout.TOUCH_CONTROL_ALPHA))
    draw_arc(pad_center, pad_radius, 0.0, TAU, 48, Color(0.44,0.84,0.76,MarshRouteLayout.TOUCH_OUTLINE_ALPHA), 4.0)
    for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
        var arrow_tip: Vector2 = pad_center + direction * 62.0
        draw_line(pad_center + direction * 30.0, arrow_tip, Color(0.78,1.0,0.91,0.42), 7.0)
        draw_circle(arrow_tip, 6.0, Color(1.0,0.94,0.68,0.72))
    var steering_target := _active_touch_target()
    var thumb := pad_center if steering_target == Vector2.ZERO else MarshRouteLayout.clamp_touch_target(steering_target)
    draw_circle(thumb + Vector2(0.0, 4.0), 24.0, Color(0.0,0.02,0.03,0.32))
    var thumb_alpha := MarshRouteLayout.TOUCH_CONTROL_ACTIVE_ALPHA if steering_target != Vector2.ZERO else MarshRouteLayout.TOUCH_CONTROL_ALPHA
    draw_circle(thumb, 22.0, Color(0.23,0.62,0.48,thumb_alpha))
    draw_arc(thumb, 22.0, 0.0, TAU, 28, Color(1.0,0.96,0.74,0.78), 3.0)
    _text(pad_center + Vector2(0.0, -102.0), "MOVE", 15, Color(1.0,1.0,1.0,0.88), HORIZONTAL_ALIGNMENT_CENTER, 100.0)

func _active_touch_target() -> Vector2:
    var steering_index := 2147483647
    for raw_index: Variant in touch_contacts:
        if str(touch_contacts[raw_index]) == "steer" and int(raw_index) < steering_index and touch_positions.has(raw_index):
            steering_index = int(raw_index)
    return Vector2(touch_positions[steering_index]) if steering_index != 2147483647 else Vector2.ZERO

func _draw_touch_action_button(center: Vector2, radius: float, label: String, active: bool, accent: Color) -> void:
    var base := accent.lightened(0.16) if active else accent.darkened(0.24)
    var alpha := MarshRouteLayout.TOUCH_CONTROL_ACTIVE_ALPHA if active else MarshRouteLayout.TOUCH_CONTROL_ALPHA
    var fill := Color(base.r, base.g, base.b, alpha)
    draw_circle(center + Vector2(0.0, 4.0), radius, Color(0.0,0.02,0.03,0.26))
    draw_circle(center, radius, fill)
    var inner := fill.lightened(0.08)
    inner.a = alpha * 0.72
    draw_circle(center - Vector2(4.0, 6.0), radius - 8.0, inner)
    draw_arc(center, radius, 0.0, TAU, 28, Color(1.0,0.96,0.74,MarshRouteLayout.TOUCH_OUTLINE_ALPHA), 3.0)
    draw_circle(center - Vector2(11.0, 13.0), 6.0, Color(1,1,1,0.24))
    _text(center + Vector2(0.0, 7.0), label, 14 if label.length() > 5 else 16, Color(1.0,1.0,1.0,0.92), HORIZONTAL_ALIGNMENT_CENTER, radius * 1.72)

func _draw_water_current() -> void:
    var flow := FredWaterCurrentVisual.profile(
        level_number,
        _current_vector(),
        float(depth.depth),
        visual_time,
        reduced_motion
    )
    for index in range(FredWaterCurrentVisual.STREAM_COUNT):
        var stream := FredWaterCurrentVisual.streamline(index, flow)
        if not bool(stream.get("valid", false)):
            continue
        var points: PackedVector2Array = stream.points
        draw_polyline(points, Color(stream.shadow), float(stream.width) + 2.2, true)
        draw_polyline(points, Color(stream.highlight), float(stream.width), true)
        var foam := float(stream.foam)
        if foam > 0.05:
            var foam_index := 4 if index % 2 == 0 else 2
            draw_circle(points[foam_index], 1.5 + foam * 1.8, Color(0.84,0.98,1.0,0.18 + foam * 0.24))
    for index in PADS.size():
        _draw_current_eddy(_pad_position(index), index, flow)
    _draw_current_eddy(_level_safe_position(), PADS.size(), flow)

func _draw_current_eddy(anchor: Vector2, index: int, flow: Dictionary) -> void:
    var eddy := FredWaterCurrentVisual.eddy(index, flow)
    if not bool(eddy.get("valid", false)):
        return
    var direction := float(flow.direction)
    var center := anchor + Vector2(direction * 6.0, 12.0)
    var rotation := float(eddy.rotation)
    var sweep := float(eddy.sweep)
    var opacity := float(eddy.opacity)
    var radius := float(eddy.radius)
    draw_arc(center, radius, rotation, rotation + sweep, 20, Color(0.62,0.94,0.96,opacity), 2.1, true)
    draw_arc(center, radius + 8.0, rotation + direction * 0.42, rotation + direction * 0.42 + sweep * 0.72, 18, Color(0.34,0.73,0.84,opacity * 0.62), 1.4, true)
    var wake_start := anchor + Vector2(direction * 30.0, 17.0)
    var wake_length := float(eddy.wake_length)
    var wake_points := PackedVector2Array([
        wake_start,
        wake_start + Vector2(direction * wake_length * 0.45, 3.0),
        wake_start + Vector2(direction * wake_length, 8.0),
    ])
    draw_polyline(wake_points, Color(0.66,0.95,0.96,opacity * 0.82), 1.6, true)

func _draw_boost_cues(position: Vector2) -> void:
    var aim := last_aim_direction.normalized()
    if aim == Vector2.ZERO:
        aim = Vector2.RIGHT
    var backwards := -aim
    for index in range(4):
        var offset := backwards * (32.0 + float(index) * 15.0)
        var side := aim.orthogonal() * (-8.0 + float(index % 3) * 8.0)
        var start := position + offset + side
        var length := 16.0 + float(index) * 4.0
        draw_line(start, start + backwards * length, Color("fff0ae"), 3.0)
    _text(position + Vector2(0,-62), "[%s]" % boost.cue(), 13, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 190)

func _draw_energy_meter() -> void:
    var meter := MarshRouteLayout.ENERGY_RECT
    draw_rect(meter, Color("06151f"), true)
    var fill_width := (meter.size.x - 6.0) * float(session.boost_energy) / 100.0
    draw_rect(Rect2(meter.position + Vector2(3,3), Vector2(fill_width, meter.size.y - 6.0)), Color("f7d36a"), true)
    draw_rect(meter, Color("e8fbff"), false, 2)
    var threshold_x := meter.position.x + meter.size.x * float(BoostLocomotion.START_THRESHOLD) / 100.0
    draw_line(Vector2(threshold_x,meter.position.y), Vector2(threshold_x,meter.end.y), Color("ff8f70"), 3)
    var label_rect := MarshRouteLayout.ENERGY_LABEL_RECT
    _text(Vector2(label_rect.get_center().x,label_rect.position.y + 16.0), "ENERGY %d%%" % session.boost_energy, 12, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x)

func _draw_depth_cues() -> void:
    var amount := float(depth.depth)
    if amount <= 0.001:
        return
    draw_rect(MarshRouteLayout.PLAYFIELD_RECT, Color(0.01,0.07,0.16,0.20 * amount), true)
    for index in range(14):
        var phase := 0.0 if reduced_motion else fmod(visual_time * (18.0 + float(index % 3) * 3.0), 150.0)
        var bubble := Vector2(90 + index * 84, 620 - fmod(float(index * 47) + phase, 470.0))
        draw_circle(bubble, 2.0 + float(index % 3), Color(0.72,0.94,1.0,0.52 * amount), false, 2)

func _draw_depth_status() -> void:
    if float(depth.depth) <= 0.001:
        return
    # Screen-space HUD is drawn after the world. The flower, camera and other
    # scenery cannot paint over this label as they did over the old world cue.
    var rect: Rect2 = MarshRouteLayout.DEPTH_STATUS_RECT
    draw_rect(rect,Color(0.01,0.05,0.08,0.88))
    _text(rect.position + Vector2(rect.size.x*0.5,20), "[%s] DEPTH %d%%" % [depth.cue(),roundi(float(depth.depth)*100.0)],14,Color("d9f7ff"),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-16)

func _draw_whirlpools() -> void:
    for index in range(mini(int(level_profile.whirlpool_count), WHIRLPOOLS.size())):
        var center: Vector2 = _whirlpool_position(index)
        WhirlpoolArt.draw_water(self, center, _whirlpool_visual(index))

func _whirlpool_visual(index: int) -> Dictionary:
    # The gameplay clock freezes on Pause/background/native overlays; the menu
    # visual clock does not. This is drawing only and cannot advance a hazard.
    return WhirlpoolArt.geometry(index, simulation_time, reduced_motion)

func _draw_predator(position: Vector2, species: String, predator_snapshot: Dictionary = {}) -> void:
    var snapshot := predator_snapshot if not predator_snapshot.is_empty() else PredatorDepth.snapshot(species, 0, level_number, simulation_time)
    var predator_depth := float(snapshot.get("depth", 0.0))
    var drawn_position := position + Vector2(0.0, predator_depth * 9.0)
    var actor_index := maxi(0, PREDATOR_SPECIES.find(species))
    var rig_pose: Dictionary = WildlifeAnimationRig.pose(species, actor_index, simulation_time, reduced_motion)
    var rig_surface: Dictionary = WildlifeAnimationRig.surface_profile(species, actor_index, simulation_time, reduced_motion)
    var contact := WaterContactArt.predator(species, predator_depth, rig_pose, simulation_time, reduced_motion)
    WaterContactArt.draw_contact(self, position, contact)
    if species == "HERON":
        _draw_heron(drawn_position, _predator_identity_profile(species), rig_pose, rig_surface)
    elif species == "SNAKE":
        _draw_snake(drawn_position, _predator_identity_profile(species), rig_pose, rig_surface)
    else:
        _draw_fish(drawn_position, species, _predator_identity_profile(species), rig_pose, rig_surface)
    _draw_predator_depth_cues(drawn_position, snapshot)

func _draw_predator_depth_cues(position: Vector2, predator_snapshot: Dictionary) -> void:
    var predator_depth := clampf(float(predator_snapshot.get("depth", 0.0)), 0.0, 1.0)
    var state := int(predator_snapshot.get("state", PredatorDepth.State.ABOVE_WATER))
    if state == PredatorDepth.State.ABOVE_WATER:
        return
    if predator_depth > 0.05:
        CharacterSurface.draw_volume(self,CharacterSurface.ellipse(position,Vector2(48,24)),Color(0.01,0.18,0.31,0.12 + predator_depth * 0.28),0.0,true)
        for bubble_index in range(3):
            var bubble_offset := Vector2(-30.0 + float(bubble_index) * 18.0, -25.0 - float(bubble_index % 2) * 11.0)
            draw_circle(position + bubble_offset, 3.0 + float(bubble_index), Color(0.72,0.96,1.0,0.48 + predator_depth * 0.30))

func _predator_identity_profile(species: String) -> Dictionary:
    match species.to_upper():
        "BASS":
            return {
                "silhouette": "deep_largemouth",
                "body": Color("69834a"),
                "back": Color("263f2c"),
                "belly": Color("d8d7a3"),
                "marking": Color("26372b"),
                "body_radii": Vector2(47,25),
                "snout_length": 45.0,
                "facing": -1.0,
                "pattern": "broken_lateral_band",
                "anatomy": ["large hinged jaw", "spiny dorsal fin", "dark lateral band", "rounded operculum", "paired pectoral fins", "forked caudal fin", "layered cycloid scales", "thick upper lip", "reference-guided cheek plane", "translucent fin rays"],
                "motion_channels": ["tail flex", "pectoral sweep", "body lift"],
                "detail_layers": 18,
                "reference": "https://sketchfab.com/3d-models/cc0-micropterus-sp-62e182cf1f2d4d5692dde7348e648f76",
                "reference_license": "CC0",
                "runtime_asset_dependency": false,
                "phone_readable": true,
            }
        "PIKE":
            return {
                "silhouette": "long_duckbill",
                "body": Color("71834a"),
                "back": Color("31472f"),
                "belly": Color("d7d7aa"),
                "marking": Color("e0d99b"),
                "body_radii": Vector2(55,17),
                "snout_length": 55.0,
                "facing": 1.0,
                "pattern": "pale_chain_spots",
                "anatomy": ["duckbill snout", "rear dorsal fin", "long torpedo body", "paired pelvic fins", "lateral line", "forked caudal fin", "needle teeth", "chain-pattern scales", "reference-guided cranial wedge", "translucent fin rays"],
                "motion_channels": ["tail flex", "pectoral sweep", "body lift"],
                "detail_layers": 18,
                "reference": "https://sketchfab.com/3d-models/northern-pike-esox-lucius-925bde79283242cf98b93d281259aa20",
                "reference_license": "CC BY",
                "runtime_asset_dependency": false,
                "phone_readable": true,
            }
        "MUSKIE":
            return {
                "silhouette": "long_barred",
                "body": Color("7c8771"),
                "back": Color("394c40"),
                "belly": Color("d2d6bf"),
                "marking": Color("33483f"),
                "body_radii": Vector2(57,19),
                "snout_length": 56.0,
                "facing": -1.0,
                "pattern": "vertical_bars",
                "anatomy": ["long predator jaw", "rear dorsal fin", "vertical flank bars", "paired pelvic fins", "lateral line", "forked caudal fin", "cheek scales", "needle teeth", "reference-guided cranial wedge", "translucent fin rays"],
                "motion_channels": ["tail flex", "pectoral sweep", "body lift"],
                "detail_layers": 18,
                "reference": "https://sketchfab.com/3d-models/northern-pike-esox-lucius-925bde79283242cf98b93d281259aa20",
                "reference_license": "CC BY",
                "runtime_asset_dependency": false,
                "phone_readable": true,
            }
        "SNAKE":
            return {
                "silhouette": "scaled_serpentine",
                "body": Color("756b32"),
                "belly": Color("cbbb70"),
                "marking": Color("364326"),
                "pattern": "dorsal_blobs",
                "anatomy": ["tapered scale body", "flattened head", "forked tongue", "overlapping dorsal scales", "belly scutes", "hinged jaw line", "keeled neck scales", "vertical pupils", "reference-guided brow plates", "muscular neck taper"],
                "motion_channels": ["spinal wave", "head lead", "tongue flick"],
                "detail_layers": 18,
                "reference": "https://sketchfab.com/3d-models/cc0-striped-snake-elaphe-quadrivirgata-0f4f583d5e3842eca1152c0bb021ec32",
                "reference_license": "CC0",
                "runtime_asset_dependency": false,
                "phone_readable": true,
            }
        "HERON":
            return {
                "silhouette": "long_necked_wader",
                "body": Color("9fb8c2"),
                "wing": Color("718d9a"),
                "marking": Color("263b43"),
                "pattern": "layered_flight_feathers",
                "anatomy": ["S-curved neck", "spear bill", "long legs and toes", "layered primary feathers", "shoulder mantle", "crown plume", "scapular feather fringe", "knuckled gripping toes", "reference-guided breast keel", "overlapping covert feathers"],
                "motion_channels": ["wing breathing", "neck poise", "toe balance"],
                "detail_layers": 18,
                "reference": "https://sketchfab.com/3d-models/realistic-heron-3d-model-95a74fb41f1a46f0acec81a2d6c85093",
                "reference_license": "CC BY",
                "runtime_asset_dependency": false,
                "phone_readable": true,
            }
    return {
        "silhouette": "generic_predator",
        "body": Color("8a8071"),
        "back": Color("4a443c"),
        "belly": Color("d4ccbc"),
        "marking": Color("3f3a34"),
        "body_radii": Vector2(45,22),
        "snout_length": 42.0,
        "facing": 1.0,
        "pattern": "plain",
        "anatomy": [],
        "motion_channels": [],
        "detail_layers": 1,
        "reference": "",
        "reference_license": "none",
        "runtime_asset_dependency": false,
        "phone_readable": false,
    }

func _wildlife_identity_profile(kind: String) -> Dictionary:
    match kind.to_upper():
        "BUG":
            return {
                "silhouette": "four_wing_marsh_fly",
                "anatomy": ["compound eyes", "head thorax abdomen", "six jointed legs", "paired antennae", "four veined wings"],
                "motion_channels": ["opposed wing beat", "abdomen hover"],
                "detail_layers": 8,
                "phone_readable": true,
                "presentation_only": true,
            }
        "FAIRY":
            return {
                "silhouette": "marsh_light_fairy",
                "anatomy": ["head thorax abdomen", "four veined wings", "paired antennae", "jointed arms and legs", "moonpetal crown"],
                "motion_channels": ["paired wing beat", "glow pulse", "hover lift"],
                "detail_layers": 9,
                "phone_readable": true,
                "presentation_only": true,
            }
    return {
        "silhouette": "unknown_wildlife",
        "anatomy": [],
        "motion_channels": [],
        "detail_layers": 0,
        "phone_readable": false,
        "presentation_only": true,
    }

func _draw_fish(position: Vector2, species: String, profile: Dictionary, rig_pose: Dictionary, rig_surface: Dictionary) -> void:
    var swim_lift := sin(simulation_time * 1.3 + position.x * 0.01) * (0.5 if reduced_motion else 2.0)
    PredatorFishArt.draw_fish(self, position + Vector2(0, swim_lift), species, profile, rig_pose, rig_surface)

func _draw_snake(position: Vector2, profile: Dictionary, rig_pose: Dictionary, rig_surface: Dictionary) -> void:
    var body := Color(profile.body)
    var belly := Color(profile.belly)
    var marking := Color(profile.marking)
    var spine := PackedVector2Array()
    var wave_time := float(rig_pose.spine_wave)
    var wave_amplitude := float(rig_pose.spine_amplitude)
    for segment in range(16):
        var taper_wave := sin(float(segment) * 0.72 + wave_time) * wave_amplitude * (1.0 - float(segment) * 0.015)
        spine.append(position + Vector2(-76.0 + float(segment) * 9.2,taper_wave))
    var widths := PackedFloat32Array()
    for segment in range(16):
        var progress := float(segment) / 15.0
        widths.append(lerpf(2.0,12.0,sin(progress * PI * 0.5)) * float(rig_pose.body_breathe))
    CharacterSurface.draw_ribbon(self,spine,widths,body)
    for segment in range(2,16):
        var center := spine[segment]
        var radius := widths[segment]
        var stripe := PackedVector2Array([center+Vector2(-3,-radius*0.66),center+Vector2(0,-radius*0.13),center+Vector2(4,radius*0.6)])
        draw_polyline(stripe,Color(marking,0.65),2.3,true)
        draw_line(center+Vector2(-2,radius*0.63),center+Vector2(3,radius*0.72),Color(belly,0.60),1.0,true)
    var head := spine[spine.size()-1] + Vector2(9.0,float(rig_pose.head_pitch)*18.0)
    _draw_volume_ellipse(head+Vector2(-3,0),Vector2(29,16),0.0,body.lightened(0.03),rig_surface,0.92)
    var head_contour := CharacterSurface.rounded_contour(PackedVector2Array([
        head+Vector2(-24,-12), head+Vector2(4,-18), head+Vector2(27,-10),
        head+Vector2(34,-2), head+Vector2(27,10), head+Vector2(5,17), head+Vector2(-24,11),
    ]))
    CharacterSurface.draw_volume(self,head_contour,body.lightened(0.08),0.4)
    draw_colored_polygon(PackedVector2Array([head+Vector2(-21,4),head+Vector2(26,1+float(rig_pose.jaw_open)),head+Vector2(27,10+float(rig_pose.jaw_open)),head+Vector2(5,17),head+Vector2(-24,11)]),Color(belly,0.44))
    CharacterSurface.draw_volume(self,CharacterSurface.ellipse(head+Vector2(7,-5),Vector2(15,7),-0.08),Color(body.lightened(0.30),0.26),0.0,true)
    CharacterSurface.draw_volume(self,CharacterSurface.ellipse(head+Vector2(10,8+float(rig_pose.jaw_open)*0.35),Vector2(17,5),0.06),Color(belly.lightened(0.20),0.30),0.0,true)
    head_contour.append(head_contour[0])
    draw_polyline(head_contour,marking.darkened(0.20),1.2,true)
    for scale_index in range(5):
        var scale_center := head + Vector2(-13.0+float(scale_index)*8.0,-5.0+float(scale_index%2)*5.0)
        draw_arc(scale_center,3.2,3.3,6.0,8,Color(0.95,0.89,0.52,0.24),0.8,true)
    for brow_side: float in [-1.0,1.0]:
        var brow := head + Vector2(9.0,brow_side*7.0)
        draw_arc(brow,6.5,3.45,5.92,10,Color(body.lightened(0.46),0.50),1.5,true)
    var jaw_shadow := PackedVector2Array([head+Vector2(-18,8),head+Vector2(4,13),head+Vector2(26,7+float(rig_pose.jaw_open))])
    draw_polyline(jaw_shadow,Color(marking.darkened(0.28),0.72),2.2,true)
    for eye_y in [-7.0,7.0]:
        var eye := head + Vector2(12,eye_y)
        draw_circle(eye,5.0,Color("d9b63f"))
        draw_circle(eye,3.4,Color("7f943a"))
        draw_line(eye+Vector2(float(rig_pose.eye_focus),-2.7),eye+Vector2(float(rig_pose.eye_focus),2.7),Color("170f08"),2.0,true)
        draw_circle(eye+Vector2(-1.3,-1.5),0.9,Color(1.0,1.0,0.88,0.92))
    draw_circle(head+Vector2(24,-3),1.7,Color("312019"))
    draw_circle(head+Vector2(24,3),1.7,Color("312019"))
    draw_arc(head+Vector2(5,1+float(rig_pose.jaw_open)*0.45),28.0,-0.18,0.52,16,Color("2b2216"),2.0,true)
    var tongue_length := 14.0 + float(rig_pose.tongue_extension)
    draw_line(head+Vector2(32,2),head+Vector2(32+tongue_length,2),Color("e45d62"),2.2,true)
    draw_line(head+Vector2(32+tongue_length,2),head+Vector2(40+tongue_length,-5),Color("e45d62"),2.2,true)
    draw_line(head+Vector2(32+tongue_length,2),head+Vector2(40+tongue_length,9),Color("e45d62"),2.2,true)

func _draw_impact_burst() -> void:
    var lifetime := 0.62
    var progress := 1.0 - clampf(impact_burst_seconds / lifetime, 0.0, 1.0)
    var radius := 18.0 + progress * 68.0
    var alpha := 1.0 - progress
    draw_circle(impact_burst_origin, radius * 0.58, Color(0.92,0.72,0.25,0.20 * alpha))
    draw_arc(impact_burst_origin, radius, 0, TAU, 32, Color(0.86,0.97,1.0,0.90 * alpha), 5)
    draw_arc(impact_burst_origin, radius * 0.72, 0, TAU, 24, Color(1.0,0.74,0.25,0.82 * alpha), 4)
    for ray in range(12):
        var angle := float(ray) * TAU / 12.0
        var inner := impact_burst_origin + Vector2.from_angle(angle) * radius * 0.42
        var outer := impact_burst_origin + Vector2.from_angle(angle) * radius * (0.82 + float(ray % 3) * 0.10)
        draw_line(inner, outer, Color(0.78,0.95,1.0,0.88 * alpha), 4)
        draw_circle(outer, 3.0 + float(ray % 2) * 2.0, Color(0.93,0.99,1.0,0.82 * alpha))
    _text(impact_burst_origin + Vector2(0,-radius-12), impact_burst_kind + "!", 14, Color(1.0,0.91,0.55,alpha), HORIZONTAL_ALIGNMENT_CENTER, 160)

func _draw_heron(position: Vector2, profile: Dictionary, rig_pose: Dictionary, rig_surface: Dictionary) -> void:
    var feathers := Color(profile.body)
    var wing := Color(profile.wing)
    var marking := Color(profile.marking)
    var wing_lift := float(rig_pose.wing_primary)
    var feather_lift := float(rig_pose.feather_lift)
    draw_colored_polygon(_ellipse_points(position+Vector2(3,8),Vector2(36,25),-0.12),Color(0.01,0.04,0.05,0.38))
    _draw_volume_ellipse(position,Vector2(31,23),-0.12,feathers,rig_surface)
    CharacterSurface.draw_volume(self,CharacterSurface.ellipse(position+Vector2(7,5),Vector2(23,15),-0.16),Color(feathers.lightened(0.22),0.38),0.0,true)
    draw_colored_polygon(PackedVector2Array([
        position+Vector2(-25,7),position+Vector2(-54,-8-wing_lift*0.48),position+Vector2(-37,21+float(rig_pose.wing_secondary)*0.45),position+Vector2(14,15),position+Vector2(8,-15),
    ]),wing)
    _draw_volume_ellipse(position+Vector2(-13,-2),Vector2(17,16),-0.24,wing,rig_surface,0.74)
    # Overlapping scapular and covert feather plates replace the old flat wing
    # read with a layered wading-bird shoulder silhouette.
    for covert in range(5):
        var covert_center := position + Vector2(-17.0+float(covert)*5.4,-8.0+float(covert%2)*5.0)
        CharacterSurface.draw_volume(self,CharacterSurface.ellipse(covert_center,Vector2(10.0,5.5),-0.28),Color(wing.lightened(0.12+float(covert)*0.025),0.76),0.12)
        draw_arc(covert_center,6.0,0.15,PI-0.15,12,Color(0.91,0.98,1.0,0.22),0.75,true)
    for feather in range(7):
        var feather_start := position+Vector2(-37+float(feather)*7.0,-3+float(feather)*3.2)
        var feather_end := feather_start+Vector2(-27+float(feather)*3.0-feather_lift,20-wing_lift*0.28+float(rig_pose.wing_secondary)*0.32)
        var feather_direction := (feather_end-feather_start).normalized()
        var feather_side := Vector2(-feather_direction.y,feather_direction.x)*3.5
        var feather_shape := PackedVector2Array([feather_start-feather_side,feather_end,feather_start+feather_side,feather_start-feather_direction*5])
        CharacterSurface.draw_volume(self,feather_shape,wing.lightened(0.10+float(feather)*0.035),0.12)
        draw_line(feather_start,feather_end,Color(0.88,0.96,1.0,0.32),0.75,true)
    draw_arc(position+Vector2(-5,1),24.0,2.8,5.7,22,Color(0.90,0.97,0.98,0.40),2.0,true)
    var breast_keel := PackedVector2Array([position+Vector2(14,-12),position+Vector2(22,1),position+Vector2(14,17),position+Vector2(2,21)])
    draw_polyline(breast_keel,Color(feathers.lightened(0.44),0.46),2.0,true)
    var neck_points := PackedVector2Array([
        position+Vector2(18,-11),position+Vector2(30+float(rig_pose.neck_curve),-25),position+Vector2(25-float(rig_pose.neck_curve)*0.55,-41),position+Vector2(38+float(rig_pose.neck_curve)*0.35,-56),
    ])
    neck_points = CharacterSurface.smooth_line(CharacterSurface.smooth_line(neck_points))
    draw_polyline(neck_points,marking,13.0,true)
    draw_polyline(neck_points,feathers.lightened(0.12),9.0,true)
    var neck_highlight := PackedVector2Array([
        position+Vector2(16,-12),position+Vector2(27+float(rig_pose.neck_curve),-26),position+Vector2(22-float(rig_pose.neck_curve)*0.55,-41),position+Vector2(35+float(rig_pose.neck_curve)*0.35,-55),
    ])
    draw_polyline(CharacterSurface.smooth_line(CharacterSurface.smooth_line(neck_highlight)),Color(0.95,1.0,1.0,0.46),2.2,true)
    var head := position+Vector2(42+float(rig_pose.neck_curve)*0.35,-59+float(rig_pose.head_pitch)*18.0)
    draw_colored_polygon(_ellipse_points(head+Vector2(2,3),Vector2(17,12),-0.12),Color(0.01,0.04,0.05,0.35))
    _draw_volume_ellipse(head,Vector2(15,11),-0.12,feathers.lightened(0.18),rig_surface,0.76)
    draw_line(head+Vector2(-13,-8),head+Vector2(1,-17),marking,5.0,true)
    draw_line(head+Vector2(-11,-10),head+Vector2(-22,-17),marking,2.2,true)
    draw_line(head+Vector2(-8,-11),head+Vector2(-17,-21),marking,1.7,true)
    draw_colored_polygon(PackedVector2Array([head+Vector2(11,-2),head+Vector2(54,2),head+Vector2(11,7+float(rig_pose.jaw_open))]),Color("e7b94e"))
    draw_colored_polygon(PackedVector2Array([head+Vector2(13,-1),head+Vector2(52,2),head+Vector2(13,2)]),Color(1.0,0.85,0.34,0.68))
    draw_line(head+Vector2(13,1),head+Vector2(52,2),Color("5b492a"),1.6)
    draw_circle(head+Vector2(41,0.8),1.1,Color("6b4a22"))
    draw_circle(head+Vector2(5,-4),3.6,Color("fff3c2"))
    draw_circle(head+Vector2(6+float(rig_pose.eye_focus),-4),2.1,Color("172026"))
    draw_circle(head+Vector2(5.4,-4.8),0.7,Color(1.0,1.0,0.94,0.94))
    var foot_contacts := WaterContactArt.heron_feet(rig_pose)
    for foot_index in 2:
        var leg_x := -9.0 if foot_index == 0 else 9.0
        var leg_motion := float(rig_pose.leg_lift) if leg_x < 0.0 else -float(rig_pose.leg_lift) * 0.42
        var knee := position+Vector2(leg_x,42-leg_motion)
        var ankle := position + foot_contacts[foot_index]
        draw_line(position+Vector2(leg_x,19),knee,Color("d7b253"),3.2)
        draw_line(knee,ankle,Color("d7b253"),2.6)
        draw_circle(knee,2.8,Color("a97d32"))
        draw_circle(knee-Vector2(0.7,0.8),1.5,Color("f1cf76"))
        draw_circle(ankle,2.2,Color("a97d32"))
        var toe_spread := float(rig_pose.toe_spread)
        draw_line(ankle,ankle+Vector2(-13-toe_spread,5),Color("d7b253"),2.0)
        draw_line(ankle,ankle+Vector2(13+toe_spread,5),Color("d7b253"),2.0)
        draw_line(ankle,ankle+Vector2(2,-7),Color("d7b253"),1.7)
        for toe_tip in [ankle+Vector2(-13-toe_spread,5),ankle+Vector2(13+toe_spread,5),ankle+Vector2(2,-7)]:
            draw_circle(toe_tip,1.5,Color("f0cb6d"))

func _draw_reeds(sway: float) -> void:
    for x in range(55,1240,95):
        var base := Vector2(x,680)
        BotanicalArt.draw_reed(self, base, 46.0 + (x % 3) * 8, sway, x % 3 == 0)

func _draw_bug(position: Vector2, index: int, flutter: float, show_label: bool = true) -> void:
    var rig_pose: Dictionary = WildlifeAnimationRig.pose("BUG", index, simulation_time, reduced_motion)
    var rig_surface: Dictionary = WildlifeAnimationRig.surface_profile("BUG", index, simulation_time, reduced_motion)
    position += Vector2(0.0,float(rig_pose.hover_lift))
    CollectibleWildlifeArt.draw_bug(self, position, rig_pose, rig_surface, flutter)
    if show_label:
        _text(position+Vector2(1,CollectibleWildlifeArt.BUG_LABEL_Y+1), "BUG %d" % (index + 1), 11, Color(0.01,0.04,0.05,0.85), HORIZONTAL_ALIGNMENT_CENTER, 70)
        _text(position+Vector2(0,CollectibleWildlifeArt.BUG_LABEL_Y), "BUG %d" % (index + 1), 11, Color("fff7cb"), HORIZONTAL_ALIGNMENT_CENTER, 70)

func _draw_fairy(position: Vector2, show_label: bool = true) -> void:
    var rig_pose: Dictionary = WildlifeAnimationRig.pose("FAIRY", 0, simulation_time, reduced_motion)
    var rig_surface: Dictionary = WildlifeAnimationRig.surface_profile("FAIRY", 0, simulation_time, reduced_motion)
    position += Vector2(0.0,float(rig_pose.hover_lift))
    CollectibleWildlifeArt.draw_fairy(self, position, rig_pose, rig_surface)
    if show_label:
        _text(position+Vector2(1,CollectibleWildlifeArt.FAIRY_LABEL_Y+1), CollectibleWildlifeArt.FAIRY_LABEL, 11, Color(0.01,0.04,0.05,0.85), HORIZONTAL_ALIGNMENT_CENTER, 100)
        _text(position+Vector2(0,CollectibleWildlifeArt.FAIRY_LABEL_Y), CollectibleWildlifeArt.FAIRY_LABEL, 11, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 100)

func _draw_eating_effect(origin: Vector2, target: Vector2) -> void:
    var progress: float = 1.0 if reduced_motion else tongue.extension_ratio()
    var tongue_tip := origin.lerp(target, progress)
    var tongue_color := Color(customization.current_style().tongue_color)
    if tongue.outcome == "miss":
        tongue_color = Color("ffd36a")
    elif tongue.outcome == "blocked":
        tongue_color = Color("d7edf0")
    draw_line(origin + Vector2(0,5), tongue_tip, tongue_color.darkened(0.35), 11)
    draw_line(origin + Vector2(0,5), tongue_tip, tongue_color, 7)
    draw_circle(tongue_tip, 7, tongue_color.lightened(0.18))
    draw_arc(origin + Vector2(0,4), 13, 0.15, PI - 0.15, 12, Color("311629"), 4)
    _text(origin + Vector2(0,-48), "[%s]" % tongue.cue(), 13, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 180)

func _draw_tongue_aim(origin: Vector2) -> void:
    var direction := last_aim_direction.normalized()
    var marker := origin + direction * 58.0
    draw_line(origin + direction * 30.0, marker, Color(1.0,0.94,0.58,0.58), 2)
    draw_arc(marker, 7, 0, TAU, 12, Color("fff0ae"), 2)
    _text(marker + Vector2(0,-13), "MUNCH", 9, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 58)

func _draw_overlay(title: String, subtitle: String, action: String, rect: Rect2, cue: String) -> void:
    draw_rect(Rect2(350,245,580,300), Color(0.02,0.07,0.1,0.94), true)
    draw_rect(Rect2(350,245,580,300), Color("70d6c2"), false, 4)
    _text(Vector2(640,275), "[%s]" % cue, 15, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 500)
    _text(Vector2(640,315), title, 35, Color("f7d36a"), HORIZONTAL_ALIGNMENT_CENTER, 520)
    _text(Vector2(640,365), subtitle, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 520)
    _button(rect, action)

func _draw_countdown() -> void:
    draw_rect(Rect2(390,210,500,310), Color(0.01,0.04,0.07,0.94), true)
    draw_rect(Rect2(390,210,500,310), Color("f7d36a"), false, 5)
    _text(Vector2(640,255), "[GET READY]", 18, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 460)
    _text(Vector2(640,385), str(maxi(1, ceili(countdown_seconds))), 112, Color("f7d36a"), HORIZONTAL_ALIGNMENT_CENTER, 460)
    _text(Vector2(640,455), "Level %03d begins soon" % level_number, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 460)

func _draw_failure() -> void:
    draw_rect(Rect2(0,0,1280,720), Color(0.08,0.02,0.04,0.94), true)
    var center := Vector2(640,295)
    var splat := PackedVector2Array()
    for index in range(24):
        var angle := float(index) * TAU / 24.0
        var radius := 170.0 if index % 2 == 0 else 115.0
        if index % 6 == 0: radius = 235.0
        splat.append(center + Vector2.from_angle(angle) * radius)
    draw_colored_polygon(splat, Color("4f9b45"))
    draw_circle(center, 132, Color("6fc75f"))
    draw_circle(center + Vector2(-55,-82), 38, Color("173128"))
    draw_circle(center + Vector2(55,-82), 38, Color("173128"))
    draw_circle(center + Vector2(-55,-82), 30, Color("7ddb70"))
    draw_circle(center + Vector2(55,-82), 30, Color("7ddb70"))
    draw_line(center + Vector2(-68,-91), center + Vector2(-43,-72), Color("173128"), 7)
    draw_line(center + Vector2(-43,-91), center + Vector2(-68,-72), Color("173128"), 7)
    draw_line(center + Vector2(43,-91), center + Vector2(68,-72), Color("173128"), 7)
    draw_line(center + Vector2(68,-91), center + Vector2(43,-72), Color("173128"), 7)
    draw_arc(center + Vector2(0,35), 42, PI+0.25, TAU-0.25, 18, Color("173128"), 7)
    _text(Vector2(640,72), "OH NO FRED!!!", 58, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 920)
    _text(Vector2(640,445), "Fred is muddy but safe. Ready for another marsh run?", 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 820)
    _button(Rect2(365,500,250,64), "TRY AGAIN?")
    _button(Rect2(665,500,250,64), "GO HOME?")
    _text(Vector2(640,605), "Try Again restarts at Level 001  |  Home returns to the main menu", 16, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 820)

func _draw_leaderboard() -> void:
    draw_rect(Rect2(0,0,1280,720), Color("03141f"), true)
    draw_circle(Vector2(180,120), 110, Color(0.2,0.75,0.55,0.08))
    draw_circle(Vector2(1100,600), 170, Color(0.5,0.3,0.8,0.07))
    _text(Vector2(640,70), "LOCAL MARSH LEADERS", 42, Color("f7d36a"), HORIZONTAL_ALIGNMENT_CENTER, 850)
    _text(Vector2(640,112), "Offline-first scores • %s" % game_center_status, 17, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 850)
    draw_rect(Rect2(260,145,760,450), Color(0.01,0.07,0.10,0.90), true)
    draw_rect(Rect2(260,145,760,450), Color("70d6c2"), false, 3)
    _text(Vector2(300,180), "RANK", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_LEFT, 90)
    _text(Vector2(420,180), "PLAYER", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_LEFT, 250)
    _text(Vector2(720,180), "LEVEL", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_LEFT, 100)
    _text(Vector2(880,180), "SCORE", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_LEFT, 110)
    var entries := leaderboard.load_entries()
    if entries.is_empty():
        _text(Vector2(640,350), "Complete a level to place Fred on the board!", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 650)
    else:
        for index in mini(entries.size(), 8):
            var entry: Dictionary = entries[index]
            var y := 225.0 + float(index) * 43.0
            draw_rect(Rect2(282,y-25,716,36), Color(0.2,0.7,0.6,0.06 if index % 2 == 0 else 0.11), true)
            _text(Vector2(315,y), "#%d" % (index+1), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 80)
            _text(Vector2(420,y), str(entry.get("player","GUEST FROG")), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 250)
            _text(Vector2(740,y), "%03d" % int(entry.get("level",1)), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 90)
            _text(Vector2(875,y), str(entry.get("score",0)), 17, Color("fff0ae"), HORIZONTAL_ALIGNMENT_LEFT, 110)
    if _game_center_available():
        if game_center.is_authenticated():
            _button(LEADERBOARD_GAME_CENTER_RECT, "OPEN GAME CENTER")
        elif _game_center_auth_state() == "authenticating":
            _button(LEADERBOARD_GAME_CENTER_RECT, "CONNECTING...")
        else:
            _button(LEADERBOARD_GAME_CENTER_RECT, "CONNECT GAME CENTER")
        _button(LEADERBOARD_HOME_SPLIT_RECT, "HOME")
    else:
        _button(LEADERBOARD_HOME_CENTER_RECT, "HOME")
    _text(Vector2(640,704), "Apple sign-in is optional. Local play and scores always remain available.", 13, Color("bfd8dc"), HORIZONTAL_ALIGNMENT_CENTER, 900)

func _button(rect: Rect2, label: String) -> void:
    draw_rect(Rect2(rect.position+Vector2(0,6),rect.size), Color(0.0,0.02,0.03,0.55), true)
    draw_rect(rect, Color("d99a2b"), true)
    draw_rect(Rect2(rect.position+Vector2(3,3),rect.size-Vector2(6,9)), Color("f2c34e"), true)
    draw_line(rect.position+Vector2(5,5), rect.position+Vector2(rect.size.x-5,5), Color("fff4bd"), 3)
    draw_rect(rect, Color("fff0ae"), false, 3)
    _text(rect.position + Vector2(rect.size.x/2, rect.size.y/2+8), label, 20, Color("102935"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _status_panel(rect: Rect2, size: int) -> void:
    draw_rect(rect, FredSaveFeedback.PANEL_BACKGROUND, true)
    draw_rect(rect, FredSaveFeedback.PANEL_BORDER, false, 2)
    var layout := MarshLabelLayout.footer(save_feedback,ThemeDB.fallback_font,size,rect.size-Vector2(16,6))
    if not bool(layout.valid):
        return
    var top: float = rect.get_center().y - float(layout.line_height)*layout.lines.size()*0.5
    for index in layout.lines.size():
        _text(Vector2(rect.get_center().x,top+float(layout.ascent)+index*float(layout.line_height)),layout.lines[index],layout.size,FredSaveFeedback.PANEL_TEXT,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-16)

func _text(anchor: Vector2, value: String, size: int, color: Color, alignment: HorizontalAlignment, width: float) -> void:
    var font := ThemeDB.fallback_font
    var x := anchor.x if alignment == HORIZONTAL_ALIGNMENT_LEFT else anchor.x-width/2
    draw_string(font, Vector2(x,anchor.y), value, alignment, width, size, color)
