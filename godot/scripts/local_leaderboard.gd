class_name FredLocalLeaderboard
extends RefCounted

const MAX_ENTRIES := 10
const DEFAULT_PATH := "user://fred_leaderboard.json"

var path := DEFAULT_PATH
var entries: Array[Dictionary] = []

func _init(custom_path: String = DEFAULT_PATH) -> void:
	path = custom_path
	load_entries()

func submit(profile_label: String, level: int, bugs: int, lives: int) -> Dictionary:
	var safe_label := _safe_label(profile_label)
	var safe_level := clampi(level, 1, 100)
	var safe_bugs := clampi(bugs, 0, 3)
	var safe_lives := clampi(lives, 0, 5)
	var score := safe_level * 1000 + safe_bugs * 100 + safe_lives * 25
	var entry := {
		"player": safe_label,
		"level": safe_level,
		"bugs": safe_bugs,
		"lives": safe_lives,
		"score": score,
	}
	entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.score) == int(b.score):
			return str(a.player) < str(b.player)
		return int(a.score) > int(b.score)
	)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	_save()
	return entry.duplicate(true)

func load_entries() -> Array[Dictionary]:
	entries.clear()
	if not FileAccess.file_exists(path):
		return entries.duplicate(true)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Array:
		return entries.duplicate(true)
	for value: Variant in parsed:
		if value is Dictionary:
			var item: Dictionary = value
			if item.has("score") and item.has("player"):
				entries.append({
					"player": _safe_label(str(item.player)),
					"level": clampi(int(item.get("level", 1)), 1, 100),
					"bugs": clampi(int(item.get("bugs", 0)), 0, 3),
					"lives": clampi(int(item.get("lives", 0)), 0, 5),
					"score": maxi(0, int(item.score)),
				})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	return entries.duplicate(true)

func _save() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entries))

func _safe_label(value: String) -> String:
	var cleaned := ""
	for character in value.strip_edges().left(24):
		if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789 _-":
			cleaned += character
	return cleaned if not cleaned.is_empty() else "Guest Frog"
