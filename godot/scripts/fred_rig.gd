class_name FredRig
extends Node2D

const CharacterSurface = preload("res://scripts/character_surface.gd")

const REQUIRED_POSE_KEYS := [
	"state",
	"state_name",
	"cue",
	"facing",
	"body_offset",
	"body_scale",
	"leg_extension",
	"tilt",
	"eye_squint",
	"mouth_open",
	"accent",
	"reduced_motion",
]

const REQUIRED_NODES := {
	"RootJoint": "Node2D",
	"RootJoint/HindLeft": "Node2D",
	"RootJoint/HindLeft/Fill": "Polygon2D",
	"RootJoint/HindLeft/Outline": "Line2D",
	"RootJoint/HindLeft/Toes": "Line2D",
	"RootJoint/HindLeft/GroundContact": "Marker2D",
	"RootJoint/HindRight": "Node2D",
	"RootJoint/HindRight/Fill": "Polygon2D",
	"RootJoint/HindRight/Outline": "Line2D",
	"RootJoint/HindRight/Toes": "Line2D",
	"RootJoint/HindRight/GroundContact": "Marker2D",
	"RootJoint/BodyJoint": "Node2D",
	"RootJoint/BodyJoint/Outline": "Polygon2D",
	"RootJoint/BodyJoint/Fill": "Polygon2D",
	"RootJoint/BodyJoint/Belly": "Polygon2D",
	"RootJoint/BodyJoint/Accent": "Polygon2D",
	"RootJoint/HeadJoint": "Node2D",
	"RootJoint/HeadJoint/Outline": "Polygon2D",
	"RootJoint/HeadJoint/Fill": "Polygon2D",
	"RootJoint/HeadJoint/EyeLeft": "Node2D",
	"RootJoint/HeadJoint/EyeLeft/Outline": "Polygon2D",
	"RootJoint/HeadJoint/EyeLeft/White": "Polygon2D",
	"RootJoint/HeadJoint/EyeLeft/Pupil": "Polygon2D",
	"RootJoint/HeadJoint/EyeRight": "Node2D",
	"RootJoint/HeadJoint/EyeRight/Outline": "Polygon2D",
	"RootJoint/HeadJoint/EyeRight/White": "Polygon2D",
	"RootJoint/HeadJoint/EyeRight/Pupil": "Polygon2D",
	"RootJoint/HeadJoint/MouthCavity": "Polygon2D",
	"RootJoint/HeadJoint/MouthLine": "Line2D",
	"RootJoint/HeadJoint/Nostrils": "Line2D",
	"RootJoint/HeadJoint/TongueAnchor": "Marker2D",
	"RootJoint/HeadJoint/CueAnchor": "Marker2D",
	"RootJoint/FrontLeft": "Line2D",
	"RootJoint/FrontRight": "Line2D",
}

const POLYGON_ORDER := [
	"RootJoint/HindLeft/Fill",
	"RootJoint/HindRight/Fill",
	"RootJoint/BodyJoint/Outline",
	"RootJoint/BodyJoint/Fill",
	"RootJoint/BodyJoint/Belly",
	"RootJoint/BodyJoint/Accent",
	"RootJoint/HeadJoint/Outline",
	"RootJoint/HeadJoint/Fill",
	"RootJoint/HeadJoint/EyeLeft/Outline",
	"RootJoint/HeadJoint/EyeRight/Outline",
	"RootJoint/HeadJoint/EyeLeft/White",
	"RootJoint/HeadJoint/EyeRight/White",
	"RootJoint/HeadJoint/EyeLeft/Pupil",
	"RootJoint/HeadJoint/EyeRight/Pupil",
	"RootJoint/HeadJoint/MouthCavity",
]

const LINE_ORDER := [
	"RootJoint/HindLeft/Outline",
	"RootJoint/HindRight/Outline",
	"RootJoint/FrontLeft",
	"RootJoint/FrontRight",
	"RootJoint/HindLeft/Toes",
	"RootJoint/HindRight/Toes",
	"RootJoint/HeadJoint/Nostrils",
	"RootJoint/HeadJoint/MouthLine",
]

const SURFACE_FILL := Color("4fbd68")
const SURFACE_HEAD := Color("66d477")
const UNDERWATER_FILL := Color("3e91a6")
const UNDERWATER_HEAD := Color("54b7bd")
const OUTLINE := Color("152e29")
const UNDERWATER_OUTLINE := Color("d6f7ff")
const MAX_COORDINATOR_STATE := 22
const ART_REFERENCE_PROFILE := {
	"source": "Sketchfab",
	"model": "CC0 American Bullfrog",
	"url": "https://sketchfab.com/3d-models/cc0-american-bullfrog-0850a4b8afc141b88981c4606cf80415",
	"license": "CC0",
	"use": "anatomy and silhouette reference only",
	"runtime_asset_dependency": false,
	"redistributed_model_files": 0,
}
const ATTIRE_IDS := [
	"marsh_runner", "trail_scout", "moon_champion", "firefly_hero",
	"pond_pilot", "rain_ranger", "bug_catcher", "star_jumper", "lily_lifeguard",
]
const ATTIRE_LABELS := {
	"marsh_runner": "Runner Goggles",
	"trail_scout": "Explorer Glasses",
	"moon_champion": "Moon Champion Visor",
	"firefly_hero": "Firefly Hero Goggles",
	"pond_pilot": "Pond Pilot Goggles",
	"rain_ranger": "Rain Ranger Glasses",
	"bug_catcher": "Bug Catcher Shades",
	"star_jumper": "Star Jumper Visor",
	"lily_lifeguard": "Lily Lifeguard Goggles",
}
const ATTIRE_EYEWEAR := {
	"marsh_runner": "sport_goggles",
	"trail_scout": "round_glasses",
	"moon_champion": "moon_visor",
	"firefly_hero": "hero_goggles",
	"pond_pilot": "pilot_goggles",
	"rain_ranger": "rain_glasses",
	"bug_catcher": "bug_shades",
	"star_jumper": "star_visor",
	"lily_lifeguard": "guard_goggles",
}
const ATTIRE_MATERIALS := {
	"marsh_runner": "breathable marsh mesh",
	"trail_scout": "waxed trail canvas",
	"moon_champion": "moonweave athletic satin",
	"firefly_hero": "reinforced firefly knit",
	"pond_pilot": "water-resistant aviator twill",
	"rain_ranger": "soft moonpetal rain shell",
	"bug_catcher": "breathable field ripstop",
	"star_jumper": "luminous star jersey jacquard",
	"lily_lifeguard": "flexible rescue neoprene",
}
const ATTIRE_FINISHES := {
	"marsh_runner": {"finish": "matte breathable knit", "drape": "athletic stretch", "roughness": 0.82, "flex": 0.90},
	"trail_scout": {"finish": "waxed woven canvas", "drape": "structured utility", "roughness": 0.68, "flex": 0.58},
	"moon_champion": {"finish": "soft moonlit satin", "drape": "fluid competition", "roughness": 0.42, "flex": 0.84},
	"firefly_hero": {"finish": "reinforced technical knit", "drape": "supportive hero", "roughness": 0.62, "flex": 0.72},
	"pond_pilot": {"finish": "brushed flight twill", "drape": "trim aviator", "roughness": 0.66, "flex": 0.70},
	"rain_ranger": {"finish": "soft water-shedding shell", "drape": "rain-ready flex", "roughness": 0.54, "flex": 0.82},
	"bug_catcher": {"finish": "breathable grid ripstop", "drape": "field utility", "roughness": 0.74, "flex": 0.68},
	"star_jumper": {"finish": "luminous woven jersey", "drape": "spring competition", "roughness": 0.38, "flex": 0.92},
	"lily_lifeguard": {"finish": "matte rescue neoprene", "drape": "buoyant support", "roughness": 0.58, "flex": 0.76},
}
const ATTIRE_CUTS := {
	"marsh_runner": {"cut": "sleeveless athletic singlet", "sleeve_ratio": 0.22, "hem_drop": 0.25, "structure": 0.18},
	"trail_scout": {"cut": "soft field vest", "sleeve_ratio": 0.48, "hem_drop": 0.52, "structure": 0.68},
	"moon_champion": {"cut": "draped competition jersey", "sleeve_ratio": 0.30, "hem_drop": 0.68, "structure": 0.28},
	"firefly_hero": {"cut": "fitted hero jersey", "sleeve_ratio": 0.40, "hem_drop": 0.38, "structure": 0.52},
	"pond_pilot": {"cut": "streamlined flight jacket", "sleeve_ratio": 0.44, "hem_drop": 0.34, "structure": 0.60},
	"rain_ranger": {"cut": "hood-free rain vest", "sleeve_ratio": 0.35, "hem_drop": 0.58, "structure": 0.36},
	"bug_catcher": {"cut": "pocketed bug-search tunic", "sleeve_ratio": 0.46, "hem_drop": 0.62, "structure": 0.64},
	"star_jumper": {"cut": "spring-fit star jersey", "sleeve_ratio": 0.26, "hem_drop": 0.30, "structure": 0.22},
	"lily_lifeguard": {"cut": "fitted marsh rescue vest", "sleeve_ratio": 0.38, "hem_drop": 0.44, "structure": 0.56},
}
const ATTIRE_FIT_FEATURES: Array[String] = [
	"contoured torso panels",
	"ribbed mouth-clear collar",
	"three-point mouth clearance",
	"cheek and jaw exclusion zone",
	"outfit-specific neckline",
	"articulated shoulder gussets",
	"stitched side seams",
	"fitted waist band",
	"layered eyewear gasket",
	"temple straps and hinges",
	"attire-specific closures",
	"pose-aware cloth folds",
	"joint-mounted sleeves and bracers",
	"soft anatomical armholes",
	"tapered limb tailoring",
	"curved bound hems",
	"garment-specific accessory placement",
	"soft edge finishing",
	"raised fabric edge lighting",
]
const REALISM_FEATURES: Array[String] = [
	"layered skin lighting",
	"dorsolateral folds",
	"visible tympanum",
	"nictitating eye rim",
	"horizontal frog pupils",
	"throat and belly volume",
	"jointed forelimbs",
	"hind-leg muscle contours",
	"webbed fingers and toe pads",
	"mottled skin texture",
	"articulated throat breathing",
	"deterministic eyelid blink",
	"layered cheek and brow volume",
	"integrated shoulder and knee caps",
	"wet skin rim lighting",
	"subsurface belly shading",
	"separated jaw and throat planes",
	"layered corneal highlights",
	"beveled garment volume",
	"pose-aware silhouette lighting",
	"reference-guided cranial wedge",
	"layered labial jaw folds",
	"hindquarter tendon definition",
	"directional wet-skin highlights",
	"volumetric throat sac contour",
	"phone-readable toe webbing",
]

var last_error := ""
var contract_valid := false
var _pose: Dictionary = {}
var _root_joint: Node2D
var _body_joint: Node2D
var _head_joint: Node2D
var _hind_left: Node2D
var _hind_right: Node2D
var _eye_left: Node2D
var _eye_right: Node2D
var _rounded_polygons: Dictionary = {}
var _style := {
	"body_color": Color("4fbd68"),
	"size_scale": 0.92,
	"body_build": "quick",
	"body_proportions": Vector2(0.90, 1.06),
	"tongue_color": Color("ff7ca8"),
	"attire": "marsh_runner",
}

func _ready() -> void:
	contract_valid = validate_contract()

