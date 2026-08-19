extends SceneTree

const Main = preload("res://scripts/main.gd")
const PredatorDepth = preload("res://scripts/predator_depth.gd")
const MarshRouteLayout = preload("res://scripts/marsh_route_layout.gd")
const WildlifeAnimationRig = preload("res://scripts/wildlife_animation_rig.gd")

const SAVE_PREFIX := "user://predator_depth_test"

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func clean_files() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))

func _init() -> void:
	_run.call_deferred()

func _pose_signature(pose: Dictionary) -> Array:
	return [
		str(pose.kind), int(pose.joint_count),
		snappedf(float(pose.body_pitch),0.0001), snappedf(float(pose.body_breathe),0.0001),
		snappedf(float(pose.tail_base),0.0001), snappedf(float(pose.tail_tip),0.0001),
		snappedf(float(pose.gill_open),0.0001), snappedf(float(pose.jaw_open),0.0001),
		snappedf(float(pose.spine_wave),0.0001), snappedf(float(pose.spine_amplitude),0.0001),
		snappedf(float(pose.wing_primary),0.0001), snappedf(float(pose.wing_secondary),0.0001),
		snappedf(float(pose.neck_curve),0.0001), snappedf(float(pose.leg_lift),0.0001),
		snappedf(float(pose.hover_lift),0.0001), snappedf(float(pose.abdomen_flex),0.0001),
		snappedf(float(pose.arm_sweep),0.0001), snappedf(float(pose.glow),0.0001),
	]

func _surface_signature(surface: Dictionary) -> Array:
	return [
		str(surface.kind),int(surface.volume_layers),str(surface.surface_kind),
		snappedf(float(surface.key_light),0.0001),snappedf(float(surface.underside_shadow),0.0001),
		snappedf(float(surface.rim_strength),0.0001),snappedf(float(surface.wet_specular),0.0001),
		snappedf(float(surface.feather_depth),0.0001),snappedf(float(surface.wing_translucency),0.0001),
		snappedf(float(surface.joint_depth),0.0001),snappedf(float(surface.facial_depth),0.0001),
		snappedf(float(surface.light_shift),0.0001),snappedf(float(surface.eye_glint),0.0001),
	]

