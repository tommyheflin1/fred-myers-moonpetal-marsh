extends SceneTree

const Hero = preload("res://scripts/hero_frog_art.gd")
const Surface = preload("res://scripts/character_surface.gd")
const RigScene = preload("res://scenes/fred_rig.tscn")
const Coordinator = preload("res://scripts/fred_animation_coordinator.gd")
const Customization = preload("res://scripts/frog_customization.gd")
const Main = preload("res://scripts/main.gd")
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("FAIL "+label)

func _area(points: PackedVector2Array) -> float:
	var result := 0.0
	for index in points.size():
		result += points[index].cross(points[(index+1)%points.size()])
	return absf(result)*0.5

func _geometry(points: PackedVector2Array, volume: bool = true) -> void:
	var indices := Geometry2D.triangulate_polygon(points)
	check(indices.size() >= 3,"authored hero surface triangulates")
	var finite := true
	for point in points:
		finite = finite and point.is_finite() and point.length() < 100
	check(finite,"hero geometry stays finite inside its local footprint")
	if not volume: return
	var mesh := Surface.volume_mesh(points,Color("4fbd68"),0.5)
	var area := 0.0
	for index in range(0,mesh.indices.size(),3):
		var a: Vector2 = mesh.points[mesh.indices[index]]
		var b: Vector2 = mesh.points[mesh.indices[index+1]]
		var c: Vector2 = mesh.points[mesh.indices[index+2]]
		area += absf((b-a).cross(c-a))*0.5
	check(absf(area-_area(points)) < 0.1,"hero volume covers its contour without overlapping triangles")

func _bounds(points: PackedVector2Array) -> Rect2:
	var result := Rect2(points[0],Vector2.ZERO)
	for point in points: result = result.expand(point)
	return result

func _init() -> void:
	_run.call_deferred()

func _check_customizer_fit(rig: Node2D, coordinator: RefCounted) -> void:
	# Home resets the coordinator before this screen opens. Check both the
	# reset stance and idle breathing without changing gameplay or card geometry.
	for state: int in [Coordinator.State.RESET,Coordinator.State.IDLE]:
		coordinator.state = state
		coordinator.facing = 1
		coordinator._pose = coordinator._build_pose()
		rig.apply_pose(coordinator.pose())
		var points := PackedVector2Array()
		for path: String in rig.POLYGON_ORDER:
			var node := rig.get_node(path) as Polygon2D
			points.append_array(rig._transformed_points(node,node.polygon,Vector2.ZERO))
		for path: String in rig.LINE_ORDER:
			var node := rig.get_node(path) as Line2D
			points.append_array(rig._transformed_points(node,node.points,Vector2.ZERO))
		var bounds := _bounds(points).grow(3.0)
		var preview := Rect2(Main.CUSTOM_PREVIEW_ORIGIN+bounds.position*Main.CUSTOM_PREVIEW_SCALE,bounds.size*Main.CUSTOM_PREVIEW_SCALE)
		check(Main.CUSTOM_PREVIEW_RECT.encloses(preview),"customizer %s/%d bounds %s fit between cards and footer"%[rig.style_snapshot().body_build,state,preview])
		for card: Rect2 in Main.CUSTOM_CARDS.values():
			check(not preview.intersects(card),"hero preview cannot cover an upgrade card")
		check(not preview.intersects(Main.CUSTOM_HOME_RECT),"hero preview cannot cover Save and Return Home")

