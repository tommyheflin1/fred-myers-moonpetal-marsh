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

func _ready() -> void:
    var result := saver.load_session(session)
    _set_feedback(FredSaveFeedback.load_message(result))
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    _tick_feedback(delta)
    if screen != Screen.PLAYING or session.paused: return
    _fixed_accumulator += delta
    while _fixed_accumulator >= 1.0 / 60.0:
        _fixed_tick(1.0 / 60.0)
        _fixed_accumulator -= 1.0 / 60.0
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
    fred = (fred + direction * speed * delta).clamp(Vector2(55,105), Vector2(1225,665))
    predator.x += predator_direction * 110.0 * delta
    if predator.x > 1120 or predator.x < 760: predator_direction *= -1.0
    in_safe_location = fred.distance_to(SAFE_LOCATION) < 55
    for index in BUGS.size():
        if index not in collected and fred.distance_to(BUGS[index]) < 35:
            collected.append(index); session.collect_bug(); _set_feedback("[STATUS] Marsh bug collected.")
    if fred.distance_to(Vector2(630,390)) < 42 and session.checkpoint_sequence < 1:
        session.reach_checkpoint(AdventureSession.CHECKPOINTS[1], 1); _save("Midpoint is safe.")
    if fred.distance_to(predator) < 45 and not in_safe_location:
        fred = START
        if session.damage(): screen = Screen.FAILED
    if fred.distance_to(EXIT) < 55 and session.complete_level():
        screen = Screen.COMPLETE; _save("Lily Leap is complete.")

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

func _handle_click(position: Vector2) -> void:
    if screen == Screen.TITLE and Rect2(490,440,300,70).has_point(position): _start()
    elif screen == Screen.PLAYING and Rect2(1120,20,120,48).has_point(position):
        session.paused = not session.paused
        _set_feedback("[PAUSED] Your last checkpoint is safe." if session.paused else "[PLAYING] Adventure resumed.")
    elif screen == Screen.PLAYING and session.paused and Rect2(490,410,300,65).has_point(position):
        session.paused = false; _set_feedback("[PLAYING] Adventure resumed.")
    elif screen == Screen.FAILED and Rect2(490,430,300,70).has_point(position): _retry()
    elif screen == Screen.COMPLETE and Rect2(490,500,300,60).has_point(position):
        screen = Screen.TITLE; queue_redraw()

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
    if screen == Screen.FAILED: _draw_overlay("Fred got gobbled!", "Press R or click Retry", "Retry", Rect2(490,430,300,70))
    elif screen == Screen.COMPLETE: _draw_overlay("Lily Leap Complete!", "The marsh path is open.", "Back to title", Rect2(490,500,300,60))
    elif session.paused: _draw_overlay("Marsh Paused", "Your checkpoint is safe.", "Resume", Rect2(490,410,300,65))

func _draw_title() -> void:
    draw_circle(Vector2(640,220), 155, Color("123e4a"))
    draw_circle(Vector2(600,215), 65, Color("69c96b")); draw_circle(Vector2(680,215), 65, Color("69c96b"))
    draw_circle(Vector2(615,190), 13, Color.WHITE); draw_circle(Vector2(665,190), 13, Color.WHITE)
    draw_circle(Vector2(615,190), 6, Color("13242a")); draw_circle(Vector2(665,190), 6, Color("13242a"))
    _text(Vector2(640,70), "FRED MYERS", 46, Color("f7d36a"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _text(Vector2(640,120), "and the Moonpetal Marsh", 30, Color("d9f4e2"), HORIZONTAL_ALIGNMENT_CENTER, 700)
    _button(Rect2(490,440,300,70), "PLAY AGAIN" if session.completed else ("CONTINUE" if session.checkpoint_sequence > 0 else "START ADVENTURE"))
    _status_panel(Rect2(280,510,720,46), 18)
    _text(Vector2(640,620), "WASD / arrows move  •  Shift boosts  •  Q dive  •  E surface  •  P pause", 17, Color("bfd8dc"), HORIZONTAL_ALIGNMENT_CENTER, 1000)

func _draw_level() -> void:
    var water := Color("075c78") if session.player_state == "surface" else Color("07334f")
    draw_rect(Rect2(35,85,1210,600), water, true)
    for x in range(60,1240,80): draw_line(Vector2(x,130 + (x % 160)), Vector2(x+35,130 + (x % 160)), Color(0.3,0.8,0.9,0.18), 3)
    for pad in PADS:
        draw_circle(pad, 43, Color("3d9a5a")); draw_line(pad, pad+Vector2(35,-18), Color("9bd36a"), 5)
    draw_circle(SAFE_LOCATION, 62, Color("183f31")); _text(SAFE_LOCATION+Vector2(0,7), "SAFE", 16, Color("b9f5c7"), HORIZONTAL_ALIGNMENT_CENTER, 100)
    for index in BUGS.size():
        if index not in collected:
            draw_circle(BUGS[index], 11, Color("ffd85a")); draw_line(BUGS[index]-Vector2(15,0), BUGS[index]+Vector2(15,0), Color("fff2a8"), 2)
    draw_circle(predator, 34, Color("d44b4b")); draw_circle(predator+Vector2(-12,-8), 5, Color.WHITE); draw_circle(predator+Vector2(12,-8), 5, Color.WHITE)
    draw_circle(EXIT, 45, Color("d49cff")); _text(EXIT+Vector2(0,6), "EXIT", 15, Color("321c45"), HORIZONTAL_ALIGNMENT_CENTER, 90)
    var fred_color := Color("75e06f") if session.player_state == "surface" else Color("62b9d5")
    draw_circle(fred, 25, fred_color); draw_circle(fred+Vector2(-11,-19), 12, fred_color); draw_circle(fred+Vector2(11,-19), 12, fred_color)
    draw_circle(fred+Vector2(-11,-21), 4, Color("17252c")); draw_circle(fred+Vector2(11,-21), 4, Color("17252c"))
    _text(Vector2(45,38), "LILY LEAP", 28, Color("f7d36a"), HORIZONTAL_ALIGNMENT_LEFT, 300)
    _text(Vector2(350,35), "Objective: " + ("Reach the moonpetal exit" if session.bug_count >= 3 else "Collect 3 marsh bugs"), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 500)
    _text(Vector2(45,710), "Bugs %d/3   Boost %d%%   Health %s   %s" % [session.bug_count, session.boost_energy, "♥".repeat(session.health), session.player_state.capitalize()], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 850)
    _status_panel(Rect2(820,632,410,42), 16)
    _button(Rect2(1120,20,120,48), "PAUSE")

func _draw_overlay(title: String, subtitle: String, action: String, rect: Rect2) -> void:
    draw_rect(Rect2(350,245,580,300), Color(0.02,0.07,0.1,0.94), true)
    draw_rect(Rect2(350,245,580,300), Color("70d6c2"), false, 4)
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
