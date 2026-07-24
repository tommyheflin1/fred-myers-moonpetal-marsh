class_name FredAnimationCoordinator
extends RefCounted

const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")
const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")

enum State {
	RESET,
	IDLE,
	GROUND_MOVE,
	SURFACE_SWIM,
	LEAP_ANTICIPATION,
	LEAP_ASCENT,
	LEAP_APEX,
	LEAP_DESCENT,
	LEAP_LANDING,
	DIVING,
	UNDERWATER_IDLE,
	UNDERWATER_SWIM,
	SURFACING,
	TONGUE_WINDUP,
	TONGUE_EXTENSION,
	TONGUE_RECOVERY,
	BOOST_BURST,
	BOOST_SUSTAIN,
	BOOST_EXHAUSTED,
	BOOST_RECOVERY,
	DAMAGE,
	INVULNERABLE,
	FAILURE,
}

const FIXED_TICK_SECONDS := 1.0 / 60.0
const DAMAGE_TICKS := 18
const TONGUE_WINDUP_SECONDS := 0.04
const LEAP_ANTICIPATION_END := 0.12
const LEAP_ASCENT_END := 0.42
const LEAP_APEX_END := 0.58
const LEAP_DESCENT_END := 1.0

var state := State.RESET
var state_ticks := 0
var facing := 1.0
var damage_ticks_remaining := 0
var failure_latched := false
var reduced_motion := false
var _pose: Dictionary = {}

func _init() -> void:
	_pose = _build_pose()

func reset() -> void:
	state = State.RESET
	state_ticks = 0
	facing = 1.0
	damage_ticks_remaining = 0
	failure_latched = false
	_pose = _build_pose()

func trigger_damage(failed: bool = false) -> void:
	if failed:
		trigger_failure()
		return
	damage_ticks_remaining = DAMAGE_TICKS
	_set_state(State.DAMAGE)

func trigger_failure() -> void:
	failure_latched = true
	damage_ticks_remaining = 0
	_set_state(State.FAILURE)

func advance(gameplay_snapshot: Dictionary, freeze: bool = false, use_reduced_motion: bool = false) -> Dictionary:
	var snapshot: Dictionary = gameplay_snapshot.duplicate(true)
	reduced_motion = use_reduced_motion
	if freeze:
		return pose()
	var movement := Vector2(snapshot.get("movement", Vector2.ZERO))
	if absf(movement.x) > 0.05:
		facing = 1.0 if movement.x > 0.0 else -1.0
	if bool(snapshot.get("failed", false)):
		failure_latched = true
	var next_state := _select_state(snapshot)
	_set_state(next_state)
	if state == State.DAMAGE and damage_ticks_remaining > 0:
		damage_ticks_remaining -= 1
	state_ticks += 1
	_pose = _build_pose()
	return pose()

func pose() -> Dictionary:
	return _pose.duplicate(true)

func cue() -> String:
	return str(_pose.get("cue", "RESET"))

func state_name() -> String:
	return _state_name(state)

func state_hash() -> String:
	var body_offset := Vector2(_pose.get("body_offset", Vector2.ZERO))
	var body_scale := Vector2(_pose.get("body_scale", Vector2.ONE))
	return "%02d:%04d:%+.1f:%+.3f,%+.3f:%+.3f,%+.3f:%+.3f:%+.3f:%s" % [
		state,
		state_ticks,
		facing,
		body_offset.x,
		body_offset.y,
		body_scale.x,
		body_scale.y,
		float(_pose.get("leg_extension", 0.0)),
		float(_pose.get("tilt", 0.0)),
		cue(),
	]

func _set_state(next_state: int) -> void:
	if state == next_state:
		return
	state = next_state
	state_ticks = 0
	_pose = _build_pose()

