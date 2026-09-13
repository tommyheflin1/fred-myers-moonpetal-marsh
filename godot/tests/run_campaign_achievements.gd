extends SceneTree

const Catalog = preload("res://scripts/fred_campaign_achievements.gd")
const Adapter = preload("res://scripts/game_center_adapter.gd")
const ExistingTest = preload("res://tests/run_game_center_adapter.gd")
var checks := 0
var failures := 0

class FakeAwards:
	extends ExistingTest.FakeGameCenter
	var awards: Array[Dictionary] = []
	var award_error := OK
	func award_achievement(payload: Dictionary) -> int:
		awards.append(payload.duplicate(true))
		return award_error

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var definitions := Catalog.definitions()
	check(definitions.size() == 25, "25 app-owned campaign achievements")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/game.json"))
	var store_package: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://store/game_center.json"))
	check(bool(config.get("capabilities", {}).get("achievements", false)), "registered campaign achievement capability enabled in candidate")
	var store_definitions: Array = store_package.get("achievements", [])
	check(store_definitions.size() == definitions.size(), "store and runtime catalog sizes match")
	var image_hashes: Dictionary = {}
	for index in mini(store_definitions.size(), definitions.size()):
		var store_record: Dictionary = store_definitions[index]
		var runtime_record: Dictionary = definitions[index]
		check(store_record.get("id") == runtime_record.id, "store ID matches exact runtime milestone")
		check(store_record.get("title") == runtime_record.name and store_record.get("reference_name") == runtime_record.name, "store names match runtime")
		for field: String in ["points", "hidden", "repeatable", "earned_description", "unearned_description"]:
			check(store_record.get(field) == runtime_record[field], "store behavior and localized text match runtime: " + field)
		var image_path := "res://" + str(store_record.get("image", ""))
		var digest := FileAccess.get_sha256(image_path)
		check(not digest.is_empty() and digest == store_record.get("sha256"), "achievement image matches recorded SHA-256")
		check(not image_hashes.has(digest), "each achievement has distinct artwork")
		image_hashes[digest] = true
	var seen: Dictionary = {}
	var total_points := 0
	for definition: Dictionary in definitions:
		check(not seen.has(definition.id), "unique permanent registered ID")
		seen[definition.id] = true
		total_points += int(definition.points)
		check(not definition.hidden and not definition.repeatable, "ordinary campaign milestone, not secret reveal")
	check(total_points == 1000, "points stay within app allowance")
	for level in range(101):
		check(Catalog.earned_ids(level).size() == level / 4, "only completed four-level milestones qualify")
	check(Catalog.earned_ids(-4).is_empty(), "invalid negative completion cannot award")
	check(Catalog.completed_level_from_records([{}, {"level": 100, "score": 0}, {"level": 101, "score": 999999}]) == 0, "malformed saved records cannot invent milestones")
	check(Catalog.completed_level_from_records([{"level": 12, "score": 12000}, {"level": 4, "score": 4200}]) == 12, "existing saved completion records support replay without new save format")
	var plugin := FakeAwards.new()
	plugin.authenticated = true
	var adapter := Adapter.new()
	root.add_child(adapter)
	adapter.configure(plugin)
	adapter.set_process(false)
	adapter.state = "authenticated"
	adapter.queue_campaign_achievements(100)
	check(adapter.pending_achievements.is_empty(), "unconfigured adapter defaults safely off")
	adapter.achievements_enabled = true
	adapter.queue_campaign_achievements(100)
	adapter.queue_campaign_achievements(100)
	check(adapter.pending_achievements.size() == 25, "duplicate enqueue is bounded")
	adapter._dispatch_campaign_achievement(0.2)
	check(plugin.awards.size() == 1, "one native dispatch per frame")
	adapter._dispatch_campaign_achievement(0.01)
	check(plugin.awards.size() == 1, "native dispatch pacing preserves UI time")
	for index in 24:
		adapter._dispatch_campaign_achievement(0.2)
	check(plugin.awards.size() == 25 and adapter.pending_achievements.is_empty(), "all eligible milestones dispatched")
	check(plugin.awards[0].progress == 100.0 and not plugin.awards[0].show_completion_banner, "replay does not flood banners")
	adapter.queue_campaign_achievements(100)
	adapter._dispatch_campaign_achievement(0.2)
	check(plugin.awards.size() == 25 and adapter.pending_achievements.is_empty(), "later level completions do not resend every started achievement")
	adapter.configure(plugin)
	adapter.set_process(false)
	adapter.state = "authenticated"
	plugin.award_error = FAILED
	adapter.queue_campaign_achievements(4)
	for index in 10:
		adapter.queue_campaign_achievements(4)
		adapter._dispatch_campaign_achievement(0.2)
	check(plugin.awards.size() == 28, "repeated enqueue cannot reset the three-attempt failure limit")
	adapter.queue_campaign_achievements(8)
	adapter.begin_sign_in()
	check(adapter.pending_achievements.is_empty(), "re-authentication clears prior account's transient queue")
	adapter.queue_campaign_achievements(100)
	check(adapter.pending_achievements.is_empty(), "provider authentication alone cannot enqueue during identity refresh")
	plugin.award_error = OK
	adapter.state = "authenticated"
	adapter.queue_campaign_achievements(4)
	adapter._dispatch_campaign_achievement(0.2)
	check(plugin.awards.size() == 29, "fresh login permits replay without assuming earlier server confirmation")
	adapter.queue_free()
	await process_frame
	print("CAMPAIGN_ACHIEVEMENTS checks=", checks, " failures=", failures, " native_device_verified=false")
	quit(1 if failures else 0)
