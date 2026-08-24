class_name FredGoldenEggDiscoveryStore
extends RefCounted

const FORMAT_VERSION := 1
const MAX_BYTES := 32768

var path := "user://fred_golden_egg_discovery.json"
var temp_path := "user://fred_golden_egg_discovery.tmp.json"

func _init(store_path: String = "user://fred_golden_egg_discovery.json") -> void:
	path = store_path
	temp_path = store_path.trim_suffix(".json") + ".tmp.json"

func stage_pending(run_evidence: Dictionary, idempotency_key: String) -> Dictionary:
	if idempotency_key.is_empty() or str(run_evidence.get("game_id", "")) != FredGoldenEggRunState.GAME_ID or str(run_evidence.get("egg_id", "")) != FredGoldenEggRunState.EGG_ID:
		return {"ok": false, "error": "invalid_discovery"}
	var record := {
		"format": FORMAT_VERSION,
		"status": "pending",
		"idempotency_key": idempotency_key,
		"evidence": run_evidence.duplicate(true),
		"privacy": "anonymous",
	}
	return {"ok": _write(record), "record": record}

func accept_server_result(result: Dictionary) -> Dictionary:
	var current := load_record()
	if not bool(current.get("ok", false)):
		return {"ok": false, "error": "no_pending_discovery"}
	for required: String in ["discovery_id", "public_ref", "server_rank", "server_time", "secret_code"]:
		if not result.has(required):
			return {"ok": false, "error": "missing_server_field"}
	var record: Dictionary = current.record
	record["status"] = "accepted"
	record["server"] = result.duplicate(true)
	return {"ok": _write(record), "record": record}

func set_privacy(choice: String, display_name: String = "") -> Dictionary:
	if choice not in ["anonymous", "public"]:
		return {"ok": false, "error": "invalid_privacy"}
	var current := load_record()
	if not bool(current.get("ok", false)):
		return {"ok": false, "error": "missing_discovery"}
	var record: Dictionary = current.record
	record["privacy"] = choice
	record["display_name"] = display_name.left(24) if choice == "public" else ""
	return {"ok": _write(record), "record": record}

func load_record() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {"ok": false, "error": "invalid_size"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or parser.data is not Dictionary:
		return {"ok": false, "error": "malformed"}
	var record: Dictionary = parser.data
	if int(record.get("format", -1)) != FORMAT_VERSION or str(record.get("status", "")) not in ["pending", "accepted"]:
		return {"ok": false, "error": "incompatible"}
	return {"ok": true, "record": record}

func _write(record: Dictionary) -> bool:
	if not path.begins_with("user://"):
		return false
	var encoded := JSON.stringify(record)
	if encoded.to_utf8_buffer().size() > MAX_BYTES:
		return false
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encoded)
	file.flush()
	if file.get_error() != OK:
		return false
	file = null
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK
