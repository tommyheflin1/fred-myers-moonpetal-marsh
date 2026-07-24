extends Node2D

const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")

enum Screen { TITLE, PLAYING, FAILED, COMPLETE }
const START := Vector2(135, 560)
const EXIT := Vector2(1150, 120)
const PADS := [Vector2(220,500), Vector2(350,420), Vector2(490,500), Vector2(630,390), Vector2(760,300), Vector2(900,225), Vector2(1040,165)]
const BUGS := [Vector2(350,390), Vector2(625,360), Vector2(900,195)]
const SAFE_LOCATION := Vector2(720,570)
const PREDATOR_START := Vector2(850,520)
const WHIRLPOOLS := [Vector2(500,405), Vector2(790,315), Vector2(960,500)]

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

func _ready() -> void:
    if "--reduced-motion" in OS.get_cmdline_user_args():
        reduced_motion = true
    var result := saver.load_session(session)
    _set_feedback(FredSaveFeedback.load_message(result))
    set_process(true)
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
    eat_effect_seconds = maxf(0.0, eat_effect_seconds - maxf(0.0, delta))
    impact_burst_seconds = maxf(0.0, impact_burst_seconds - maxf(0.0, delta))
    queue_redraw()

func _fixed_tick(delta: float) -> void:
    simulation_time += maxf(0.0, delta)
    danger_cooldown_seconds = maxf(0.0, danger_cooldown_seconds - maxf(0.0, delta))
    var direction := FredInputIntent.movement()
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
    direction = direction.normalized()
    if FredInputIntent.pressed(FredInputIntent.Intent.LEAP):
        _request_leap(direction)
    var depth_step: Dictionary = depth.advance(delta)
    if bool(depth_step.completed):
        session.set_underwater(str(depth_step.mode) == "underwater")
        _set_feedback("[DEPTH] Fred reached the %s." % str(depth_step.mode))
    var current := _current_vector()
    if leap.state == LeapTraversal.State.AIRBORNE:
        var leap_step: Dictionary = leap.advance(delta)
        fred = (fred + Vector2(leap_step.movement) + current * delta * 0.35).clamp(Vector2(55,105), Vector2(1225,665))
        if bool(leap_step.landed):
            _resolve_landing()
    else:
        leap.advance(delta)
        var speed := 210.0 * float(depth.movement_scale())
        if depth.is_transitioning():
            speed *= 0.55
        if FredInputIntent.held(FredInputIntent.Intent.BOOST) and session.use_boost(1):
            speed = 380.0 * (DepthTraversal.UNDERWATER_BOOST_SCALE if depth.is_underwater_band() else 1.0)
        elif direction == Vector2.ZERO: session.recharge_boost(1)
        fred = (fred + (direction * speed + current) * delta).clamp(Vector2(55,105), Vector2(1225,665))
    camera_response_y = 0.0 if reduced_motion else (-minf(10.0, leap.visual_height * 0.18) + float(depth.depth) * 8.0)
    predator.x += predator_direction * 110.0 * float(level_profile.predator_speed_scale) * delta
    if bool(level_profile.weaving_patrol):
        predator.y = PREDATOR_START.y + sin(visual_time * (0.8 + float(level_number) * 0.015)) * minf(115.0, 42.0 + float(level_number))
    if predator.x > 1120 or predator.x < 760: predator_direction *= -1.0
    _update_secondary_predators()
    in_safe_location = fred.distance_to(SAFE_LOCATION) < float(level_profile.safe_radius)
    for index in BUGS.size():
        var bug_position := _bug_position(index)
        if index not in collected and fred.distance_to(bug_position) < 35:
            eat_target = bug_position
            eat_effect_seconds = 0.32
            collected.append(index); session.collect_bug(); _set_feedback("[MUNCH!] Fred ate a marsh bug.")
    if fred.distance_to(_pad_position(3)) < 42 and session.checkpoint_sequence < 1:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1); _save("Midpoint is safe.")
    if _check_danger_collision():
        return
    if fred.distance_to(EXIT) < 55 and session.complete_level():
        screen = Screen.COMPLETE; _save("Lily Leap is complete.")

func _current_vector() -> Vector2:
    var strength := float(level_profile.current_strength)
    if is_zero_approx(strength):
        return Vector2.ZERO
    var direction := 1.0
    if bool(level_profile.reversing_current):
        var frequency := 0.65 if level_number < 8 else 1.05
        direction = 1.0 if sin(visual_time * frequency) >= 0.0 else -1.0
    var vertical := 0.0
    if level_number >= 7 and depth.is_underwater_band():
        vertical = sin(visual_time * 0.9) * strength * 0.55
    return Vector2(strength * direction, vertical)

