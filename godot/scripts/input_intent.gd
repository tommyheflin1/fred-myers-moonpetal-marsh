class_name FredInputIntent
extends RefCounted

enum Intent { MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACKWARD, LEAP, DIVE, SURFACE, BOOST, INTERACT, PAUSE, CONFIRM, RETRY }

const ACTIONS := {
    Intent.MOVE_LEFT: "move_left", Intent.MOVE_RIGHT: "move_right",
    Intent.MOVE_FORWARD: "move_up", Intent.MOVE_BACKWARD: "move_down",
    Intent.LEAP: "leap", Intent.DIVE: "dive", Intent.SURFACE: "surface",
    Intent.BOOST: "boost", Intent.INTERACT: "interact", Intent.PAUSE: "pause",
    Intent.CONFIRM: "confirm", Intent.RETRY: "retry"
}

static func pressed(intent: Intent) -> bool:
    return Input.is_action_just_pressed(ACTIONS[intent])

static func held(intent: Intent) -> bool:
    return Input.is_action_pressed(ACTIONS[intent])

static func movement() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")

# Touch, controller, and web adapters can feed these same intents without changing gameplay.
static func event_to_intent(event: InputEvent) -> int:
    for intent: Intent in ACTIONS:
        if event.is_action_pressed(ACTIONS[intent]): return intent
    return -1