func validate_contract() -> bool:
	last_error = ""
	for path in REQUIRED_NODES:
		var node := get_node_or_null(str(path))
		if node == null:
			last_error = "Missing authored rig node: %s" % str(path)
			contract_valid = false
			return false
		if not node.is_class(str(REQUIRED_NODES[path])):
			last_error = "Invalid authored rig node type at %s" % str(path)
			contract_valid = false
			return false
	_root_joint = get_node("RootJoint") as Node2D
	_body_joint = get_node("RootJoint/BodyJoint") as Node2D
	_head_joint = get_node("RootJoint/HeadJoint") as Node2D
	_hind_left = get_node("RootJoint/HindLeft") as Node2D
	_hind_right = get_node("RootJoint/HindRight") as Node2D
	_eye_left = get_node("RootJoint/HeadJoint/EyeLeft") as Node2D
	_eye_right = get_node("RootJoint/HeadJoint/EyeRight") as Node2D
	_rounded_polygons.clear()
	for path in POLYGON_ORDER:
		var polygon := get_node(str(path)) as Polygon2D
		_rounded_polygons[path] = CharacterSurface.rounded_contour(polygon.polygon)
	contract_valid = true
	return true

func apply_style(style: Dictionary) -> bool:
	if typeof(style.get("body_color")) != TYPE_COLOR or typeof(style.get("tongue_color")) != TYPE_COLOR:
		return false
	var size_scale := float(style.get("size_scale", 1.0))
	var body_proportions := Vector2(style.get("body_proportions", Vector2.ONE))
	var attire := str(style.get("attire", "marsh_runner"))
	if not is_finite(size_scale) or size_scale < 0.88 or size_scale > 1.14:
		return false
	if not is_finite(body_proportions.x) or not is_finite(body_proportions.y) or body_proportions.x < 0.75 or body_proportions.x > 1.30 or body_proportions.y < 0.90 or body_proportions.y > 1.24:
		return false
	if attire not in ATTIRE_IDS:
		return false
	_style = style.duplicate(true)
	return true

func apply_pose(pose: Dictionary, depth_amount: float = 0.0) -> bool:
	if not contract_valid and not validate_contract():
		return false
	if not _valid_pose(pose):
		_neutralize()
		return false
	_pose = pose.duplicate(true)
	var facing := -1.0 if float(pose.facing) < 0.0 else 1.0
	var body_scale := Vector2(pose.body_scale)
	var extension := clampf(float(pose.leg_extension), -1.0, 1.0)
	var squint := clampf(float(pose.eye_squint), 0.0, 1.0)
	var mouth_open := clampf(float(pose.mouth_open), 0.0, 1.0)
	var submerged := clampf(depth_amount, 0.0, 1.0)

	_root_joint.position = Vector2(pose.body_offset)
	_root_joint.rotation = float(pose.tilt)
	var cosmetic_scale := float(_style.size_scale)
	var build_proportions := Vector2(_style.get("body_proportions", Vector2.ONE))
	_root_joint.scale = Vector2(body_scale.x * facing * build_proportions.x, body_scale.y * build_proportions.y) * cosmetic_scale
	_body_joint.rotation = extension * 0.018
	_head_joint.position = Vector2(0.0, -17.0 - maxf(0.0, extension) * 1.5)
	_hind_left.rotation = -0.12 - extension * 0.28
	_hind_right.rotation = 0.12 + extension * 0.28
	_hind_left.position = Vector2(-18.0 - extension * 4.0, 14.0 + extension * 2.0)
	_hind_right.position = Vector2(18.0 + extension * 4.0, 14.0 + extension * 2.0)
	_eye_left.scale = Vector2(1.0, maxf(0.18, 1.0 - squint * 0.82))
	_eye_right.scale = _eye_left.scale
	(get_node("RootJoint/HeadJoint/EyeLeft/Pupil") as Polygon2D).position = Vector2(3.0, squint * 1.5)
	(get_node("RootJoint/HeadJoint/EyeRight/Pupil") as Polygon2D).position = Vector2(3.0, squint * 1.5)

	var mouth := get_node("RootJoint/HeadJoint/MouthCavity") as Polygon2D
	mouth.visible = mouth_open > 0.04
	mouth.scale = Vector2(0.65 + mouth_open * 0.55, 0.25 + mouth_open * 0.95)
	var mouth_line := get_node("RootJoint/HeadJoint/MouthLine") as Line2D
	mouth_line.visible = mouth_open <= 0.04

	var styled_fill := Color(_style.body_color)
	var fill := styled_fill.lerp(UNDERWATER_FILL, submerged)
	var head_fill := styled_fill.lightened(0.12).lerp(UNDERWATER_HEAD, submerged)
	var outline := OUTLINE.lerp(UNDERWATER_OUTLINE, submerged * 0.58)
	(get_node("RootJoint/BodyJoint/Fill") as Polygon2D).color = fill
	(get_node("RootJoint/HeadJoint/Fill") as Polygon2D).color = head_fill
	(get_node("RootJoint/HindLeft/Fill") as Polygon2D).color = fill.darkened(0.04)
	(get_node("RootJoint/HindRight/Fill") as Polygon2D).color = fill.darkened(0.04)
	(get_node("RootJoint/BodyJoint/Accent") as Polygon2D).color = Color(pose.accent)
	for path in LINE_ORDER:
		(get_node(str(path)) as Line2D).default_color = outline
	(get_node("RootJoint/BodyJoint/Outline") as Polygon2D).color = outline
	(get_node("RootJoint/HeadJoint/Outline") as Polygon2D).color = outline
	(get_node("RootJoint/HeadJoint/EyeLeft/Outline") as Polygon2D).color = outline
	(get_node("RootJoint/HeadJoint/EyeRight/Outline") as Polygon2D).color = outline
	return true

func render_to(canvas: Node2D, world_position: Vector2, presentation_time_seconds: float = 0.0, reduced_motion_override: bool = false) -> bool:
	if not contract_valid:
		_draw_safe_fallback(canvas, world_position)
		return false
	_draw_ground_shadow(canvas, world_position)
	_draw_attire_back(canvas, world_position)
	for path in POLYGON_ORDER:
		var polygon := get_node(str(path)) as Polygon2D
		if not polygon.visible:
			continue
		var points := _transformed_points(polygon, _rounded_polygons[path], world_position)
		if points.size() >= 3:
			if str(path).ends_with("/Fill") or str(path).ends_with("/Belly"):
				CharacterSurface.draw_volume(canvas, points, polygon.color, 0.55)
			else:
				canvas.draw_colored_polygon(points, polygon.color)
	_draw_skin_dimension(canvas, world_position, presentation_time_seconds, reduced_motion_override)
	_draw_reference_anatomy_finish(canvas, world_position)
	_draw_body_build_finish(canvas, world_position)
	_draw_front_limbs(canvas, world_position)
	for path in LINE_ORDER:
		if str(path) in ["RootJoint/FrontLeft", "RootJoint/FrontRight"] or "/Hind" in str(path):
			continue
		var line := get_node(str(path)) as Line2D
		if not line.visible:
			continue
		var points := _transformed_points(line, line.points, world_position)
		if points.size() >= 2:
			var scale_width := maxf(0.5, absf(_root_joint.scale.x) + absf(_root_joint.scale.y)) * 0.5
			canvas.draw_polyline(points, line.default_color, line.width * scale_width, true)
	_draw_webbed_feet(canvas, world_position)
	_draw_sport_gear(canvas, world_position)
	_draw_face_finish(canvas, world_position, presentation_time_seconds, reduced_motion_override)
	return true

func _draw_body_build_finish(canvas: Node2D, world_position: Vector2) -> void:
	var build := str(_style.get("body_build", "quick"))
	var body_color := Color(_style.body_color)
	var highlight := body_color.lightened(0.32)
	var shadow := body_color.darkened(0.38)
	match build:
		"power", "strong":
			for side in [-1.0, 1.0]:
				_draw_transformed_ellipse(canvas, _body_joint, Vector2(18.0 * side, -7.0), Vector2(8.5, 11.5), Color(highlight if side < 0.0 else shadow, 0.30), world_position)
				var thigh := world_position + _node_point(_hind_left if side < 0.0 else _hind_right, Vector2(0.0, 5.0))
				canvas.draw_arc(thigh, 10.0 * float(_style.size_scale), 3.4, 5.9, 12, Color(highlight, 0.48), 2.2, true)
			canvas.draw_arc(world_position + _node_point(_body_joint, Vector2(0.0, 3.0)), 21.0, 3.45, 5.98, 18, Color(shadow, 0.40), 2.0, true)
		"pocket_hopper":
			_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 0.0), Vector2(27.0, 19.0), Color(highlight, 0.10), world_position)
			canvas.draw_arc(world_position + _node_point(_body_joint, Vector2(0.0, 8.0)), 14.0, 0.2, PI - 0.2, 14, Color(highlight, 0.38), 1.8, true)
		"springy", "swift":
			for limb in [_hind_left, _hind_right]:
				var knee := world_position + _node_point(limb, Vector2(0.0, 10.0))
				canvas.draw_arc(knee, 8.5, 3.25, 6.05, 12, Color(highlight, 0.50), 2.0, true)
			canvas.draw_line(world_position + _node_point(_body_joint, Vector2(-9.0, 17.0)), world_position + _node_point(_body_joint, Vector2(9.0, 17.0)), Color(shadow, 0.34), 2.0, true)
		"trail_fit", "classic":
			canvas.draw_arc(world_position + _node_point(_body_joint, Vector2(0.0, 4.0)), 18.0, 3.35, 6.07, 18, Color(highlight, 0.34), 1.8, true)

func _draw_webbed_feet(canvas: Node2D, world_position: Vector2) -> void:
	var fill := (get_node("RootJoint/BodyJoint/Fill") as Polygon2D).color
	for side: float in [-1.0, 1.0]:
		var hind := _hind_left if side < 0 else _hind_right
		var foot := PackedVector2Array([Vector2(29 * side, 20), Vector2(41 * side, 27), Vector2(37 * side, 29), Vector2(39 * side, 34), Vector2(33 * side, 32), Vector2(29 * side, 35), Vector2(27 * side, 27)])
		var points := _transformed_points(hind, CharacterSurface.rounded_contour(foot), world_position)
		CharacterSurface.draw_volume(canvas, points, fill, 0.4)
		canvas.draw_polyline(_closed_points(points), Color(fill.darkened(0.58), 0.82), 1.2 * float(_style.size_scale), true)
		for tip in [Vector2(41 * side, 27), Vector2(39 * side, 34), Vector2(29 * side, 35)]:
			var root_point := world_position + _node_point(hind, Vector2(30 * side, 23))
			var tip_point := world_position + _node_point(hind, tip)
			canvas.draw_line(root_point, tip_point, Color(fill.lightened(0.35), 0.55), 0.9 * float(_style.size_scale), true)
			canvas.draw_circle(tip_point, 1.6 * float(_style.size_scale), fill.lightened(0.36))

func style_snapshot() -> Dictionary:
	return _style.duplicate(true)

func attire_snapshot() -> Dictionary:
	if not contract_valid:
		return {"valid": false, "error": last_error}
	var attire := str(_style.attire)
	var left_anchor := _node_point(_head_joint, Vector2(-12.0, -21.0))
	var right_anchor := _node_point(_head_joint, Vector2(12.0, -21.0))
	var mouth_lower_anchor := _node_point(_head_joint, Vector2(0.0, 13.0))
	var mouth_left_anchor := _node_point(_head_joint, Vector2(-10.0, 8.0))
	var mouth_right_anchor := _node_point(_head_joint, Vector2(10.0, 8.0))
	var neckline := _neckline_local_points(attire)
	var collar_left_anchor := _node_point(_body_joint, neckline[0])
	var collar_anchor := _node_point(_body_joint, neckline[2])
	var collar_right_anchor := _node_point(_body_joint, neckline[4])
	var mouth_clearance := minf(
		collar_anchor.y - mouth_lower_anchor.y,
		minf(collar_left_anchor.y - mouth_left_anchor.y, collar_right_anchor.y - mouth_right_anchor.y)
	)
	var finish: Dictionary = ATTIRE_FINISHES.get(attire, {})
	var cut: Dictionary = ATTIRE_CUTS.get(attire, {})
	var motion := attire_motion_snapshot()
	return {
		"valid": true,
		"attire": attire,
		"label": str(ATTIRE_LABELS.get(attire, "Unknown Gear")),
		"eyewear": str(ATTIRE_EYEWEAR.get(attire, "none")),
		"material": str(ATTIRE_MATERIALS.get(attire, "unknown")),
		"finish": str(finish.get("finish", "unknown")),
		"drape": str(finish.get("drape", "unknown")),
		"roughness": float(finish.get("roughness", 1.0)),
		"flex": float(finish.get("flex", 0.0)),
		"cut": str(cut.get("cut", "unknown")),
		"sleeve_ratio": float(cut.get("sleeve_ratio", 0.0)),
		"hem_drop": float(cut.get("hem_drop", 0.0)),
		"structure": float(cut.get("structure", 0.0)),
		"motion": motion,
		"fit_features": ATTIRE_FIT_FEATURES.duplicate(),
		"fabric_layers": 18,
		"eyewear_depth_layers": 5,
		"tailored_panels": 9,
		"functional_seams": true,
		"limb_fit": true,
		"anatomical_openings": 3,
		"soft_edge_px": 1.0 + float(cut.get("structure", 0.0)) * 0.8,
		"left_eye_anchor": left_anchor,
		"right_eye_anchor": right_anchor,
		"eye_span": left_anchor.distance_to(right_anchor),
		"mouth_lower_anchor": mouth_lower_anchor,
		"mouth_left_anchor": mouth_left_anchor,
		"mouth_right_anchor": mouth_right_anchor,
		"collar_left_anchor": collar_left_anchor,
		"collar_anchor": collar_anchor,
		"collar_right_anchor": collar_right_anchor,
		"mouth_clearance_pixels": mouth_clearance,
		"jaw_exclusion_zone_pixels": mouth_clearance,
		"neckline_point_count": neckline.size(),
		"body_anchor": _node_point(_body_joint, Vector2(0.0, 3.0)),
		"child_readable": attire in ATTIRE_IDS,
		"presentation_only": true,
		"reference_guided": true,
		"runtime_asset_dependency": false,
		"mouth_overlay_pixels": 0.0,
		"collision_mutation": false,
		"save_fields": 0,
	}

func attire_motion_snapshot() -> Dictionary:
	var body_scale := Vector2(_pose.get("body_scale", Vector2.ONE))
	var leg_extension := float(_pose.get("leg_extension", 0.0))
	var tilt := float(_pose.get("tilt", 0.0))
	var reduced_motion := bool(_pose.get("reduced_motion", false))
	var stretch := clampf((body_scale.y - 1.0) * 1.8 + leg_extension * 0.18, -0.32, 0.42)
	var compression := clampf((1.0 - body_scale.y) * 2.0, 0.0, 0.42)
	var fold_bias := clampf(tilt * 0.28, -0.22, 0.22)
	var secondary_scale := 0.18 if reduced_motion else 1.0
	return {
		"stretch": stretch,
		"compression": compression,
		"fold_bias": fold_bias,
		"secondary_scale": secondary_scale,
		"reduced_motion": reduced_motion,
		"presentation_only": true,
		"collision_mutation": false,
		"save_fields": 0,
	}

func realism_snapshot() -> Dictionary:
	return {
		"features": REALISM_FEATURES.duplicate(),
		"feature_count": REALISM_FEATURES.size(),
		"surface_model": "layered vector volume",
		"volume_layers": 18,
		"reference": ART_REFERENCE_PROFILE.duplicate(true),
		"integrated_joint_caps": true,
		"facial_depth": true,
		"presentation_only": true,
		"phone_safe_vector_rig": true,
		"collision_mutation": false,
		"save_fields": 0,
	}

func reference_profile_snapshot() -> Dictionary:
	return ART_REFERENCE_PROFILE.duplicate(true)

func micro_motion_snapshot(presentation_time_seconds: float, reduced_motion_override: bool = false) -> Dictionary:
	var safe_time := maxf(0.0, presentation_time_seconds) if is_finite(presentation_time_seconds) else 0.0
	var motion_scale := 0.12 if reduced_motion_override else 1.0
	var blink_cycle := fmod(safe_time, 4.6)
	var blink := clampf(1.0 - absf(blink_cycle - 0.12) / 0.12, 0.0, 1.0) * motion_scale
	return {
		"breath": sin(safe_time * 1.7) * 1.25 * motion_scale,
		"throat": (sin(safe_time * 1.7 - 0.35) + 1.0) * 0.75 * motion_scale,
		"blink": blink,
		"reduced_motion": reduced_motion_override,
		"presentation_only": true,
		"collision_mutation": false,
		"save_fields": 0,
	}

func _draw_ground_shadow(canvas: Node2D, world_position: Vector2) -> void:
	var contacts := ground_contacts()
	var center := world_position + (contacts[0] + contacts[1]) * 0.5 + Vector2(0.0, 2.5)
	var width := 35.0 * float(_style.size_scale)
	canvas.draw_colored_polygon(_ellipse_points(center, Vector2(width, 8.0), 22), Color(0.005, 0.03, 0.04, 0.38))
	canvas.draw_colored_polygon(_ellipse_points(center + Vector2(-4.0,-1.0), Vector2(width * 0.67, 4.2), 20), Color(0.12, 0.42, 0.31, 0.16))
	canvas.draw_polyline(_closed_points(_ellipse_points(center, Vector2(width - 4.0, 5.0), 22)), Color(0.36, 0.93, 0.72, 0.12), 1.4, true)
	for contact in contacts:
		canvas.draw_arc(world_position + contact, 5.2 * float(_style.size_scale), 0.05, PI - 0.05, 10, Color(0.66,0.96,0.74,0.22), 1.2, true)

func _draw_attire_back(canvas: Node2D, world_position: Vector2) -> void:
	if str(_style.attire) != "firefly_hero":
		return
	var motion := attire_motion_snapshot()
	var sway := float(motion.fold_bias) * 12.0 * float(motion.secondary_scale)
	var drop := float(motion.stretch) * 3.0 * float(motion.secondary_scale)
	var cape := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-16.0, -3.0), Vector2(-24.0, 1.0), Vector2(-28.0+sway, 9.0),
		Vector2(-27.0+sway, 16.0+drop), Vector2(-23.0+sway*0.8, 21.0+drop),
		Vector2(-18.0+sway*0.55, 18.0+drop), Vector2(-13.0+sway*0.3, 21.0+drop),
		Vector2(-9.0, 13.0), Vector2(-7.0, -1.0),
	]), world_position)
	canvas.draw_colored_polygon(cape, Color("742f48"))
	var cape_inner := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-15.0, -1.5), Vector2(-22.0, 2.5), Vector2(-25.0+sway*0.8, 9.5),
		Vector2(-24.0+sway*0.8, 15.0+drop), Vector2(-20.5+sway*0.6, 18.0+drop),
		Vector2(-17.0+sway*0.35, 15.0+drop), Vector2(-12.0, 17.0), Vector2(-9.0, 0.5),
	]), world_position)
	canvas.draw_colored_polygon(cape_inner, Color("d85265"))
	canvas.draw_polyline(_closed_points(cape), Color("ffd36a"), 1.25 * float(_style.size_scale), true)
	var cape_seam := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-15.0, -0.5), Vector2(-19.0, 4.0), Vector2(-20.0+sway*0.45, 11.0), Vector2(-18.0+sway*0.35, 17.0+drop),
	]), world_position)
	canvas.draw_polyline(cape_seam, Color(1.0, 0.82, 0.40, 0.56), 0.85 * float(_style.size_scale), true)

func _draw_skin_dimension(canvas: Node2D, world_position: Vector2, presentation_time_seconds: float, reduced_motion_override: bool) -> void:
	var body_color := (get_node("RootJoint/BodyJoint/Fill") as Polygon2D).color
	var head_color := (get_node("RootJoint/HeadJoint/Fill") as Polygon2D).color
	var highlight := head_color.lightened(0.28)
	var shadow := body_color.darkened(0.32)
	var micro := micro_motion_snapshot(presentation_time_seconds, reduced_motion_override)
	var breath := float(micro.breath)
	var throat := float(micro.throat)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(9.0, 7.0), Vector2(12.0, 17.0), Color(shadow, 0.34), world_position)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(-9.0, -9.0), Vector2(8.0, 5.0), Color(highlight, 0.34), world_position)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(-5.0,-4.0), Vector2(17.0,22.0), Color(body_color.lightened(0.20),0.16), world_position)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(5.0,11.0), Vector2(17.0,12.0), Color(shadow,0.18), world_position)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(0.0, 13.0+breath*0.18), Vector2(13.0+breath*0.25, 11.0+breath*0.28), Color(body_color.lightened(0.30), 0.16), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 9.0), Vector2(22.0, 8.0), Color(shadow, 0.20), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(-8.0, -12.0), Vector2(10.0, 5.0), Color(highlight, 0.26), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(-18.0,3.0), Vector2(10.0,9.0), Color(head_color.lightened(0.20),0.24), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(18.0,4.0), Vector2(10.0,9.0), Color(shadow,0.18), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 12.0+throat*0.20), Vector2(17.0+throat*0.32, 6.5+throat*0.38), Color(head_color.lightened(0.34), 0.18), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 15.0+throat*0.24), Vector2(11.0+throat*0.25, 3.2+throat*0.30), Color(body_color.lightened(0.34),0.18), world_position)
	for ear_x in [-23.0, 23.0]:
		var tympanum := world_position + _node_point(_head_joint, Vector2(ear_x, 1.5))
		canvas.draw_circle(tympanum, 5.2 * float(_style.size_scale), Color(shadow, 0.30))
		canvas.draw_arc(tympanum, 4.0 * float(_style.size_scale), 0.25, TAU - 0.25, 16, Color(highlight, 0.42), 1.3 * float(_style.size_scale), true)
	var left_fold := _transformed_points(_body_joint, PackedVector2Array([Vector2(-19,-17),Vector2(-18,-5),Vector2(-15,9),Vector2(-11,19)]), world_position)
	var right_fold := _transformed_points(_body_joint, PackedVector2Array([Vector2(19,-17),Vector2(18,-5),Vector2(15,9),Vector2(11,19)]), world_position)
	canvas.draw_polyline(left_fold, Color(highlight,0.34), 1.7 * float(_style.size_scale), true)
	canvas.draw_polyline(right_fold, Color(shadow,0.28), 1.7 * float(_style.size_scale), true)
	for spot in [Vector2(-19.0, 1.0), Vector2(18.0, -1.0), Vector2(-10.0, 11.0), Vector2(11.0, 12.0)]:
		_draw_transformed_ellipse(canvas, _head_joint, spot, Vector2(2.2, 1.5), Color(shadow, 0.30), world_position)
	for spot in [Vector2(-13.0,-8.0),Vector2(11.0,-13.0),Vector2(-7.0,17.0),Vector2(14.0,9.0)]:
		_draw_transformed_ellipse(canvas, _body_joint, spot, Vector2(2.0,1.2), Color(shadow,0.22), world_position)
	for node in [_hind_left, _hind_right]:
		var side := -1.0 if node == _hind_left else 1.0
		_draw_transformed_ellipse(canvas,node,Vector2(side*15.0,6.0),Vector2(8.0,7.0),Color(shadow,0.38),world_position)
		_draw_transformed_ellipse(canvas,node,Vector2(side*16.5,4.5),Vector2(5.0,4.0),Color(highlight,0.32),world_position)
		var muscle := _transformed_points(node, PackedVector2Array([Vector2(side*2,-3),Vector2(side*17,1),Vector2(side*29,12)]), world_position)
		canvas.draw_polyline(muscle, Color(highlight, 0.48), 2.2 * float(_style.size_scale), true)
		var lower_muscle := _transformed_points(node, PackedVector2Array([Vector2(side*27,13),Vector2(side*32,19),Vector2(side*31,25)]), world_position)
		canvas.draw_polyline(lower_muscle, Color(shadow,0.34), 1.5 * float(_style.size_scale), true)