func _update_secondary_predators() -> void:
    var pressure := float(level_profile.predator_speed_scale)
    secondary_predators[0] = Vector2(505 + sin(simulation_time * 1.15 * pressure) * 190, 250 + cos(simulation_time * 0.75) * 55)
    secondary_predators[1] = Vector2(1030 + cos(simulation_time * 0.62 * pressure) * 105, 350 + sin(simulation_time * 0.94) * 125)
    secondary_predators[2] = Vector2(770 + sin(simulation_time * 0.82) * 135, 175 + absf(sin(simulation_time * 1.28)) * 125)
    secondary_predators[3] = Vector2(405 + cos(simulation_time * 1.05) * 150, 575 + sin(simulation_time * 0.65) * 55)

func _pad_position(index: int) -> Vector2:
    var base: Vector2 = PADS[index]
    var level_phase := float(level_number * 17 + index * 31)
    var level_offset := Vector2(
        sin(level_phase * 0.19) * minf(34.0, 8.0 + float(level_number) * 0.28),
        cos(level_phase * 0.13) * minf(26.0, 6.0 + float(level_number) * 0.20)
    )
    var drift := float(level_profile.lily_drift)
    var motion := Vector2(
        sin(simulation_time * (0.22 + float(index % 3) * 0.035) + float(index)) * drift,
        cos(simulation_time * (0.18 + float(index % 2) * 0.04) + float(index) * 0.7) * drift * 0.55
    )
    return (base + level_offset + motion).clamp(Vector2(100, 140), Vector2(1135, 620))

func _bug_position(index: int) -> Vector2:
    var base: Vector2 = BUGS[index]
    var radius := float(level_profile.bug_flight_radius)
    var speed := float(level_profile.bug_flight_speed)
    var level_phase := float(level_number * 23 + index * 41)
    var level_offset := Vector2(sin(level_phase * 0.17) * 38.0, cos(level_phase * 0.11) * 25.0)
    var angle := simulation_time * speed * (1.0 if index % 2 == 0 else -1.0) + float(index) * 2.1
    var flight := Vector2(cos(angle) * radius, sin(angle * 1.35) * radius * 0.72)
    return (base + level_offset + flight).clamp(Vector2(90, 130), Vector2(1170, 620))

func _active_predator_positions() -> Array[Vector2]:
    var positions: Array[Vector2] = [predator]
    var extra_count := maxi(0, int(level_profile.predator_count) - 1)
    for index in range(mini(extra_count, secondary_predators.size())):
        positions.append(secondary_predators[index])
    return positions

func _check_danger_collision() -> bool:
    if danger_cooldown_seconds > 0.0 or in_safe_location:
        return false
    if fred.distance_to(predator) < float(level_profile.danger_radius):
        _apply_danger_hit("[DANGER] A marsh predator caught Fred!")
        return true
    if not hazards_enabled:
        return false
    var active_positions := _active_predator_positions()
    for index in range(1, active_positions.size()):
        var position: Vector2 = active_positions[index]
        if fred.distance_to(position) < float(level_profile.danger_radius):
            _apply_danger_hit("[DANGER] A marsh predator caught Fred!")
            return true
    for index in range(mini(int(level_profile.whirlpool_count), WHIRLPOOLS.size())):
        if fred.distance_to(WHIRLPOOLS[index]) < 50.0:
            _apply_danger_hit("[WHIRLPOOL] The current swept Fred back!")
            return true
    return false

func _apply_danger_hit(message: String) -> void:
    impact_burst_origin = fred
    impact_burst_seconds = 0.62
    impact_burst_kind = "CURRENT BURST" if message.begins_with("[WHIRLPOOL]") else ("LANDING SPLASH" if message.begins_with("[LANDING]") else "PREDATOR HIT")
    leap.reset()
    depth.reset("surface")
    session.set_underwater(false)
    camera_response_y = 0.0
    fred = START
    danger_cooldown_seconds = 1.0
    _set_feedback(message)
    if session.damage():
        screen = Screen.FAILED

func direct_route_has_danger() -> bool:
    for step in range(1, 20):
        var point := START.lerp(EXIT, float(step) / 20.0)
        for index in range(mini(int(level_profile.whirlpool_count), WHIRLPOOLS.size())):
            if point.distance_to(WHIRLPOOLS[index]) < 58.0:
                return true
    return false

