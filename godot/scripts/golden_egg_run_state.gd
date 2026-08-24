class_name FredGoldenEggRunState
extends RefCounted

enum Phase { LOCKED, CORNERS, WAIT_SURFACE, JUMPS, ARMED, REVEALED, INVALID }

const GAME_ID := "fred-myers"
const EGG_ID := "moonpetal-golden-egg"
const TARGET_LEVEL := 10
const REQUIRED_JUMPS := 4
const FORMAT_VERSION := 1
const CORNER_RECTS: Array[Rect2] = [
	Rect2(55, 105, 150, 125),
	Rect2(1075, 105, 150, 125),
	Rect2(1075, 540, 150, 125),
	Rect2(55, 540, 150, 125),
]

var path := "user://fred_golden_egg_guard.json"
var temp_path := "user://fred_golden_egg_guard.tmp.json"
var run_id := ""
var phase := Phase.LOCKED
var highest_level := 0
var next_corner := 0
var surface_jumps := 0
var deathless := false
var started_at_level_one := false
var invalid_reason := ""
var _inside_corner := -1

func _init(guard_path: String = "user://fred_golden_egg_guard.json") -> void:
	path = guard_path
	temp_path = guard_path.trim_suffix(".json") + ".tmp.json"
	_load()

func begin_level_one(new_run_id: String = "") -> void:
	run_id = new_run_id if not new_run_id.is_empty() else _new_run_id()
	phase = Phase.LOCKED
	highest_level = 1
	next_corner = 0
	surface_jumps = 0
	deathless = true
	started_at_level_one = true
	invalid_reason = ""
	_inside_corner = -1
	_persist()

func advance_level(from_level: int, to_level: int) -> void:
	if not is_run_alive():
		return
	if from_level != highest_level or to_level != from_level + 1:
		invalidate("non_sequential_level")
		return
	highest_level = to_level
	if to_level == TARGET_LEVEL:
		phase = Phase.CORNERS
	elif to_level > TARGET_LEVEL:
		invalidate("passed_target_level")
		return
	_persist()

func note_death(reason: String = "danger") -> void:
	if phase == Phase.REVEALED:
		return
	deathless = false
	invalidate("death:" + _safe_reason(reason))

func note_run_abandoned() -> void:
	if is_run_alive():
		invalidate("run_abandoned")

func observe_position(level: int, position: Vector2, underwater: bool) -> void:
	if level != TARGET_LEVEL or phase != Phase.CORNERS or not underwater:
		_inside_corner = -1
		return
	var corner := _corner_at(position)
	if corner < 0:
		_inside_corner = -1
		return
	if corner == _inside_corner:
		return
	_inside_corner = corner
	if corner != next_corner:
		invalidate("wrong_corner_order")
		return
	next_corner += 1
	if next_corner == CORNER_RECTS.size():
		phase = Phase.WAIT_SURFACE
	_persist()

func note_surface_complete(level: int) -> void:
	if level == TARGET_LEVEL and phase == Phase.WAIT_SURFACE:
		phase = Phase.JUMPS
		_persist()
	elif level == TARGET_LEVEL and phase == Phase.CORNERS and next_corner > 0:
		invalidate("surface_before_corners_complete")

func note_valid_surface_jump(level: int) -> void:
	if level != TARGET_LEVEL:
		return
	if phase in [Phase.CORNERS, Phase.WAIT_SURFACE]:
		invalidate("jump_before_surface_sequence")
		return
	if phase == Phase.ARMED:
		invalidate("extra_surface_jump")
		return
	if phase != Phase.JUMPS:
		return
	surface_jumps += 1
	phase = Phase.ARMED if surface_jumps == REQUIRED_JUMPS else Phase.JUMPS
	_persist()

func note_dive_after_surface(level: int) -> void:
	if level == TARGET_LEVEL and phase in [Phase.JUMPS, Phase.ARMED]:
		invalidate("dive_after_surface_sequence")

func try_predator_event(level: int) -> bool:
	if level != TARGET_LEVEL or phase != Phase.ARMED or not eligible_for_reveal():
		return false
	phase = Phase.REVEALED
	_persist()
	return true

func invalidate(reason: String) -> void:
	if phase in [Phase.INVALID, Phase.REVEALED]:
		return
	phase = Phase.INVALID
	invalid_reason = _safe_reason(reason)
	_persist()

func is_run_alive() -> bool:
	return started_at_level_one and deathless and phase not in [Phase.INVALID, Phase.REVEALED]

func eligible_for_reveal() -> bool:
	return started_at_level_one and deathless and highest_level == TARGET_LEVEL and next_corner == CORNER_RECTS.size() and surface_jumps == REQUIRED_JUMPS

func snapshot() -> Dictionary:
	return {
		"format": FORMAT_VERSION,
		"game_id": GAME_ID,
		"egg_id": EGG_ID,
		"run_id": run_id,
		"phase": phase,
		"highest_level": highest_level,
		"next_corner": next_corner,
		"surface_jumps": surface_jumps,
		"deathless": deathless,
		"started_at_level_one": started_at_level_one,
		"invalid_reason": invalid_reason,
	}

func evidence() -> Dictionary:
	return {
		"game_id": GAME_ID,
		"egg_id": EGG_ID,
		"run_id": run_id,
		"level": TARGET_LEVEL,
		"deathless": deathless,
		"sequential_level": highest_level,
		"corner_count": next_corner,
		"surface_jump_count": surface_jumps,
	}

func _corner_at(position: Vector2) -> int:
	for index in CORNER_RECTS.size():
		if CORNER_RECTS[index].has_point(position):
			return index
	return -1

func _persist() -> bool:
	if not path.begins_with("user://"):
		return false
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	if file.get_error() != OK:
		return false
	file = null
	if FileAccess.file_exists(path):
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK

func _load() -> void:
	if not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or parser.data is not Dictionary:
		phase = Phase.INVALID
		invalid_reason = "guard_corrupt"
		return
	var data: Dictionary = parser.data
	if int(data.get("format", -1)) != FORMAT_VERSION or str(data.get("game_id", "")) != GAME_ID or str(data.get("egg_id", "")) != EGG_ID:
		phase = Phase.INVALID
		invalid_reason = "guard_incompatible"
		return
	run_id = str(data.get("run_id", ""))
	phase = clampi(int(data.get("phase", Phase.INVALID)), Phase.LOCKED, Phase.INVALID)
	highest_level = clampi(int(data.get("highest_level", 0)), 0, TARGET_LEVEL)
	next_corner = clampi(int(data.get("next_corner", 0)), 0, CORNER_RECTS.size())
	surface_jumps = clampi(int(data.get("surface_jumps", 0)), 0, REQUIRED_JUMPS + 1)
	deathless = bool(data.get("deathless", false))
	started_at_level_one = bool(data.get("started_at_level_one", false))
	invalid_reason = str(data.get("invalid_reason", ""))
	if run_id.is_empty() or (phase == Phase.REVEALED and not eligible_for_reveal()):
		phase = Phase.INVALID
		invalid_reason = "guard_invalid"

func _new_run_id() -> String:
	return "%s-%s" % [str(Time.get_unix_time_from_system()).replace(".", ""), Crypto.new().generate_random_bytes(16).hex_encode()]

func _safe_reason(value: String) -> String:
	var cleaned := value.to_lower().replace(" ", "_")
	return cleaned.left(48)
