extends SceneTree
## Run with --main-pack <local unsigned PCK> --script <this absolute path>.
## Read-only packing check; this is not an iOS binary, signature or device test.

var files: PackedStringArray = []

func _init() -> void:
	_scan("res://")
	var forbidden: PackedStringArray = []
	var required_missing: PackedStringArray = []
	for path in files:
		for prefix in ["res://tests/", "res://tools/", "res://docs/", "res://builds/", "res://store/", "res://governance/", "res://.agents/", "res://assets/store/screenshots/"]:
			if path.begins_with(prefix):
				forbidden.append(path)
		# Imported images must not retain excluded screenshots behind remapped paths.
		if path.begins_with("res://.godot/imported/"):
			for capture in ["egg-reveal.png-", "name-review.png-", "level5-return.png-", "iphone69-", "ipad13-"]:
				if path.get_file().contains(capture):
					forbidden.append(path)
	for required in ["res://assets/security/update-policy-public.pub", "res://game/game.json"]:
		if not FileAccess.file_exists(required):
			required_missing.append(required)
	for required in ["res://scripts/golden_egg_art.gd", "res://scripts/main.gd", "res://scripts/fred_update_gate.gd"]:
		if not ResourceLoader.exists(required):
			required_missing.append(required)
	var art: Script = load("res://scripts/golden_egg_art.gd")
	var art_loadable := art != null and art.can_instantiate()
	var okay := forbidden.is_empty() and required_missing.is_empty() and art_loadable
	print(JSON.stringify({"status": "PASS" if okay else "FAIL", "scope": "unsigned_resource_pack_only", "files": files.size(), "forbidden_paths": forbidden, "required_missing": required_missing, "frog_art_loadable": art_loadable}))
	quit(0 if okay else 1)

func _scan(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.include_hidden = true
	for file in directory.get_files():
		files.append(path.path_join(file))
	for subdirectory in directory.get_directories():
		_scan(path.path_join(subdirectory))
