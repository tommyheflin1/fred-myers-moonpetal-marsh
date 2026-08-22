extends SceneTree

const Customization = preload("res://scripts/frog_customization.gd")
const Rig = preload("res://scripts/fred_rig.gd")
const PROFILE_PATH := "user://customization_expansion_profile.json"
const BASE_CATALOG_COUNT := 15
const EXPANSION_COUNT := 20

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_clean()
	var total_catalog_count := 0
	var expansion_ids: Dictionary = {}
	var all_ids: Dictionary = {}
	var all_labels: Dictionary = {}
	for category: String in Customization.CATEGORIES:
		var entries: Array = Customization.CATALOG[category]
		var new_ids: Array = Customization.BUILD_2_EXPANSION_IDS[category]
		check(new_ids.size() == 5, "%s receives exactly five new Build 2 choices" % category)
		check(entries.size() >= new_ids.size() + 1, "%s keeps its starter and earlier choices" % category)
		total_catalog_count += entries.size()
		var category_values: Dictionary = {}
		var previous_cost := -1
		for entry: Dictionary in entries:
			var item_id := str(entry.id)
			var label := str(entry.label)
			var value_key := str(entry.value)
			check(not all_ids.has(item_id), "%s is globally unique" % item_id)
			all_ids[item_id] = true
			check(not all_labels.has(label), "%s is a unique player-facing name" % label)
			all_labels[label] = true
			check(not category_values.has(value_key), "%s has a unique visible value in %s" % [label, category])
			category_values[value_key] = true
			check(int(entry.cost) >= previous_cost, "%s unlock costs remain ordered for young players" % category)
			previous_cost = int(entry.cost)
		for item_id: String in new_ids:
			check(all_ids.has(item_id), "%s is present in the live catalog" % item_id)
			check(not expansion_ids.has(item_id), "%s appears once in the expansion" % item_id)
			expansion_ids[item_id] = true
	check(expansion_ids.size() == EXPANSION_COUNT, "Build 2 adds exactly twenty unique customizations")
	check(total_catalog_count == BASE_CATALOG_COUNT + EXPANSION_COUNT, "the catalog grows from fifteen to thirty-five choices")
	check(Customization.CATALOG.body.size() == 9 and Customization.CATALOG.tongue.size() == 9, "frog and tongue colors each expose nine choices")
	check(Customization.CATALOG["size"].size() == 8 and Customization.CATALOG.attire.size() == 9, "build and fitted gear expose eight and nine choices")
	check(Rig.ATTIRE_IDS.size() == 9, "all nine attire choices are accepted by the authored rig")
	check(Customization.BODY_PROPORTIONS.size() == Customization.CATALOG["size"].size(), "every body build owns an explicit silhouette proportion")
	var build_silhouettes: Dictionary = {}
	var build_probe := Customization.new("")
	for build_entry: Dictionary in Customization.CATALOG["size"]:
		build_probe.selected.size = str(build_entry.id)
		var build_style: Dictionary = build_probe.current_style()
		var proportions := Vector2(build_style.body_proportions)
		build_silhouettes["%.2f:%.2f" % [proportions.x, proportions.y]] = true
		check(absf(proportions.x - 1.0) >= 0.03 or absf(proportions.y - 1.0) >= 0.03 or str(build_entry.id) == "classic", "%s visibly changes Fred's width or height" % str(build_entry.label))
	check(build_silhouettes.size() == Customization.CATALOG["size"].size(), "all eight body builds have distinct silhouettes")
	for attire_id: String in Customization.BUILD_2_EXPANSION_IDS.attire:
		check(attire_id in Rig.ATTIRE_IDS, "%s is connected to Fred's runtime rig" % attire_id)
		check(Rig.ATTIRE_LABELS.has(attire_id) and Rig.ATTIRE_EYEWEAR.has(attire_id), "%s has named fitted eyewear metadata" % attire_id)
		check(Rig.ATTIRE_MATERIALS.has(attire_id) and Rig.ATTIRE_CUTS.has(attire_id), "%s has authored material and anatomical cut metadata" % attire_id)

	var profile := Customization.new(PROFILE_PATH)
	profile.earn_coins(Customization.MAX_COINS)
	var expected_spend := 0
	for category: String in Customization.CATEGORIES:
		var entries: Array = Customization.CATALOG[category]
		for index in range(1, entries.size()):
			expected_spend += int(entries[index].cost)
			var result: Dictionary = profile.select_next(category)
			check(bool(result.get("ok", false)), "%s unlocks in deterministic catalog order" % str(entries[index].label))
			check(str(result.get("item", "")) == str(entries[index].id), "%s equips the intended catalog ID" % str(entries[index].label))
		check(profile.selected_position(category) == entries.size(), "%s reaches its final new look" % category)
		check(profile.item_count(category) == entries.size(), "%s reports the complete choice count" % category)
		for item_id: String in Customization.BUILD_2_EXPANSION_IDS[category]:
			check(item_id in Array(profile.owned[category]), "%s remains owned after unlock" % item_id)
	check(profile.coins == Customization.MAX_COINS - expected_spend, "the offline coin wallet deducts each unlock exactly once")
	var style := profile.current_style()
	check(str(style.attire) == "lily_lifeguard", "the final gear choice equips through the typed style contract")
	check(float(style.size_scale) == 1.12, "the final athletic build remains presentation-only and bounded")
	check(str(style.body_build) == "strong" and Vector2(style.body_proportions).x >= 1.20, "Strong resolves to a visibly broad athletic silhouette")
	check(Color(style.body_color).to_html(false) == "d6e7cf", "the final frog color resolves to Pearl Hopper")
	check(Color(style.tongue_color).to_html(false) == "ffd34e", "the final tongue color resolves to Golden Zap")
	check(profile.next_cost("attire") == 0 and profile.next_label("attire") == "Runner Goggles", "a completed gear carousel wraps to the owned starter without another charge")
	check(profile.save_profile(), "the expanded profile saves through the existing local atomic path")
	var restored := Customization.new(PROFILE_PATH)
	check(restored.to_dictionary() == profile.to_dictionary(), "all twenty new ownership and selection values round-trip exactly")
	check(JSON.stringify(restored.to_dictionary()).to_utf8_buffer().size() < Customization.MAX_PROFILE_BYTES, "the complete expanded profile remains inside the bounded file budget")

	var legacy := Customization.new("")
	check(legacy.restore({
		"schema_version": 1,
		"coins": 77,
		"owned": {"body":["marsh_green","moonberry"],"size":["quick"],"tongue":["berry"],"attire":["marsh_runner","trail_scout"]},
		"selected": {"body":"moonberry","size":"quick","tongue":"berry","attire":"trail_scout"},
	}), "a pre-expansion schema-v1 profile still restores")
	check(legacy.selected_label("body") == "Moonberry" and legacy.selected_label("attire") == "Explorer Glasses", "legacy selections remain unchanged")
	check(legacy.to_dictionary().keys().size() == 4 and legacy.to_dictionary().has("schema_version"), "the expansion adds no save-v1 fields")
	var invalid := legacy.to_dictionary()
	invalid.owned.attire = ["marsh_runner", "floating_paper_hat"]
	invalid.selected.attire = "floating_paper_hat"
	check(legacy.restore(invalid) and legacy.selected.attire == "marsh_runner", "unknown gear still fails closed to the fitted starter")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("35 HERO LOOKS") and main_source.contains("20 NEW"), "the customizer clearly announces the expanded collection")
	check(main_source.contains("LOOK %d OF %d") and main_source.contains("swatch_center"), "every card shows position and a non-text visual swatch")

	_clean()
	print("RESULT customization_expansion_passed=%d customization_expansion_failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func _clean() -> void:
	for path: String in [PROFILE_PATH, PROFILE_PATH.trim_suffix(".json") + ".tmp.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
