class_name FredBoostLocomotion
extends RefCounted

enum State { READY, BURST, SUSTAIN, EXHAUSTED, RECOVERING }

const MAX_ENERGY := 100
const START_THRESHOLD := 15
const ACTIVATION_COST := 1
const BURST_TICKS := 12
const DRAIN_INTERVAL_TICKS := 3
const RELEASE_RECOVERY_DELAY_TICKS := 30
const EXHAUSTED_RECOVERY_DELAY_TICKS := 54
const RECOVERY_INTERVAL_TICKS := 2
const BURST_SPEED_MULTIPLIER := 1.85
const SUSTAIN_SPEED_MULTIPLIER := 1.55
const BURST_LEAP_MULTIPLIER := 1.28
const SUSTAIN_LEAP_MULTIPLIER := 1.16

var state := State.READY
var active_ticks := 0
var drain_ticks := 0
var recovery_delay_ticks := 0
var recovery_ticks := 0
var requires_release := false

func advance(boost_held: bool, movement_active: bool, allowed: bool, current_energy: int) -> Dictionary:
	var energy := clampi(current_energy, 0, MAX_ENERGY)
	var event := ""
	if requires_release and not boost_held:
		requires_release = false

	if state in [State.BURST, State.SUSTAIN]:
		if not boost_held or not movement_active or not allowed:
			_begin_recovery(false)
			event = "cancelled"
		else:
			active_ticks += 1
			drain_ticks += 1
			if state == State.BURST and active_ticks >= BURST_TICKS:
				state = State.SUSTAIN
				event = "sustain"
			if drain_ticks >= DRAIN_INTERVAL_TICKS:
				drain_ticks = 0
				energy = maxi(0, energy - 1)
			if energy <= 0:
				_begin_recovery(true)
				event = "exhausted"
	elif boost_held and movement_active and allowed and not requires_release and (state == State.READY or (state == State.RECOVERING and recovery_delay_ticks <= 0)):
		if energy >= START_THRESHOLD:
			state = State.BURST
			active_ticks = 1
			drain_ticks = 0
			recovery_delay_ticks = 0
			recovery_ticks = 0
			energy = maxi(0, energy - ACTIVATION_COST)
			event = "started"
		else:
			_begin_recovery(true)
			event = "exhausted"
	elif state == State.READY and energy < MAX_ENERGY:
		state = State.RECOVERING
		recovery_delay_ticks = 0
		recovery_ticks = 0

	if state in [State.EXHAUSTED, State.RECOVERING]:
		if recovery_delay_ticks > 0:
			recovery_delay_ticks -= 1
		else:
			if state == State.EXHAUSTED:
				state = State.RECOVERING
				event = "recovering" if event.is_empty() else event
			recovery_ticks += 1
			if recovery_ticks >= RECOVERY_INTERVAL_TICKS:
				recovery_ticks = 0
				energy = mini(MAX_ENERGY, energy + 1)
			if energy >= MAX_ENERGY and not requires_release:
				state = State.READY
				event = "ready" if event.is_empty() else event

	return {
		"energy": energy,
		"event": event,
		"state": state,
		"active": is_active(),
		"speed_multiplier": speed_multiplier(),
		"leap_multiplier": leap_multiplier(),
		"cue": cue(),
	}

func cancel(current_energy: int, exhausted: bool = false) -> Dictionary:
	var energy := clampi(current_energy, 0, MAX_ENERGY)
	if state in [State.BURST, State.SUSTAIN] or exhausted:
		_begin_recovery(exhausted)
	return {
		"energy": energy,
		"state": state,
		"active": is_active(),
		"cue": cue(),
	}

func reset() -> void:
	state = State.READY
	active_ticks = 0
	drain_ticks = 0
	recovery_delay_ticks = 0
	recovery_ticks = 0
	requires_release = false

func is_active() -> bool:
	return state in [State.BURST, State.SUSTAIN]

func speed_multiplier() -> float:
	if state == State.BURST:
		return BURST_SPEED_MULTIPLIER
	if state == State.SUSTAIN:
		return SUSTAIN_SPEED_MULTIPLIER
	return 1.0

func leap_multiplier() -> float:
	if state == State.BURST:
		return BURST_LEAP_MULTIPLIER
	if state == State.SUSTAIN:
		return SUSTAIN_LEAP_MULTIPLIER
	return 1.0

func cue() -> String:
	match state:
		State.BURST:
			return "BOOST BURST"
		State.SUSTAIN:
			return "BOOST"
		State.EXHAUSTED:
			return "BOOST EXHAUSTED"
		State.RECOVERING:
			return "BOOST RECOVERING"
		_:
			return "BOOST READY"

func _begin_recovery(exhausted: bool) -> void:
	state = State.EXHAUSTED if exhausted else State.RECOVERING
	active_ticks = 0
	drain_ticks = 0
	recovery_ticks = 0
	recovery_delay_ticks = EXHAUSTED_RECOVERY_DELAY_TICKS if exhausted else RELEASE_RECOVERY_DELAY_TICKS
	requires_release = exhausted