func _request_leap(requested_direction: Vector2) -> bool:
    if screen != Screen.PLAYING or session.paused or depth.state != DepthTraversal.State.SURFACE:
        return false
    var accepted: bool = leap.request(requested_direction)
    if accepted:
        _set_feedback("[LEAP] Fred launched toward a landing.")
    return accepted

func _can_dive_here(position: Vector2) -> bool:
    if position.distance_to(START) < 62.0 or position.distance_to(SAFE_LOCATION) < float(level_profile.safe_radius) + 8.0:
        return false
    if position.distance_to(EXIT) < 52.0:
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
        _set_feedback("[DIVING] Hold your course while Fred descends.")
    elif depth.state == DepthTraversal.State.SURFACE and not allowed:
        _set_feedback("[DIVE BLOCKED] Move into open water.")
    return accepted

func _request_surface() -> bool:
    if screen != Screen.PLAYING or session.paused or leap.state != LeapTraversal.State.GROUNDED:
        return false
    var accepted: bool = depth.request_surface(true)
    if accepted:
        _set_feedback("[SURFACING] Fred is swimming toward the light.")
    return accepted

func _is_valid_landing(position: Vector2) -> bool:
    if position.distance_to(START) <= 78.0 or position.distance_to(SAFE_LOCATION) <= float(level_profile.safe_radius) + 16.0:
        return true
    if position.distance_to(EXIT) <= 58.0:
        return true
    for index in PADS.size():
        if position.distance_to(_pad_position(index)) <= 64.0:
            return true
    return false

func _resolve_landing() -> bool:
    if _is_valid_landing(fred):
        _set_feedback("[LANDING] Fred found a safe perch.")
        return true
    _apply_danger_hit("[LANDING] Fred splashed down away from a safe perch!")
    return false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _handle_click(event.position)
    if not event is InputEventKey and event.is_action_pressed("pause") and screen == Screen.PLAYING:
        session.paused = not session.paused
        _set_feedback("[PAUSED] Your last checkpoint is safe." if session.paused else "[PLAYING] Adventure resumed.")
    if not event is InputEventKey and event.is_action_pressed("dive") and screen == Screen.PLAYING:
        _request_dive()
    if not event is InputEventKey and event.is_action_pressed("surface") and screen == Screen.PLAYING:
        _request_surface()
    if not event is InputEventKey and event.is_action_pressed("leap") and screen == Screen.PLAYING:
        _request_leap(FredInputIntent.movement())
    if not event is InputEventKey and event.is_action_pressed("retry") and screen == Screen.FAILED: _retry()
    if not event is InputEventKey and event.is_action_pressed("confirm") and screen == Screen.TITLE: _start()
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_Q:
                if screen == Screen.PLAYING: _request_dive()
            KEY_E:
                if screen == Screen.PLAYING: _request_surface()
            KEY_P, KEY_ESCAPE:
                if screen == Screen.PLAYING:
                    session.paused = not session.paused
                    _set_feedback("[PAUSED] Your last checkpoint is safe." if session.paused else "[PLAYING] Adventure resumed.")
            KEY_R:
                if screen == Screen.FAILED: _retry()
            KEY_ENTER:
                if screen == Screen.TITLE: _start()
                elif screen == Screen.COMPLETE: _advance_level()

func _handle_click(position: Vector2) -> void:
    if screen == Screen.TITLE and Rect2(490,440,300,70).has_point(position): _start()
    elif screen == Screen.PLAYING and Rect2(1120,20,120,48).has_point(position):
        session.paused = not session.paused
        _set_feedback("[PAUSED] Your last checkpoint is safe." if session.paused else "[PLAYING] Adventure resumed.")
    elif screen == Screen.PLAYING and session.paused and Rect2(490,410,300,65).has_point(position):
        session.paused = false; _set_feedback("[PLAYING] Adventure resumed.")
    elif screen == Screen.PLAYING:
        _request_leap(position - fred)
    elif screen == Screen.FAILED and Rect2(490,430,300,70).has_point(position): _retry()
    elif screen == Screen.COMPLETE and Rect2(490,500,300,60).has_point(position):
        _advance_level()

func _start() -> void:
    if session.completed:
        session = AdventureSession.new(1337)
        _set_feedback("[NEW GAME] A fresh Lily Leap run is ready.")
    screen = Screen.PLAYING
    fred = Vector2(630,390) if session.current_checkpoint == AdventureSession.CHECKPOINTS[1] else START
    collected.clear()
    for index in range(mini(session.bug_count, BUGS.size())): collected.append(index)
    queue_redraw()

