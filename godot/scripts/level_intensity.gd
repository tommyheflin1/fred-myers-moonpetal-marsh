class_name FredLevelIntensity
extends RefCounted

const MIN_LEVEL := 1
const MAX_LEVEL := 100
const CAMPAIGN_ID := "campaign_1"
const CAMPAIGN_NAME := "Campaign 1: The Moonpetal Promise"
const CONTENT_RATING := "PG"
const TARGET_MIN_AGE := 5
const CHAPTER_SIZE := 10

static func profile(level: int) -> Dictionary:
	var safe_level := clampi(level, MIN_LEVEL, MAX_LEVEL)
	var progress := float(safe_level - 1) / float(MAX_LEVEL - 1)
	var curve := progress * progress * (3.0 - 2.0 * progress)
	var chapter := mini(10, ((safe_level - 1) / CHAPTER_SIZE) + 1)
	return {
		"campaign_id": CAMPAIGN_ID,
		"campaign_name": CAMPAIGN_NAME,
		"content_rating": CONTENT_RATING,
		"target_min_age": TARGET_MIN_AGE,
		"level": safe_level,
		"difficulty_step": safe_level,
		"difficulty_stars": mini(5, 1 + ((safe_level - 1) / 20)),
		"intensity": snappedf(0.75 + curve * 0.75, 0.0001),
		"predator_speed_scale": snappedf(0.74 + curve * 0.56, 0.0001),
		"reaction_window_seconds": snappedf(2.20 - curve * 0.85, 0.0001),
		"mistake_grace_seconds": snappedf(2.75 - curve * 0.95, 0.0001),
		"objective_density": snappedf(1.0 + curve * 0.25, 0.0001),
		"chapter": chapter,
		"chapter_level": ((safe_level - 1) % CHAPTER_SIZE) + 1,
		"assist_mode": "FULL" if chapter <= 2 else ("GUIDED" if chapter <= 6 else "HERO"),
		"label": _label_for(safe_level),
		"new_twist": _twist_for(safe_level),
		"current_strength": 0.0 if safe_level <= 3 else snappedf(6.0 + curve * 26.0, 0.01),
		"weaving_patrol": safe_level >= 9,
		"reversing_current": safe_level >= 14,
		"safe_radius": snappedf(68.0 - curve * 18.0, 0.01),
		"danger_radius": snappedf(36.0 + curve * 12.0, 0.01),
		"predator_count": mini(5, 1 + int(floor(progress * 5.0))),
		"whirlpool_count": 0 if safe_level <= 15 else (1 if safe_level <= 45 else (2 if safe_level <= 75 else 3)),
		"lily_drift": snappedf(1.5 + curve * 9.5, 0.01),
		"bug_flight_radius": snappedf(4.0 + curve * 13.0, 0.01),
		"bug_flight_speed": snappedf(0.38 + curve * 0.54, 0.01),
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
		1: "Use the right control pad",
		2: "Land on the lily path",
		3: "Munch the glowing bugs",
		4: "Follow a gentle current",
		5: "Try Fred's boost trail",
		6: "Dive and surface safely",
		7: "Watch the moving lily pads",
		8: "Follow the flying bugs",
		9: "Meet the first fish patrol",
		10: "Find the helpful fairy",
	}
	if introductions.has(level):
		return introductions[level]
	var focus: String = str(["current", "patrol", "lily route", "timing", "bug chase"][(level - 11) % 5])
	return "Level %03d: practice the %s" % [level, focus]
