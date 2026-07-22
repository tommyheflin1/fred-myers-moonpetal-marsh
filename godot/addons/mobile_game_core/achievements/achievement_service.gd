class_name AchievementService
extends RefCounted

signal achievement_unlocked(achievement_id: String)
signal progress_changed(achievement_id: String, progress: int, threshold: int)

var _definitions: Dictionary = {}
var _event_index: Dictionary = {}
var _progress: Dictionary = {}
var _unlocked: Dictionary = {}

func configure(definitions: Array) -> bool:
    _definitions.clear()
    _event_index.clear()
    _progress.clear()
    _unlocked.clear()
    for value: Variant in definitions:
        if value is not Dictionary:
            return false
        var definition: Dictionary = value
        var achievement_id := str(definition.get("id", ""))
        var event_name := str(definition.get("event", ""))
        var threshold := int(definition.get("threshold", 0))
        if achievement_id.is_empty() or event_name.is_empty() or threshold < 1 or _definitions.has(achievement_id):
            return false
        _definitions[achievement_id] = definition.duplicate(true)
        if not _event_index.has(event_name):
            _event_index[event_name] = []
        _event_index[event_name].append(achievement_id)
        _progress[achievement_id] = 0
    return not _definitions.is_empty()

func record(event_name: String, amount: int = 1) -> Array[String]:
    var newly_unlocked: Array[String] = []
    if amount <= 0:
        return newly_unlocked
    for value: Variant in _event_index.get(event_name, []):
        var achievement_id := str(value)
        if is_unlocked(achievement_id):
            continue
        var threshold := int((_definitions[achievement_id] as Dictionary).get("threshold", 1))
        var next_progress := mini(threshold, int(_progress.get(achievement_id, 0)) + amount)
        _progress[achievement_id] = next_progress
        progress_changed.emit(achievement_id, next_progress, threshold)
        if next_progress >= threshold:
            _unlocked[achievement_id] = true
            newly_unlocked.append(achievement_id)
            achievement_unlocked.emit(achievement_id)
    return newly_unlocked

func set_progress(event_name: String, total: int) -> Array[String]:
    var newly_unlocked: Array[String] = []
    for value: Variant in _event_index.get(event_name, []):
        var achievement_id := str(value)
        if is_unlocked(achievement_id):
            continue
        var threshold := int((_definitions[achievement_id] as Dictionary).get("threshold", 1))
        var next_progress := clampi(total, 0, threshold)
        if next_progress <= int(_progress.get(achievement_id, 0)):
            continue
        _progress[achievement_id] = next_progress
        progress_changed.emit(achievement_id, next_progress, threshold)
        if next_progress >= threshold:
            _unlocked[achievement_id] = true
            newly_unlocked.append(achievement_id)
            achievement_unlocked.emit(achievement_id)
    return newly_unlocked

func is_unlocked(achievement_id: String) -> bool:
    return _unlocked.has(achievement_id)

func progress(achievement_id: String) -> int:
    return int(_progress.get(achievement_id, 0))

func unlocked_ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _unlocked.keys():
        result.append(str(value))
    result.sort()
    return result

func snapshot() -> Dictionary:
    return {"progress": _progress.duplicate(true), "unlocked": unlocked_ids()}

func restore(data: Dictionary) -> void:
    for achievement_id: Variant in _definitions:
        _progress[achievement_id] = 0
    _unlocked.clear()
    var stored_progress: Variant = data.get("progress", {})
    if stored_progress is Dictionary:
        for value: Variant in stored_progress:
            var achievement_id := str(value)
            if not _definitions.has(achievement_id):
                continue
            var threshold := int((_definitions[achievement_id] as Dictionary).get("threshold", 1))
            _progress[achievement_id] = clampi(int(stored_progress[value]), 0, threshold)
    for value: Variant in data.get("unlocked", []):
        var achievement_id := str(value)
        if _definitions.has(achievement_id):
            _unlocked[achievement_id] = true
            _progress[achievement_id] = int((_definitions[achievement_id] as Dictionary).get("threshold", 1))
