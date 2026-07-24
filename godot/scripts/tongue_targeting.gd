class_name FredTongueTargeting
extends RefCounted

enum State { READY, EXTENDING, RECOVERING }

const MAX_RANGE := 190.0
const PROXIMITY_ASSIST_RANGE := 96.0
const CONE_HALF_ANGLE_DEGREES := 42.0
const CONE_COSINE := 0.7431448254773942
const EXTEND_SECONDS := 0.16
const RECOVERY_SECONDS := 0.39
const COOLDOWN_SECONDS := EXTEND_SECONDS + RECOVERY_SECONDS
const TIE_EPSILON := 0.00001

var state := State.READY
var elapsed := 0.0
var aim_direction := Vector2.RIGHT
var target_point := Vector2.ZERO
var target_id := ""
var target_kind := ""
var outcome := "idle"
var blocked_reason := ""
var shot_serial := 0

func reset() -> void:
    state = State.READY
    elapsed = 0.0
    target_point = Vector2.ZERO
    target_id = ""
    target_kind = ""
    outcome = "idle"
    blocked_reason = ""

func is_ready() -> bool:
    return state == State.READY

func is_busy() -> bool:
    return state != State.READY

func request(origin: Vector2, requested_aim: Vector2, candidates: Array[Dictionary]) -> Dictionary:
    if not is_ready():
        return {
            "accepted": false,
            "outcome": "cooldown",
            "reason": "recovery",
            "target_id": target_id,
            "target_kind": target_kind,
            "target_point": target_point,
        }
    if requested_aim.length_squared() > 0.0001:
        aim_direction = requested_aim.normalized()
    var selection := _select_target(origin, aim_direction, candidates)
    state = State.EXTENDING
    elapsed = 0.0
    shot_serial += 1
    target_id = str(selection.get("id", ""))
    target_kind = str(selection.get("kind", ""))
    outcome = str(selection.get("outcome", "miss"))
    blocked_reason = str(selection.get("blocked_reason", ""))
    target_point = Vector2(selection.get("position", origin + aim_direction * MAX_RANGE))
    return {
        "accepted": true,
        "outcome": outcome,
        "reason": blocked_reason,
        "target_id": target_id,
        "target_kind": target_kind,
        "target_point": target_point,
        "shot_serial": shot_serial,
    }

func advance(delta: float) -> void:
    if state == State.READY:
        return
    elapsed += maxf(0.0, delta)
    if state == State.EXTENDING and elapsed >= EXTEND_SECONDS:
        elapsed -= EXTEND_SECONDS
        state = State.RECOVERING
    if state == State.RECOVERING and elapsed >= RECOVERY_SECONDS:
        state = State.READY
        elapsed = 0.0

func extension_ratio() -> float:
    if state == State.EXTENDING:
        return clampf(elapsed / EXTEND_SECONDS, 0.08, 1.0)
    if state == State.RECOVERING:
        return 1.0 - clampf(elapsed / RECOVERY_SECONDS, 0.0, 1.0)
    return 0.0

func cue() -> String:
    if state == State.READY:
        return "TONGUE READY"
    match outcome:
        "hit":
            return "TONGUE HIT"
        "blocked":
            return "TONGUE BLOCKED"
        "miss":
            return "TONGUE MISS"
        _:
            return "TONGUE READY"

func _select_target(origin: Vector2, aim: Vector2, candidates: Array[Dictionary]) -> Dictionary:
    var best: Dictionary = {}
    var best_assisted := false
    var best_alignment := -2.0
    var best_distance := INF
    var best_id := ""
    for candidate: Dictionary in candidates:
        var candidate_id := str(candidate.get("id", ""))
        var candidate_kind := str(candidate.get("kind", ""))
        var position := Vector2(candidate.get("position", origin))
        if candidate_id.is_empty() or candidate_kind.is_empty():
            continue
        if not is_finite(position.x) or not is_finite(position.y):
            continue
        var offset := position - origin
        var distance := offset.length()
        if distance <= 0.001 or distance > MAX_RANGE + TIE_EPSILON:
            continue
        var alignment := aim.dot(offset / distance)
        var assisted := (
            distance <= PROXIMITY_ASSIST_RANGE + TIE_EPSILON
            and alignment + TIE_EPSILON < CONE_COSINE
        )
        if not assisted and alignment + TIE_EPSILON < CONE_COSINE:
            continue
        var wins := best.is_empty()
        if not wins and assisted and not best_assisted:
            wins = true
        elif not wins and assisted == best_assisted and assisted and distance < best_distance - TIE_EPSILON:
            wins = true
        elif (
            not wins
            and assisted == best_assisted
            and assisted
            and is_equal_approx(distance, best_distance)
            and alignment > best_alignment + TIE_EPSILON
        ):
            wins = true
        elif (
            not wins
            and assisted == best_assisted
            and not assisted
            and alignment > best_alignment + TIE_EPSILON
        ):
            wins = true
        elif (
            not wins
            and assisted == best_assisted
            and not assisted
            and is_equal_approx(alignment, best_alignment)
            and distance < best_distance - TIE_EPSILON
        ):
            wins = true
        elif (
            not wins
            and assisted == best_assisted
            and is_equal_approx(alignment, best_alignment)
            and is_equal_approx(distance, best_distance)
            and candidate_id < best_id
        ):
            wins = true
        if wins:
            best = candidate
            best_assisted = assisted
            best_alignment = alignment
            best_distance = distance
            best_id = candidate_id
    if best.is_empty():
        return {
            "outcome": "miss",
            "position": origin + aim * MAX_RANGE,
        }
    var eligible := bool(best.get("eligible", true))
    return {
        "outcome": "hit" if eligible else "blocked",
        "id": str(best.get("id", "")),
        "kind": str(best.get("kind", "")),
        "position": Vector2(best.get("position", origin)),
        "blocked_reason": "" if eligible else str(best.get("blocked_reason", "ineligible")),
    }
