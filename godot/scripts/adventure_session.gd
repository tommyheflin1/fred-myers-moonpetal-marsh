class_name AdventureSession
extends RefCounted

const GAME_ID := "fred-myers-moonpetal-marsh"
const SCHEMA_VERSION := 1
const CAMPAIGN_VERSION := "1"
const CORE_VERSION := "0.5.1"
const LEVEL_ID := "lily_leap"
const OBJECTIVE_REACH := "lily_leap_reach_exit"
const OBJECTIVE_BUGS := "lily_leap_collect_bugs"
const CHECKPOINTS := ["lily_leap_start", "lily_leap_midpoint", "lily_leap_complete"]

var rng := RandomNumberGenerator.new()
var current_campaign := CAMPAIGN_VERSION
var current_level := LEVEL_ID
var active_objective := OBJECTIVE_BUGS
var completed_objectives: Array[String] = []
var completed_levels: Array[String] = []
var current_checkpoint := CHECKPOINTS[0]
var checkpoint_sequence := 0
var player_state := "surface"
var bug_count := 0
var boost_energy := 100
var health := 5
var paused := false
var completed := false
var retrying := false

func _init(seed: int = 1337) -> void:
    rng.seed = seed

func collect_bug() -> void:
    if completed or paused: return
    bug_count += 1
    if bug_count >= 3 and OBJECTIVE_BUGS not in completed_objectives:
        completed_objectives.append(OBJECTIVE_BUGS)
        active_objective = OBJECTIVE_REACH

func use_boost(amount: int = 20) -> bool:
    if boost_energy < amount or paused or completed: return false
    boost_energy -= amount
    return true

func recharge_boost(amount: int = 10) -> void:
    boost_energy = mini(100, boost_energy + maxi(0, amount))

func set_underwater(value: bool) -> void:
    player_state = "underwater" if value else "surface"

func damage(amount: int = 1, hidden: bool = false) -> bool:
    if hidden or paused or completed: return false
    health = maxi(0, health - amount)
    return health == 0

func gain_life(amount: int = 1) -> bool:
    if health >= 5 or amount <= 0 or completed: return false
    health = mini(5, health + amount)
    return true

func reach_checkpoint(checkpoint_id: String, sequence: int) -> bool:
    if checkpoint_id not in CHECKPOINTS or sequence <= checkpoint_sequence: return false
    checkpoint_sequence = sequence
    current_checkpoint = checkpoint_id
    return true

func complete_level() -> bool:
    if bug_count < 3: return false
    if OBJECTIVE_REACH not in completed_objectives: completed_objectives.append(OBJECTIVE_REACH)
    if LEVEL_ID not in completed_levels: completed_levels.append(LEVEL_ID)
    completed = true
    reach_checkpoint(CHECKPOINTS[2], maxi(2, checkpoint_sequence + 1))
    return true

func retry_from_checkpoint() -> void:
    health = 5
    paused = false
    completed = false
    retrying = true
    player_state = "surface"

func to_save(updated_timestamp: String = "2000-01-01T00:00:00Z") -> Dictionary:
    return {
        "game_id": GAME_ID, "schema_version": SCHEMA_VERSION,
        "campaign_version": current_campaign, "core_version": CORE_VERSION,
        "current_level_id": current_level, "completed_level_ids": completed_levels.duplicate(),
        "current_objective_id": active_objective, "completed_objective_ids": completed_objectives.duplicate(),
        "bugs_collected": bug_count, "boost_state": {"energy": boost_energy},
        "player_state": {"mode": player_state, "health": health},
        "checkpoint_id": current_checkpoint, "checkpoint_sequence": checkpoint_sequence,
        "updated_timestamp": updated_timestamp
    }

func restore(data: Dictionary) -> Dictionary:
    if typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT]: return {"ok":false, "error":"malformed"}
    if int(data.get("schema_version", -1)) != SCHEMA_VERSION: return {"ok":false, "error":"unsupported_schema"}
    if str(data.get("core_version", "")) != CORE_VERSION: return {"ok":false, "error":"core_incompatible"}
    if str(data.get("game_id", "")) != GAME_ID: return {"ok":false, "error":"invalid_game"}
    if str(data.get("current_level_id", "")) != LEVEL_ID: return {"ok":false, "error":"invalid_level"}
    var checkpoint := str(data.get("checkpoint_id", ""))
    var sequence := int(data.get("checkpoint_sequence", -1))
    if checkpoint not in CHECKPOINTS or sequence < checkpoint_sequence: return {"ok":false, "error":"stale_checkpoint"}
    current_campaign = str(data.get("campaign_version", CAMPAIGN_VERSION))
    current_checkpoint = checkpoint
    checkpoint_sequence = sequence
    bug_count = clampi(int(data.get("bugs_collected", 0)), 0, 999)
    var boost: Dictionary = data.get("boost_state", {}) if data.get("boost_state", {}) is Dictionary else {}
    boost_energy = clampi(int(boost.get("energy", 100)), 0, 100)
    var player: Dictionary = data.get("player_state", {}) if data.get("player_state", {}) is Dictionary else {}
    player_state = str(player.get("mode", "surface")) if str(player.get("mode", "surface")) in ["surface", "underwater"] else "surface"
    health = clampi(int(player.get("health", 5)), 1, 5)
    completed_levels = _strings(data.get("completed_level_ids", []), [LEVEL_ID])
    completed_objectives = _strings(data.get("completed_objective_ids", []), [OBJECTIVE_BUGS, OBJECTIVE_REACH])
    active_objective = str(data.get("current_objective_id", OBJECTIVE_BUGS))
    if active_objective not in [OBJECTIVE_BUGS, OBJECTIVE_REACH]: active_objective = OBJECTIVE_BUGS
    completed = LEVEL_ID in completed_levels
    return {"ok":true}

func _strings(value: Variant, allowed: Array[String]) -> Array[String]:
    var result: Array[String] = []
    if value is Array:
        for item: Variant in value:
            var text := str(item)
            if text in allowed and text not in result: result.append(text)
    return result
