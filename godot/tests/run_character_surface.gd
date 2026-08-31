extends SceneTree

const Surface = preload("res://scripts/character_surface.gd")
const FishArt = preload("res://scripts/predator_fish_art.gd")
const RigScene = preload("res://scenes/fred_rig.tscn")
const Coordinator = preload("res://scripts/fred_animation_coordinator.gd")
const Customization = preload("res://scripts/frog_customization.gd")
const Main = preload("res://scripts/main.gd")
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	_run.call_deferred()

func _area(points: PackedVector2Array) -> float:
	var area := 0.0
	for index in points.size():
		area += points[index].cross(points[(index + 1) % points.size()])
	return absf(area) * 0.5

func _check_mesh(contour: PackedVector2Array, label: String) -> void:
	var original := contour.duplicate()
	var mesh := Surface.volume_mesh(contour, Color("4fbd68"), 0.55)
	check(contour == original, label + " does not mutate its authored contour")
	check(mesh.points.size() == contour.size() * 2 + 1, label + " has bounded two-ring geometry")
	check(mesh.indices.size() == contour.size() * 9, label + " has exactly three triangles per edge")
	check(mesh.colors.size() == mesh.points.size(), label + " has a color per vertex")
	var valid := true
	var area := 0.0
	for index in range(0, mesh.indices.size(), 3):
		var a: Vector2 = mesh.points[mesh.indices[index]]
		var b: Vector2 = mesh.points[mesh.indices[index + 1]]
		var c: Vector2 = mesh.points[mesh.indices[index + 2]]
		valid = valid and a.is_finite() and b.is_finite() and c.is_finite()
		area += absf((b - a).cross(c - a)) * 0.5
	check(valid, label + " has finite triangles")
	check(absf(area - _area(contour)) < 0.1, label + " covers the silhouette without overlapping fill")
	check(var_to_bytes(mesh) == var_to_bytes(Surface.volume_mesh(contour, Color("4fbd68"), 0.55)), label + " lighting is byte-deterministic")

func _run() -> void:
	check(Surface.volume_mesh(PackedVector2Array(), Color.WHITE).points.is_empty(), "empty contour fails closed")
	check(Surface.volume_mesh(PackedVector2Array([Vector2.ZERO, Vector2.ONE]), Color.WHITE).points.is_empty(), "line cannot become a surface")
	check(Surface.volume_mesh(PackedVector2Array([Vector2.ZERO, Vector2.ONE, Vector2(NAN, 0)]), Color.WHITE).points.is_empty(), "nonfinite coordinates fail closed")
	var oversized := PackedVector2Array()
	oversized.resize(97)
	check(Surface.volume_mesh(oversized, Color.WHITE).points.is_empty(), "unbounded contour fails closed")
	var ellipse := Surface.ellipse(Vector2.ZERO, Vector2(30, 20))
	_check_mesh(ellipse, "ellipse")
	var mutable := Surface.volume_mesh(ellipse, Color.WHITE)
	var detached_indices := PackedInt32Array(mutable.indices)
	detached_indices[0] = 999
	mutable.indices = detached_indices
	check(Surface.volume_mesh(ellipse, Color.WHITE).indices[0] == 0, "returned geometry cannot poison the reusable index layout")
	check(Surface.ellipse(Vector2.ZERO, Vector2(3, 2)).size() == 8, "tiny markings use bounded phone-scale detail")
	check(Surface.ellipse(Vector2.ZERO, Vector2(12, 9)).size() == 16, "medium features retain smooth bounded detail")
	var faded := Surface.volume_mesh(ellipse, Color(1, 1, 1, 0.4), 0, true)
	check(is_equal_approx(faded.colors[0].a, 0.4), "soft patch retains its center opacity")
	var transparent_edge := true
	for index in range(ellipse.size() + 1, faded.colors.size()):
		transparent_edge = transparent_edge and faded.colors[index].a == 0.0
	check(transparent_edge, "soft lighting has a transparent outer edge")
	var line := PackedVector2Array([Vector2(0, 0), Vector2(10, 20), Vector2(30, 40)])
	var smooth := Surface.smooth_line(line)
	check(smooth[0] == line[0] and smooth[-1] == line[-1], "smoothing retains neck attachment endpoints")
	var rig: Node2D = RigScene.instantiate()
	root.add_child(rig)
	await process_frame
	for path: String in rig.POLYGON_ORDER:
		if path.ends_with("/Fill") or path.ends_with("/Belly"):
			_check_mesh(rig._rounded_polygons[path], path)
	var profile_reader := Main.new()
	for species: String in ["BASS", "PIKE", "MUSKIE"]:
		var profile: Dictionary = profile_reader._predator_identity_profile(species)
		var radii := Vector2(profile.body_radii)
		var contour := FishArt.body_contour(species, radii)
		_check_mesh(contour, species)
		var bounded := true
		for point in contour:
			bounded = bounded and absf(point.x) <= radii.x * 1.03 and absf(point.y) <= radii.y
		check(bounded, species + " retains the established body footprint")
	profile_reader.free()
	var style := Customization.new("")
	var animation := Coordinator.new()
	# Cross every existing body/garment/pose/facing combination. No catalog,
	# purchase, progression, save or collision values change in this art pass.
	for body: Dictionary in Customization.CATALOG["size"]:
		style.selected.size = str(body.id)
		for attire: String in rig.ATTIRE_IDS:
			style.selected.attire = attire
			check(rig.apply_style(style.current_style()), "existing body and attire combination is accepted")
			for state: int in Coordinator.State.values():
				for facing: float in [-1.0, 1.0]:
					animation.state = state
					animation.facing = facing
					animation.reduced_motion = state % 2 == 0
					animation._pose = animation._build_pose()
					rig.apply_pose(animation.pose(), 0.7 if state % 2 == 0 else 0.0)
					var fit: Dictionary = rig.attire_snapshot()
					check(float(fit.mouth_clearance_pixels) >= 4.0, "%s/%s/%d/%s keeps mouth clear" % [body.id, attire, state, facing])
	var before_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var started := Time.get_ticks_msec()
	for iteration in 10000:
		Surface.volume_mesh(ellipse, Color("4fbd68"), 0.55)
	var elapsed := Time.get_ticks_msec() - started
	var memory_growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - before_memory
	check(elapsed < 5000, "10,000 generated surfaces remain CPU bounded")
	check(memory_growth < 1024 * 1024, "10,000 generated surfaces retain no growing cache")
	check(Surface._index_cache.size() <= Surface.MAX_CONTOUR_POINTS, "triangle layouts are bounded independently of play time")
	print("MEASURE surface_meshes=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed, memory_growth])
	rig.queue_free()
	await process_frame
	print("RESULT character_surface_passed=%d character_surface_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
