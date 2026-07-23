extends Node2D

enum Screen { TITLE, PLAYING, FAILED, COMPLETE }
const START := Vector2(135, 560)
const EXIT := Vector2(1150, 120)
const PADS := [Vector2(220,500), Vector2(350,420), Vector2(490,500), Vector2(630,390), Vector2(760,300), Vector2(900,225), Vector2(1040,165)]
const BUGS := [Vector2(350,390), Vector2(625,360), Vector2(900,195)]
const SAFE_LOCATION := Vector2(720,570)
const PREDATOR_START := Vector2(850,520)

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
    queue_redraw()

func _fixed_tick(delta: float) -> void:
    var direction := FredInputIntent.movement()
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
    direction = direction.normalized()
    var speed := 210.0
    if FredInputIntent.held(FredInputIntent.Intent.BOOST) and session.use_boost(1): speed = 380.0
    elif direction == Vector2.ZERO: session.recharge_boost(1)
    var current := _current_vector()
    fred = (fred + (direction * speed + current) * delta).clamp(Vector2(55,105), Vector2(1225,665))
    predator.x += predator_direction * 110.0 * float(level_profile.predator_speed_scale) * delta
    if bool(level_profile.weaving_patrol):
        predator.y = PREDATOR_START.y + sin(visual_time * (0.8 + float(level_number) * 0.015)) * minf(115.0, 42.0 + float(level_number))
    if predator.x > 1120 or predator.x < 760: predator_direction *= -1.0
    in_safe_location = fred.distance_to(SAFE_LOCATION) < float(level_profile.safe_radius)
    for index in BUGS.size():
        if index not in collected and fred.distance_to(BUGS[index]) < 35:
            eat_target = BUGS[index]
            eat_effect_seconds = 0.32
            collected.append(index); session.collect_bug(); _set_feedback("[MUNCH!] Fred ate a marsh bug.")
    if fred.distance_to(Vector2(630,390)) < 42 and session.checkpoint_sequence < 1:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1); _save("Midpoint is safe.")
    if fred.distance_to(predator) < float(level_profile.danger_radius) and not in_safe_location:
        fred = START
        if session.damage(): screen = Screen.FAILED
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
    if level_number >= 7 and session.player_state == "underwater":
        vertical = sin(visual_time * 0.9) * strength * 0.55
    return Vector2(strength * direction, vertical)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _handle_click(event.position)
    if not event is InputEventKey and event.is_action_pressed("pause") and screen == Screen.PLAYING:
        session.paused = not session.paused
        _set_feedback("[PAUSED] Your last checkpoint is safe." if session.paused else "[PLAYING] Adventure resumed.")
    if not event is InputEventKey and event.is_action_pressed("dive") and screen == Screen.PLAYING:
        session.set_underwater(true); _set_feedback("[STATUS] Fred is underwater.")
    if not event is InputEventKey and event.is_action_pressed("surface") and screen == Screen.PLAYING:
        session.set_underwater(false); _set_feedback("[STATUS] Fred is at the surface.")
    if not event is InputEventKey and event.is_action_pressed("retry") and screen == Screen.FAILED: _retry()
    if not event is InputEventKey and event.is_action_pressed("confirm") and screen == Screen.TITLE: _start()
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_Q:
                if screen == Screen.PLAYING: session.set_underwater(true); _set_feedback("[STATUS] Fred is underwater.")
            KEY_E:
                if screen == Screen.PLAYING: session.set_underwater(false); _set_feedback("[STATUS] Fred is at the surface.")
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
    screen = Screen.PLAYING
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
    _text(Vector2(640,620), "WASD / arrows move  •  Shift boosts  •  Q dive  •  E surface  •  P pause", 17, Color("bfd8dc"), HORIZONTAL_ALIGNMENT_CENTER, 1000)