func _run() -> void:
	clean_files()
	check(PredatorDepth.naturally_submerges("BASS"), "bass naturally uses surface and underwater bands")
	check(PredatorDepth.naturally_submerges("PIKE"), "pike naturally uses surface and underwater bands")
	check(PredatorDepth.naturally_submerges("MUSKIE"), "muskie naturally uses surface and underwater bands")
	check(PredatorDepth.naturally_submerges("SNAKE"), "marsh snake naturally uses surface and underwater bands")
	check(not PredatorDepth.naturally_submerges("HERON"), "heron correctly remains above water")

	var surface := PredatorDepth.snapshot("BASS", 0, 1, 0.0)
	var diving := PredatorDepth.snapshot("BASS", 0, 1, PredatorDepth.SURFACE_HOLD_SECONDS + PredatorDepth.DIVE_SECONDS * 0.5)
	var underwater := PredatorDepth.snapshot("BASS", 0, 1, PredatorDepth.UNDERWATER_START_SECONDS + 0.4)
	var surfacing := PredatorDepth.snapshot("BASS", 0, 1, PredatorDepth.SURFACING_START_SECONDS + PredatorDepth.SURFACE_SECONDS * 0.5)
	check(int(surface.state) == PredatorDepth.State.SURFACE and float(surface.depth) == 0.0, "fish begins with a readable surface patrol")
	check(int(diving.state) == PredatorDepth.State.DIVING and float(diving.depth) > 0.0 and float(diving.depth) < 1.0, "fish has an explicit dive transition")
	check(int(underwater.state) == PredatorDepth.State.UNDERWATER and float(underwater.depth) == 1.0, "fish reaches the full underwater band")
	check(int(surfacing.state) == PredatorDepth.State.SURFACING and float(surfacing.depth) > 0.0 and float(surfacing.depth) < 1.0, "fish has an explicit surface transition")
	var snake_underwater := PredatorDepth.snapshot("SNAKE", 0, 1, PredatorDepth.UNDERWATER_START_SECONDS + 0.4)
	check(int(snake_underwater.state) == PredatorDepth.State.UNDERWATER and is_equal_approx(float(snake_underwater.depth), 0.78), "snake uses a shallower but collidable underwater band")
	var heron := PredatorDepth.snapshot("HERON", 2, 50, 999.0)
	check(int(heron.state) == PredatorDepth.State.ABOVE_WATER and float(heron.depth) == 0.0, "heron never receives a fictional underwater state")

	check(PredatorDepth.shares_depth(0.0, surface), "surface Fred shares danger depth with a surface fish")
	check(not PredatorDepth.shares_depth(1.0, surface), "underwater Fred can safely pass beneath a surface fish")
	check(not PredatorDepth.shares_depth(0.0, underwater), "surface Fred is safe above an underwater fish")
	check(PredatorDepth.shares_depth(1.0, underwater), "underwater Fred shares danger depth with an underwater fish")
	check(PredatorDepth.shares_depth(1.0, snake_underwater), "underwater snake remains a real underwater threat")
	check(PredatorDepth.shares_depth(0.0, heron) and not PredatorDepth.shares_depth(1.0, heron), "Fred can dive beneath the above-water heron")

	var reference_hash := 0
	for trace in range(100):
		var trace_hash := 0
		for tick in range(480):
			for predator_index in range(Main.PREDATOR_SPECIES.size()):
				var sample := PredatorDepth.snapshot(Main.PREDATOR_SPECIES[predator_index], predator_index, 37, float(tick) / 60.0)
				trace_hash = hash([trace_hash, int(sample.state), snappedf(float(sample.depth), 0.0001), str(sample.cue)])
		if trace == 0:
			reference_hash = trace_hash
		check(trace_hash == reference_hash, "predator depth trace %03d is fixed-tick deterministic" % (trace + 1))

	var game: Node2D = Main.new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.countdown_enabled = false
	game.hazards_enabled = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var identity_silhouettes: Dictionary = {}
	for species: String in Main.PREDATOR_SPECIES:
		var identity: Dictionary = game._predator_identity_profile(species)
		identity_silhouettes[str(identity.silhouette)] = true
		check(Array(identity.anatomy).size() >= 6, "%s has at least six explicit species anatomy cues" % species.to_lower())
		check(Array(identity.motion_channels).size() >= 3, "%s has layered species-specific motion channels" % species.to_lower())
		check(int(identity.detail_layers) >= 8 and bool(identity.phone_readable), "%s realism remains detailed and phone-readable" % species.to_lower())
	check(identity_silhouettes.size() == Main.PREDATOR_SPECIES.size(), "every named predator has a distinct rendered silhouette contract")
	var bass_identity: Dictionary = game._predator_identity_profile("BASS")
	check(str(bass_identity.silhouette) == "deep_largemouth", "bass uses a deep-bodied largemouth silhouette")
	check(str(bass_identity.pattern) == "broken_lateral_band", "bass uses its recognizable broken lateral band")
	check("large hinged jaw" in Array(bass_identity.anatomy) and "spiny dorsal fin" in Array(bass_identity.anatomy), "bass exposes its large jaw and spiny dorsal anatomy")
	var pike_identity: Dictionary = game._predator_identity_profile("PIKE")
	check(str(pike_identity.silhouette) == "long_duckbill" and str(pike_identity.pattern) == "pale_chain_spots", "pike uses a long duckbill body with pale chain spots")
	var muskie_identity: Dictionary = game._predator_identity_profile("MUSKIE")
	check(str(muskie_identity.silhouette) == "long_barred" and str(muskie_identity.pattern) == "vertical_bars", "muskie uses a long barred predator silhouette")
	var snake_identity: Dictionary = game._predator_identity_profile("SNAKE")
	check("forked tongue" in Array(snake_identity.anatomy) and str(snake_identity.silhouette) == "scaled_serpentine", "snake keeps a scaled body, flattened head and forked tongue")
	var heron_identity: Dictionary = game._predator_identity_profile("HERON")
	check("S-curved neck" in Array(heron_identity.anatomy) and "long legs and toes" in Array(heron_identity.anatomy) and "layered primary feathers" in Array(heron_identity.anatomy), "heron keeps its wading-bird neck, bill, layered feathers, legs and toes")
	var bug_identity: Dictionary = game._wildlife_identity_profile("BUG")
	check(Array(bug_identity.anatomy).size() >= 5 and "six jointed legs" in Array(bug_identity.anatomy), "marsh bugs expose recognizable insect anatomy")
	check("four veined wings" in Array(bug_identity.anatomy) and int(bug_identity.detail_layers) >= 8, "marsh bugs use a four-wing detailed vector rig")
	var fairy_identity: Dictionary = game._wildlife_identity_profile("FAIRY")
	check(Array(fairy_identity.anatomy).size() >= 5 and "moonpetal crown" in Array(fairy_identity.anatomy), "life fairy exposes a distinct child-readable anatomy contract")
	check("four veined wings" in Array(fairy_identity.anatomy) and bool(fairy_identity.presentation_only), "life fairy detail remains four-wing and presentation-only")
	check(WildlifeAnimationRig.SUPPORTED_KINDS == ["BASS","PIKE","MUSKIE","SNAKE","HERON","BUG","FAIRY"], "articulation rig covers every gameplay wildlife character")
	for kind: String in WildlifeAnimationRig.SUPPORTED_KINDS:
		var pose: Dictionary = WildlifeAnimationRig.pose(kind,0,1.375,false)
		var repeated_pose: Dictionary = WildlifeAnimationRig.pose(kind,0,1.375,false)
		var reduced_pose: Dictionary = WildlifeAnimationRig.pose(kind,0,1.375,true)
		check(bool(pose.valid) and _pose_signature(pose) == _pose_signature(repeated_pose), "%s articulation pose is deterministic" % kind.to_lower())
		check(int(pose.joint_count) >= 11, "%s uses at least eleven connected presentation joints" % kind.to_lower())
		check(bool(pose.presentation_only) and not bool(pose.collision_mutation) and int(pose.save_fields) == 0, "%s articulation cannot change collision or save v1" % kind.to_lower())
		var normal_motion := absf(float(pose.tail_tip))+absf(float(pose.spine_amplitude))+absf(float(pose.wing_primary))+absf(float(pose.neck_curve))+absf(float(pose.hover_lift))
		var reduced_motion_amount := absf(float(reduced_pose.tail_tip))+absf(float(reduced_pose.spine_amplitude))+absf(float(reduced_pose.wing_primary))+absf(float(reduced_pose.neck_curve))+absf(float(reduced_pose.hover_lift))
		check(reduced_motion_amount <= normal_motion*0.20+0.001, "%s reduced motion restrains secondary articulation" % kind.to_lower())
		var rig_surface: Dictionary = WildlifeAnimationRig.surface_profile(kind,0,1.375,false)
		var repeated_surface: Dictionary = WildlifeAnimationRig.surface_profile(kind,0,1.375,false)
		var reduced_surface: Dictionary = WildlifeAnimationRig.surface_profile(kind,0,1.375,true)
		check(bool(rig_surface.valid) and _surface_signature(rig_surface)==_surface_signature(repeated_surface),"%s layered surface is deterministic" % kind.to_lower())
		check(int(rig_surface.volume_layers)>=9 and not str(rig_surface.surface_kind).is_empty(),"%s exposes at least nine dimensional surface layers" % kind.to_lower())
		check(float(rig_surface.joint_depth)>0.0 and float(rig_surface.facial_depth)>0.0,"%s surface integrates joints and facial depth" % kind.to_lower())
		check(absf(float(reduced_surface.light_shift))<=absf(float(rig_surface.light_shift))*0.11+0.001,"%s reduced motion restrains moving specular light" % kind.to_lower())
		check(bool(rig_surface.presentation_only) and not bool(rig_surface.collision_mutation) and int(rig_surface.save_fields)==0,"%s dimensional surface cannot change collision or save v1" % kind.to_lower())
	check(not bool(WildlifeAnimationRig.pose("DRAGON",0,1.0).valid), "unknown wildlife cannot enter the articulation contract")
	check(not bool(WildlifeAnimationRig.pose("BASS",-1,1.0).valid), "negative wildlife actor index fails closed")
	check(not bool(WildlifeAnimationRig.pose("BASS",0,NAN).valid), "non-finite wildlife time fails closed")
	check(not bool(WildlifeAnimationRig.surface_profile("DRAGON",0,1.0).valid),"unknown wildlife cannot enter the dimensional surface contract")
	check(not bool(WildlifeAnimationRig.surface_profile("BASS",-1,1.0).valid),"negative actor index fails the dimensional surface contract")
	check(not bool(WildlifeAnimationRig.surface_profile("BASS",0,NAN).valid),"non-finite time fails the dimensional surface contract")
	var articulation_reference := 0
	for trace_index in range(100):
		var articulation_hash := 0
		for tick in range(240):
			for kind: String in WildlifeAnimationRig.SUPPORTED_KINDS:
				articulation_hash = hash([articulation_hash,_pose_signature(WildlifeAnimationRig.pose(kind,tick%4,float(tick)/60.0,false)),_surface_signature(WildlifeAnimationRig.surface_profile(kind,tick%4,float(tick)/60.0,false))])
		if trace_index == 0:
			articulation_reference = articulation_hash
		check(articulation_hash == articulation_reference, "all-character articulation trace %03d is deterministic" % (trace_index+1))
	var stable_identity_snapshot: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	var identity_hash := 0
	for identity_iteration in range(10000):
		var sampled_predator: Dictionary = game._predator_identity_profile(Main.PREDATOR_SPECIES[identity_iteration % Main.PREDATOR_SPECIES.size()])
		var sampled_wildlife: Dictionary = game._wildlife_identity_profile("BUG" if identity_iteration % 2 == 0 else "FAIRY")
		var sampled_pose: Dictionary = WildlifeAnimationRig.pose(WildlifeAnimationRig.SUPPORTED_KINDS[identity_iteration%WildlifeAnimationRig.SUPPORTED_KINDS.size()],identity_iteration%4,float(identity_iteration)/60.0,identity_iteration%11==0)
		var sampled_surface: Dictionary = WildlifeAnimationRig.surface_profile(WildlifeAnimationRig.SUPPORTED_KINDS[identity_iteration%WildlifeAnimationRig.SUPPORTED_KINDS.size()],identity_iteration%4,float(identity_iteration)/60.0,identity_iteration%11==0)
		identity_hash = hash([identity_hash,str(sampled_predator.silhouette),int(sampled_predator.detail_layers),str(sampled_wildlife.silhouette),_pose_signature(sampled_pose),_surface_signature(sampled_surface)])
	check(identity_hash != 0, "10,000 realism profile reads produce a stable observation")
	check(game.session.to_save("2000-01-01T00:00:00Z") == stable_identity_snapshot, "realism profiles cannot mutate canonical gameplay or saves")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(not main_source.contains("animation.cue()"), "Fred's locomotion and location text is hidden above his head")
	game.screen = game.Screen.PLAYING
	game.level_number = 1
	game.level_profile = FredLevelIntensity.profile(1)
	game.secondary_predators.assign([Vector2(1100,650), Vector2(1100,650), Vector2(1100,650), Vector2(1100,650)])
	game.in_safe_location = false
	check(not main_source.contains("_predator_label_offset") and not main_source.contains("%s • %s"), "predator nameplates are absent from the playfield")
	check(main_source.contains("_draw_predator_depth_cues(drawn_position, snapshot)"), "non-text ripple and bubble depth cues remain")
	var phase_before_pause: Dictionary = game._predator_depth_snapshot(0)
	game.session.paused = true
	game._process(0.75)
	check(game._predator_depth_snapshot(0) == phase_before_pause, "pause freezes every predator depth phase")
	game.session.paused = false

	game.simulation_time = 0.0
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	game.session.health = 3
	game.fred = Vector2(600,300)
	game.predator = game.fred
	check(not game._predator_can_hit(0), "integrated surface bass cannot hit underwater Fred")
	check(not game._check_danger_collision() and game.session.health == 3, "passing under a surface predator preserves every life")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	check(game._predator_can_hit(0), "integrated surface bass can threaten surface Fred")
	check(game._check_danger_collision() and game.session.health == 2, "same-depth surface contact applies one normal predator hit")

	game.danger_cooldown_seconds = 0.0
	game.session.health = 3
	game.simulation_time = PredatorDepth.UNDERWATER_START_SECONDS + 0.4
	game.fred = Vector2(600,300)
	game.predator = game.fred
	game.depth.reset("surface")
	game.session.set_underwater(false)
	check(not game._predator_can_hit(0), "integrated underwater bass cannot hit surface Fred")
	check(not game._check_danger_collision() and game.session.health == 3, "staying above an underwater predator preserves every life")

	game.depth.reset("underwater")
	game.session.set_underwater(true)
	check(game._predator_can_hit(0), "integrated underwater bass can threaten underwater Fred")
	check(game._check_danger_collision() and game.session.health == 2, "same-depth underwater contact applies one normal predator hit")
	check(game.depth.state == game.depth.State.SURFACE and game.session.player_state == "surface", "underwater predator recovery returns Fred to the canonical safe surface")

	game.predator = Vector2(1150,650)
	game.fred = Vector2(600,300)
	game.simulation_time = 0.0
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.danger_cooldown_seconds = 0.0
	game._handle_touch(71, Rect2(MarshRouteLayout.touch_action_rects().depth).get_center(), true)
	game._handle_touch(71, Rect2(MarshRouteLayout.touch_action_rects().depth).get_center(), false)
	check(game.depth.state == game.depth.State.DIVING, "phone/tablet Dive button starts Fred's canonical descent")
	for frame in range(48):
		game._fixed_tick(1.0 / 60.0)
	check(game.depth.state == game.depth.State.UNDERWATER and game.session.player_state == "underwater", "touch-driven Fred reaches the underwater band")
	game.predator = game.fred
	check(not game._check_danger_collision(), "touch-driven underwater Fred passes beneath the surface bass")

	game.simulation_time = 12.5
	var save_snapshot: Dictionary = game.session.to_save("2000-01-01T00:00:00Z")
	check(not save_snapshot.has("predator_depth") and not save_snapshot.has("predator_phase"), "save v1 excludes transient predator depth state")
	check(game.saver.save(game.session, "2000-01-01T00:00:00Z").get("ok", false), "stable session still saves with predator depth active")
	var restored := AdventureSession.new(1337)
	check(game.saver.load_session(restored).get("ok", false) and restored.to_save("2000-01-01T00:00:00Z") == save_snapshot, "reload preserves canonical gameplay without transient predator depth")

	var memory_before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var started := Time.get_ticks_msec()
	var stress_hash := 0
	for iteration in range(10000):
		var stress := PredatorDepth.snapshot(Main.PREDATOR_SPECIES[iteration % Main.PREDATOR_SPECIES.size()], iteration % 5, 1 + iteration % 100, float(iteration) / 60.0)
		stress_hash = hash([stress_hash, int(stress.state), snappedf(float(stress.depth), 0.0001)])
	var elapsed_ms := Time.get_ticks_msec() - started
	var memory_growth := maxi(0, int(Performance.get_monitor(Performance.MEMORY_STATIC) - memory_before))
	check(elapsed_ms < 1500, "10,000 predator depth updates remain time-bounded")
	check(memory_growth < 2 * 1024 * 1024, "10,000 predator depth updates remain memory-bounded")
	check(stress_hash != 0, "predator depth stress loop produces a stable observation")
	print("MEASURE predator_depth_updates=10000 elapsed_ms=%d memory_growth_bytes=%d hash=%d" % [elapsed_ms, memory_growth, stress_hash])

	game.queue_free()
	await process_frame
	clean_files()
	print("RESULT predator_depth_passed=%d predator_depth_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