func _draw_reference_anatomy_finish(canvas: Node2D, world_position: Vector2) -> void:
	# Anatomical planes are derived from a commercial-compatible CC0 bullfrog
	# reference, then rebuilt as original phone-safe vector geometry. They add
	# depth without importing a remote model or changing the authored joints.
	var scale_width := float(_style.size_scale)
	var body_color := (get_node("RootJoint/BodyJoint/Fill") as Polygon2D).color
	var head_color := (get_node("RootJoint/HeadJoint/Fill") as Polygon2D).color
	var outline := (get_node("RootJoint/HeadJoint/MouthLine") as Line2D).default_color
	var cranial_ridge := _transformed_points(_head_joint, PackedVector2Array([
		Vector2(-24.0,-10.0),Vector2(-14.0,-16.0),Vector2(0.0,-18.5),
		Vector2(14.0,-16.0),Vector2(24.0,-10.0),
	]), world_position)
	canvas.draw_polyline(cranial_ridge, Color(head_color.lightened(0.40),0.52), 2.2 * scale_width, true)
	var nasal_plane := _transformed_points(_head_joint, PackedVector2Array([
		Vector2(-12.0,-8.0),Vector2(0.0,-11.0),Vector2(12.0,-8.0),Vector2(8.0,-1.5),Vector2(0.0,1.0),Vector2(-8.0,-1.5),
	]), world_position)
	canvas.draw_colored_polygon(nasal_plane, Color(head_color.lightened(0.26),0.13))
	canvas.draw_polyline(_closed_points(nasal_plane), Color(head_color.lightened(0.42),0.24), 0.9 * scale_width, true)
	var upper_jaw := _transformed_points(_head_joint, PackedVector2Array([
		Vector2(-22.0,6.0),Vector2(-12.0,9.0),Vector2(0.0,10.2),Vector2(12.0,9.0),Vector2(22.0,6.0),
	]), world_position)
	canvas.draw_polyline(upper_jaw, Color(head_color.lightened(0.34),0.48), 1.6 * scale_width, true)
	var lower_jaw := _transformed_points(_head_joint, PackedVector2Array([
		Vector2(-20.0,11.0),Vector2(-11.0,16.0),Vector2(0.0,18.2),Vector2(11.0,16.0),Vector2(20.0,11.0),
	]), world_position)
	canvas.draw_polyline(lower_jaw, Color(outline,0.30), 1.45 * scale_width, true)
	var back_ridge := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-18.0,-15.0),Vector2(-9.0,-20.0),Vector2(0.0,-21.5),Vector2(9.0,-20.0),Vector2(18.0,-15.0),
	]), world_position)
	canvas.draw_polyline(back_ridge, Color(body_color.lightened(0.43),0.48), 2.0 * scale_width, true)
	for side: float in [-1.0,1.0]:
		var flank_tendon := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(side*17.0,-11.0),Vector2(side*20.5,0.0),Vector2(side*18.0,12.0),
		]), world_position)
		canvas.draw_polyline(flank_tendon, Color(body_color.darkened(0.36),0.25), 1.4 * scale_width, true)
		var hind := _hind_left if side < 0.0 else _hind_right
		var tendon := _transformed_points(hind, PackedVector2Array([
			Vector2(side*5.0,-1.0),Vector2(side*17.0,5.0),Vector2(side*27.0,16.0),Vector2(side*30.0,25.0),
		]), world_position)
		canvas.draw_polyline(tendon, Color(body_color.lightened(0.40),0.44), 1.8 * scale_width, true)
	for glint in [Vector2(-15.0,-9.0),Vector2(-6.0,-13.0),Vector2(10.0,-8.0)]:
		_draw_transformed_ellipse(canvas,_head_joint,glint,Vector2(2.6,1.1),Color(0.92,1.0,0.86,0.48),world_position)

func _draw_front_limbs(canvas: Node2D, world_position: Vector2) -> void:
	var fill := (get_node("RootJoint/BodyJoint/Fill") as Polygon2D).color
	var outline := (get_node("RootJoint/FrontLeft") as Line2D).default_color
	for path in ["RootJoint/FrontLeft", "RootJoint/FrontRight"]:
		var limb := get_node(path) as Line2D
		var points := _transformed_points(limb, limb.points, world_position)
		var width_scale := float(_style.size_scale)
		canvas.draw_polyline(points, outline, 9.0 * width_scale, true)
		canvas.draw_polyline(points, fill.lightened(0.05), 5.2 * width_scale, true)
		var elbow := points[1]
		canvas.draw_circle(elbow, 5.0 * width_scale, outline)
		canvas.draw_circle(elbow - Vector2(1.2,1.2), 3.0 * width_scale, fill.lightened(0.16))
		canvas.draw_arc(elbow-Vector2(0.8,0.9),3.6*width_scale,3.35,6.0,10,Color(fill.lightened(0.42),0.64),1.2*width_scale,true)
		var hand := points[points.size() - 1]
		canvas.draw_colored_polygon(_ellipse_points(hand, Vector2(6.0, 4.0) * width_scale, 14), fill.lightened(0.10))
		canvas.draw_polyline(_closed_points(_ellipse_points(hand, Vector2(6.0, 4.0) * width_scale, 14)), outline, 1.5 * width_scale, true)
		var forward := (hand - points[points.size() - 2]).normalized()
		var sideways := Vector2(-forward.y, forward.x)
		var finger_tips := PackedVector2Array()
		for spread: float in [-1.0, 0.0, 1.0]:
			var tip: Vector2 = hand + forward * (7.0 + (1.0 - absf(spread)) * 2.0) * width_scale + sideways * spread * 5.0 * width_scale
			finger_tips.append(tip)
			canvas.draw_line(hand, tip, fill.lightened(0.18), 2.8 * width_scale, true)
			canvas.draw_circle(tip, 2.0 * width_scale, Color("b9e67d"))
		canvas.draw_colored_polygon(PackedVector2Array([hand,finger_tips[0],finger_tips[1],finger_tips[2]]), Color(fill.lightened(0.22),0.28))

func _draw_face_finish(canvas: Node2D, world_position: Vector2, presentation_time_seconds: float, reduced_motion_override: bool) -> void:
	var head_color := (get_node("RootJoint/HeadJoint/Fill") as Polygon2D).color
	var outline := (get_node("RootJoint/HeadJoint/MouthLine") as Line2D).default_color
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 13.0), Vector2(14.0, 3.2), Color(head_color.lightened(0.34), 0.24), world_position)
	_draw_transformed_ellipse(canvas,_head_joint,Vector2(-14.0,-17.0),Vector2(9.0,4.2),Color(head_color.lightened(0.30),0.28),world_position)
	_draw_transformed_ellipse(canvas,_head_joint,Vector2(14.0,-17.0),Vector2(9.0,4.2),Color(head_color.darkened(0.18),0.18),world_position)
	for eye in [_eye_left, _eye_right]:
		var iris_center := world_position + _node_point(eye, Vector2(2.0, 0.0))
		canvas.draw_circle(iris_center, 5.2 * float(_style.size_scale), Color("a6c95e"))
		canvas.draw_arc(iris_center, 4.8 * float(_style.size_scale), 0.0, TAU, 18, Color("456d35"), 1.5 * float(_style.size_scale), true)
		canvas.draw_line(iris_center + Vector2(-3.6,0), iris_center + Vector2(3.6,0), Color("13241d"), 2.2 * float(_style.size_scale), true)
		canvas.draw_arc(iris_center + Vector2(0,1.2), 5.8 * float(_style.size_scale), 0.18, PI - 0.18, 14, Color(0.78,0.94,0.74,0.42), 1.0 * float(_style.size_scale), true)
		var glint := world_position + _node_point(eye, Vector2(-1.0, -3.0))
		canvas.draw_circle(glint, 1.8 * float(_style.size_scale), Color(1.0, 1.0, 0.92, 0.92))
		var blink := float(micro_motion_snapshot(presentation_time_seconds,reduced_motion_override).blink)
		if blink > 0.02:
			var eyelid_center := world_position + _node_point(eye,Vector2(0.0,-1.0+blink*3.2))
			canvas.draw_line(eyelid_center+Vector2(-6.0,0.0),eyelid_center+Vector2(6.0,0.0),Color(head_color.darkened(0.18),0.86),1.4+blink*2.2,true)
	for nostril_x in [-5.0,5.0]:
		var nostril := world_position + _node_point(_head_joint, Vector2(nostril_x,-0.5))
		canvas.draw_circle(nostril,1.5 * float(_style.size_scale),Color(outline,0.72))
		canvas.draw_circle(nostril+Vector2(-0.4,-0.5),0.55 * float(_style.size_scale),Color(0.86,1.0,0.82,0.52))
	var cheek_color := Color(Color("f0a37f"), 0.28)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(-20.0, 7.0), Vector2(4.0, 2.3), cheek_color, world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(20.0, 7.0), Vector2(4.0, 2.3), cheek_color, world_position)
	# A lit lower-jaw plane and a dark throat crease keep Fred's mouth readable
	# above every outfit, including compressed landing and damage poses.
	var jaw_plane := _transformed_points(_head_joint, PackedVector2Array([
		Vector2(-20.0, 11.0), Vector2(-11.0, 16.5), Vector2(0.0, 19.5),
		Vector2(11.0, 16.5), Vector2(20.0, 11.0),
	]), world_position)
	canvas.draw_polyline(jaw_plane, Color(head_color.lightened(0.34), 0.66), 2.2 * float(_style.size_scale), true)
	var throat_crease := _transformed_points(_head_joint, PackedVector2Array([
		Vector2(-13.0, 18.0), Vector2(0.0, 20.5), Vector2(13.0, 18.0),
	]), world_position)
	canvas.draw_polyline(throat_crease, Color(outline, 0.34), 1.25 * float(_style.size_scale), true)
	var mouth := get_node("RootJoint/HeadJoint/MouthCavity") as Polygon2D
	if mouth.visible:
		var mouth_points := _transformed_points(mouth, mouth.polygon, world_position)
		canvas.draw_colored_polygon(mouth_points, mouth.color)
		canvas.draw_polyline(_closed_points(mouth_points), outline, 1.8 * float(_style.size_scale), true)
	else:
		var mouth_line := get_node("RootJoint/HeadJoint/MouthLine") as Line2D
		var line_points := _transformed_points(mouth_line, mouth_line.points, world_position)
		canvas.draw_polyline(line_points, outline, 2.7 * float(_style.size_scale), true)
	var left_corner := world_position + _node_point(_head_joint, Vector2(-11.0, 5.0))
	var right_corner := world_position + _node_point(_head_joint, Vector2(11.0, 5.0))
	canvas.draw_circle(left_corner, 1.6 * float(_style.size_scale), outline)
	canvas.draw_circle(right_corner, 1.6 * float(_style.size_scale), outline)

