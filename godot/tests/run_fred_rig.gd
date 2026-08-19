extends SceneTree

const AnimationCoordinator = preload("res://scripts/fred_animation_coordinator.gd")
const FredRigScene = preload("res://scenes/fred_rig.tscn")
const FredRigScript = preload("res://scripts/fred_rig.gd")
const Main = preload("res://scripts/main.gd")
const SAVE_PREFIX := "user://fred_rig_test"

var passed := 0
var failed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)

func _pose_for(state_value: int, facing: float = 1.0, reduced: bool = false) -> Dictionary:
	var coordinator := AnimationCoordinator.new()
	coordinator.state = state_value
	coordinator.facing = facing
	coordinator.reduced_motion = reduced
	coordinator._pose = coordinator._build_pose()
	return coordinator.pose()

func _trace(rig: Node2D, extra_reads: bool = false, reduced: bool = false) -> String:
	var hashes: Array[String] = []
	for cycle in range(3):
		for state_value in AnimationCoordinator.State.values():
			var facing := 1.0 if (cycle + int(state_value)) % 2 == 0 else -1.0
			var pose := _pose_for(int(state_value), facing, reduced)
			rig.apply_pose(pose, 0.8 if int(state_value) in [
				AnimationCoordinator.State.DIVING,
				AnimationCoordinator.State.UNDERWATER_IDLE,
				AnimationCoordinator.State.UNDERWATER_SWIM,
				AnimationCoordinator.State.SURFACING,
			] else 0.0)
			if extra_reads:
				rig.snapshot()
				rig.tongue_anchor()
				rig.cue_anchor()
				rig.ground_contacts()
			hashes.append(rig.state_hash())
	return "|".join(hashes)

