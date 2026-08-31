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

func _reference_volume(contour: PackedVector2Array, base: Color, gloss: float, feathered: bool) -> Dictionary:
	# Frozen pre-optimization implementation from c44301b. Test-only oracle;
	# intentionally keep the duplicated work to catch accidental visual changes.
	var center := Vector2.ZERO
	for point in contour: center += point
	center /= float(contour.size())
	var points := PackedVector2Array([center])
	var colors := PackedColorArray([base if feathered else base.lightened(0.12)])
	for ring: float in [0.56, 1.0]:
		for point in contour:
			points.append(center.lerp(point, ring))
			var direction := (point - center).normalized()
			var light := direction.dot(Vector2(-0.5, -0.866))
			var color := base
			if feathered:
				color.a *= 0.46 if ring < 1.0 else 0.0
			else:
				color = base.lightened(maxf(0.0, light) * (0.14 + clampf(gloss, 0, 1) * 0.16))
				color = color.darkened(maxf(0.0, -light) * ring * 0.44 + ring * 0.06)
				color.a = base.a
			colors.append(color)
	return {"points": points, "colors": colors, "indices": Surface._triangle_indices(contour.size())}

func _reference_ellipse(center: Vector2, radii: Vector2, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var detail := 8 if radii.length() < 8.0 else (16 if radii.length() < 25.0 else Surface.ELLIPSE_SEGMENTS)
	for index in detail:
		var angle := float(index) * TAU / detail
		points.append(center + (Vector2(cos(angle), sin(angle)) * radii).rotated(rotation))
	return points

func _check_optimized_geometry() -> void:
	for count in range(3, Surface.MAX_CONTOUR_POINTS + 1):
		var contour := PackedVector2Array()
		for index in count:
			var angle := TAU * float(index) / count
			contour.append(Vector2(217.3, -42.8) + Vector2(cos(angle) * 26.7, sin(angle) * 18.3))
		for base: Color in [Color("4fbd68"), Color(0.2, 0.6, 0.8, 0.28), Color(1, 0.9, 0.2, 0), Color(1.2, -0.1, 0.4, 0.85)]:
			for gloss: float in [-0.5, 0.0, 0.35, 1.0, 1.7]:
				for feathered: bool in [false, true]:
					var expected := _reference_volume(contour, base, gloss, feathered)
					check(var_to_bytes(Surface.volume_mesh(contour, base, gloss, feathered)) == var_to_bytes(expected),"optimized two-ring mesh is byte-identical to the previous rendering math")
	for radii: Vector2 in [Vector2.ZERO, Vector2(3, 2), Vector2(8, 0), Vector2(12, 9), Vector2(25, 0), Vector2(30, 20), Vector2(-14, 7)]:
		for center: Vector2 in [Vector2.ZERO, Vector2(500.25, -391.75)]:
			for angle: float in [-PI, -0.23, 0, 0.71, PI]:
				check(Surface.ellipse(center, radii, angle) == _reference_ellipse(center, radii, angle),"cached unit ellipses retain exact detail thresholds, translation, scaling and rotation")
	var units := Surface._unit_ellipse_points(8)
	units[0] = Vector2(999,999)
	check(Surface._unit_ellipse_points(8)[0] == Vector2.RIGHT,"callers cannot poison the unit ellipse template")
	check(Surface._unit_ellipse_points(99).is_empty(),"unsupported ellipse template cannot grow the cache")
	var before_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for index in 20000:
		Surface.ellipse(Vector2(index * 0.3,index * -0.7), Vector2(1 + index % 40,3 + index % 27), index * 0.012)
	var growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - before_memory
	check(growth < 1024 * 1024,"moving and resizing ellipses do not retain per-frame geometry")
	check(Surface._ellipse_cache.size() == 3,"unit ellipse cache is capped at three detail levels")
	var vertices := 0
	for value: PackedVector2Array in Surface._ellipse_cache.values(): vertices += value.size()
	check(vertices == 48,"ellipse templates retain exactly 48 vertices regardless of play time")
	var contour := Surface.ellipse(Vector2.ZERO, Vector2(30,20))
	check(Surface.volume_mesh(contour,Color.WHITE,NAN).points.is_empty(),"nonfinite gloss still fails closed")
	var optimized_times: Array[int] = []
	var reference_times: Array[int] = []
	# Alternate order inside one process to reduce warm-up/order bias. This is
	# CPU construction time only, never a device-FPS or performance assertion.
	for batch in 5:
		for slot in 2:
			var optimized := (batch + slot) % 2 == 0
			var started := Time.get_ticks_usec()
			for iteration in 4000:
				if optimized: Surface.volume_mesh(contour,Color("4fbd68"),0.55,iteration % 2 == 0)
				else: _reference_volume(contour,Color("4fbd68"),0.55,iteration % 2 == 0)
			var elapsed := Time.get_ticks_usec() - started
			if optimized: optimized_times.append(elapsed)
			else: reference_times.append(elapsed)
	optimized_times.sort()
	reference_times.sort()
	print("MEASURE surface_ab batches=5 meshes_per_batch=4000 reference_median_us=%d optimized_median_us=%d ellipse_cache_vertices=%d churn_memory_growth_bytes=%d" % [reference_times[2],optimized_times[2],vertices,growth])

func _run() -> void:
	_check_optimized_geometry()
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
	# Exercise a non-identity parent transform, not just the game's usual origin.
	rig.position = Vector2(51.3,-18.7)
	rig.rotation = 0.17
	rig.scale = Vector2(1.3,0.8)
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
					var source := PackedVector2Array([Vector2(-12.3,-5.6),Vector2(1.7,8.2),Vector2(19.1,-3.7)])
					for path: String in ["RootJoint/HeadJoint","RootJoint/BodyJoint","RootJoint/HindLeft"]:
						var joint := rig.get_node(path) as Node2D
						var expected := PackedVector2Array()
						for point in source: expected.append(Vector2(420,315) + rig.to_local(joint.to_global(point)))
						check(rig._transformed_points(joint,source,Vector2(420,315)) == expected,"per-contour transforms exactly preserve each current joint pose")
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
