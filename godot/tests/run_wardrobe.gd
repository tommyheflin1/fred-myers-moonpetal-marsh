extends SceneTree

const Profile = preload("res://scripts/frog_customization.gd")
const Main = preload("res://scripts/main.gd")
const Layout = preload("res://scripts/wardrobe_layout.gd")
const Hero = preload("res://scripts/hero_frog_art.gd")
const RigScene = preload("res://scenes/fred_rig.tscn")
const Coordinator = preload("res://scripts/fred_animation_coordinator.gd")
class FailingProfile extends "res://scripts/frog_customization.gd":
	func save_profile() -> bool:
		return false

var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("FAIL "+label)

func _init() -> void:
	_run.call_deferred()

func _check_preview_fit(rig: Node2D) -> void:
	var points := PackedVector2Array()
	for path: String in rig.POLYGON_ORDER:
		var node := rig.get_node(path) as Polygon2D
		points.append_array(rig._transformed_points(node,node.polygon,Vector2.ZERO))
	for path: String in rig.LINE_ORDER:
		var node := rig.get_node(path) as Line2D
		points.append_array(rig._transformed_points(node,node.points,Vector2.ZERO))
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point: Vector2 in points: bounds = bounds.expand(point)
	bounds = bounds.grow(3.0)
	var preview := Rect2(Layout.PREVIEW_ORIGIN+bounds.position*Layout.PREVIEW_SCALE,bounds.size*Layout.PREVIEW_SCALE)
	check(Layout.PREVIEW_RECT.encloses(preview),"all hero/build/outfit previews fit between the cards and footer: %s" % preview)

func _tap(position: Vector2, mouse: bool = false) -> void:
	for pressed: bool in [true,false]:
		var event: InputEvent
		if mouse:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = position
			click.pressed = pressed
			event = click
		else:
			var touch := InputEventScreenTouch.new()
			touch.index = 3
			touch.position = position
			touch.pressed = pressed
			event = touch
		Input.parse_input_event(event.xformed_by(root.get_final_transform()))
		Input.flush_buffered_events()

