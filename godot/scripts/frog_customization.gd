class_name FredFrogCustomization
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://fred_profile.json"
const MAX_PROFILE_BYTES := 32768
const MAX_COINS := 999999
const CATEGORIES: Array[String] = ["hero", "body", "size", "tongue", "attire"]
const BODY_PROPORTIONS := {
	"quick": Vector2(0.90, 1.06),
	"classic": Vector2(1.00, 1.00),
	"power": Vector2(1.18, 0.94),
	"pocket_hopper": Vector2(0.82, 1.12),
	"springy": Vector2(0.78, 1.20),
	"swift": Vector2(0.84, 1.08),
	"trail_fit": Vector2(1.04, 1.02),
	"strong": Vector2(1.24, 0.98),
}
const BUILD_2_EXPANSION_IDS := {
	"body": ["golden_glider", "river_sapphire", "berry_bolt", "night_hero", "pearl_hopper"],
	"size": ["pocket_hopper", "springy", "swift", "trail_fit", "strong"],
	"tongue": ["coral_pop", "lime_spark", "cherry_flash", "ice_stream", "golden_zap"],
	"attire": ["pond_pilot", "rain_ranger", "bug_catcher", "star_jumper", "lily_lifeguard"],
}
const CATALOG := {
	"hero": [
		{"id":"classic_fred", "label":"Classic Fred", "cost":0, "value":"classic_fred"},
		{"id":"girl_hero", "label":"Girl Hero", "cost":0, "value":"girl_hero"},
		{"id":"boy_hero", "label":"Boy Hero", "cost":0, "value":"boy_hero"},
	],
	"body": [
		{"id":"marsh_green", "label":"Marsh Green", "cost":0, "value":"4fbd68"},
		{"id":"turquoise_dash", "label":"Turquoise Dash", "cost":30, "value":"35b7a5"},
		{"id":"sunset_sprinter", "label":"Sunset Sprinter", "cost":55, "value":"d77a45"},
		{"id":"moonberry", "label":"Moonberry", "cost":80, "value":"8268c7"},
		{"id":"golden_glider", "label":"Golden Glider", "cost":105, "value":"e4bd3c"},
		{"id":"river_sapphire", "label":"River Sapphire", "cost":135, "value":"3f80d9"},
		{"id":"berry_bolt", "label":"Berry Bolt", "cost":170, "value":"c84f6f"},
		{"id":"night_hero", "label":"Night Hero", "cost":210, "value":"38518f"},
		{"id":"pearl_hopper", "label":"Pearl Hopper", "cost":255, "value":"d6e7cf"},
		{"id":"rose_dew", "label":"Rose Dew", "cost":275, "value":"ce899f"},
		{"id":"forest_jade", "label":"Forest Jade", "cost":295, "value":"397963"},
	],
	"size": [
		{"id":"quick", "label":"Quick", "cost":0, "value":1.05},
		{"id":"classic", "label":"Classic", "cost":25, "value":1.10},
		{"id":"power", "label":"Power", "cost":65, "value":1.14},
		{"id":"pocket_hopper", "label":"Pocket Hopper", "cost":85, "value":0.88},
		{"id":"springy", "label":"Springy", "cost":110, "value":0.92},
		{"id":"swift", "label":"Swift", "cost":140, "value":0.96},
		{"id":"trail_fit", "label":"Trail Fit", "cost":175, "value":1.00},
		{"id":"strong", "label":"Strong", "cost":215, "value":1.12},
	],
	"tongue": [
		{"id":"berry", "label":"Berry Tongue", "cost":0, "value":"ff7ca8"},
		{"id":"mango", "label":"Mango Tongue", "cost":30, "value":"ffb34d"},
		{"id":"electric", "label":"Electric Tongue", "cost":55, "value":"72e9ff"},
		{"id":"moonbeam", "label":"Moonbeam Tongue", "cost":75, "value":"d7b9ff"},
		{"id":"coral_pop", "label":"Coral Pop Tongue", "cost":100, "value":"ff6f61"},
		{"id":"lime_spark", "label":"Lime Spark Tongue", "cost":125, "value":"b7f34a"},
		{"id":"cherry_flash", "label":"Cherry Flash Tongue", "cost":155, "value":"e43f5a"},
		{"id":"ice_stream", "label":"Ice Stream Tongue", "cost":190, "value":"8ce7f2"},
		{"id":"golden_zap", "label":"Golden Zap Tongue", "cost":230, "value":"ffd34e"},
	],
	"attire": [
		{"id":"marsh_runner", "label":"Runner Goggles", "cost":0, "value":"marsh_runner"},
		{"id":"trail_scout", "label":"Explorer Glasses", "cost":45, "value":"trail_scout"},
		{"id":"moon_champion", "label":"Moon Champion Visor", "cost":95, "value":"moon_champion"},
		{"id":"firefly_hero", "label":"Firefly Hero Goggles", "cost":140, "value":"firefly_hero"},
		{"id":"pond_pilot", "label":"Pond Pilot Goggles", "cost":190, "value":"pond_pilot"},
		{"id":"rain_ranger", "label":"Rain Ranger Glasses", "cost":245, "value":"rain_ranger"},
		{"id":"bug_catcher", "label":"Bug Catcher Shades", "cost":305, "value":"bug_catcher"},
		{"id":"star_jumper", "label":"Star Jumper Visor", "cost":370, "value":"star_jumper"},
		{"id":"lily_lifeguard", "label":"Lily Lifeguard Goggles", "cost":440, "value":"lily_lifeguard"},
		{"id":"petal_guardian", "label":"Petal Guardian", "cost":460, "value":"petal_guardian"},
		{"id":"moon_blossom", "label":"Moon Blossom", "cost":480, "value":"moon_blossom"},
		{"id":"reed_sentinel", "label":"Reed Sentinel", "cost":500, "value":"reed_sentinel"},
		{"id":"storm_striker", "label":"Storm Striker", "cost":520, "value":"storm_striker"},
	],
}