func _attire_palette(attire: String) -> Dictionary:
	match attire:
		"trail_scout":
			return {"fabric": Color("8b5a32"), "shadow": Color("4a301f"), "panel": Color("b77a43"), "trim": Color("f4d6a4"), "accent": Color("d95f4b"), "lens": Color(0.82, 0.95, 0.88, 0.22), "eyewear": "round_glasses"}
		"moon_champion":
			return {"fabric": Color("5547a9"), "shadow": Color("30275f"), "panel": Color("7567cf"), "trim": Color("ffe184"), "accent": Color("e7b94f"), "lens": Color(0.64, 0.52, 1.0, 0.34), "eyewear": "moon_visor"}
		"firefly_hero":
			return {"fabric": Color("162b4a"), "shadow": Color("0a1729"), "panel": Color("27496a"), "trim": Color("dfff68"), "accent": Color("d85265"), "lens": Color(0.76, 1.0, 0.42, 0.32), "eyewear": "hero_goggles"}
		"pond_pilot":
			return {"fabric": Color("365a7a"), "shadow": Color("172c42"), "panel": Color("3d8790"), "trim": Color("ffd36a"), "accent": Color("ef8b3f"), "lens": Color(0.55, 0.88, 1.0, 0.30), "eyewear": "pilot_goggles"}
		"rain_ranger":
			return {"fabric": Color("dca62d"), "shadow": Color("73541b"), "panel": Color("f0cc55"), "trim": Color("fff3c1"), "accent": Color("2d7da6"), "lens": Color(0.58, 0.88, 1.0, 0.25), "eyewear": "rain_glasses"}
		"bug_catcher":
			return {"fabric": Color("486b3d"), "shadow": Color("263c24"), "panel": Color("79945a"), "trim": Color("f0d39a"), "accent": Color("d95e45"), "lens": Color(1.0, 0.72, 0.28, 0.26), "eyewear": "bug_shades"}
		"star_jumper":
			return {"fabric": Color("3d2d78"), "shadow": Color("211843"), "panel": Color("705bc1"), "trim": Color("74e6ed"), "accent": Color("ff78b7"), "lens": Color(0.72, 0.55, 1.0, 0.32), "eyewear": "star_visor"}
		"lily_lifeguard":
			return {"fabric": Color("d9474d"), "shadow": Color("74252e"), "panel": Color("ef6a61"), "trim": Color("fff6df"), "accent": Color("49c7d1"), "lens": Color(0.70, 0.96, 1.0, 0.28), "eyewear": "guard_goggles"}
		_:
			return {"fabric": Color("087f7a"), "shadow": Color("064946"), "panel": Color("10aaa0"), "trim": Color("f5d35f"), "accent": Color("f0a13a"), "lens": Color(0.55, 0.92, 1.0, 0.30), "eyewear": "sport_goggles"}

func _neckline_local_points(attire: String) -> PackedVector2Array:
	# The left/center/right anchors deliberately sit below the actual mouth
	# corners. Each cut has a distinct silhouette while sharing a generous
	# five-point jaw exclusion zone.
	match attire:
		"trail_scout":
			return PackedVector2Array([
				Vector2(-9.0, -0.5), Vector2(-6.5, 1.5), Vector2(0.0, 9.0),
				Vector2(6.5, 1.5), Vector2(9.0, -0.5),
			])
		"moon_champion":
			return PackedVector2Array([
				Vector2(-9.0, 0.0), Vector2(-5.5, 2.5), Vector2(0.0, 7.5),
				Vector2(5.5, 2.5), Vector2(9.0, 0.0),
			])
		"firefly_hero":
			return PackedVector2Array([
				Vector2(-8.5, -0.5), Vector2(-5.0, 2.0), Vector2(0.0, 8.0),
				Vector2(5.0, 2.0), Vector2(8.5, -0.5),
			])
		"pond_pilot":
			return PackedVector2Array([
				Vector2(-9.0, -0.8), Vector2(-6.0, 2.0), Vector2(0.0, 8.8),
				Vector2(6.0, 2.0), Vector2(9.0, -0.8),
			])
		"rain_ranger":
			return PackedVector2Array([
				Vector2(-8.8, -0.2), Vector2(-6.8, 2.8), Vector2(0.0, 9.2),
				Vector2(6.8, 2.8), Vector2(8.8, -0.2),
			])
		"bug_catcher":
			return PackedVector2Array([
				Vector2(-9.2, 0.0), Vector2(-5.8, 3.0), Vector2(0.0, 8.4),
				Vector2(5.8, 3.0), Vector2(9.2, 0.0),
			])
		"star_jumper":
			return PackedVector2Array([
				Vector2(-8.2, -1.0), Vector2(-4.8, 1.8), Vector2(0.0, 7.8),
				Vector2(4.8, 1.8), Vector2(8.2, -1.0),
			])
		"lily_lifeguard":
			return PackedVector2Array([
				Vector2(-9.0, -0.4), Vector2(-6.2, 2.4), Vector2(0.0, 8.6),
				Vector2(6.2, 2.4), Vector2(9.0, -0.4),
			])
		_:
			return PackedVector2Array([
				Vector2(-8.0, -1.0), Vector2(-5.0, 2.0), Vector2(0.0, 8.5),
				Vector2(5.0, 2.0), Vector2(8.0, -1.0),
			])

