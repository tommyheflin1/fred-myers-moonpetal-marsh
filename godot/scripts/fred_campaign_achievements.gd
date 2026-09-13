class_name FredCampaignAchievements
extends RefCounted

# App-owned proposed IDs, not a claim of Apple registration. No puzzle changes.
const PREFIX := "com.flinsvault.fredmyers.campaign_"
const TITLES: Array[String] = [
	"First Lily Trail", "Reed Runner", "Moonlit Explorer", "Marsh Pathfinder",
	"Moonpetal Scout", "Current Cruiser", "Lily Lane Hero", "Wetland Wanderer",
	"Marshland Strider", "Moonbeam Voyager", "Reedway Ranger", "Lily Leap Legend",
	"Beyond Halfway", "Current Champion", "Moonpetal Guardian", "Marshlight Adventurer",
	"Reedland Rescuer", "Lilyway Luminary", "Moonwater Marvel", "Wetland Wonder",
	"Marshland Master", "Moonpetal Mentor", "Final Stretch Frog", "Promise Keeper",
	"Hero of Moonpetal"
]

static func definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in TITLES.size():
		var level := (index + 1) * 4
		result.append({
			"id": PREFIX + "%03d" % level, "event": "completed_level",
			"threshold": level, "name": TITLES[index], "points": 40,
			"hidden": false, "repeatable": false,
			"unearned_description": "Complete Level %d in Fred's marsh adventure." % level,
			"earned_description": "You completed Level %d. Keep the marsh glowing!" % level,
		})
	return result

static func earned_ids(completed_level: int) -> Array[String]:
	var rules := AchievementService.new()
	rules.configure(definitions())
	rules.set_progress("completed_level", clampi(completed_level, 0, 100))
	return rules.unlocked_ids()

static func completed_level_from_records(records: Array) -> int:
	var best := 0
	for value: Variant in records:
		if value is Dictionary:
			var level := int(value.get("level", 0))
			if level >= 1 and level <= 100 and int(value.get("score", 0)) >= level * 1000:
				best = maxi(best, level)
	return best