var path := DEFAULT_PATH
var temp_path := "user://fred_profile.tmp.json"
var persistent := true
var coins := 0
var owned := {
	"hero": ["classic_fred", "girl_hero", "boy_hero"],
	"body": ["marsh_green"],
	"size": ["quick"],
	"tongue": ["berry"],
	"attire": ["marsh_runner"],
}
var selected := {
	"hero": "classic_fred",
	"body": "marsh_green",
	"size": "quick",
	"tongue": "berry",
	"attire": "marsh_runner",
}

func _init(custom_path: String = DEFAULT_PATH) -> void:
	if custom_path.is_empty():
		path = ""
		temp_path = ""
		persistent = false
		return
	path = custom_path
	temp_path = custom_path.trim_suffix(".json") + ".tmp.json"
	load_profile()

func earn_coins(amount: int) -> int:
	coins = clampi(coins + maxi(0, amount), 0, MAX_COINS)
	save_profile()
	return coins

func select_next(category: String) -> Dictionary:
	if category not in CATEGORIES:
		return {"ok":false, "reason":"invalid_category"}
	var entries: Array = CATALOG[category]
	var current_index := 0
	for index in entries.size():
		if str(entries[index].id) == str(selected[category]):
			current_index = index
			break
	var next: Dictionary = entries[(current_index + 1) % entries.size()]
	return purchase_and_equip(category, str(next.id))

func entry_for(category: String, item_id: String) -> Dictionary:
	if category in CATEGORIES:
		for entry: Dictionary in CATALOG[category]:
			if str(entry.id) == item_id:
				return entry.duplicate(true)
	return {}

func owns(category: String, item_id: String) -> bool:
	return not entry_for(category, item_id).is_empty() and item_id in Array(owned.get(category, []))

func equip(category: String, item_id: String) -> Dictionary:
	if not owns(category, item_id):
		return {"ok":false, "reason":"not_owned"}
	return _commit_choice(category, entry_for(category, item_id), false)

func purchase_and_equip(category: String, item_id: String) -> Dictionary:
	var entry := entry_for(category, item_id)
	if entry.is_empty():
		return {"ok":false, "reason":"invalid_item"}
	if owns(category, item_id):
		return equip(category, item_id)
	if coins < int(entry.cost):
		return {"ok":false, "reason":"need_coins", "cost":int(entry.cost), "label":str(entry.label)}
	return _commit_choice(category, entry, true)

