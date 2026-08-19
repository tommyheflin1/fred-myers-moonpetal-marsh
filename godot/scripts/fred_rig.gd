class_name FredRig
extends Node2D

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
const ATTIRE_IDS := ["marsh_runner", "trail_scout", "moon_champion", "firefly_hero"]
const ATTIRE_LABELS := {
	"marsh_runner": "Runner Goggles",
	"trail_scout": "Explorer Glasses",
	"moon_champion": "Moon Champion Visor",
	"firefly_hero": "Firefly Hero Goggles",
}
const ATTIRE_EYEWEAR := {
	"marsh_runner": "sport_goggles",
	"trail_scout": "round_glasses",
	"moon_champion": "moon_visor",
	"firefly_hero": "hero_goggles",
}
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
var _style := {
	"body_color": Color("4fbd68"),
	"size_scale": 0.92,
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
	contract_valid = true
	return true

func apply_style(style: Dictionary) -> bool:
	if typeof(style.get("body_color")) != TYPE_COLOR or typeof(style.get("tongue_color")) != TYPE_COLOR:
		return false
	var size_scale := float(style.get("size_scale", 1.0))
	var attire := str(style.get("attire", "marsh_runner"))
	if not is_finite(size_scale) or size_scale < 0.88 or size_scale > 1.14:
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
	_root_joint.scale = Vector2(body_scale.x * facing, body_scale.y) * cosmetic_scale
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

func render_to(canvas: Node2D, world_position: Vector2) -> bool:
	if not contract_valid:
		_draw_safe_fallback(canvas, world_position)
		return false
	_draw_ground_shadow(canvas, world_position)
	_draw_attire_back(canvas, world_position)
	for path in POLYGON_ORDER:
		var polygon := get_node(str(path)) as Polygon2D
		if not polygon.visible:
			continue
		var points := _transformed_points(polygon, polygon.polygon, world_position)
		if points.size() >= 3:
			canvas.draw_colored_polygon(points, polygon.color)
	_draw_skin_dimension(canvas, world_position)
	_draw_front_limbs(canvas, world_position)
	for path in LINE_ORDER:
		if str(path) in ["RootJoint/FrontLeft", "RootJoint/FrontRight"]:
			continue
		var line := get_node(str(path)) as Line2D
		if not line.visible:
			continue
		var points := _transformed_points(line, line.points, world_position)
		if points.size() >= 2:
			var scale_width := maxf(0.5, absf(_root_joint.scale.x) + absf(_root_joint.scale.y)) * 0.5
			canvas.draw_polyline(points, line.default_color, line.width * scale_width, true)
	_draw_sport_gear(canvas, world_position)
	_draw_face_finish(canvas, world_position)
	return true

func style_snapshot() -> Dictionary:
	return _style.duplicate(true)

func attire_snapshot() -> Dictionary:
	if not contract_valid:
		return {"valid": false, "error": last_error}
	var attire := str(_style.attire)
	var left_anchor := _node_point(_head_joint, Vector2(-13.0, -21.0))
	var right_anchor := _node_point(_head_joint, Vector2(13.0, -21.0))
	var mouth_lower_anchor := _node_point(_head_joint, Vector2(0.0, 14.0))
	var collar_anchor := _node_point(_body_joint, Vector2(0.0, 5.0))
	return {
		"valid": true,
		"attire": attire,
		"label": str(ATTIRE_LABELS.get(attire, "Unknown Gear")),
		"eyewear": str(ATTIRE_EYEWEAR.get(attire, "none")),
		"left_eye_anchor": left_anchor,
		"right_eye_anchor": right_anchor,
		"eye_span": left_anchor.distance_to(right_anchor),
		"mouth_lower_anchor": mouth_lower_anchor,
		"collar_anchor": collar_anchor,
		"mouth_clearance_pixels": collar_anchor.y - mouth_lower_anchor.y,
		"body_anchor": _node_point(_body_joint, Vector2(0.0, 3.0)),
		"child_readable": attire in ATTIRE_IDS,
	}

func realism_snapshot() -> Dictionary:
	return {
		"features": REALISM_FEATURES.duplicate(),
		"feature_count": REALISM_FEATURES.size(),
		"presentation_only": true,
		"phone_safe_vector_rig": true,
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
	var cape := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-18.0, -13.0), Vector2(-31.0, -5.0), Vector2(-34.0, 20.0),
		Vector2(-14.0, 17.0), Vector2(-7.0, -8.0),
	]), world_position)
	canvas.draw_colored_polygon(cape, Color("d54d62"))
	canvas.draw_polyline(_closed_points(cape), Color("ffd36a"), 2.0 * float(_style.size_scale), true)