func _retry() -> void:
    session.retry_from_checkpoint()
    leap.reset()
    depth.reset("surface")
    session.set_underwater(false)
    camera_response_y = 0.0
    fred = Vector2(630,390) if session.current_checkpoint == AdventureSession.CHECKPOINTS[1] else START
    screen = Screen.PLAYING; _set_feedback("[RESTORED] Your checkpoint is ready.")

func _advance_level() -> void:
    level_number = mini(FredLevelIntensity.MAX_LEVEL, level_number + 1)
    level_profile = FredLevelIntensity.profile(level_number)
    session = AdventureSession.new(1337 + level_number)
    fred = START
    predator = PREDATOR_START + Vector2(-25.0 * float((level_number - 1) % 4), 0)
    collected.clear()
    eat_effect_seconds = 0.0
    simulation_time = 0.0
    danger_cooldown_seconds = 0.0
    impact_burst_seconds = 0.0
    leap.reset()
    depth.reset("surface")
    camera_response_y = 0.0
    screen = Screen.PLAYING
    depth.reset(session.player_state)
    _set_feedback("[NEW TWIST] %s" % str(level_profile.new_twist))

func _save(message: String) -> void:
    var timestamp := Time.get_datetime_string_from_system(true, true)
    var result := saver.save(session, timestamp)
    _set_feedback(FredSaveFeedback.save_message(result, message))

func _set_feedback(message: String) -> void:
    save_feedback = message
    save_feedback_seconds = FredSaveFeedback.DISPLAY_SECONDS
    queue_redraw()

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
    _draw_level()
    if screen == Screen.FAILED: _draw_overlay("Fred got gobbled!", "Press R or click Retry", "Retry", Rect2(490,430,300,70), "TRY AGAIN")
    elif screen == Screen.COMPLETE: _draw_overlay("Lily Leap Complete!", "Level %03d is ready." % mini(100, level_number + 1), "Next Level", Rect2(490,500,300,60), "LEVEL CLEAR")
    elif session.paused: _draw_overlay("Marsh Paused", "Your checkpoint is safe.", "Resume", Rect2(490,410,300,65), "PAUSED")

