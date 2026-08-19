class_name FredFrogCustomization
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://fred_profile.json"
const MAX_PROFILE_BYTES := 32768
const MAX_COINS := 999999
const CATEGORIES: Array[String] = ["body", "size", "tongue", "attire"]
const CATALOG := {
	"body": [
		{"id":"marsh_green", "label":"Marsh Green", "cost":0, "value":"4fbd68"},
		{"id":"turquoise_dash", "label":"Turquoise Dash", "cost":30, "value":"35b7a5"},
		{"id":"sunset_sprinter", "label":"Sunset Sprinter", "cost":55, "value":"d77a45"},
		{"id":"moonberry", "label":"Moonberry", "cost":80, "value":"8268c7"},
	],
	"size": [
		{"id":"quick", "label":"Quick", "cost":0, "value":1.05},
		{"id":"classic", "label":"Classic", "cost":25, "value":1.10},
		{"id":"power", "label":"Power", "cost":65, "value":1.14},
	],
	"tongue": [
		{"id":"berry", "label":"Berry Tongue", "cost":0, "value":"ff7ca8"},
		{"id":"mango", "label":"Mango Tongue", "cost":30, "value":"ffb34d"},
		{"id":"electric", "label":"Electric Tongue", "cost":55, "value":"72e9ff"},
		{"id":"moonbeam", "label":"Moonbeam Tongue", "cost":75, "value":"d7b9ff"},
	],
	"attire": [
		{"id":"marsh_runner", "label":"Runner Goggles", "cost":0, "value":"marsh_runner"},
		{"id":"trail_scout", "label":"Explorer Glasses", "cost":45, "value":"trail_scout"},
		{"id":"moon_champion", "label":"Moon Champion Visor", "cost":95, "value":"moon_champion"},
		{"id":"firefly_hero", "label":"Firefly Hero Goggles", "cost":140, "value":"firefly_hero"},
	],
}

var path := DEFAULT_PATH
var temp_path := "user://fred_profile.tmp.json"
var persistent := true
var coins := 0
var owned := {
	"body": ["marsh_green"],
	"size": ["quick"],
	"tongue": ["berry"],
	"attire": ["marsh_runner"],
}
var selected := {
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
	var item_id := str(next.id)
	if item_id not in Array(owned[category]):
		var cost := int(next.cost)
		if coins < cost:
			return {"ok":false, "reason":"need_coins", "cost":cost, "label":str(next.label)}
		coins -= cost
		var unlocked: Array = Array(owned[category]).duplicate()
		unlocked.append(item_id)
		owned[category] = unlocked
	selected[category] = item_id
	save_profile()
	return {"ok":true, "category":category, "item":item_id, "label":str(next.label), "coins":coins}

func current_style() -> Dictionary:
	return {
		"body_color": Color(str(_selected_entry("body").value)),
		"size_scale": float(_selected_entry("size").value),
		"tongue_color": Color(str(_selected_entry("tongue").value)),
		"attire": str(_selected_entry("attire").value),
	}

func selected_label(category: String) -> String:
	return str(_selected_entry(category).get("label", "Unknown"))

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
		var restored_owned: Array[String] = [starter]
		if incoming_owned.get(category, []) is Array:
			for value: Variant in incoming_owned[category]:
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