func _commit_choice(category: String, entry: Dictionary, purchase: bool) -> Dictionary:
	var before := to_dictionary()
	var item_id := str(entry.id)
	if purchase:
		coins -= int(entry.cost)
		var unlocked: Array = Array(owned[category]).duplicate()
		unlocked.append(item_id)
		owned[category] = unlocked
	selected[category] = item_id
	if not save_profile():
		restore(before)
		return {"ok":false, "reason":"save_failed"}
	return {"ok":true, "category":category, "item":item_id, "label":str(entry.label), "coins":coins, "purchased":purchase}

func preview_style(category: String, item_id: String) -> Dictionary:
	# A temporary in-memory profile never buys, equips or writes player data.
	var preview := get_script().new("") as RefCounted
	preview.restore(to_dictionary())
	if not entry_for(category, item_id).is_empty():
		preview.selected[category] = item_id
	return preview.current_style()

func current_style() -> Dictionary:
	var body_build := str(_selected_entry("size").id)
	return {
		"hero_style": str(_selected_entry("hero").value),
		"body_color": Color(str(_selected_entry("body").value)),
		"size_scale": float(_selected_entry("size").value),
		"body_build": body_build,
		"body_proportions": Vector2(BODY_PROPORTIONS.get(body_build, Vector2.ONE)),
		"tongue_color": Color(str(_selected_entry("tongue").value)),
		"attire": str(_selected_entry("attire").value),
	}

func selected_label(category: String) -> String:
	return str(_selected_entry(category).get("label", "Unknown"))

func item_count(category: String) -> int:
	return CATALOG[category].size() if category in CATEGORIES else 0

func selected_position(category: String) -> int:
	if category not in CATEGORIES:
		return 0
	for index in CATALOG[category].size():
		if str(CATALOG[category][index].id) == str(selected[category]):
			return index + 1
	return 1

func next_cost(category: String) -> int:
	if category not in CATEGORIES:
		return 0
	var entries: Array = CATALOG[category]
	var current_index := 0
	for index in entries.size():
		if str(entries[index].id) == str(selected[category]):
			current_index = index
			break
	var next: Dictionary = entries[(current_index + 1) % entries.size()]
	return 0 if str(next.id) in Array(owned[category]) else int(next.cost)

func next_label(category: String) -> String:
	if category not in CATEGORIES:
		return "Unknown"
	var entries: Array = CATALOG[category]
	var current_index := 0
	for index in entries.size():
		if str(entries[index].id) == str(selected[category]):
			current_index = index
			break
	return str(entries[(current_index + 1) % entries.size()].label)

func to_dictionary() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"coins": coins,
		"owned": owned.duplicate(true),
		"selected": selected.duplicate(true),
	}

func restore(data: Dictionary) -> bool:
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return false
	coins = clampi(int(data.get("coins", 0)), 0, MAX_COINS)
	var incoming_owned: Dictionary = data.get("owned", {}) if data.get("owned", {}) is Dictionary else {}
	var incoming_selected: Dictionary = data.get("selected", {}) if data.get("selected", {}) is Dictionary else {}
	for category in CATEGORIES:
		var valid_ids: Array[String] = []
		for entry: Dictionary in CATALOG[category]:
			valid_ids.append(str(entry.id))
		var starter := str(CATALOG[category][0].id)
		var restored_owned: Array[String] = []
		for entry: Dictionary in CATALOG[category]:
			if int(entry.cost) == 0:
				restored_owned.append(str(entry.id))
		if incoming_owned.get(category, []) is Array:
			for value: Variant in incoming_owned.get(category, []):
				var item_id := str(value)
				if item_id in valid_ids and item_id not in restored_owned:
					restored_owned.append(item_id)
		owned[category] = restored_owned
		var choice := str(incoming_selected.get(category, starter))
		selected[category] = choice if choice in restored_owned else starter
	return true

func save_profile() -> bool:
	if not persistent:
		return true
	var encoded := JSON.stringify(to_dictionary(), "  ")
	if encoded.to_utf8_buffer().size() > MAX_PROFILE_BYTES:
		return false
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encoded)
	file.flush()
	if file.get_error() != OK:
		return false
	file = null
	if FileAccess.file_exists(path):
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK

func load_profile() -> bool:
	if not persistent:
		return false
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_PROFILE_BYTES:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed is Dictionary and restore(parsed)

func _selected_entry(category: String) -> Dictionary:
	if category not in CATEGORIES:
		return {}
	for entry: Dictionary in CATALOG[category]:
		if str(entry.id) == str(selected[category]):
			return entry
	return CATALOG[category][0]
