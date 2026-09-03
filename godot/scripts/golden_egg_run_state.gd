class_name FredGoldenEggRunState
extends RefCounted

enum Phase { LOCKED, TONGUES, JUMPS, DIVES, ARMED, ROOM, REVEALED, INVALID }
const GAME_ID := "fred-myers"
const EGG_ID := "moonpetal-golden-egg"
const TARGET_LEVEL := 5
const ACTIVATION_ZONE := Rect2(55, 105, 245, 175)
const UP_DOT_MIN := 0.92
const REQUIRED_TONGUES := 3
const REQUIRED_JUMPS := 4
const REQUIRED_DIVE_CYCLES := 2
const FORMAT_VERSION := 2

var path := "user://fred_golden_egg_guard.json"
var run_id := ""
var phase := Phase.LOCKED
var highest_level := 0
var tongue_count := 0
var jump_count := 0
var dive_count := 0
var dive_open := false
var deathless := false
var foodless_level_five := true
var started_at_level_one := false
var invalid_reason := ""

func _init(guard_path: String = "user://fred_golden_egg_guard.json") -> void:
	path = guard_path

func begin_level_one(new_run_id: String = "local-run") -> void:
	run_id = new_run_id
	phase = Phase.LOCKED
	highest_level = 1
	tongue_count = 0
	jump_count = 0
	dive_count = 0
	dive_open = false
	deathless = true
	foodless_level_five = true
	started_at_level_one = true
	invalid_reason = ""

func advance_level(from_level: int, to_level: int) -> void:
	if not is_run_alive(): return
	if from_level != highest_level or to_level != from_level + 1:
		invalidate("non_sequential_level")
		return
	highest_level = to_level
	if to_level == TARGET_LEVEL: phase = Phase.TONGUES
	elif to_level > TARGET_LEVEL: invalidate("passed_target_level")

func observe_position(level: int, position: Vector2, facing: Vector2 = Vector2.UP) -> void:
	if level == TARGET_LEVEL and phase in [Phase.TONGUES, Phase.JUMPS, Phase.DIVES, Phase.ARMED]:
		if not ACTIVATION_ZONE.has_point(position) or facing.normalized().dot(Vector2.UP) < UP_DOT_MIN:
			reset_sequence("activation_alignment_lost")

func note_tongue_complete(level: int, position: Vector2, facing: Vector2) -> void:
	if not _ready(level, position, facing): return
	if phase != Phase.TONGUES:
		reset_sequence("wrong_order_tongue")
		return
	tongue_count += 1
	if tongue_count == REQUIRED_TONGUES: phase = Phase.JUMPS

func note_valid_surface_jump(level: int, position: Vector2 = Vector2.ZERO, facing: Vector2 = Vector2.UP) -> void:
	if not _ready(level, position, facing): return
	if phase != Phase.JUMPS:
		reset_sequence("wrong_order_jump")
		return
	jump_count += 1
	if jump_count == REQUIRED_JUMPS: phase = Phase.DIVES

func note_dive_started(level: int, position: Vector2, facing: Vector2) -> void:
	if not _ready(level, position, facing): return
	if phase != Phase.DIVES or dive_open:
		reset_sequence("wrong_order_dive")
		return
	dive_open = true

func note_surface_complete(level: int, position: Vector2 = Vector2.ZERO, facing: Vector2 = Vector2.UP) -> void:
	if not _ready(level, position, facing): return
	if phase != Phase.DIVES or not dive_open:
		reset_sequence("surface_without_dive")
		return
	dive_open = false
	dive_count += 1
	if dive_count == REQUIRED_DIVE_CYCLES: phase = Phase.ARMED

func try_upward_wall_boost(level: int, position: Vector2, facing: Vector2) -> bool:
	if not _ready(level, position, facing) or phase != Phase.ARMED: return false
	phase = Phase.ROOM
	return true

func touch_egg() -> bool:
	if phase != Phase.ROOM: return false
	phase = Phase.REVEALED
	return true

func note_food_collected(level: int) -> void:
	if level == TARGET_LEVEL:
		foodless_level_five = false
		invalidate("normal_food_collected")

func note_death(reason: String = "danger") -> void:
	deathless = false
	invalidate("death:" + reason)

func note_pause(level: int) -> void:
	if level == TARGET_LEVEL: reset_sequence("paused")

func note_level_restart(level: int) -> void:
	if level == TARGET_LEVEL: reset_sequence("level_restart")

func note_run_abandoned() -> void:
	if is_run_alive(): invalidate("run_abandoned")

func reset_sequence(reason: String) -> void:
	if highest_level != TARGET_LEVEL or not deathless or not foodless_level_five: return
	phase = Phase.TONGUES
	tongue_count = 0
	jump_count = 0
	dive_count = 0
	dive_open = false
	invalid_reason = reason

func invalidate(reason: String) -> void:
	if phase in [Phase.REVEALED, Phase.INVALID]: return
	phase = Phase.INVALID
	invalid_reason = reason.left(48)

func is_run_alive() -> bool:
	return started_at_level_one and deathless and phase not in [Phase.INVALID, Phase.REVEALED]

func eligible_for_reveal() -> bool:
	return phase in [Phase.ROOM, Phase.REVEALED] and deathless and foodless_level_five

func blocks_ordinary_level_completion(level: int) -> bool:
	return level == TARGET_LEVEL and phase in [Phase.JUMPS, Phase.DIVES, Phase.ARMED, Phase.ROOM]

func snapshot() -> Dictionary:
	return {"format":FORMAT_VERSION,"game_id":GAME_ID,"egg_id":EGG_ID,"phase":phase,"highest_level":highest_level,"tongues":tongue_count,"jumps":jump_count,"dives":dive_count,"deathless":deathless,"foodless":foodless_level_five}

func evidence() -> Dictionary:
	return {"game_id":GAME_ID,"egg_id":EGG_ID,"run_id":run_id,"level":TARGET_LEVEL,"deathless":deathless,"foodless":foodless_level_five,"tongue_count":tongue_count,"jump_count":jump_count,"dive_cycles":dive_count}

func _ready(level: int, position: Vector2, facing: Vector2) -> bool:
	if level != TARGET_LEVEL or not deathless or not foodless_level_five: return false
	if not ACTIVATION_ZONE.has_point(position) or facing.normalized().dot(Vector2.UP) < UP_DOT_MIN:
		reset_sequence("activation_alignment_lost")
		return false
	return true