func _draw_title() -> void:
    var visual := FredVisualState.snapshot(visual_time, reduced_motion)
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
    _status_panel(Rect2(280,510,720,46), 18)
    if reduced_motion:
        _text(Vector2(640,675), "[REDUCED MOTION] All gameplay cues remain visible.", 15, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _text(Vector2(640,650), "[GUEST] Play now. Platform account linking stays optional.", 15, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 900)
    _text(Vector2(640,620), "WASD / arrows move  •  Space leaps  •  Shift boosts  •  Q dive  •  E surface  •  P pause", 17, Color("bfd8dc"), HORIZONTAL_ALIGNMENT_CENTER, 1100)

func _draw_level() -> void:
    var visual := FredVisualState.snapshot(visual_time, reduced_motion)
    var water := Color("075c78").lerp(Color("07334f"), float(depth.depth))
    draw_rect(Rect2(26,76,1228,618), Color("03131c"), true)
    draw_rect(Rect2(35,85,1210,600), water, true)
    draw_rect(Rect2(35,85,1210,600), Color("8be8e1"), false, 3)
    draw_rect(Rect2(35,85,1210,120), Color(0.2,0.75,0.85,0.08), true)
    _draw_depth_cues()
    for glow in [Vector2(180,155), Vector2(530,260), Vector2(1020,420)]:
        draw_circle(glow, 95, Color(0.2,0.85,0.78,0.035))
    draw_set_transform(Vector2(0,camera_response_y))
    _draw_current_trails()
    for row in range(4):
        var ripple_y := 150.0 + row * 130.0
        var shift := float(visual.water_shift) * (1.0 if row % 2 == 0 else -1.0)
        for x in range(55,1240,120):
            draw_line(Vector2(x + shift,ripple_y), Vector2(x + 58 + shift,ripple_y), Color(0.55,0.9,0.95,0.22), 3)
    _draw_reeds(float(visual.reed_sway))
    _draw_whirlpools()
    for index in PADS.size():
        var pad: Vector2 = _pad_position(index)
        var pad_bob := FredVisualState.wave(visual_time, float(index) * 0.65, 3.0, reduced_motion)
        var drawn_pad: Vector2 = pad + Vector2(0,pad_bob)
        draw_circle(drawn_pad + Vector2(0,5), 45, Color(0.01,0.12,0.12,0.3))
        draw_circle(drawn_pad, 43, Color("3d9a5a")); draw_arc(drawn_pad, 43, 0, TAU, 32, Color("a7df78"), 2)
        draw_line(drawn_pad, drawn_pad+Vector2(35,-18), Color("c4eb8b"), 5)
        for vein_angle in [-0.55, 0.0, 0.55]:
            draw_line(drawn_pad + Vector2(3,0), drawn_pad + Vector2.from_angle(vein_angle) * 28.0, Color(0.72,0.93,0.55,0.42), 2)
    var safe_radius := float(level_profile.safe_radius)
    draw_circle(SAFE_LOCATION, safe_radius + 7, Color(0.02,0.08,0.08,0.35))
    draw_circle(SAFE_LOCATION, safe_radius, Color("183f31"))
    draw_arc(SAFE_LOCATION, safe_radius, 0, TAU, 32, Color("8fe5a2"), 2)
    _text(SAFE_LOCATION+Vector2(0,7), "SAFE", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_CENTER, 100)
    for index in BUGS.size():
        if index not in collected:
            _draw_bug(_bug_position(index), index, float(visual.wildlife_flutter))
    var predator_names := ["BASS", "PIKE", "HERON", "SNAKE", "MUSKIE"]
    var active_positions := _active_predator_positions()
    for index in active_positions.size():
        _draw_predator(active_positions[index], predator_names[index])
    var exit_radius := 45.0 * float(visual.exit_pulse)
    draw_circle(EXIT, exit_radius + 5, Color(0.9,0.8,1.0,0.16)); draw_circle(EXIT, exit_radius, Color("d49cff"))
    _text(EXIT+Vector2(0,6), "EXIT", 15, Color("321c45"), HORIZONTAL_ALIGNMENT_CENTER, 90)
    if leap.state == LeapTraversal.State.GROUNDED:
        _draw_fred(fred + Vector2(0,float(visual.fred_bob)))
    else:
        draw_circle(fred + Vector2(0,10), 20.0 + leap.visual_height * 0.10, Color(0.01,0.05,0.08,0.28))
        _draw_fred(fred + Vector2(0,float(visual.fred_bob) - leap.visual_height))
        _text(fred + Vector2(0,-leap.visual_height-48), "[%s]" % leap.cue(), 13, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 120)
    if eat_effect_seconds > 0.0:
        _draw_eating_effect(fred + Vector2(0,float(visual.fred_bob)), eat_target)
    if impact_burst_seconds > 0.0:
        _draw_impact_burst()
    draw_set_transform(Vector2.ZERO)
    _text(Vector2(45,38), "LILY LEAP", 28, Color("f7d36a"), HORIZONTAL_ALIGNMENT_LEFT, 300)
    _text(Vector2(45,75), "LEVEL %03d  -  %s" % [level_profile.level, level_profile.label], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_LEFT, 280)
    _text(Vector2(890,75), "NEW: %s  |  THREATS %d" % [str(level_profile.new_twist).to_upper(), int(level_profile.predator_count)], 13, Color("fff0ae"), HORIZONTAL_ALIGNMENT_LEFT, 350)
    draw_rect(Rect2(330,10,560,52), Color("06151f"), true); draw_rect(Rect2(330,10,560,52), Color("e8fbff"), false, 2)
    _text(Vector2(350,43), "OBJECTIVE: " + ("Reach the moonpetal exit" if session.bug_count >= 3 else "Collect 3 marsh bugs"), 19, Color("e8fbff"), HORIZONTAL_ALIGNMENT_LEFT, 520)
    _text(Vector2(45,710), "Bugs %d/3   Boost %d%%   Health %s   %s %d%%" % [session.bug_count, session.boost_energy, "♥".repeat(session.health), depth.cue(), roundi(float(depth.depth) * 100.0)], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 850)
    _status_panel(Rect2(820,632,410,42), 16)
    _button(Rect2(1120,20,120,48), "PAUSE")
    if reduced_motion:
        _text(Vector2(1000,105), "[REDUCED MOTION]", 14, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 220)

func _draw_current_trails() -> void:
    if level_number < 2:
        return
    var current := _current_vector()
    var arrow := ">" if current.x >= 0.0 else "<"
    for row in range(3):
        for column in range(6):
            var point := Vector2(130 + column * 190, 210 + row * 145)
            var phase := 0.0 if reduced_motion else sin(visual_time * 1.4 + float(column + row)) * 10.0
            _text(point + Vector2(phase,0), arrow + arrow, 18, Color(0.65,0.95,1.0,0.36), HORIZONTAL_ALIGNMENT_CENTER, 54)

func _draw_depth_cues() -> void:
    var amount := float(depth.depth)
    if amount <= 0.001:
        return
    draw_rect(Rect2(35,85,1210,600), Color(0.01,0.07,0.16,0.20 * amount), true)
    for index in range(14):
        var phase := 0.0 if reduced_motion else fmod(visual_time * (18.0 + float(index % 3) * 3.0), 150.0)
        var bubble := Vector2(90 + index * 84, 620 - fmod(float(index * 47) + phase, 470.0))
        draw_circle(bubble, 2.0 + float(index % 3), Color(0.72,0.94,1.0,0.52 * amount), false, 2)
    _text(Vector2(1080,130), "[%s] DEPTH %d%%" % [depth.cue(), roundi(amount * 100.0)], 14, Color("d9f7ff"), HORIZONTAL_ALIGNMENT_CENTER, 260)

func _draw_whirlpools() -> void:
    for index in range(mini(int(level_profile.whirlpool_count), WHIRLPOOLS.size())):
        var center: Vector2 = WHIRLPOOLS[index]
        var rotation := 0.0 if reduced_motion else visual_time * (1.1 + float(index) * 0.2)
        draw_circle(center + Vector2(0,5), 62, Color(0.01,0.06,0.12,0.45))
        draw_circle(center, 58, Color(0.02,0.20,0.31,0.72))
        draw_circle(center, 45, Color(0.02,0.13,0.23,0.88))
        draw_circle(center, 18, Color(0.005,0.035,0.07,0.96))
        for ring in range(4):
            var radius := 16.0 + float(ring) * 11.0
            var brightness := 0.78 - float(ring) * 0.09
            draw_arc(center, radius, rotation + float(ring) * 0.8, rotation + float(ring) * 0.8 + PI * 1.55, 28, Color(0.55,0.93,1.0,brightness), 3.5)
        for foam_index in range(8):
            var foam_angle := rotation * 0.7 + float(foam_index) * TAU / 8.0
            var foam_position := center + Vector2.from_angle(foam_angle) * (47.0 + float(foam_index % 2) * 7.0)
            draw_circle(foam_position, 3.5, Color(0.78,0.96,1.0,0.72))
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-9,-4), center+Vector2(1,-11), center+Vector2(11,-2),
            center+Vector2(6,8), center+Vector2(-7,9)
        ]), Color(0.0,0.02,0.04,0.9))
        _text(center + Vector2(0,72), "WHIRLPOOL", 11, Color("cdefff"), HORIZONTAL_ALIGNMENT_CENTER, 110)

