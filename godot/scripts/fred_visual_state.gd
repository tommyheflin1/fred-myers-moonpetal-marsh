class_name FredVisualState
extends RefCounted

const MAX_VISUAL_TIME := TAU * 100.0

static func wave(time: float, phase: float, amplitude: float, reduced_motion: bool) -> float:
    if reduced_motion:
        return 0.0
    return sin(time * 1.7 + phase) * amplitude

static func pulse(time: float, phase: float, reduced_motion: bool) -> float:
    if reduced_motion:
        return 1.0
    return 1.0 + sin(time * 2.2 + phase) * 0.06

static func bounded_time(current: float, delta: float) -> float:
    return fmod(maxf(0.0, current + maxf(0.0, delta)), MAX_VISUAL_TIME)

static func snapshot(time: float, reduced_motion: bool) -> Dictionary:
    return {
        "fred_bob":wave(time, 0.0, 3.0, reduced_motion),
        "water_shift":wave(time, 0.7, 14.0, reduced_motion),
        "reed_sway":wave(time, 1.4, 5.0, reduced_motion),
        "wildlife_flutter":wave(time, 2.1, 4.0, reduced_motion),
        "exit_pulse":pulse(time, 0.4, reduced_motion),
    }