func _draw_sport_gear(canvas: Node2D, world_position: Vector2) -> void:
	var attire := str(_style.attire)
	var palette := _attire_palette(attire)
	var fabric: Color = palette.fabric
	var shadow: Color = palette.shadow
	var panel: Color = palette.panel
	var trim: Color = palette.trim
	var accent: Color = palette.accent
	var lens: Color = palette.lens
	var eyewear := str(palette.eyewear)
	var scale_width := float(_style.size_scale)
	var motion := attire_motion_snapshot()
	var stretch := float(motion.stretch)
	var compression := float(motion.compression)
	var fold_bias := float(motion.fold_bias)
	var cut: Dictionary = ATTIRE_CUTS.get(attire, {})
	var hem_drop := float(cut.get("hem_drop", 0.0))
	var structure := float(cut.get("structure", 0.0))
	var edge_width := 1.0 + structure * 0.8
	var hem_y := 21.0 + hem_drop * 2.0 + stretch * 4.0 - compression * 2.0
	var neckline := _neckline_local_points(attire)

	# The garment starts below the jaw exclusion zone. A recessed silhouette,
	# seven fitted layers and raised edge light create cloth volume instead of a
	# flat paper cutout while remaining inexpensive vector drawing for phones.
	var under_panel := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-18.5,1.0),Vector2(-17.2,-1.0),Vector2(-13.5,-2.5),Vector2(-8,-2.0),Vector2(0,6.5),Vector2(8,-2.0),
		Vector2(13.5,-2.5),Vector2(17.2,-1.0),Vector2(18.5,1.0),Vector2(18.2,6),Vector2(16.2,15.5),
		Vector2(10.5,hem_y),Vector2(5.5,hem_y+1.4),Vector2(0,hem_y+1.8),Vector2(-5.5,hem_y+1.4),Vector2(-10.5,hem_y),Vector2(-16.2,15.5),Vector2(-18.2,6),
	]), world_position)
	var garment_depth := PackedVector2Array()
	for point: Vector2 in under_panel:
		garment_depth.append(point + Vector2(1.4, 2.0) * scale_width)
	canvas.draw_colored_polygon(garment_depth, Color(shadow.darkened(0.45), 0.50))
	CharacterSurface.draw_volume(canvas, under_panel, fabric, 1.0 - float(ATTIRE_FINISHES[attire].roughness))
	canvas.draw_polyline(_closed_points(under_panel), Color(shadow.darkened(0.30),0.78), edge_width * scale_width, true)
	var center_panel := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-7,0.0),Vector2(0,7.0),Vector2(7,0.0),Vector2(8.5,7),Vector2(9.5,17),Vector2(5,hem_y),Vector2(0,hem_y+1.2),Vector2(-5,hem_y),Vector2(-9.5,17),Vector2(-8.5,7),
	]), world_position)
	var left_panel := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-18.5,1.0),Vector2(-16.5,-1.0),Vector2(-13,-2.5),Vector2(-8,-2.0),Vector2(-7,0.0),Vector2(-8.5,7),Vector2(-9.5,17),Vector2(-15.5,15),Vector2(-17.5,8),
	]), world_position)
	var right_panel := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(18.5,1.0),Vector2(16.5,-1.0),Vector2(13,-2.5),Vector2(8,-2.0),Vector2(7,0.0),Vector2(8.5,7),Vector2(9.5,17),Vector2(15.5,15),Vector2(17.5,8),
	]), world_position)
	CharacterSurface.draw_volume(canvas, left_panel, Color(fabric.lightened(0.10),0.82), 0.3)
	CharacterSurface.draw_volume(canvas, right_panel, Color(panel,0.54 + structure * 0.24), 0.3)
	CharacterSurface.draw_volume(canvas, center_panel, Color(fabric.lightened(0.03),0.86), 1.0 - float(ATTIRE_FINISHES[attire].roughness))
	var torso_highlight := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-12,-1.5),Vector2(-8,-1.5),Vector2(-5,1.0),Vector2(-4,14),Vector2(-7,18),Vector2(-11,14),
	]), world_position)
	var torso_shadow := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(7,0.5),Vector2(13,-2.0),Vector2(17,0.5),Vector2(16,13),Vector2(11,18),Vector2(8,13),
	]), world_position)
	canvas.draw_colored_polygon(torso_highlight, Color(panel.lightened(0.38), 0.18))
	canvas.draw_colored_polygon(torso_shadow, Color(shadow, 0.20 + structure * 0.08))
	canvas.draw_polyline(_closed_points(left_panel), Color(trim, 0.28 + structure * 0.18), 0.65 * scale_width, true)
	canvas.draw_polyline(_closed_points(right_panel), Color(trim, 0.28 + structure * 0.18), 0.65 * scale_width, true)
	canvas.draw_polyline(_closed_points(center_panel), Color(shadow, 0.42 + structure * 0.14), 0.7 * scale_width, true)

	# Outfit-specific collar points are shared with the measurable fit contract.
	var transformed_neckline := _transformed_points(_body_joint, neckline, world_position)
	canvas.draw_polyline(transformed_neckline, shadow.darkened(0.24), 3.15 * scale_width, true)
	canvas.draw_polyline(transformed_neckline, Color(trim,0.88), 1.45 * scale_width, true)
	var collar_glint := PackedVector2Array()
	for point: Vector2 in transformed_neckline:
		collar_glint.append(point - Vector2(0.0, 0.75) * scale_width)
	canvas.draw_polyline(collar_glint, Color(trim.lightened(0.34), 0.36), 0.7 * scale_width, true)
	for side: float in [-1.0, 1.0]:
		var shoulder := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(side * 8.0,-2.0),Vector2(side * 14.0,-2.0),Vector2(side * 19.0,1.0),Vector2(side * 17.0,3.5),
		]), world_position)
		canvas.draw_polyline(shoulder, shadow.darkened(0.20), 2.75 * scale_width, true)
		canvas.draw_polyline(shoulder, Color(trim,0.82), 1.2 * scale_width, true)
		var side_seam := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(side * 16.8,1.0),Vector2(side * 17.0,8.0),Vector2(side * 14.0,16.0),
		]), world_position)
		canvas.draw_polyline(side_seam, Color(trim, 0.48), 0.9 * scale_width, true)
	var hem_shadow := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-16,14.8),Vector2(-11,hem_y-0.2),Vector2(-5.5,hem_y+1.0),Vector2(0,hem_y+1.35),Vector2(5.5,hem_y+1.0),Vector2(11,hem_y-0.2),Vector2(16,14.8),
	]), world_position)
	var hem_binding := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-15.5,14.1),Vector2(-10.5,hem_y-1.0),Vector2(-5.2,hem_y),Vector2(0,hem_y+0.35),Vector2(5.2,hem_y),Vector2(10.5,hem_y-1.0),Vector2(15.5,14.1),
	]), world_position)
	canvas.draw_polyline(hem_shadow, shadow.darkened(0.22), 2.7 * scale_width, true)
	canvas.draw_polyline(hem_binding, Color(trim,0.84), 1.25 * scale_width, true)

	# Deterministic fabric grain and top-stitching add material depth without texture assets.
	for local_x: float in [-11.0, -5.5, 5.5, 11.0]:
		var grain := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(local_x,2.0),Vector2(local_x * 0.94,7.0),Vector2(local_x * 0.84,13.0),
		]), world_position)
		canvas.draw_polyline(grain, Color(panel.lightened(0.34), 0.22), 0.85 * scale_width, true)
	for weave_y: float in [5.0, 9.0, 13.0, 17.0]:
		var weave := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(-12.5, weave_y), Vector2(0.0, weave_y + fold_bias * 1.5), Vector2(12.5, weave_y),
		]), world_position)
		canvas.draw_polyline(weave, Color(trim.lightened(0.18), 0.10), 0.65 * scale_width, true)
	var center_stitch := _transformed_points(_body_joint, PackedVector2Array([Vector2(0,4),Vector2(0,17)]), world_position)
	canvas.draw_polyline(center_stitch, Color(trim, 0.58), 1.0 * scale_width, true)
	for stitch_y: float in [6.0, 10.0, 14.0]:
		_draw_transformed_ellipse(canvas, _body_joint, Vector2(0.0, stitch_y), Vector2(0.8, 0.8), Color(trim, 0.78), world_position)
	var fold_strength := (0.6 + absf(stretch) * 1.6 + compression * 1.2) * float(motion.secondary_scale)
	for fold_index in range(3):
		var side := -1.0 if fold_index % 2 == 0 else 1.0
		var fold_y := 5.0 + float(fold_index) * 4.8
		var fold := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(side * (4.0 + fold_bias * 8.0), fold_y),
			Vector2(side * (8.0 + fold_bias * 5.0), fold_y + 1.0 + stretch),
			Vector2(side * 11.5, fold_y + 0.4 + compression * 2.0),
		]), world_position)
		canvas.draw_polyline(fold, Color(shadow, 0.24 + fold_strength * 0.13), maxf(0.65, fold_strength) * scale_width, true)
		canvas.draw_polyline(PackedVector2Array([fold[0] - Vector2(0,0.8),fold[1] - Vector2(0,0.6)]), Color(panel.lightened(0.42),0.20), 0.7 * scale_width, true)

	var chest_center := world_position + to_local(_body_joint.to_global(Vector2(0,7)))
	match attire:
		"trail_scout":
			var left_pocket := _transformed_points(_body_joint, PackedVector2Array([Vector2(-13,8),Vector2(-6,8.5),Vector2(-6.5,14),Vector2(-12.5,13.5)]), world_position)
			var right_pocket := _transformed_points(_body_joint, PackedVector2Array([Vector2(6,8.5),Vector2(13,8),Vector2(12.5,13.5),Vector2(6.5,14)]), world_position)
			for pocket in [left_pocket, right_pocket]:
				canvas.draw_colored_polygon(pocket, shadow)
				canvas.draw_polyline(_closed_points(pocket), trim.darkened(0.18), 1.1 * scale_width, true)
			var zipper := _transformed_points(_body_joint, PackedVector2Array([Vector2(0,3),Vector2(0,18)]), world_position)
			canvas.draw_polyline(zipper, trim.lightened(0.12), 1.5 * scale_width, true)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,10), Vector2(1.8,2.4), accent, world_position)
			var scarf_band := _transformed_points(_body_joint, PackedVector2Array([Vector2(-7,1),Vector2(0,6),Vector2(7,1)]), world_position)
			canvas.draw_polyline(scarf_band, Color(shadow.darkened(0.12),0.82), 3.4 * scale_width, true)
			canvas.draw_polyline(scarf_band, Color(accent,0.90), 1.9 * scale_width, true)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,6.5), Vector2(2.1,1.8), accent.lightened(0.18), world_position)
			var scarf_tail := _transformed_points(_body_joint, PackedVector2Array([Vector2(-1.4,8),Vector2(1.9,8),Vector2(3.0,13.5),Vector2(0.5,12),Vector2(-1.6,14)]), world_position)
			canvas.draw_colored_polygon(scarf_tail, accent.darkened(0.08))
			canvas.draw_polyline(_closed_points(scarf_tail), shadow, 1.0 * scale_width, true)
		"moon_champion":
			var sash := _transformed_points(_body_joint, PackedVector2Array([Vector2(-13,-2),Vector2(-8,3),Vector2(9,17),Vector2(12,14)]), world_position)
			canvas.draw_polyline(sash, Color(trim,0.68), 2.1 * scale_width, true)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,7), Vector2(4.9,4.9), trim.darkened(0.18), world_position)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,7), Vector2(3.5,3.5), trim, world_position)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0.9,6.1), Vector2(2.1,2.1), fabric, world_position)
			var crescent := _transformed_points(_body_joint, PackedVector2Array([Vector2(-1,2.8),Vector2(-3.5,6),Vector2(-2.5,10),Vector2(1,11.5)]), world_position)
			canvas.draw_polyline(crescent, Color("fff3bd"), 2.0 * scale_width, true)
			var ribbon_left := _transformed_points(_body_joint, PackedVector2Array([Vector2(-3,11),Vector2(-5,17),Vector2(-0.8,15)]), world_position)
			var ribbon_right := _transformed_points(_body_joint, PackedVector2Array([Vector2(3,11),Vector2(5,17),Vector2(0.8,15)]), world_position)
			canvas.draw_colored_polygon(ribbon_left, accent)
			canvas.draw_colored_polygon(ribbon_right, trim)
		"firefly_hero":
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,7), Vector2(4.8,4.8), Color(shadow,0.88), world_position)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,7), Vector2(3.0,3.0), trim, world_position)
			for ray_index in range(6):
				var angle := TAU * float(ray_index) / 6.0
				canvas.draw_line(chest_center + Vector2.from_angle(angle) * 4.8 * scale_width, chest_center + Vector2.from_angle(angle) * 7.4 * scale_width, Color(trim,0.82), 1.0 * scale_width, true)
			for clasp_x: float in [-12.0, 12.0]:
				_draw_transformed_ellipse(canvas, _body_joint, Vector2(clasp_x,0.0), Vector2(2.4,2.4), accent, world_position)
		"pond_pilot":
			var pilot_wings := _transformed_points(_body_joint, PackedVector2Array([
				Vector2(-11,7),Vector2(-4,5),Vector2(0,8),Vector2(4,5),Vector2(11,7),
			]), world_position)
			canvas.draw_polyline(pilot_wings, Color(trim,0.88), 2.0 * scale_width, true)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,8), Vector2(3.4,3.4), accent, world_position)
			for button_y: float in [13.0,17.0]:
				_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,button_y), Vector2(1.0,1.0), trim.lightened(0.24), world_position)
		"rain_ranger":
			var rain_drop := _transformed_points(_body_joint, PackedVector2Array([
				Vector2(0,2),Vector2(5,9),Vector2(4,13),Vector2(0,16),Vector2(-4,13),Vector2(-5,9),
			]), world_position)
			canvas.draw_colored_polygon(rain_drop, Color(accent,0.92))
			canvas.draw_polyline(_closed_points(rain_drop), trim.darkened(0.18), 1.2 * scale_width, true)
			var rain_glint := _transformed_points(_body_joint, PackedVector2Array([Vector2(-1,6),Vector2(-2.5,9),Vector2(-2,11)]), world_position)
			canvas.draw_polyline(rain_glint, Color(1,1,1,0.72), 1.0 * scale_width, true)
		"bug_catcher":
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,10), Vector2(4.2,5.4), Color(accent,0.90), world_position)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,5.8), Vector2(2.6,2.8), trim.darkened(0.10), world_position)
			for bug_side: float in [-1.0,1.0]:
				var antenna := _transformed_points(_body_joint, PackedVector2Array([Vector2(bug_side*1.4,4),Vector2(bug_side*4.0,1.5)]), world_position)
				canvas.draw_polyline(antenna, trim, 1.0 * scale_width, true)
				var bug_wing := _transformed_points(_body_joint, PackedVector2Array([Vector2(bug_side*2,8),Vector2(bug_side*7,7),Vector2(bug_side*5,12),Vector2(bug_side*2,11)]), world_position)
				canvas.draw_colored_polygon(bug_wing, Color(trim,0.48))
		"star_jumper":
			var star := _transformed_points(_body_joint, PackedVector2Array([
				Vector2(0,2),Vector2(2,7),Vector2(7,7),Vector2(3,10),Vector2(5,16),
				Vector2(0,12.5),Vector2(-5,16),Vector2(-3,10),Vector2(-7,7),Vector2(-2,7),
			]), world_position)
			canvas.draw_colored_polygon(star, Color(accent,0.96))
			canvas.draw_polyline(_closed_points(star), trim, 1.15 * scale_width, true)
		"lily_lifeguard":
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,9), Vector2(7.5,7.5), Color(trim,0.94), world_position)
			var rescue_cross_h := _transformed_points(_body_joint, PackedVector2Array([Vector2(-5,9),Vector2(5,9)]), world_position)
			var rescue_cross_v := _transformed_points(_body_joint, PackedVector2Array([Vector2(0,4),Vector2(0,14)]), world_position)
			canvas.draw_polyline(rescue_cross_h, fabric, 2.8 * scale_width, true)
			canvas.draw_polyline(rescue_cross_v, fabric, 2.8 * scale_width, true)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(11,2), Vector2(2.0,2.0), accent, world_position)
		_:
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,7), Vector2(4.7,4.7), Color(trim.darkened(0.18),0.84), world_position)
			_draw_transformed_ellipse(canvas, _body_joint, Vector2(0,7), Vector2(3.2,3.2), trim, world_position)
			var runner_mark := _transformed_points(_body_joint, PackedVector2Array([Vector2(-1,4),Vector2(1,4),Vector2(1,10),Vector2(3,10)]), world_position)
			canvas.draw_polyline(runner_mark, Color(shadow,0.82), 1.35 * scale_width, true)

	_draw_limb_attire(canvas, world_position, attire, fabric, panel, shadow, trim, accent)
	_draw_attire_dimension_finish(canvas, world_position, fabric, panel, shadow, trim)
	_draw_eyewear(canvas, world_position, eyewear, fabric, trim, lens)