func _draw_predator(position: Vector2, species: String) -> void:
    draw_circle(position + Vector2(0,8), 44, Color(0.02,0.08,0.1,0.34))
    if species == "HERON":
        _draw_heron(position)
    elif species == "SNAKE":
        _draw_snake(position)
    else:
        _draw_fish(position, species)
    _text(position+Vector2(0,55), species, 11, Color("fff2dc"), HORIZONTAL_ALIGNMENT_CENTER, 90)

func _draw_fish(position: Vector2, species: String) -> void:
    var body := Color("d76145")
    if species == "PIKE": body = Color("759d55")
    elif species == "MUSKIE": body = Color("777bb0")
    var facing := -1.0 if species == "BASS" or species == "MUSKIE" else 1.0
    var nose := position + Vector2(38.0 * facing, 0)
    var tail_root := position - Vector2(36.0 * facing, 0)
    draw_colored_polygon(PackedVector2Array([
        tail_root, tail_root - Vector2(26.0 * facing, 22), tail_root - Vector2(22.0 * facing, -23)
    ]), body.darkened(0.2))
    draw_colored_polygon(PackedVector2Array([
        position + Vector2(-7, -22), position + Vector2(9, -39), position + Vector2(22, -18)
    ]), body.lightened(0.12))
    draw_colored_polygon(PackedVector2Array([
        position + Vector2(-4, 19), position + Vector2(13, 34), position + Vector2(22, 16)
    ]), body.darkened(0.12))
    draw_colored_polygon(PackedVector2Array([
        position - Vector2(35.0 * facing, 0), position + Vector2(0, -27), nose,
        position + Vector2(0, 27)
    ]), body)
    draw_arc(position, 27, 0, TAU, 28, Color("f2dfc7"), 2)
    for stripe in [-13.0, 0.0, 13.0]:
        draw_line(position + Vector2(stripe, -18), position + Vector2(stripe + 5, 18), body.darkened(0.28), 3)
    var eye := position + Vector2(22.0 * facing, -7)
    draw_circle(eye, 5, Color.WHITE)
    draw_circle(eye + Vector2(1.5 * facing, 0), 2.5, Color("172026"))
    draw_line(nose + Vector2(0, 7), nose - Vector2(9.0 * facing, -8), body.darkened(0.45), 2)