func _run() -> void:
	var profile := Profile.new("")
	check(profile.owned.hero.size() == 3 and profile.coins == 0,"all three hero styles are free without changing starting coins")
	var legacy := {"schema_version":1,"coins":0,"owned":{"body":["marsh_green","moonberry"],"attire":["marsh_runner","trail_scout","lily_lifeguard"]},"selected":{"body":"moonberry","attire":"trail_scout"}}
	check(profile.restore(legacy),"legacy save v1 restores without migration loss")
	check(profile.selected.hero == "classic_fred" and profile.selected.attire == "trail_scout" and profile.selected.body == "moonberry","legacy selections and default appearance are preserved")
	check(profile.equip("attire","marsh_runner").ok and profile.equip("attire","lily_lifeguard").ok and profile.coins == 0,"earlier and later purchases are selectable with zero coins")
	var before := profile.to_dictionary()
	check(not profile.equip("attire","storm_striker").ok,"equip alone cannot unlock unowned gear")
	check(not profile.purchase_and_equip("attire","storm_striker").ok and profile.to_dictionary() == before,"insufficient coins change neither ownership nor selection")
	for pair: Array in [["bad","bad"],["attire","bad"],["body","storm_striker"]]:
		check(not profile.purchase_and_equip(pair[0],pair[1]).ok and profile.to_dictionary() == before,"invalid item cannot spend coins")
	for category: String in Profile.CATEGORIES:
		for item: Dictionary in Profile.CATALOG[category]:
			var preview: Dictionary = profile.preview_style(category,str(item.id))
			check(not preview.is_empty() and profile.to_dictionary() == before,"preview never buys, equips or writes")
	profile.earn_coins(600)
	check(profile.purchase_and_equip("attire","storm_striker").ok and profile.coins == 80,"explicit purchase charges the exact catalog cost")
	for repeat in 10:
		check(profile.purchase_and_equip("attire","storm_striker").ok and profile.coins == 80,"repeated equip never charges again")
	var bad_disk := FailingProfile.new("")
	bad_disk.coins = 600
	var untouched := bad_disk.to_dictionary()
	check(bad_disk.purchase_and_equip("attire","storm_striker").reason == "save_failed" and bad_disk.to_dictionary() == untouched,"failed persistence rolls back the wallet and item selection")
	var stored := Profile.new("user://wardrobe_roundtrip.json")
	stored.restore(profile.to_dictionary())
	check(stored.save_profile(),"wardrobe persists in isolated user data")
	var reopened := Profile.new("user://wardrobe_roundtrip.json")
	check(reopened.to_dictionary() == stored.to_dictionary(),"purchases and equipped item survive restart exactly")
	check(reopened.equip("attire","trail_scout").ok and reopened.coins == 80,"old purchased gear remains usable after restart")
	check(Layout.pages(13) == 3 and Layout.pages(0) == 1,"pagination is bounded including an empty filter")
	check(Rect2(0,0,1280,720).encloses(Layout.COINS) and not Layout.COINS.intersects(Layout.FILTER),"coin counter stays inside phone/tablet canvas above the filter")
	check(ThemeDB.fallback_font.get_string_size("999999 COINS",HORIZONTAL_ALIGNMENT_LEFT,-1,24).x <= Layout.COINS.size.x,"maximum coin balance fits without clipping")
	var zones: Array[Rect2] = [Layout.HOME,Layout.APPLY,Layout.FILTER,Layout.PREVIOUS,Layout.NEXT]
	for tab: Rect2 in Layout.TABS.values(): zones.append(tab)
	for slot in Layout.PAGE_SIZE: zones.append(Layout.card(slot))
	for a in zones.size():
		check(Rect2(0,0,1280,720).encloses(zones[a]) and zones[a].size.y >= 46,"touch target is inside the logical phone canvas")
		check(not Layout.PREVIEW_RECT.intersects(zones[a]),"preview never overlaps a touch target")
		for b in range(a+1,zones.size()): check(not zones[a].intersects(zones[b]),"wardrobe controls do not overlap")
	var rig: Node2D = RigScene.instantiate()
	root.add_child(rig)
	await process_frame
	var coordinator := Coordinator.new()
	var shapes := {}
	for hero_id: String in Hero.HERO_STYLES:
		profile.selected.hero = hero_id
		shapes[var_to_bytes(Hero.build("classic",hero_id)).hex_encode()] = true
		for body: Dictionary in Profile.CATALOG["size"]:
			profile.selected.size = body.id
			for outfit: Dictionary in Profile.CATALOG.attire:
				profile.selected.attire = outfit.id
				check(rig.apply_style(profile.current_style()),"every style/build/outfit combination is accepted")
				for state: int in Coordinator.State.values():
					coordinator.state = state
					for facing: float in [-1.0,1.0]:
						coordinator.facing = facing
						coordinator._pose = coordinator._build_pose()
						check(rig.apply_pose(coordinator.pose(),1.0 if state % 2 else 0.0),"hero supports every pose and facing above/below water")
						check(float(rig.attire_snapshot().mouth_clearance_pixels) >= 4.0,"all hero styles keep mouths clear of clothing")
						if state in [Coordinator.State.RESET,Coordinator.State.IDLE]: _check_preview_fit(rig)
	check(shapes.size() == 3,"classic, girl and boy have genuinely different anatomical profiles")
	var invalid_style := profile.current_style()
	invalid_style.hero_style = "unknown"
	check(not rig.apply_style(invalid_style),"unknown hero style fails closed")
	rig.queue_free()
	await process_frame
	var game: Node2D = Main.new()
	game.audio_enabled = false
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.saver = FredSaveAdapter.new("user://wardrobe_scene")
	game.leaderboard = FredLocalLeaderboard.new("user://wardrobe_scene_board.json")
	game.customization = Profile.new("")
	game.customization.restore(legacy)
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for mouse: bool in [false,true]:
		game.customization.restore(legacy)
		game.wardrobe_category = "hero"
		game.screen = game.Screen.TITLE
		_tap(Main.TITLE_CUSTOMIZE_RECT.get_center(),mouse)
		check(game.screen == game.Screen.CUSTOMIZE,"engine-dispatched touch/pointer opens wardrobe")
		_tap(Layout.TABS.attire.get_center(),mouse)
		var snapshot: Dictionary = game.customization.to_dictionary()
		_tap(Layout.card(0).get_center(),mouse)
		check(game.wardrobe_item == "marsh_runner" and game.customization.to_dictionary() == snapshot,"touch/pointer preview does not equip or spend")
		_tap(Layout.APPLY.get_center(),mouse)
		check(game.customization.selected.attire == "marsh_runner" and game.customization.coins == 0,"touch/pointer re-equips an earlier purchase at zero cost")
		_tap(Layout.NEXT.get_center(),mouse)
		_tap(Layout.card(2).get_center(),mouse)
		_tap(Layout.APPLY.get_center(),mouse)
		check(game.customization.selected.attire == "lily_lifeguard","owned gear remains accessible beyond locked items")
		_tap(Layout.NEXT.get_center(),mouse)
		_tap(Layout.card(0).get_center(),mouse)
		_tap(Layout.APPLY.get_center(),mouse)
		check(game.customization.selected.attire == "lily_lifeguard" and game.customization.coins == 0,"unaffordable preview cannot replace equipped gear")
		_tap(Layout.FILTER.get_center(),mouse)
		check(game.wardrobe_owned_only and Layout.entries(game.customization,"attire",true).size() == 3,"owned-only filter includes every earlier purchase")
		_tap(Layout.TABS.hero.get_center(),mouse)
		_tap(Layout.card(1).get_center(),mouse)
		_tap(Layout.APPLY.get_center(),mouse)
		check(game.customization.selected.hero == "girl_hero" and game.customization.selected.attire == "lily_lifeguard","hero selection does not change purchased outfit")
		_tap(Layout.HOME.get_center(),mouse)
		check(game.screen == game.Screen.TITLE,"return home remains reachable")
		game.wardrobe_owned_only = false
	# Explicit purchase through actual scene input, followed by reopening the wardrobe.
	game.screen = game.Screen.CUSTOMIZE
	game.customization = Profile.new("")
	game.customization.earn_coins(600)
	game.wardrobe_category = "attire"
	game._reset_wardrobe_selection()
	_tap(Layout.NEXT.get_center())
	_tap(Layout.NEXT.get_center())
	_tap(Layout.card(0).get_center())
	check(game.customization.coins == 600 and game.customization.selected.attire == "marsh_runner","previewing a locked outfit leaves wallet and equipment unchanged")
	_tap(Layout.APPLY.get_center())
	_tap(Layout.APPLY.get_center())
	check(game.customization.coins == 80 and game.customization.selected.attire == "storm_striker","double-tapping purchase buys once and equips once")
	_tap(Layout.HOME.get_center())
	_tap(Main.TITLE_CUSTOMIZE_RECT.get_center())
	check(game.wardrobe_item == "storm_striker" and game.wardrobe_page == 2,"reopened wardrobe locates the equipped item on the correct page")
	_tap(Layout.TABS.hero.get_center())
	_tap(Layout.card(1).get_center())
	_tap(Layout.HOME.get_center())
	check(game.customization.selected.hero == "classic_fred" and game.fred_rig.style_snapshot().hero_style == "classic_fred","leaving an unconfirmed preview retains the equipped hero")
	game.queue_free()
	await process_frame
	print("RESULT wardrobe_passed=%d wardrobe_failed=%d" % [passed,failed])
	quit(1 if failed else 0)