func _draw_skin_dimension(canvas: Node2D, world_position: Vector2) -> void:
	var body_color := (get_node("RootJoint/BodyJoint/Fill") as Polygon2D).color
	var head_color := (get_node("RootJoint/HeadJoint/Fill") as Polygon2D).color
	var highlight := head_color.lightened(0.28)
	var shadow := body_color.darkened(0.32)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(9.0, 7.0), Vector2(12.0, 17.0), Color(shadow, 0.34), world_position)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(-9.0, -9.0), Vector2(8.0, 5.0), Color(highlight, 0.34), world_position)
	_draw_transformed_ellipse(canvas, _body_joint, Vector2(0.0, 13.0), Vector2(13.0, 11.0), Color(body_color.lightened(0.30), 0.16), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 9.0), Vector2(22.0, 8.0), Color(shadow, 0.20), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(-8.0, -12.0), Vector2(10.0, 5.0), Color(highlight, 0.26), world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 12.0), Vector2(17.0, 6.5), Color(head_color.lightened(0.34), 0.18), world_position)
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
		var muscle := _transformed_points(node, PackedVector2Array([Vector2(-2,-3),Vector2(-17,1),Vector2(-29,12)]), world_position)
		canvas.draw_polyline(muscle, Color(highlight, 0.48), 2.2 * float(_style.size_scale), true)
		var lower_muscle := _transformed_points(node, PackedVector2Array([Vector2(-27,13),Vector2(-32,19),Vector2(-31,25)]), world_position)
		canvas.draw_polyline(lower_muscle, Color(shadow,0.34), 1.5 * float(_style.size_scale), true)

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

func _draw_face_finish(canvas: Node2D, world_position: Vector2) -> void:
	var head_color := (get_node("RootJoint/HeadJoint/Fill") as Polygon2D).color
	var outline := (get_node("RootJoint/HeadJoint/MouthLine") as Line2D).default_color
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(0.0, 13.0), Vector2(14.0, 3.2), Color(head_color.lightened(0.34), 0.24), world_position)
	for eye in [_eye_left, _eye_right]:
		var iris_center := world_position + _node_point(eye, Vector2(2.0, 0.0))
		canvas.draw_circle(iris_center, 5.2 * float(_style.size_scale), Color("a6c95e"))
		canvas.draw_arc(iris_center, 4.8 * float(_style.size_scale), 0.0, TAU, 18, Color("456d35"), 1.5 * float(_style.size_scale), true)
		canvas.draw_line(iris_center + Vector2(-3.6,0), iris_center + Vector2(3.6,0), Color("13241d"), 2.2 * float(_style.size_scale), true)
		canvas.draw_arc(iris_center + Vector2(0,1.2), 5.8 * float(_style.size_scale), 0.18, PI - 0.18, 14, Color(0.78,0.94,0.74,0.42), 1.0 * float(_style.size_scale), true)
		var glint := world_position + _node_point(eye, Vector2(-1.0, -3.0))
		canvas.draw_circle(glint, 1.8 * float(_style.size_scale), Color(1.0, 1.0, 0.92, 0.92))
	for nostril_x in [-5.0,5.0]:
		var nostril := world_position + _node_point(_head_joint, Vector2(nostril_x,-0.5))
		canvas.draw_circle(nostril,1.5 * float(_style.size_scale),Color(outline,0.72))
		canvas.draw_circle(nostril+Vector2(-0.4,-0.5),0.55 * float(_style.size_scale),Color(0.86,1.0,0.82,0.52))
	var cheek_color := Color(Color("f0a37f"), 0.28)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(-20.0, 7.0), Vector2(4.0, 2.3), cheek_color, world_position)
	_draw_transformed_ellipse(canvas, _head_joint, Vector2(20.0, 7.0), Vector2(4.0, 2.3), cheek_color, world_position)
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