func _draw_snake(position: Vector2) -> void:
    var body := Color("8e7838")
    for segment in range(9):
        var offset := Vector2(-55 + segment * 12, sin(float(segment) * 1.18 + simulation_time * 2.0) * 15)
        var radius := 11.0 + sin(float(segment) * 0.6) * 1.5
        draw_circle(position + offset + Vector2(0,4), radius + 2.0, Color(0.03,0.08,0.05,0.32))
        draw_circle(position + offset, radius, body.darkened(float(segment % 2) * 0.12))
        draw_arc(position + offset, radius * 0.58, -2.7, -0.45, 8, Color("d6c36b"), 2)
        draw_circle(position + offset + Vector2(0,4), 2.5, Color("4f5f2d"))
    var head := position + Vector2(46, -4)
    draw_colored_polygon(PackedVector2Array([
        head+Vector2(-17,-14), head+Vector2(12,-17), head+Vector2(28,-5),
        head+Vector2(27,9), head+Vector2(8,17), head+Vector2(-17,12)
    ]), body.lightened(0.08))
    draw_arc(head, 20, -2.4, 2.4, 20, Color("d6c36b"), 2)
    draw_circle(head + Vector2(11, -7), 4.5, Color("f4e077"))
    draw_line(head + Vector2(12,-10), head + Vector2(12,-4), Color("17150b"), 2)
    draw_circle(head + Vector2(21,1), 1.8, Color("3a2619"))
    draw_line(head + Vector2(27, 4), head + Vector2(40, 4), Color("e45d62"), 2)
    draw_line(head + Vector2(40, 4), head + Vector2(47, -2), Color("e45d62"), 2)
    draw_line(head + Vector2(40, 4), head + Vector2(47, 10), Color("e45d62"), 2)

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

func _draw_heron(position: Vector2) -> void:
    var feathers := Color("9fb8c2")
    var wing_lift := 0.0 if reduced_motion else sin(visual_time * 3.0) * 10.0
    draw_colored_polygon(PackedVector2Array([
        position+Vector2(-30, 5), position+Vector2(-58, -18-wing_lift), position+Vector2(-6, -9)
    ]), feathers.darkened(0.12))
    draw_colored_polygon(PackedVector2Array([
        position+Vector2(20, 7), position+Vector2(47, -20-wing_lift), position+Vector2(4, -10)
    ]), feathers.lightened(0.08))
    draw_circle(position, 24, feathers)
    draw_line(position + Vector2(13,-17), position + Vector2(31,-39), feathers.lightened(0.12), 9)
    var head := position + Vector2(34,-43)
    draw_circle(head, 12, feathers.lightened(0.18))
    draw_colored_polygon(PackedVector2Array([head+Vector2(8,-2), head+Vector2(44,4), head+Vector2(8,7)]), Color("e7b94e"))
    draw_circle(head + Vector2(4,-4), 3, Color.WHITE)
    draw_circle(head + Vector2(5,-4), 1.5, Color("172026"))
    draw_line(position+Vector2(-8,20), position+Vector2(-13,48), Color("d7b253"), 3)
    draw_line(position+Vector2(8,20), position+Vector2(14,48), Color("d7b253"), 3)
    draw_line(position+Vector2(-13,48), position+Vector2(-22,52), Color("d7b253"), 2)
    draw_line(position+Vector2(14,48), position+Vector2(24,52), Color("d7b253"), 2)

func _draw_reeds(sway: float) -> void:
    for x in range(55,1240,95):
        var base := Vector2(x,680)
        draw_line(base, base + Vector2(sway,-46 - (x % 3) * 8), Color("78ad63"), 4)
        draw_line(base + Vector2(sway,-30), base + Vector2(sway + 14,-40), Color("a8d77c"), 3)

func _draw_bug(position: Vector2, index: int, flutter: float) -> void:
    var wing := absf(flutter) + 5.0
    draw_circle(position + Vector2(-9,-wing), 9, Color(0.92,0.98,1.0,0.56))
    draw_circle(position + Vector2(9,-wing), 9, Color(0.92,0.98,1.0,0.56))
    draw_circle(position + Vector2(-8,wing), 7, Color(0.92,0.98,1.0,0.45))
    draw_circle(position + Vector2(8,wing), 7, Color(0.92,0.98,1.0,0.45))
    draw_circle(position, 10, Color("eab23d"))
    draw_circle(position + Vector2(0,-10), 6, Color("59401d"))
    draw_line(position + Vector2(-3,-15), position + Vector2(-8,-22), Color("59401d"), 2)
    draw_line(position + Vector2(3,-15), position + Vector2(8,-22), Color("59401d"), 2)
    draw_line(position + Vector2(-7,-2), position + Vector2(7,-2), Color("59401d"), 2)
    draw_line(position + Vector2(-7,4), position + Vector2(7,4), Color("59401d"), 2)
    _text(position+Vector2(0,30), "BUG %d" % (index + 1), 11, Color("fff7cb"), HORIZONTAL_ALIGNMENT_CENTER, 70)