func _select_state(snapshot: Dictionary) -> int:
	# Priority is deliberately explicit: terminal and safety feedback preempt
	# interactions, which preempt traversal, which preempts ambient locomotion.
	if failure_latched:
		return State.FAILURE
	if damage_ticks_remaining > 0:
		return State.DAMAGE
	if bool(snapshot.get("invulnerable", false)):
		return State.INVULNERABLE

	var tongue_state := int(snapshot.get("tongue_state", TongueTargeting.State.READY))
	if tongue_state == TongueTargeting.State.EXTENDING:
		if float(snapshot.get("tongue_elapsed", 0.0)) < TONGUE_WINDUP_SECONDS:
			return State.TONGUE_WINDUP
		return State.TONGUE_EXTENSION
	if tongue_state == TongueTargeting.State.RECOVERING:
		return State.TONGUE_RECOVERY

	var depth_state := int(snapshot.get("depth_state", DepthTraversal.State.SURFACE))
	if depth_state == DepthTraversal.State.DIVING:
		return State.DIVING
	if depth_state == DepthTraversal.State.SURFACING:
		return State.SURFACING

	var leap_state := int(snapshot.get("leap_state", LeapTraversal.State.GROUNDED))
	if leap_state == LeapTraversal.State.LANDING:
		return State.LEAP_LANDING
	if leap_state == LeapTraversal.State.AIRBORNE:
		var leap_progress := clampf(
			float(snapshot.get("leap_elapsed", 0.0)) / LeapTraversal.AIRBORNE_SECONDS,
			0.0,
			1.0
		)
		if leap_progress < LEAP_ANTICIPATION_END:
			return State.LEAP_ANTICIPATION
		if leap_progress < LEAP_ASCENT_END:
			return State.LEAP_ASCENT
		if leap_progress < LEAP_APEX_END:
			return State.LEAP_APEX
		if leap_progress < LEAP_DESCENT_END:
			return State.LEAP_DESCENT

	var boost_state := int(snapshot.get("boost_state", BoostLocomotion.State.READY))
	if boost_state == BoostLocomotion.State.BURST:
		return State.BOOST_BURST
	if boost_state == BoostLocomotion.State.SUSTAIN:
		return State.BOOST_SUSTAIN
	if boost_state == BoostLocomotion.State.EXHAUSTED:
		return State.BOOST_EXHAUSTED
	if boost_state == BoostLocomotion.State.RECOVERING:
		return State.BOOST_RECOVERY

	var moving := bool(snapshot.get("moving", false))
	if depth_state == DepthTraversal.State.UNDERWATER:
		return State.UNDERWATER_SWIM if moving else State.UNDERWATER_IDLE
	if not bool(snapshot.get("on_perch", false)):
		return State.SURFACE_SWIM
	return State.GROUND_MOVE if moving else State.IDLE