func _draw_sport_gear(canvas: Node2D, world_position: Vector2) -> void:
	var attire := str(_style.attire)
	var jersey := Color("087f7a")
	var trim := Color("f5d35f")
	var lens := Color(0.55, 0.92, 1.0, 0.30)
	var eyewear := "sport_goggles"
	match attire:
		"trail_scout":
			jersey = Color("8b5a32")
			trim = Color("f4d6a4")
			lens = Color(0.82, 0.95, 0.88, 0.22)
			eyewear = "round_glasses"
		"moon_champion":
			jersey = Color("5547a9")
			trim = Color("ffe184")
			lens = Color(0.64, 0.52, 1.0, 0.34)
			eyewear = "moon_visor"
		"firefly_hero":
			jersey = Color("162b4a")
			trim = Color("dfff68")
			lens = Color(0.76, 1.0, 0.42, 0.32)
			eyewear = "hero_goggles"
	var jersey_points := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-21,-4),Vector2(-15,-9),Vector2(-9,-10),Vector2(-6,-2),
		Vector2(0,5),Vector2(6,-2),Vector2(9,-10),Vector2(15,-9),
		Vector2(21,-4),Vector2(19,15),Vector2(10,23),Vector2(-10,23),Vector2(-19,15),
	]), world_position)
	canvas.draw_colored_polygon(jersey_points, jersey)
	canvas.draw_polyline(_closed_points(jersey_points), trim.darkened(0.18), 2.4 * float(_style.size_scale), true)
	var neckline := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-9,-10),Vector2(-6,-2),Vector2(0,5),Vector2(6,-2),Vector2(9,-10),
	]), world_position)
	canvas.draw_polyline(neckline, trim, 2.3 * float(_style.size_scale), true)
	var waist := _transformed_points(_body_joint, PackedVector2Array([Vector2(-18,14),Vector2(0,18),Vector2(18,14)]), world_position)
	canvas.draw_polyline(waist, Color(trim, 0.76), 1.8 * float(_style.size_scale), true)
	var chest_center := world_position + to_local(_body_joint.to_global(Vector2(0,4)))
	canvas.draw_circle(chest_center, 7.2 * float(_style.size_scale), trim)
	match attire:
		"trail_scout":
			canvas.draw_rect(Rect2(chest_center + Vector2(-4.2,-3.2), Vector2(8.4,6.4)), jersey.darkened(0.28), true)
			var scarf := _transformed_points(_body_joint, PackedVector2Array([Vector2(-10,-4),Vector2(0,3),Vector2(10,-4),Vector2(6,4),Vector2(0,10),Vector2(-6,4)]), world_position)
			canvas.draw_colored_polygon(scarf, Color("d95f4b"))
			canvas.draw_polyline(_closed_points(scarf), trim.darkened(0.25), 1.2, true)
		"moon_champion":
			canvas.draw_circle(chest_center, 3.3 * float(_style.size_scale), Color("4b3b9b"))
			var ribbon := _transformed_points(_body_joint, PackedVector2Array([Vector2(-3,10),Vector2(0,20),Vector2(3,10)]), world_position)
			canvas.draw_polyline(ribbon, trim, 2.0, true)
		"firefly_hero":
			canvas.draw_circle(chest_center, 3.0 * float(_style.size_scale), Color("17243a"))
			for ray_index in range(6):
				var angle := TAU * float(ray_index) / 6.0
				canvas.draw_line(chest_center + Vector2.from_angle(angle) * 8.0, chest_center + Vector2.from_angle(angle) * 12.0, trim, 1.4, true)
		_:
			canvas.draw_circle(chest_center, 3.3 * float(_style.size_scale), jersey.darkened(0.30))
	_draw_eyewear(canvas, world_position, eyewear, jersey, trim, lens)
	for contact in ground_contacts():
		canvas.draw_circle(world_position + contact, 3.5 * float(_style.size_scale), trim.lightened(0.12))

func _draw_eyewear(canvas: Node2D, world_position: Vector2, eyewear: String, frame: Color, trim: Color, lens: Color) -> void:
	var left_center := Vector2(-13.0, -21.0)
	var right_center := Vector2(13.0, -21.0)
	var strap := _transformed_points(_head_joint, PackedVector2Array([Vector2(-27,-20),Vector2(-20,-24),Vector2(20,-24),Vector2(27,-20)]), world_position)
	canvas.draw_polyline(strap, frame.darkened(0.22), 3.8 * float(_style.size_scale), true)
	if eyewear == "moon_visor":
		var visor := _transformed_points(_head_joint, PackedVector2Array([
			Vector2(-25,-29),Vector2(-8,-32),Vector2(8,-32),Vector2(25,-28),
			Vector2(22,-16),Vector2(7,-13),Vector2(-8,-13),Vector2(-23,-17),
		]), world_position)
		canvas.draw_colored_polygon(visor, lens)
		canvas.draw_polyline(_closed_points(visor), trim, 2.8 * float(_style.size_scale), true)
		var visor_shine := _transformed_points(_head_joint, PackedVector2Array([Vector2(-18,-26),Vector2(-6,-29),Vector2(2,-29)]), world_position)
		canvas.draw_polyline(visor_shine, Color(1,1,1,0.70), 1.6, true)
		return
	var radius := Vector2(10.6, 9.2)
	if eyewear == "round_glasses":
		radius = Vector2(9.6, 9.6)
	elif eyewear == "hero_goggles":
		radius = Vector2(11.4, 9.0)
	for center in [left_center, right_center]:
		var lens_points := _transformed_ellipse_points(_head_joint, center, radius, world_position, 18)
		canvas.draw_colored_polygon(lens_points, lens)
		canvas.draw_polyline(_closed_points(lens_points), trim, 2.5 * float(_style.size_scale), true)
	var bridge := _transformed_points(_head_joint, PackedVector2Array([Vector2(-3,-21),Vector2(0,-19),Vector2(3,-21)]), world_position)
	canvas.draw_polyline(bridge, trim, 2.2 * float(_style.size_scale), true)
	var left_shine := world_position + _node_point(_head_joint, left_center + Vector2(-3,-3))
	var right_shine := world_position + _node_point(_head_joint, right_center + Vector2(-3,-3))
	canvas.draw_circle(left_shine, 1.8 * float(_style.size_scale), Color(1,1,1,0.82))
	canvas.draw_circle(right_shine, 1.8 * float(_style.size_scale), Color(1,1,1,0.82))

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
	canvas.draw_colored_polygon(_transformed_ellipse_points(node, center, radius, world_position, 18), color)

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