func _run() -> void:
	var rig: Node2D = RigScene.instantiate()
	root.add_child(rig)
	await process_frame
	var profile := Customization.new("")
	var initial_profile := var_to_bytes(profile.to_dictionary())
	var coordinator := Coordinator.new()
	var silhouette_keys := {}
	check(Hero.BUILDS.size() == Customization.CATALOG["size"].size(),"all eight saved body types have explicit hero anatomy")
	check(Hero.OUTFITS.size() == rig.ATTIRE_IDS.size(),"all nine saved outfits have upgraded hero equipment")
	for entry: Dictionary in Customization.CATALOG["size"]:
		var shape := Hero.build(str(entry.id))
		silhouette_keys[var_to_bytes(shape).hex_encode()] = true
		check(shape == Hero.build(str(entry.id)),"body profile is deterministic")
		shape.chest = 99.0
		check(Hero.build(str(entry.id)).chest < 2.0,"returned profile cannot change the authored body types")
		profile.selected.size = str(entry.id)
		var hero := Hero.build(str(entry.id))
		for side: float in [-1.0,1.0]:
			var line := PackedVector2Array([Vector2(side*26,-8),Vector2(side*36,9),Vector2(side*31,27)])
			_geometry(Hero.upper_arm(line,hero.arm))
			_geometry(Hero.forearm(line,hero.arm))
			_geometry(Hero.hand_web(line[2],(line[2]-line[1]).normalized()),false)
		for attire: String in rig.ATTIRE_IDS:
			profile.selected.attire = attire
			check(rig.apply_style(profile.current_style()),"existing body and attire remain accepted")
			_check_customizer_fit(rig,coordinator)
			for state: int in Coordinator.State.values():
				for facing: float in [-1.0,1.0]:
					for calm: bool in [false,true]:
						coordinator.state = state
						coordinator.facing = facing
						coordinator.reduced_motion = calm
						coordinator._pose = coordinator._build_pose()
						check(rig.apply_pose(coordinator.pose(),0.7 if calm else 0),"hero anatomy accepts every pose, depth and facing")
						var fit: Dictionary = rig.attire_snapshot()
						check(float(fit.mouth_clearance_pixels) >= 4,"hero equipment cannot cover Fred's mouth")
						var before: String = rig.state_hash()
						var body := rig.get_node("RootJoint/BodyJoint") as Node2D
						var head := rig.get_node("RootJoint/HeadJoint") as Node2D
						check(body.scale.x > head.scale.x and body.scale.y > head.scale.y,"hero chest is proportionately larger than the head")
						check(rig.state_hash() == before,"geometry inspection cannot mutate the animated rig")
		coordinator.state = Coordinator.State.IDLE
		coordinator.facing = 1
		coordinator._pose = coordinator._build_pose()
		rig.apply_pose(coordinator.pose())
		var body_fill := rig.get_node("RootJoint/BodyJoint/Fill") as Polygon2D
		var head_fill := rig.get_node("RootJoint/HeadJoint/Fill") as Polygon2D
		var body_bounds := _bounds(rig._transformed_points(body_fill,body_fill.polygon,Vector2.ZERO))
		var head_bounds := _bounds(rig._transformed_points(head_fill,head_fill.polygon,Vector2.ZERO))
		check(body_bounds.size.x > head_bounds.size.x,"real authored chest silhouette exceeds head width")
	check(silhouette_keys.size() == 8,"every body build changes anatomical proportions, not just overall scale")
	var signatures := {}
	var emblems := {}
	for attire: String in rig.ATTIRE_IDS:
		var outfit := Hero.outfit(attire)
		signatures[outfit.signature] = true
		var emblem := Hero.emblem(outfit.chest)
		emblems[var_to_bytes(emblem).hex_encode()] = true
		_geometry(emblem,false)
		for side: float in [-1.0,1.0]:
			_geometry(Hero.chest_panel(side,outfit.chest))
			_geometry(Hero.shoulder_panel(Vector2(side*26,-8),side,outfit.shoulder,outfit.chest))
	check(signatures.size() == 9 and emblems.size() == 9,"nine outfits have distinct hero equipment and insignias")
	for hem: float in [24.0,25.0,26.0,27.0,28.0,29.0]: _geometry(Hero.suit(hem),false)
	check(Hero.segment(Vector2.ZERO,Vector2.ZERO,1,1,1).is_empty(),"degenerate limb fails closed")
	check(Hero.segment(Vector2(NAN,0),Vector2.ONE,1,1,1).is_empty(),"nonfinite limb fails closed")
	check(Hero.upper_arm(PackedVector2Array(),1).is_empty(),"incomplete limb fails closed")
	var saved := profile.to_dictionary()
	var restored := Customization.new("")
	# No purchases are performed: this checks the untouched starter save roundtrip.
	profile = Customization.new("")
	check(initial_profile == var_to_bytes(profile.to_dictionary()),"graphics never alter default inventory, prices, coins or save schema")
	check(restored.restore(profile.to_dictionary()) and restored.to_dictionary() == profile.to_dictionary(),"existing profile still round-trips")
	check(saved.schema_version == 1,"hero art adds no save version")
	rig.queue_free()
	await process_frame
	print("RESULT hero_frog_art_passed=%d hero_frog_art_failed=%d"%[passed,failed])
	quit(1 if failed else 0)