func _build_pose() -> Dictionary:
	var body_offset := Vector2.ZERO
	var body_scale := Vector2.ONE
	var leg_extension := 0.0
	var tilt := 0.0
	var eye_squint := 0.0
	var mouth_open := 0.0
	var accent := Color("b9f5c7")
	var cue_text := _state_name(state)
	var secondary_motion := 0.0 if reduced_motion else sin(float(state_ticks) * 0.34)

	match state:
		State.RESET:
			body_scale = Vector2(1.04, 0.96)
			cue_text = "READY"
		State.IDLE:
			body_offset.y = secondary_motion * 1.4
			cue_text = "PERCHED"
		State.GROUND_MOVE:
			body_offset.y = absf(secondary_motion) * -2.2
			leg_extension = 0.45
			tilt = secondary_motion * 0.025
			cue_text = "HOP"
		State.SURFACE_SWIM:
			body_offset.y = secondary_motion * 2.0
			body_scale = Vector2(1.06, 0.94)
			leg_extension = 0.34
			cue_text = "SURFACE SWIM"
		State.LEAP_ANTICIPATION:
			body_scale = Vector2(1.14, 0.82) if not reduced_motion else Vector2(1.08, 0.90)
			leg_extension = -0.35
			cue_text = "LEAP READY"
		State.LEAP_ASCENT:
			body_scale = Vector2(0.90, 1.16) if not reduced_motion else Vector2(0.96, 1.08)
			leg_extension = 0.72
			tilt = -0.08 * facing if not reduced_motion else 0.0
			cue_text = "LEAP UP"
		State.LEAP_APEX:
			body_scale = Vector2(1.08, 0.96)
			leg_extension = 0.86
			cue_text = "LEAP APEX"
		State.LEAP_DESCENT:
			body_scale = Vector2(0.96, 1.08)
			leg_extension = 0.62
			tilt = 0.07 * facing if not reduced_motion else 0.0
			cue_text = "LEAP DOWN"
		State.LEAP_LANDING:
			body_scale = Vector2(1.18, 0.78) if not reduced_motion else Vector2(1.10, 0.88)
			leg_extension = -0.24
			cue_text = "LANDING"
		State.DIVING:
			body_scale = Vector2(0.94, 1.08)
			leg_extension = 0.36
			tilt = 0.10 * facing if not reduced_motion else 0.0
			accent = Color("9be8ff")
			cue_text = "DIVING"
		State.UNDERWATER_IDLE:
			body_offset.y = secondary_motion * 1.6
			body_scale = Vector2(1.04, 0.96)
			accent = Color("9be8ff")
			cue_text = "UNDERWATER"
		State.UNDERWATER_SWIM:
			body_offset.y = secondary_motion * 1.8
			body_scale = Vector2(1.10, 0.90)
			leg_extension = 0.64
			tilt = secondary_motion * 0.035
			accent = Color("9be8ff")
			cue_text = "DEEP SWIM"
		State.SURFACING:
			body_scale = Vector2(0.92, 1.10)
			leg_extension = 0.48
			tilt = -0.08 * facing if not reduced_motion else 0.0
			accent = Color("d9f7ff")
			cue_text = "SURFACING"
		State.TONGUE_WINDUP:
			body_scale = Vector2(1.10, 0.90)
			mouth_open = 0.35
			cue_text = "AIMED MUNCH"
		State.TONGUE_EXTENSION:
			body_scale = Vector2(0.96, 1.05)
			mouth_open = 1.0
			eye_squint = 0.28
			cue_text = "TONGUE SNAP"
		State.TONGUE_RECOVERY:
			body_scale = Vector2(1.05, 0.95)
			mouth_open = 0.42
			cue_text = "TONGUE RETURN"
		State.BOOST_BURST:
			body_scale = Vector2(1.18, 0.84)
			leg_extension = 0.66
			tilt = -0.06 * facing if not reduced_motion else 0.0
			accent = Color("fff0ae")
			cue_text = "BOOST BURST"
		State.BOOST_SUSTAIN:
			body_scale = Vector2(1.12, 0.90)
			leg_extension = 0.50
			accent = Color("fff0ae")
			cue_text = "BOOST"
		State.BOOST_EXHAUSTED:
			body_scale = Vector2(1.12, 0.84)
			body_offset.y = 3.0
			eye_squint = 0.65
			accent = Color("ffb38f")
			cue_text = "EXHAUSTED"
		State.BOOST_RECOVERY:
			body_scale = Vector2(1.06, 0.92)
			body_offset.y = 2.0 if reduced_motion else 2.0 + secondary_motion
			eye_squint = 0.25
			accent = Color("ffe8a6")
			cue_text = "RECOVERING"
		State.DAMAGE:
			body_scale = Vector2(1.16, 0.80)
			body_offset = Vector2(-4.0 * facing, 3.0) if not reduced_motion else Vector2(0,3)
			eye_squint = 1.0
			mouth_open = 0.8
			accent = Color("ff9b86")
			cue_text = "OUCH"
		State.INVULNERABLE:
			body_scale = Vector2(1.08, 0.92)
			eye_squint = 0.35
			accent = Color("d9f7ff")
			cue_text = "SAFE BLINK"
		State.FAILURE:
			body_scale = Vector2(1.24, 0.68)
			body_offset.y = 7.0
			eye_squint = 1.0
			mouth_open = 1.0
			accent = Color("ff9b86")
			cue_text = "OH NO FRED"

	return {
		"state": state,
		"state_name": _state_name(state),
		"cue": cue_text,
		"facing": facing,
		"body_offset": body_offset,
		"body_scale": body_scale,
		"leg_extension": leg_extension,
		"tilt": tilt,
		"eye_squint": eye_squint,
		"mouth_open": mouth_open,
		"accent": accent,
		"reduced_motion": reduced_motion,
	}

func _state_name(value: int) -> String:
	return State.keys()[clampi(value, 0, State.size() - 1)]
