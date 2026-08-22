class_name FredLevelIntensity
extends RefCounted

const MIN_LEVEL := 1
const MAX_LEVEL := 100
const CAMPAIGN_ID := "campaign_1"
const CAMPAIGN_NAME := "Campaign 1: The Moonpetal Promise"
const CONTENT_RATING := "PG"
const TARGET_MIN_AGE := 5
const CHAPTER_SIZE := 10
const OPENING_CHALLENGE := 1.9

static func profile(level: int) -> Dictionary:
	var safe_level := clampi(level, MIN_LEVEL, MAX_LEVEL)
	var chapter := mini(10, ((safe_level - 1) / CHAPTER_SIZE) + 1)
	var chapter_level := ((safe_level - 1) % CHAPTER_SIZE) + 1
	# Owner testing found the original first chapter too empty. Level 1 now
	# begins at the former Level 10 pressure and every level still advances one
	# exact tenth: 1.9x...2.8x through 10.9x...11.8x.
	var challenge_multiplier := OPENING_CHALLENGE + float(safe_level - 1) * 0.1
	var campaign_progress := (challenge_multiplier - OPENING_CHALLENGE) / 9.9
	# A concave pressure curve makes the first ten levels visibly different
	# without pushing late-game motion beyond the age-five safety caps.
	var pressure_curve := sqrt(campaign_progress)
	var whirlpool_count := 0 if chapter == 1 else mini(3, 1 + ((chapter - 2) / 3))
	return {
		"campaign_id": CAMPAIGN_ID,
		"campaign_name": CAMPAIGN_NAME,
		"content_rating": CONTENT_RATING,
		"target_min_age": TARGET_MIN_AGE,
		"level": safe_level,
		"difficulty_step": safe_level,
		"difficulty_stars": mini(5, 1 + ((chapter - 1) / 2)),
		"intensity": snappedf(challenge_multiplier, 0.0001),
		"challenge_multiplier": snappedf(challenge_multiplier, 0.0001),
		"challenge_label": "CHAPTER %02d  •  STEP %d/10  •  %.1fx" % [chapter, chapter_level, challenge_multiplier],
		"predator_speed_scale": snappedf(0.72 + pressure_curve * 0.55, 0.0001),
		"reaction_window_seconds": snappedf(2.40 - pressure_curve * 0.90, 0.0001),
		"mistake_grace_seconds": snappedf(2.90 - pressure_curve * 1.00, 0.0001),
		"objective_density": snappedf(1.0 + pressure_curve * 0.35, 0.0001),
		"chapter": chapter,
		"chapter_level": chapter_level,
		"assist_mode": "FULL" if chapter <= 2 else ("GUIDED" if chapter <= 6 else "HERO"),
		"label": _label_for(safe_level),
		"new_twist": _twist_for(safe_level),
		"current_strength": snappedf(4.0 + pressure_curve * 28.0, 0.01),
		"weaving_patrol": safe_level >= 3,
		"predator_weave_amplitude": 0.0 if safe_level < 3 else snappedf(22.0 + pressure_curve * 93.0, 0.01),
		"predator_weave_speed": snappedf(0.68 + pressure_curve * 0.52, 0.0001),
		"reversing_current": safe_level >= 8,
		"current_reversal_frequency": snappedf(0.45 + pressure_curve * 0.75, 0.0001),
		"safe_radius": snappedf(70.0 - pressure_curve * 20.0, 0.01),
		"danger_radius": snappedf(34.0 + pressure_curve * 12.0, 0.01),
		"predator_count": mini(5, chapter + 1),
		"whirlpool_count": whirlpool_count,
		"lily_drift": snappedf(0.8 + pressure_curve * 10.0, 0.01),
		"bug_flight_radius": snappedf(3.0 + pressure_curve * 14.0, 0.01),
		"bug_flight_speed": snappedf(0.32 + pressure_curve * 0.58, 0.0001),
	}

static func _label_for(level: int) -> String:
	if level <= 10:
		return "Gentle Marsh"
	if level <= 20:
		return "Rising Waters"
	if level <= 30:
		return "Winding Waters"
	if level <= 40:
		return "Current Challenge"
	if level <= 50:
		return "Wild Marsh"
	if level <= 60:
		return "Deepwater Dash"
	if level <= 70:
		return "Predator Crossing"
	if level <= 80:
		return "Moonlit Challenge"
	if level <= 90:
		return "Hero's Gauntlet"
	return "Moonpetal Mastery"

static func _twist_for(level: int) -> String:
	var introductions := {
		1: "Learn Fred's safe hero moves",
		2: "Follow the first drifting lily",
		3: "Chase the circling marsh bugs",
		4: "Follow a gentle current",
		5: "Outsmart the weaving fish patrol",
		6: "Dive beneath a surface predator",
		7: "Time the wider lily drift",
		8: "Read the reversing current",
		9: "Combine leap, boost, and tongue",
		10: "Earn the chapter fairy reward",
	}
	if introductions.has(level):
		return introductions[level]
	var chapter := ((level - 1) / CHAPTER_SIZE) + 1
	var chapter_level := ((level - 1) % CHAPTER_SIZE) + 1
	var focus: String = str([
		"stronger current",
		"wider patrol",
		"drifting lilies",
		"circling bugs",
		"underwater timing",
		"boost route",
		"reverse current",
		"mixed depths",
		"tight landing",
		"chapter trial",
	][chapter_level - 1])
	return "Chapter %02d step %d: %s" % [chapter, chapter_level, focus]