func _draw_attire_dimension_finish(canvas: Node2D, world_position: Vector2, fabric: Color, panel: Color, shadow: Color, trim: Color) -> void:
	# A raised inner collar, shoulder piping and bound hem make the outfit read
	# as fitted equipment. All points stay on the torso below the measured jaw
	# exclusion zone, so no customization can cover Fred's mouth.
	var scale_width := float(_style.size_scale)
	var inner_collar := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-7.5,0.0),Vector2(-4.5,2.6),Vector2(0.0,7.2),Vector2(4.5,2.6),Vector2(7.5,0.0),
	]), world_position)
	canvas.draw_polyline(inner_collar, Color(shadow.darkened(0.28),0.82), 2.7 * scale_width, true)
	canvas.draw_polyline(inner_collar, Color(trim.lightened(0.18),0.72), 1.0 * scale_width, true)
	for side: float in [-1.0,1.0]:
		var shoulder_panel := _transformed_points(_body_joint, PackedVector2Array([
			Vector2(side*8.0,-1.2),Vector2(side*13.0,-2.2),Vector2(side*17.0,0.5),Vector2(side*15.5,5.5),
		]), world_position)
		canvas.draw_polyline(shoulder_panel, Color(panel.lightened(0.28) if side < 0.0 else shadow,0.44), 1.35 * scale_width, true)
	var raised_hem := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-14.5,15.0),Vector2(-9.0,20.0),Vector2(0.0,22.0),Vector2(9.0,20.0),Vector2(14.5,15.0),
	]), world_position)
	canvas.draw_polyline(raised_hem, Color(shadow.darkened(0.24),0.70), 2.5 * scale_width, true)
	canvas.draw_polyline(PackedVector2Array([raised_hem[0]-Vector2(0,1),raised_hem[1]-Vector2(0,1),raised_hem[2]-Vector2(0,1)]), Color(fabric.lightened(0.46),0.28), 0.8 * scale_width, true)

func _draw_limb_attire(canvas: Node2D, world_position: Vector2, attire: String, fabric: Color, panel: Color, shadow: Color, trim: Color, accent: Color) -> void:
	var scale_width := float(_style.size_scale)
	var cut: Dictionary = ATTIRE_CUTS.get(attire, {})
	var sleeve_ratio := float(cut.get("sleeve_ratio", 0.3))
	for path: String in ["RootJoint/FrontLeft", "RootJoint/FrontRight"]:
		var limb := get_node(path) as Line2D
		var points := _transformed_points(limb, limb.points, world_position)
		if points.size() < 3:
			continue
		var shoulder := points[0]
		var elbow := points[1]
		var hand := points[points.size() - 1]
		var upper_direction := (elbow - shoulder).normalized()
		var upper_normal := Vector2(-upper_direction.y, upper_direction.x)
		var sleeve_end := shoulder.lerp(elbow, sleeve_ratio)
		var shoulder_radius := 4.5 * scale_width
		var cuff_radius := lerpf(2.6, 3.5, sleeve_ratio) * scale_width
		var sleeve_shadow := PackedVector2Array([
			shoulder + upper_normal * (shoulder_radius + 0.9),
			shoulder - upper_normal * (shoulder_radius + 0.9),
			sleeve_end - upper_normal * (cuff_radius + 0.7),
			sleeve_end + upper_normal * (cuff_radius + 0.7),
		])
		var sleeve := PackedVector2Array([
			shoulder + upper_normal * shoulder_radius,
			shoulder - upper_normal * shoulder_radius,
			sleeve_end - upper_normal * cuff_radius,
			sleeve_end + upper_normal * cuff_radius,
		])
		canvas.draw_colored_polygon(sleeve_shadow, Color(shadow.darkened(0.24),0.86))
		canvas.draw_colored_polygon(sleeve, fabric if path.ends_with("Left") else panel)
		canvas.draw_polyline(_closed_points(sleeve), Color(trim,0.46), 0.8 * scale_width, true)
		canvas.draw_line(sleeve_end - upper_normal * cuff_radius, sleeve_end + upper_normal * cuff_radius, Color(trim,0.86), 1.35 * scale_width, true)
		canvas.draw_line(shoulder - upper_normal * shoulder_radius * 0.68, sleeve_end - upper_normal * cuff_radius * 0.68, Color(panel.lightened(0.38),0.24), 0.9 * scale_width, true)
		if attire in ["firefly_hero", "moon_champion", "pond_pilot", "star_jumper", "lily_lifeguard"]:
			var bracer_center := elbow.lerp(hand, 0.56)
			var lower_direction := (hand - elbow).normalized()
			var lower_normal := Vector2(-lower_direction.y, lower_direction.x)
			canvas.draw_line(bracer_center - lower_direction * 3.7 * scale_width, bracer_center + lower_direction * 3.7 * scale_width, Color(shadow,0.82), 5.6 * scale_width, true)
			canvas.draw_line(bracer_center - lower_direction * 3.3 * scale_width, bracer_center + lower_direction * 3.3 * scale_width, accent if attire in ["firefly_hero", "star_jumper", "lily_lifeguard"] else fabric.lightened(0.16), 3.5 * scale_width, true)
			canvas.draw_line(bracer_center - lower_normal * 2.8 * scale_width, bracer_center + lower_normal * 2.8 * scale_width, Color(trim,0.82), 1.0 * scale_width, true)
		elif attire in ["trail_scout", "rain_ranger", "bug_catcher"]:
			var cuff_center := elbow.lerp(hand, 0.24)
			var cuff_direction := (hand - elbow).normalized()
			var cuff_normal := Vector2(-cuff_direction.y, cuff_direction.x)
			canvas.draw_line(cuff_center - cuff_normal * 3.1 * scale_width, cuff_center + cuff_normal * 3.1 * scale_width, accent.darkened(0.12), 1.8 * scale_width, true)
		else:
			var sweatband_center := elbow.lerp(hand, 0.40)
			var forearm_direction := (hand - elbow).normalized()
			var forearm_normal := Vector2(-forearm_direction.y, forearm_direction.x)
			canvas.draw_line(sweatband_center - forearm_normal * 2.7 * scale_width, sweatband_center + forearm_normal * 2.7 * scale_width, Color(trim,0.72), 1.45 * scale_width, true)

	# Garment-specific leg accents follow the authored hind joints; bare runner legs stay uncluttered.
	for hind: Node2D in [_hind_left, _hind_right]:
		if attire in ["trail_scout", "firefly_hero", "rain_ranger", "bug_catcher", "lily_lifeguard"]:
			var knee_color := accent if attire in ["firefly_hero", "lily_lifeguard"] else fabric.darkened(0.08)
			_draw_transformed_ellipse(canvas, hind, Vector2(-15.0,6.0), Vector2(5.8,3.8), Color(shadow.darkened(0.18),0.74), world_position)
			_draw_transformed_ellipse(canvas, hind, Vector2(-15.5,5.3), Vector2(4.5,2.7), Color(knee_color,0.76), world_position)
			var knee_band := _transformed_points(hind, PackedVector2Array([Vector2(-20,7),Vector2(-15,8.5),Vector2(-10,7)]), world_position)
			canvas.draw_polyline(knee_band, Color(trim,0.68), 1.0 * scale_width, true)
		elif attire in ["moon_champion", "pond_pilot", "star_jumper"]:
			var ribbon := _transformed_points(hind, PackedVector2Array([Vector2(-19,5),Vector2(-15,7),Vector2(-11,5)]), world_position)
			canvas.draw_polyline(ribbon, Color(trim,0.66), 1.05 * scale_width, true)

func _draw_eyewear(canvas: Node2D, world_position: Vector2, eyewear: String, frame: Color, trim: Color, lens: Color) -> void:
	var left_center := Vector2(-12.0, -21.0)
	var right_center := Vector2(12.0, -21.0)
	var scale_width := float(_style.size_scale)
	var strap_shadow := _transformed_points(_head_joint, PackedVector2Array([Vector2(-26,-19),Vector2(-20,-24),Vector2(20,-24),Vector2(26,-19)]), world_position)
	var strap := _transformed_points(_head_joint, PackedVector2Array([Vector2(-26,-20),Vector2(-19.5,-23.5),Vector2(19.5,-23.5),Vector2(26,-20)]), world_position)
	canvas.draw_polyline(strap_shadow, Color(frame.darkened(0.42),0.76), 3.2 * scale_width, true)
	canvas.draw_polyline(strap, Color(frame.lightened(0.08),0.88), 1.55 * scale_width, true)
	for hinge_x: float in [-21.0, 21.0]:
		_draw_transformed_ellipse(canvas, _head_joint, Vector2(hinge_x,-21), Vector2(2.5,2.5), trim.darkened(0.18), world_position)
		_draw_transformed_ellipse(canvas, _head_joint, Vector2(hinge_x-0.5,-21.5), Vector2(0.8,0.8), trim.lightened(0.28), world_position)
	if eyewear in ["moon_visor", "star_visor"]:
		var gasket := _transformed_points(_head_joint, PackedVector2Array([
			Vector2(-22,-27.5),Vector2(-7.5,-30),Vector2(7.5,-30),Vector2(22,-27.5),Vector2(19.5,-17),Vector2(6.5,-14),Vector2(-6.5,-14),Vector2(-20,-18),
		]), world_position)
		var visor := _transformed_points(_head_joint, PackedVector2Array([
			Vector2(-20.8,-26.5),Vector2(-7,-28.8),Vector2(7,-28.8),Vector2(20.8,-26.5),Vector2(18.2,-18.2),Vector2(6,-15.4),Vector2(-6,-15.4),Vector2(-18.6,-19),
		]), world_position)
		canvas.draw_colored_polygon(gasket, frame.darkened(0.42))
		canvas.draw_colored_polygon(visor, lens)
		canvas.draw_polyline(_closed_points(visor), Color(trim,0.90), 1.75 * scale_width, true)
		var lower_rim := _transformed_points(_head_joint, PackedVector2Array([Vector2(-19.5,-17.5),Vector2(-6.5,-15),Vector2(6.5,-15),Vector2(19.5,-17.5)]), world_position)
		canvas.draw_polyline(lower_rim, Color(trim.darkened(0.18),0.88), 1.4 * scale_width, true)
		var visor_shine := _transformed_points(_head_joint, PackedVector2Array([Vector2(-18,-26),Vector2(-7,-29),Vector2(4,-29)]), world_position)
		canvas.draw_polyline(visor_shine, Color(1,1,1,0.72), 1.5 * scale_width, true)
		for screw_x: float in [-18.5, 18.5]:
			_draw_transformed_ellipse(canvas, _head_joint, Vector2(screw_x,-18), Vector2(1.2,1.2), trim.lightened(0.25), world_position)
		if eyewear == "star_visor":
			var star_glint := _transformed_points(_head_joint, PackedVector2Array([
				Vector2(0,-27),Vector2(1.3,-23.5),Vector2(5,-23.5),Vector2(2,-21.5),
				Vector2(3,-18),Vector2(0,-20),Vector2(-3,-18),Vector2(-2,-21.5),Vector2(-5,-23.5),Vector2(-1.3,-23.5),
			]), world_position)
			canvas.draw_polyline(_closed_points(star_glint), Color(trim.lightened(0.30),0.90), 1.0 * scale_width, true)
		return
	var radius := Vector2(8.3, 6.9)
	if eyewear == "round_glasses":
		radius = Vector2(7.9, 7.9)
	elif eyewear == "hero_goggles":
		radius = Vector2(8.8, 7.0)
	elif eyewear == "pilot_goggles":
		radius = Vector2(9.3, 6.4)
	elif eyewear == "rain_glasses":
		radius = Vector2(7.2, 8.6)
	elif eyewear == "bug_shades":
		radius = Vector2(9.4, 5.4)
	elif eyewear == "guard_goggles":
		radius = Vector2(8.6, 7.5)
	for center: Vector2 in [left_center, right_center]:
		var gasket_points := _transformed_ellipse_points(_head_joint, center + Vector2(0,0.7), radius + Vector2(1.7,1.7), world_position, 20)
		var frame_points := _transformed_ellipse_points(_head_joint, center, radius + Vector2(0.7,0.7), world_position, 20)
		var lens_points := _transformed_ellipse_points(_head_joint, center, radius - Vector2(0.9,0.9), world_position, 20)
		canvas.draw_colored_polygon(gasket_points, frame.darkened(0.44))
		canvas.draw_colored_polygon(frame_points, trim.darkened(0.16))
		canvas.draw_colored_polygon(lens_points, lens)
		canvas.draw_polyline(_closed_points(frame_points), Color(trim.lightened(0.12),0.88), 1.15 * scale_width, true)
		var lower_lens := _transformed_ellipse_points(_head_joint, center + Vector2(0,1.7), radius - Vector2(1.8,2.6), world_position, 16)
		canvas.draw_polyline(_closed_points(lower_lens), Color(frame.darkened(0.18),0.34), 0.9 * scale_width, true)
		if eyewear == "pilot_goggles":
			var pilot_bar := _transformed_points(_head_joint, PackedVector2Array([center+Vector2(-6,0),center+Vector2(6,0)]), world_position)
			canvas.draw_polyline(pilot_bar, Color(trim,0.54), 0.9 * scale_width, true)
		elif eyewear == "rain_glasses":
			var rain_mark := _transformed_points(_head_joint, PackedVector2Array([center+Vector2(0,-4),center+Vector2(-2,1),center+Vector2(0,4),center+Vector2(2,1)]), world_position)
			canvas.draw_polyline(rain_mark, Color(1,1,1,0.44), 0.8 * scale_width, true)
		elif eyewear == "bug_shades":
			var shade_brow := _transformed_points(_head_joint, PackedVector2Array([center+Vector2(-7,-3),center+Vector2(7,-3)]), world_position)
			canvas.draw_polyline(shade_brow, Color(frame.darkened(0.25),0.78), 1.5 * scale_width, true)
		elif eyewear == "guard_goggles":
			var guard_cross_h := _transformed_points(_head_joint, PackedVector2Array([center+Vector2(-3,0),center+Vector2(3,0)]), world_position)
			var guard_cross_v := _transformed_points(_head_joint, PackedVector2Array([center+Vector2(0,-3),center+Vector2(0,3)]), world_position)
			canvas.draw_polyline(guard_cross_h, Color(trim,0.68), 0.85 * scale_width, true)
			canvas.draw_polyline(guard_cross_v, Color(trim,0.68), 0.85 * scale_width, true)
	var bridge_shadow := _transformed_points(_head_joint, PackedVector2Array([Vector2(-3.5,-20),Vector2(0,-17.5),Vector2(3.5,-20)]), world_position)
	var bridge := _transformed_points(_head_joint, PackedVector2Array([Vector2(-3,-21),Vector2(0,-19),Vector2(3,-21)]), world_position)
	canvas.draw_polyline(bridge_shadow, frame.darkened(0.44), 3.5 * scale_width, true)
	canvas.draw_polyline(bridge, trim, 1.8 * scale_width, true)
	for pad_x: float in [-3.0,3.0]:
		_draw_transformed_ellipse(canvas, _head_joint, Vector2(pad_x,-17.5), Vector2(1.2,1.7), Color(trim.lightened(0.22),0.74), world_position)
	for center: Vector2 in [left_center, right_center]:
		var shine := world_position + _node_point(_head_joint, center + Vector2(-3,-3))
		canvas.draw_circle(shine, 1.7 * scale_width, Color(1,1,1,0.84))
		canvas.draw_line(shine + Vector2(2.0,0.5), shine + Vector2(5.0,2.0), Color(1,1,1,0.42), 0.9 * scale_width, true)