func _draw_fred(position: Vector2) -> void:
    var underwater_amount := float(depth.depth)
    var fred_color := Color("75e06f").lerp(Color("62b9d5"), underwater_amount)
    var outline := Color("173128").lerp(Color("d8f7ff"), underwater_amount)
    draw_circle(position + Vector2(-22,18), 14, outline); draw_circle(position + Vector2(22,18), 14, outline)
    draw_line(position+Vector2(-16,14), position+Vector2(-34,30), outline, 8)
    draw_line(position+Vector2(16,14), position+Vector2(34,30), outline, 8)
    draw_circle(position, 28, outline)
    draw_circle(position, 24, fred_color)
    draw_circle(position-Vector2(7,7), 8, Color(1,1,1,0.12))
    draw_circle(position+Vector2(-12,-20), 13, outline); draw_circle(position+Vector2(12,-20), 13, outline)
    draw_circle(position+Vector2(-12,-20), 10, fred_color); draw_circle(position+Vector2(12,-20), 10, fred_color)
    draw_circle(position+Vector2(-12,-22), 4, Color("17252c")); draw_circle(position+Vector2(12,-22), 4, Color("17252c"))
    draw_arc(position + Vector2(0,1), 10, 0.2, PI - 0.2, 10, outline, 2)
    if underwater_amount > 0.65:
        draw_circle(position + Vector2(30,-30), 5, Color(0.75,0.95,1.0,0.65), false, 2)
        draw_circle(position + Vector2(42,-45), 3, Color(0.75,0.95,1.0,0.65), false, 2)

func _draw_eating_effect(origin: Vector2, target: Vector2) -> void:
    var progress := clampf(eat_effect_seconds / 0.32, 0.0, 1.0)
    var tongue_tip := origin.lerp(target, sin(progress * PI))
    draw_line(origin + Vector2(0,5), tongue_tip, Color("ff7ca8"), 7)
    draw_circle(tongue_tip, 6, Color("ffb1c9"))
    draw_arc(origin + Vector2(0,4), 13, 0.15, PI - 0.15, 12, Color("311629"), 4)
    _text(origin + Vector2(0,-48), "MUNCH!", 14, Color("fff0ae"), HORIZONTAL_ALIGNMENT_CENTER, 100)

func _draw_overlay(title: String, subtitle: String, action: String, rect: Rect2, cue: String) -> void:
    draw_rect(Rect2(350,245,580,300), Color(0.02,0.07,0.1,0.94), true)
    draw_rect(Rect2(350,245,580,300), Color("70d6c2"), false, 4)
    _text(Vector2(640,275), "[%s]" % cue, 15, Color("e8fbff"), HORIZONTAL_ALIGNMENT_CENTER, 500)
    _text(Vector2(640,315), title, 35, Color("f7d36a"), HORIZONTAL_ALIGNMENT_CENTER, 520)
    _text(Vector2(640,365), subtitle, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 520)
    _button(rect, action)

func _button(rect: Rect2, label: String) -> void:
    draw_rect(rect, Color("e9b949"), true); draw_rect(rect, Color("fff0ae"), false, 3)
    _text(rect.position + Vector2(rect.size.x/2, rect.size.y/2+8), label, 20, Color("102935"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _status_panel(rect: Rect2, size: int) -> void:
    draw_rect(rect, FredSaveFeedback.PANEL_BACKGROUND, true)
    draw_rect(rect, FredSaveFeedback.PANEL_BORDER, false, 2)
    _text(
        rect.position + Vector2(rect.size.x / 2.0, rect.size.y / 2.0 + 6.0),
        save_feedback,
        size,
        FredSaveFeedback.PANEL_TEXT,
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x - 16.0
    )

func _text(anchor: Vector2, value: String, size: int, color: Color, alignment: HorizontalAlignment, width: float) -> void:
    var font := ThemeDB.fallback_font
    var x := anchor.x if alignment == HORIZONTAL_ALIGNMENT_LEFT else anchor.x-width/2
    draw_string(font, Vector2(x,anchor.y), value, alignment, width, size, color)
