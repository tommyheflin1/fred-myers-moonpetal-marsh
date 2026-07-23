class_name FredLevelIntensity
extends RefCounted

const MIN_LEVEL := 1
const MAX_LEVEL := 100

static func profile(level: int) -> Dictionary:
	var safe_level := clampi(level, MIN_LEVEL, MAX_LEVEL)
	var progress := float(safe_level - 1) / float(MAX_LEVEL - 1)
	var curve := progress * progress * (3.0 - 2.0 * progress)
	return {
		"level": safe_level,
		"intensity": snappedf(1.0 + curve * 0.75, 0.0001),
		"predator_speed_scale": snappedf(1.0 + curve * 0.42, 0.0001),
		"reaction_window_seconds": snappedf(1.4 - curve * 0.35, 0.0001),
		"objective_density": snappedf(1.0 + curve * 0.30, 0.0001),
		"chapter": mini(10, ((safe_level - 1) / 10) + 1),
		"label": _label_for(safe_level),
	}

static func _label_for(level: int) -> String:
	if level <= 10:
		return "Gentle Marsh"
	if level <= 30:
		return "Winding Waters"
	if level <= 60:
		return "Wild Marsh"
	if level <= 80:
		return "Moonlit Challenge"
	return "Moonpetal Mastery"