func tongue_anchor() -> Vector2:
	return _marker_point("RootJoint/HeadJoint/TongueAnchor")

func cue_anchor() -> Vector2:
	return _marker_point("RootJoint/HeadJoint/CueAnchor")

func ground_contacts() -> PackedVector2Array:
	return PackedVector2Array([
		_marker_point("RootJoint/HindLeft/GroundContact"),
		_marker_point("RootJoint/HindRight/GroundContact"),
	])

func snapshot() -> Dictionary:
	if not contract_valid:
		return {"valid": false, "error": last_error}
	return {
		"valid": true,
		"state": int(_pose.get("state", -1)),
		"state_name": str(_pose.get("state_name", "INVALID")),
		"cue": str(_pose.get("cue", "INVALID")),
		"facing": -1 if _root_joint.scale.x < 0.0 else 1,
		"root_position": _root_joint.position,
		"root_rotation": _root_joint.rotation,
		"root_scale": _root_joint.scale,
		"body_rotation": _body_joint.rotation,
		"head_position": _head_joint.position,
		"hind_left_position": _hind_left.position,
		"hind_left_rotation": _hind_left.rotation,
		"hind_right_position": _hind_right.position,
		"hind_right_rotation": _hind_right.rotation,
		"eye_scale": _eye_left.scale,
		"pupil_position": (get_node("RootJoint/HeadJoint/EyeLeft/Pupil") as Polygon2D).position,
		"mouth_visible": (get_node("RootJoint/HeadJoint/MouthCavity") as Polygon2D).visible,
		"tongue_anchor": tongue_anchor(),
		"cue_anchor": cue_anchor(),
		"ground_contacts": ground_contacts(),
		"accent": (get_node("RootJoint/BodyJoint/Accent") as Polygon2D).color,
		"style": style_snapshot(),
	}

func state_hash() -> String:
	var data := snapshot()
	if not bool(data.get("valid", false)):
		return "INVALID:%s" % str(data.get("error", "unknown"))
	return "%02d:%s:%+d:%+.3f,%+.3f:%+.4f:%+.3f,%+.3f:%+.3f:%+.3f,%+.3f:%+.3f,%+.3f:%s" % [
		int(data.state),
		str(data.state_name),
		int(data.facing),
		Vector2(data.root_position).x,
		Vector2(data.root_position).y,
		float(data.root_rotation),
		Vector2(data.root_scale).x,
		Vector2(data.root_scale).y,
		float(data.body_rotation),
		Vector2(data.head_position).y,
		Vector2(data.eye_scale).y,
		Vector2(data.tongue_anchor).x,
		Vector2(data.tongue_anchor).y,
		str(data.cue),
	]

func _valid_pose(pose: Dictionary) -> bool:
	for key in REQUIRED_POSE_KEYS:
		if not pose.has(key):
			last_error = "Missing authored rig pose key: %s" % str(key)
			return false
	if (
		typeof(pose.state) != TYPE_INT
		or typeof(pose.state_name) != TYPE_STRING
		or typeof(pose.cue) != TYPE_STRING
		or typeof(pose.facing) not in [TYPE_INT, TYPE_FLOAT]
		or typeof(pose.body_offset) != TYPE_VECTOR2
		or typeof(pose.body_scale) != TYPE_VECTOR2
		or typeof(pose.leg_extension) not in [TYPE_INT, TYPE_FLOAT]
		or typeof(pose.tilt) not in [TYPE_INT, TYPE_FLOAT]
		or typeof(pose.eye_squint) not in [TYPE_INT, TYPE_FLOAT]
		or typeof(pose.mouth_open) not in [TYPE_INT, TYPE_FLOAT]
		or typeof(pose.accent) != TYPE_COLOR
		or typeof(pose.reduced_motion) != TYPE_BOOL
	):
		last_error = "Authored rig pose contains an invalid value type"
		return false
	var scale := Vector2(pose.body_scale)
	var offset := Vector2(pose.body_offset)
	var scalars := [
		float(pose.facing),
		scale.x,
		scale.y,
		offset.x,
		offset.y,
		float(pose.leg_extension),
		float(pose.tilt),
		float(pose.eye_squint),
		float(pose.mouth_open),
	]
	for value in scalars:
		if not is_finite(float(value)):
			last_error = "Authored rig pose contains a non-finite value"
			return false
	if scale.x <= 0.0 or scale.y <= 0.0:
		last_error = "Authored rig pose scale must be positive"
		return false
	if int(pose.state) < 0 or int(pose.state) > MAX_COORDINATOR_STATE or str(pose.state_name).is_empty() or str(pose.cue).is_empty():
		last_error = "Authored rig pose state metadata is invalid"
		return false
	last_error = ""
	return true

func _neutralize() -> void:
	if not contract_valid:
		return
	_pose = {}
	_root_joint.position = Vector2.ZERO
	_root_joint.rotation = 0.0
	_root_joint.scale = Vector2.ONE
	_body_joint.rotation = 0.0
	_head_joint.position = Vector2(0.0, -17.0)
	_hind_left.position = Vector2(-18.0, 14.0)
	_hind_right.position = Vector2(18.0, 14.0)
	_hind_left.rotation = -0.12
	_hind_right.rotation = 0.12
	_eye_left.scale = Vector2.ONE
	_eye_right.scale = Vector2.ONE
	(get_node("RootJoint/HeadJoint/EyeLeft/Pupil") as Polygon2D).position = Vector2(3.0,0.0)
	(get_node("RootJoint/HeadJoint/EyeRight/Pupil") as Polygon2D).position = Vector2(3.0,0.0)

func _transformed_points(node: Node2D, source: PackedVector2Array, world_position: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in source:
		points.append(world_position + to_local(node.to_global(point)))
	return points

func _node_point(node: Node2D, local_point: Vector2) -> Vector2:
	return to_local(node.to_global(local_point))

func _ellipse_points(center: Vector2, radius: Vector2, segments: int = 18) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(8, segments)):
		var angle := TAU * float(index) / float(maxi(8, segments))
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points

func _closed_points(source: PackedVector2Array) -> PackedVector2Array:
	var points := source.duplicate()
	if not points.is_empty():
		points.append(points[0])
	return points

func _transformed_ellipse_points(node: Node2D, center: Vector2, radius: Vector2, world_position: Vector2, segments: int = 18) -> PackedVector2Array:
	return _transformed_points(node, _ellipse_points(center, radius, segments), world_position)

func _draw_transformed_ellipse(canvas: Node2D, node: Node2D, center: Vector2, radius: Vector2, color: Color, world_position: Vector2) -> void:
	var detail := 8 if radius.length() < 8.0 else 16
	var points := _transformed_ellipse_points(node, center, radius, world_position, detail)
	CharacterSurface.draw_volume(canvas, points, color, 0.35, color.a < 0.5)

func _marker_point(path: String) -> Vector2:
	if not contract_valid:
		return Vector2.ZERO
	var marker := get_node(path) as Marker2D
	return to_local(marker.global_position)

func _draw_safe_fallback(canvas: Node2D, world_position: Vector2) -> void:
	var outline := Color("ffcf70")
	canvas.draw_colored_polygon(PackedVector2Array([
		world_position + Vector2(0,-18),
		world_position + Vector2(18,0),
		world_position + Vector2(0,18),
		world_position + Vector2(-18,0),
	]), Color("355f46"))
	canvas.draw_polyline(PackedVector2Array([
		world_position + Vector2(-11,-11),
		world_position + Vector2(11,11),
	]), outline, 3.0, true)
	canvas.draw_polyline(PackedVector2Array([
		world_position + Vector2(11,-11),
		world_position + Vector2(-11,11),
	]), outline, 3.0, true)