func _draw_level() -> void:
    var visual := FredVisualState.snapshot(visual_time, reduced_motion)
    var water := Color("075c78") if session.player_state == "surface" else Color("07334f")
    draw_rect(Rect2(26,76,1228,618), Color("03131c"), true)
    draw_rect(Rect2(35,85,1210,600), water, true)
    draw_rect(Rect2(35,85,1210,600), Color("8be8e1"), false, 3)
    draw_rect(Rect2(35,85,1210,120), Color(0.2,0.75,0.85,0.08), true)
    for glow in [Vector2(180,155), Vector2(530,260), Vector2(1020,420)]:
        draw_circle(glow, 95, Color(0.2,0.85,0.78,0.035))
    _draw_current_trails()
    for row in range(4):
        var ripple_y := 150.0 + row * 130.0
        var shift := float(visual.water_shift) * (1.0 if row % 2 == 0 else -1.0)
        for x in range(55,1240,120):
            draw_line(Vector2(x + shift,ripple_y), Vector2(x + 58 + shift,ripple_y), Color(0.55,0.9,0.95,0.22), 3)
    _draw_reeds(float(visual.reed_sway))
    for index in PADS.size():
        var pad: Vector2 = PADS[index]
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
            _draw_bug(BUGS[index], index, float(visual.wildlife_flutter))
    draw_circle(predator + Vector2(0,5), 37, Color(0.02,0.08,0.1,0.35))
    draw_circle(predator, 34, Color("d44b4b")); draw_arc(predator, 34, 0, TAU, 24, Color("ffd2c7"), 2)
    draw_circle(predator+Vector2(-12,-8), 6, Color.WHITE); draw_circle(predator+Vector2(12,-8), 6, Color.WHITE)
    draw_circle(predator+Vector2(-12,-8), 3, Color("301519")); draw_circle(predator+Vector2(12,-8), 3, Color("301519"))
    draw_colored_polygon(PackedVector2Array([predator+Vector2(-34,4), predator+Vector2(-55,-15), predator+Vector2(-50,18)]), Color("a83445"))
    draw_arc(predator, 25, 0.25, PI - 0.25, 16, Color("ff9b88"), 3)
    var exit_radius := 45.0 * float(visual.exit_pulse)
    draw_circle(EXIT, exit_radius + 5, Color(0.9,0.8,1.0,0.16)); draw_circle(EXIT, exit_radius, Color("d49cff"))
    _text(EXIT+Vector2(0,6), "EXIT", 15, Color("321c45"), HORIZONTAL_ALIGNMENT_CENTER, 90)
    _draw_fred(fred + Vector2(0,float(visual.fred_bob)))
    if eat_effect_seconds > 0.0:
        _draw_eating_effect(fred + Vector2(0,float(visual.fred_bob)), eat_target)
    _text(Vector2(45,38), "LILY LEAP", 28, Color("f7d36a"), HORIZONTAL_ALIGNMENT_LEFT, 300)
    _text(Vector2(45,75), "LEVEL %03d  -  %s" % [level_profile.level, level_profile.label], 15, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_LEFT, 280)
    _text(Vector2(915,75), "NEW: %s" % str(level_profile.new_twist).to_upper(), 13, Color("fff0ae"), HORIZONTAL_ALIGNMENT_LEFT, 320)
    draw_rect(Rect2(330,10,560,52), Color("06151f"), true); draw_rect(Rect2(330,10,560,52), Color("e8fbff"), false, 2)
    _text(Vector2(350,43), "OBJECTIVE: " + ("Reach the moonpetal exit" if session.bug_count >= 3 else "Collect 3 marsh bugs"), 19, Color("e8fbff"), HORIZONTAL_ALIGNMENT_LEFT, 520)
    _text(Vector2(45,710), "Bugs %d/3   Boost %d%%   Health %s   %s" % [session.bug_count, session.boost_energy, "♥".repeat(session.health), session.player_state.capitalize()], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 850)
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

func _draw_reeds(sway: float) -> void:
    for x in range(55,1240,95):
        var base := Vector2(x,680)
        draw_line(base, base + Vector2(sway,-46 - (x % 3) * 8), Color("78ad63"), 4)
        draw_line(base + Vector2(sway,-30), base + Vector2(sway + 14,-40), Color("a8d77c"), 3)

func _draw_bug(position: Vector2, index: int, flutter: float) -> void:
    var wing := absf(flutter) + 5.0
    draw_circle(position, 12, Color("ffd85a")); draw_arc(position, 12, 0, TAU, 18, Color("4d3512"), 2)
    draw_line(position-Vector2(5,2), position-Vector2(18,wing), Color("fff4b0"), 3)
    draw_line(position+Vector2(5,-2), position+Vector2(18,wing), Color("fff4b0"), 3)
    draw_circle(position-Vector2(4,0), 2, Color("3b2810"))
    draw_circle(position+Vector2(4,0), 2, Color("3b2810"))
    _text(position+Vector2(0,30), "BUG %d" % (index + 1), 11, Color("fff7cb"), HORIZONTAL_ALIGNMENT_CENTER, 70)

func _draw_fred(position: Vector2) -> void:
    var fred_color := Color("75e06f") if session.player_state == "surface" else Color("62b9d5")
    var outline := Color("173128") if session.player_state == "surface" else Color("d8f7ff")
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
    if session.player_state == "underwater":
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
