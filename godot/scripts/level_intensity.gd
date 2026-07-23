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
		"intensity": snappedf(1.0 + curve * 1.05, 0.0001),
		"predator_speed_scale": snappedf(1.0 + curve * 0.68, 0.0001),
		"reaction_window_seconds": snappedf(1.4 - curve * 0.50, 0.0001),
		"objective_density": snappedf(1.0 + curve * 0.45, 0.0001),
		"chapter": mini(10, ((safe_level - 1) / 10) + 1),
		"label": _label_for(safe_level),
		"new_twist": _twist_for(safe_level),
		"current_strength": 0.0 if safe_level == 1 else snappedf(12.0 + curve * 34.0, 0.01),
		"weaving_patrol": safe_level >= 3,
		"reversing_current": safe_level >= 4,
		"safe_radius": snappedf(maxf(42.0, 55.0 - float(maxi(0, safe_level - 4)) * 0.16), 0.01),
		"danger_radius": snappedf(minf(53.0, 45.0 + float(maxi(0, safe_level - 5)) * 0.10), 0.01),
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

static func _twist_for(level: int) -> String:
	var introductions := {
		1: "Learn the lily path",
		2: "Marsh current",
		3: "Weaving predator",
		4: "Reversing water flow",
		5: "Tighter safe island",
		6: "Wider danger reach",
		7: "Underwater cross-flow",
		8: "Quicker current changes",
		9: "Denser patrol pressure",
		10: "Chapter challenge mix",
	}
	if introductions.has(level):
		return introductions[level]
	var focus: String = str(["current", "patrol", "safe route", "reaction window", "objective pressure"][(level - 11) % 5])
	return "Level %03d: stronger %s pattern" % [level, focus]
