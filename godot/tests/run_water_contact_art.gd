extends SceneTree

const Contact = preload("res://scripts/water_contact_art.gd")
const Wildlife = preload("res://scripts/wildlife_animation_rig.gd")
const Fish = preload("res://scripts/predator_fish_art.gd")
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func bounded(geometry: Dictionary) -> bool:
	if not geometry.valid or geometry.curves.size() > Contact.MAX_CURVES or geometry.bubbles.size() > Contact.MAX_BUBBLES:
		return false
	if not Vector2(geometry.shadow_center).is_finite() or not Vector2(geometry.shadow_radii).is_finite() or not is_finite(float(geometry.shadow_alpha)):
		return false
	for curve: Dictionary in geometry.curves:
		if curve.points.size() != 17 or float(curve.alpha) < 0 or float(curve.alpha) > 1:
			return false
		for point: Vector2 in curve.points:
			if not point.is_finite() or point.length() > 260.0:
				return false
	for bubble: Dictionary in geometry.bubbles:
		if not Vector2(bubble.center).is_finite() or float(bubble.radius) <= 0 or float(bubble.alpha) < 0 or float(bubble.alpha) > 1:
			return false
	return true

func _init() -> void:
	var surface := {"depth": 0.0, "height": 0.0, "moving": true, "direction": Vector2.RIGHT}
	var before := var_to_bytes(surface)
	var swim := Contact.frog(surface, 0.3)
	var repeated := Contact.frog(surface, 0.3)
	check(var_to_bytes(swim) == var_to_bytes(repeated), "identical state has deterministic water contact")
	check(before == var_to_bytes(surface), "contact generation does not mutate gameplay snapshot")
	check(swim.curves.size() == 4, "swimming has a contact ring and a trailing wake")
	var reverse := surface.duplicate(true)
	reverse.direction = Vector2.LEFT
	var reverse_swim := Contact.frog(reverse, 0.3)
	check(float(swim.curves[2].points[8].x) < 0 and float(reverse_swim.curves[2].points[8].x) > 0, "wake trails either movement direction")
	var leap := surface.duplicate(true)
	leap.airborne = true
	leap.height = 52.0
	var airborne := Contact.frog(leap, 0.3)
	check(airborne.shadow_center == swim.shadow_center, "leap shadow remains on the water plane")
	check(airborne.shadow_alpha < swim.shadow_alpha, "higher leap softens contact shadow")
	check(airborne.shadow_radii.x > swim.shadow_radii.x, "higher leap diffuses contact shadow")
	check(airborne.curves.is_empty() and airborne.bubbles.is_empty(), "airborne Fred has no water ring attached to his feet")
	var perch := Contact.frog({"perched": true, "moving": true}, 0.3)
	check(perch.curves.is_empty(), "dry perch does not produce a swimming wake")
	var deep := surface.duplicate(true)
	deep.depth = 1.0
	var underwater := Contact.frog(deep, 0.3)
	check(underwater.curves.is_empty(), "submerged Fred has no surface contact ring")
	check(underwater.bubbles.size() == 4, "submerged Fred has a bounded bubble trail")
	var below_pad := deep.duplicate(true)
	below_pad.perched = true
	check(Contact.frog(below_pad, 0.3).bubbles.size() == 4, "swimming below a pad keeps underwater presentation")
	check(var_to_bytes(Contact.frog(deep, 1.0, true)) == var_to_bytes(Contact.frog(deep, 999.0, true)), "reduced motion freezes decorative bubble drift")
	check(var_to_bytes(Contact.frog(surface, 1.0, true)) == var_to_bytes(Contact.frog(surface, 999.0, true)), "reduced motion freezes decorative wake expansion")
	check(var_to_bytes(Contact.frog(surface, 0.0)) != var_to_bytes(Contact.frog(surface, 0.5)), "normal motion animates the wake")
	check(Contact.frog({"landing": 0.2}, 0.3).curves.size() == 4, "water landing has an expanding second ring")
	check(not Contact.frog({}, NAN).valid, "nonfinite time fails closed")
	for key: String in ["depth", "height", "size", "landing"]:
		check(not Contact.frog({key: NAN}, 0.3).valid, key + " rejects nonfinite input")
	check(not Contact.frog({"direction": Vector2(INF, 0)}, 0.3).valid, "invalid direction fails closed")
	check(not Contact.predator("UNKNOWN", 0, {}, 0).valid, "unknown wildlife does not generate water geometry")
	check(not Contact.predator("BASS", NAN, {}, 0).valid, "invalid predator depth fails closed")
	for tick in 61:
		var time := tick / 12.0
		for depth: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			for calm: bool in [false, true]:
				var snapshot := {"depth": depth, "size": 1.6, "moving": true, "boosting": true, "landing": 0.3, "direction": Vector2(-1, -1)}
				check(bounded(Contact.frog(snapshot, time, calm)), "all frog transition geometry stays finite and bounded")
				for species: String in ["BASS", "PIKE", "MUSKIE", "SNAKE", "HERON"]:
					var pose := Wildlife.pose(species, 0, time, calm)
					var geometry := Contact.predator(species, depth, pose, time, calm)
					check(bounded(geometry), "all wildlife contact geometry stays finite and bounded")
		var heron_pose := Wildlife.pose("HERON", 0, time)
		var feet := Contact.heron_feet(heron_pose)
		var heron := Contact.predator("HERON", 0, heron_pose, time)
		check(heron.shadow_center.y > 60.0 and heron.shadow_center.y < 66.0, "heron shadow belongs at feet, not mid-leg")
		check(is_equal_approx(feet[0].y, 61.0 - float(heron_pose.leg_lift) * 0.58), "heron left water contact follows the authored ankle")
		check(is_equal_approx(feet[1].y, 61.0 + float(heron_pose.leg_lift) * 0.42 * 0.58), "heron right water contact follows the authored ankle")
		for species: String in ["BASS", "PIKE", "MUSKIE"]:
			var pose := Wildlife.pose(species, 0, time)
			var pose_before := var_to_bytes(pose)
			var details := Fish.detail_pose(pose)
			check(details.pelvic_sweep == pose.pelvic_sweep and details.eye_focus == pose.eye_focus, "fish fin and eye use their authored channels")
			check(is_equal_approx(details.gill_flare, pose.gill_open), "fish gill uses authored breath channel")
			check(var_to_bytes(pose) == pose_before, "fish detail drawing does not mutate animation")
	var calm_low := Fish.detail_pose({"gill_open": 0.0, "reduced_motion": true})
	var calm_high := Fish.detail_pose({"gill_open": 1.0, "reduced_motion": true})
	check(float(calm_high.gill_flare) - float(calm_low.gill_flare) < 0.15, "reduced-motion gill breathing is attenuated")
	var started := Time.get_ticks_msec()
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for iteration in 10000:
		Contact.frog(surface, iteration / 60.0)
	var elapsed := Time.get_ticks_msec() - started
	var memory_growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
	check(elapsed < 5000, "contact geometry has bounded CPU cost")
	check(memory_growth < 1024 * 1024, "contact geometry retains no growing trail history")
	print("MEASURE water_contacts=10000 elapsed_ms=%d memory_growth_bytes=%d" % [elapsed, memory_growth])
	print("RESULT water_contact_art_passed=%d water_contact_art_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