func _clean_files() -> void:
	for suffix in [".json", ".bak", ".tmp"]:
		var path: String = SAVE_PREFIX + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_clean_files()
	var rig: Node2D = FredRigScene.instantiate()
	root.add_child(rig)
	await process_frame

	check(rig.validate_contract(), "authored rig scene satisfies its complete node/type contract")
	check(rig.REQUIRED_NODES.size() == 34, "rig contract exposes 34 inspectable authored nodes")
	check(rig.get_node("RootJoint/BodyJoint/Fill") is Polygon2D, "body is authored as inspectable Polygon2D geometry")
	check(rig.get_node("RootJoint/HeadJoint/Fill") is Polygon2D, "head is authored independently from the body")
	check(rig.get_node("RootJoint/HeadJoint/TongueAnchor") is Marker2D, "tongue origin is a stable authored marker")
	check(rig.get_node("RootJoint/HindLeft/GroundContact") is Marker2D and rig.get_node("RootJoint/HindRight/GroundContact") is Marker2D, "both feet expose authored ground contacts")
	check(rig.get_node("RootJoint/FrontLeft") is Line2D and rig.get_node("RootJoint/FrontRight") is Line2D, "front limbs remain independently articulated")
	var realism: Dictionary = rig.realism_snapshot()
	check(int(realism.feature_count) == 16, "Fred exposes sixteen inspectable anatomical, material, volume and micro-motion realism features")
	for feature: String in ["dorsolateral folds", "visible tympanum", "horizontal frog pupils", "webbed fingers and toe pads", "mottled skin texture"]:
		check(feature in Array(realism.features), "Fred realism contract includes %s" % feature)
	check(bool(realism.presentation_only) and bool(realism.phone_safe_vector_rig), "Fred realism remains presentation-only and phone-safe")
	check(not bool(realism.collision_mutation) and int(realism.save_fields) == 0, "Fred realism cannot alter collision or save-v1 authority")
	for feature: String in ["articulated throat breathing","deterministic eyelid blink"]:
		check(feature in Array(realism.features), "Fred micro-motion contract includes %s" % feature)
	for feature: String in ["layered cheek and brow volume","integrated shoulder and knee caps","wet skin rim lighting","subsurface belly shading"]:
		check(feature in Array(realism.features), "Fred dimensional surface contract includes %s" % feature)
	check(str(realism.surface_model)=="layered vector volume" and int(realism.volume_layers)>=9,"Fred uses a deep layered vector surface model")
	check(bool(realism.integrated_joint_caps) and bool(realism.facial_depth),"Fred surface model integrates joint caps and facial depth")
	var micro_reference: Dictionary = rig.micro_motion_snapshot(2.37,false)
	check(micro_reference == rig.micro_motion_snapshot(2.37,false), "Fred breathing and blink micro-motion is deterministic")
	var micro_reduced: Dictionary = rig.micro_motion_snapshot(2.37,true)
	check(absf(float(micro_reduced.breath)) <= absf(float(micro_reference.breath))*0.13+0.001, "reduced motion restrains Fred breathing while retaining anatomy")
	check(bool(micro_reference.presentation_only) and not bool(micro_reference.collision_mutation) and int(micro_reference.save_fields)==0, "Fred micro-motion cannot mutate collision or save v1")

	var attire_style := {
		"body_color": Color("4fbd68"),
		"size_scale": 1.05,
		"tongue_color": Color("ff7ca8"),
		"attire": "marsh_runner",
	}
	var attire_materials: Dictionary = {}
	var attire_cuts: Dictionary = {}
	for attire_id: String in rig.ATTIRE_IDS:
		attire_style.attire = attire_id
		check(rig.apply_style(attire_style), "%s applies through the typed rig style contract" % attire_id)
		rig.apply_pose(_pose_for(AnimationCoordinator.State.IDLE, 1.0))
		var right_gear: Dictionary = rig.attire_snapshot()
		check(bool(right_gear.valid) and bool(right_gear.child_readable), "%s exposes child-readable gear metadata" % attire_id)
		check(str(right_gear.label) in ["Runner Goggles", "Explorer Glasses", "Moon Champion Visor", "Firefly Hero Goggles"], "%s has an obvious visible name" % attire_id)
		check(str(right_gear.eyewear) != "none", "%s includes aligned eyewear" % attire_id)
		check(str(right_gear.material) != "unknown", "%s exposes a specific garment material" % attire_id)
		attire_materials[str(right_gear.material)] = true
		check(str(right_gear.finish) != "unknown" and str(right_gear.drape) != "unknown", "%s exposes a specific material finish and drape" % attire_id)
		check(float(right_gear.roughness) >= 0.0 and float(right_gear.roughness) <= 1.0, "%s material roughness remains physically bounded" % attire_id)
		check(float(right_gear.flex) >= 0.5 and float(right_gear.flex) <= 1.0, "%s garment flex supports articulated frog movement" % attire_id)
		check(str(right_gear.cut) != "unknown", "%s exposes an authored garment cut" % attire_id)
		attire_cuts[str(right_gear.cut)] = true
		check(float(right_gear.sleeve_ratio) >= 0.2 and float(right_gear.sleeve_ratio) <= 0.5, "%s sleeve length stays fitted to Fred's forelimb" % attire_id)
		check(float(right_gear.hem_drop) >= 0.2 and float(right_gear.hem_drop) <= 0.7, "%s hem drape stays bounded around Fred's belly" % attire_id)
		check(float(right_gear.structure) >= 0.1 and float(right_gear.structure) <= 0.7, "%s fabric structure stays soft enough for frog movement" % attire_id)
		check(Array(right_gear.fit_features).size() == 15, "%s exposes fifteen tailored fit features" % attire_id)
		for fit_feature: String in ["contoured torso panels", "ribbed mouth-clear collar", "articulated shoulder gussets", "layered eyewear gasket", "attire-specific closures", "pose-aware cloth folds", "joint-mounted sleeves and bracers", "soft anatomical armholes", "tapered limb tailoring", "curved bound hems", "garment-specific accessory placement", "soft edge finishing"]:
			check(fit_feature in Array(right_gear.fit_features), "%s attire contract includes %s" % [attire_id, fit_feature])
		check(int(right_gear.fabric_layers) >= 12 and int(right_gear.eyewear_depth_layers) >= 5, "%s uses layered fabric and eyewear depth" % attire_id)
		check(int(right_gear.tailored_panels) == 5 and bool(right_gear.functional_seams) and bool(right_gear.limb_fit), "%s clothing is fitted around Fred's torso and limbs" % attire_id)
		check(int(right_gear.anatomical_openings) == 3 and float(right_gear.soft_edge_px) <= 2.0, "%s uses soft bound neck and arm openings" % attire_id)
		check(bool(right_gear.presentation_only) and not bool(right_gear.collision_mutation) and int(right_gear.save_fields) == 0, "%s attire cannot alter collision or save-v1 authority" % attire_id)
		check(Vector2(right_gear.left_eye_anchor).is_finite() and Vector2(right_gear.right_eye_anchor).is_finite(), "%s eyewear anchors remain finite" % attire_id)
		check(float(right_gear.eye_span) >= 20.0 and float(right_gear.eye_span) <= 40.0, "%s eyewear spans both eyes without leaving Fred's head" % attire_id)
		check(float(right_gear.mouth_clearance_pixels) >= 5.0, "%s collar stays below Fred's mouth" % attire_id)
		rig.apply_pose(_pose_for(AnimationCoordinator.State.IDLE, -1.0))
		var left_gear: Dictionary = rig.attire_snapshot()
		check(is_equal_approx(Vector2(right_gear.left_eye_anchor).x, -Vector2(left_gear.left_eye_anchor).x), "%s eyewear mirrors with Fred instead of drifting" % attire_id)
		check(float(left_gear.mouth_clearance_pixels) >= 5.0, "%s mirrored collar stays below Fred's mouth" % attire_id)
		for state_value: int in AnimationCoordinator.State.values():
			rig.apply_pose(_pose_for(state_value, 1.0))
			check(float(rig.attire_snapshot().mouth_clearance_pixels) >= 5.0, "%s keeps mouth clearance in state %02d" % [attire_id, state_value])
			check(rig.attire_snapshot() == rig.attire_snapshot(), "%s fit snapshot stays deterministic in state %02d" % [attire_id, state_value])
			var attire_motion: Dictionary = rig.attire_motion_snapshot()
			check(is_finite(float(attire_motion.stretch)) and is_finite(float(attire_motion.compression)) and is_finite(float(attire_motion.fold_bias)), "%s cloth deformation stays finite in state %02d" % [attire_id, state_value])
			check(float(attire_motion.stretch) >= -0.32 and float(attire_motion.stretch) <= 0.42, "%s cloth stretch stays bounded in state %02d" % [attire_id, state_value])
			check(float(attire_motion.compression) >= 0.0 and float(attire_motion.compression) <= 0.42, "%s cloth compression stays bounded in state %02d" % [attire_id, state_value])
			check(bool(attire_motion.presentation_only) and not bool(attire_motion.collision_mutation) and int(attire_motion.save_fields) == 0, "%s cloth deformation cannot mutate gameplay in state %02d" % [attire_id, state_value])
	check(attire_materials.size() == rig.ATTIRE_IDS.size(), "all four attire choices use distinct readable garment materials")
	check(attire_cuts.size() == rig.ATTIRE_IDS.size(), "all four attire choices use distinct anatomical garment cuts")
	attire_style.attire = "floating_paper_hat"
	check(not rig.apply_style(attire_style), "unknown attire cannot bypass the aligned gear catalog")
	attire_style.attire = "marsh_runner"
	check(rig.apply_style(attire_style), "rig restores the valid starter gear after a rejected style")

	var state_hashes: Dictionary = {}
	for state_value in AnimationCoordinator.State.values():
		var pose := _pose_for(int(state_value))
		check(rig.apply_pose(pose, 0.75 if int(state_value) in [
			AnimationCoordinator.State.DIVING,
			AnimationCoordinator.State.UNDERWATER_IDLE,
			AnimationCoordinator.State.UNDERWATER_SWIM,
			AnimationCoordinator.State.SURFACING,
		] else 0.0), "state %02d applies to the authored rig" % int(state_value))
		var snapshot: Dictionary = rig.snapshot()
		check(bool(snapshot.valid) and int(snapshot.state) == int(state_value), "state %02d produces a valid matching rig snapshot" % int(state_value))
		check(str(snapshot.state_name) == str(pose.state_name) and str(snapshot.cue) == str(pose.cue), "state %02d retains semantic and non-color cues" % int(state_value))
		check(Vector2(snapshot.root_scale).x > 0.0 and Vector2(snapshot.root_scale).y > 0.0, "state %02d keeps a positive readable silhouette" % int(state_value))
		check(PackedVector2Array(snapshot.ground_contacts).size() == 2, "state %02d retains two deterministic ground contacts" % int(state_value))
		check(Vector2(snapshot.tongue_anchor).is_finite() and Vector2(snapshot.cue_anchor).is_finite(), "state %02d keeps finite tongue and cue anchors" % int(state_value))
		state_hashes[int(state_value)] = rig.state_hash()
	check(state_hashes.size() == AnimationCoordinator.State.size(), "all 23 coordinator states map to explicit rig output")
	var unique_hashes: Dictionary = {}
	for value in state_hashes.values():
		unique_hashes[str(value)] = true
	check(unique_hashes.size() == AnimationCoordinator.State.size(), "all 23 state mappings are independently inspectable")

	for state_value in AnimationCoordinator.State.values():
		var right_pose := _pose_for(int(state_value), 1.0)
		var left_pose := _pose_for(int(state_value), -1.0)
		rig.apply_pose(right_pose)
		var right_snapshot: Dictionary = rig.snapshot()
		rig.apply_pose(left_pose)
		var left_snapshot: Dictionary = rig.snapshot()
		check(int(right_snapshot.facing) == 1 and int(left_snapshot.facing) == -1, "state %02d mirrors facing without changing canonical state" % int(state_value))
		check(is_equal_approx(absf(Vector2(right_snapshot.root_scale).x), absf(Vector2(left_snapshot.root_scale).x)), "state %02d mirror preserves silhouette scale" % int(state_value))
		check(is_equal_approx(Vector2(right_snapshot.tongue_anchor).x, -Vector2(left_snapshot.tongue_anchor).x), "state %02d mirror preserves the authored tongue anchor" % int(state_value))
		check(Vector2(right_snapshot.pupil_position).x > 0.0 and Vector2(left_snapshot.pupil_position).x > 0.0, "state %02d retains an eye-direction cue that mirrors with the rig root" % int(state_value))

	rig.apply_pose(_pose_for(AnimationCoordinator.State.LEAP_ANTICIPATION))
	var anticipation: Dictionary = rig.snapshot()
	rig.apply_pose(_pose_for(AnimationCoordinator.State.LEAP_APEX))
	var apex: Dictionary = rig.snapshot()
	check(Vector2(anticipation.root_scale).y < Vector2(apex.root_scale).y, "leap anticipation crouches before the authored apex stretch")
	check(absf(float(anticipation.hind_left_rotation) - float(apex.hind_left_rotation)) > 0.15, "hind-leg articulation clearly separates crouch and apex")
	rig.apply_pose(_pose_for(AnimationCoordinator.State.TONGUE_EXTENSION))
	check(bool(rig.snapshot().mouth_visible), "tongue extension visibly opens Fred's authored mouth")
	rig.apply_pose(_pose_for(AnimationCoordinator.State.IDLE))
	check(not bool(rig.snapshot().mouth_visible), "idle restores the authored closed-mouth line")
	rig.apply_pose(_pose_for(AnimationCoordinator.State.DAMAGE))
	check(Vector2(rig.snapshot().eye_scale).y <= 0.2, "damage preemption closes the articulated eyes")
	rig.apply_pose(_pose_for(AnimationCoordinator.State.FAILURE))
	check(bool(rig.snapshot().mouth_visible) and Vector2(rig.snapshot().root_scale).y < 0.8, "failure produces a readable flattened splat pose")

	var normal_pose := _pose_for(AnimationCoordinator.State.LEAP_ASCENT, 1.0, false)
	var reduced_pose := _pose_for(AnimationCoordinator.State.LEAP_ASCENT, 1.0, true)
	rig.apply_pose(normal_pose)
	var normal_snapshot: Dictionary = rig.snapshot()
	rig.apply_pose(reduced_pose)
	var reduced_snapshot: Dictionary = rig.snapshot()
	check(absf(float(normal_snapshot.root_rotation)) > 0.01 and is_zero_approx(float(reduced_snapshot.root_rotation)), "reduced motion removes rig overshoot while retaining the leap pose")
	check(str(normal_snapshot.cue) == str(reduced_snapshot.cue), "reduced motion retains equivalent semantic cue information")

	var reference_trace := _trace(rig)
	for scenario in range(100):
		check(_trace(rig) == reference_trace, "authored pose trace %03d is byte-identical" % (scenario + 1))
	check(_trace(rig, true) == reference_trace, "render-order rig reads cannot mutate deterministic pose output")
	check(_trace(rig, false, true) == _trace(rig, true, true), "reduced-motion rig hashes ignore presentation read rate")

	var invalid_rig: Node2D = FredRigScript.new()
	root.add_child(invalid_rig)
	await process_frame
	check(not invalid_rig.validate_contract(), "missing authored nodes fail the rig contract safely")
	check("Missing authored rig node" in invalid_rig.last_error, "missing-node failure is observable without filesystem details")
	check(not invalid_rig.apply_pose(_pose_for(AnimationCoordinator.State.IDLE)), "missing-node rig refuses pose input")
	invalid_rig.queue_free()
	await process_frame

	var before_invalid: String = rig.state_hash()
	var invalid_pose := _pose_for(AnimationCoordinator.State.IDLE)
	invalid_pose.erase("cue")
	check(not rig.apply_pose(invalid_pose), "invalid pose input fails safely")
	check("Missing authored rig pose key" in rig.last_error, "invalid pose failure is observable")
	check(before_invalid != rig.state_hash(), "invalid pose neutralizes stale presentation instead of masquerading as valid state")
	invalid_pose = _pose_for(AnimationCoordinator.State.IDLE)
	invalid_pose.body_scale = "large"
	check(not rig.apply_pose(invalid_pose) and "invalid value type" in rig.last_error, "wrongly typed pose input fails without an engine conversion error")
	invalid_pose = _pose_for(AnimationCoordinator.State.IDLE)
	invalid_pose.state = 99
	check(not rig.apply_pose(invalid_pose) and "state metadata" in rig.last_error, "unknown coordinator state fails safely")
	check(rig.validate_contract(), "valid rig recovers after malformed pose input")

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.hazards_enabled = false
	game.countdown_enabled = false
	game.device_intent_adapter_enabled = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	check(is_instance_valid(game.fred_rig) and game.fred_rig.validate_contract(), "runtime main scene instantiates the authored rig")
	check(not game.has_method("_draw_fred") and not game.has_method("_fred_pose_point"), "runtime retired the inline procedural Fred body path")

	var stable_session: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	var stable_fred: Vector2 = game.fred
	var stable_collision_position: Vector2 = game.fred
	for query in range(100):
		game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
		game.fred_rig.snapshot()
		game.fred_rig.state_hash()
	check(game.session.to_save("2000-01-01T00:00:00Z") == stable_session, "rig updates cannot mutate canonical session state")
	check(game.fred == stable_fred and stable_collision_position == game.fred, "rig updates cannot mutate player position or collision authority")

	Input.action_press("move_right")
	game._fixed_tick(1.0 / 60.0)
	Input.action_release("move_right")
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(int(game.fred_rig.snapshot().state) in [AnimationCoordinator.State.GROUND_MOVE, AnimationCoordinator.State.SURFACE_SWIM], "synthetic platform movement drives the integrated rig")
	game.leap.reset()
	game._request_leap(Vector2.RIGHT)
	game._fixed_tick(1.0 / 60.0)
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(int(game.fred_rig.snapshot().state) == AnimationCoordinator.State.LEAP_ANTICIPATION, "integrated leap drives the authored anticipation pose")
	game.leap.reset()
	game.depth.reset("surface")
	game.fred = Vector2(560,330)
	check(game._request_dive(), "integration fixture accepts a real dive")
	game._fixed_tick(1.0 / 60.0)
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(int(game.fred_rig.snapshot().state) == AnimationCoordinator.State.DIVING, "integrated dive drives the articulated rig")
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.collected.assign([0,1,2])
	game.tongue.reset()
	game._request_tongue(Vector2.RIGHT)
	game._fixed_tick(1.0 / 60.0)
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(bool(game.fred_rig.snapshot().mouth_visible), "integrated tongue interaction opens the rig mouth at its authored anchor")
	game.tongue.reset()
	game.session.health = 2
	game._apply_danger_hit("[DANGER] Authored rig damage test.")
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(int(game.fred_rig.snapshot().state) == AnimationCoordinator.State.DAMAGE and game.session.health == 1, "real damage preempts the rig after the canonical health change")
	game.session.health = 1
	game._apply_danger_hit("[DANGER] Authored rig failure test.")
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(int(game.fred_rig.snapshot().state) == AnimationCoordinator.State.FAILURE and game.screen == game.Screen.FAILED, "final-life failure drives the authored failure pose")
	game._retry()
	game.fred_rig.apply_pose(game.animation.pose(), float(game.depth.depth))
	check(int(game.fred_rig.snapshot().state) == AnimationCoordinator.State.RESET, "retry snaps the authored rig to ready")

	var stable_save: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not stable_save.has("rig") and not stable_save.has("animation") and not stable_save.has("pose"), "save v1 excludes all transient rig fields")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "schema-v1 save succeeds after authored rig traversal")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false), "schema-v1 reload succeeds without rig data")
	check(restored.to_save("2000-01-01T00:00:00Z") == stable_save, "authored rig integration causes no canonical save drift")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var objects_before := Performance.get_monitor(Performance.OBJECT_COUNT)
	var resources_before := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var started_ms := Time.get_ticks_msec()
	var stress_coordinator := AnimationCoordinator.new()
	for iteration in range(10000):
		stress_coordinator.state = iteration % AnimationCoordinator.State.size()
		stress_coordinator.facing = 1.0 if iteration % 2 == 0 else -1.0
		stress_coordinator.reduced_motion = iteration % 11 == 0
		stress_coordinator.state_ticks = iteration % 60
		stress_coordinator._pose = stress_coordinator._build_pose()
		rig.apply_pose(stress_coordinator.pose(), float(iteration % 101) / 100.0)
		rig.state_hash()
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	var object_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_COUNT) - objects_before))
	var resource_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT) - resources_before))
	var node_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) - nodes_before))
	var orphan_growth := maxi(0, int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) - orphans_before))
	check(elapsed_ms < 5000, "10,000 rig updates remain time-bounded")
	check(memory_growth < 3 * 1024 * 1024, "10,000 rig updates remain memory-bounded")
	check(node_growth == 0 and orphan_growth == 0, "10,000 rig updates create no nodes or orphans")
	check(resource_growth == 0, "10,000 rig updates create no retained resources")
	print("MEASURE rig_updates=10000 elapsed_ms=%d memory_growth_bytes=%d object_growth=%d resource_growth=%d node_growth=%d orphan_growth=%d" % [
		elapsed_ms, memory_growth, object_growth, resource_growth, node_growth, orphan_growth
	])

	game.menu_music.stop()
	game.chase_music.stop()
	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	rig.queue_free()
	await process_frame
	_clean_files()
	print("RESULT fred_rig_passed=%d fred_rig_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
