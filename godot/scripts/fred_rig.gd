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
	if attire not in ["marsh_runner", "trail_scout", "moon_champion", "firefly_hero"]:
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
	for path in POLYGON_ORDER:
		var polygon := get_node(str(path)) as Polygon2D
		if not polygon.visible:
			continue
		var points := _transformed_points(polygon, polygon.polygon, world_position)
		if points.size() >= 3:
			canvas.draw_colored_polygon(points, polygon.color)
	_draw_sport_gear(canvas, world_position)
	for path in LINE_ORDER:
		var line := get_node(str(path)) as Line2D
		if not line.visible:
			continue
		var points := _transformed_points(line, line.points, world_position)
		if points.size() >= 2:
			var scale_width := maxf(0.5, absf(_root_joint.scale.x) + absf(_root_joint.scale.y)) * 0.5
			canvas.draw_polyline(points, line.default_color, line.width * scale_width, true)
	return true

func style_snapshot() -> Dictionary:
	return _style.duplicate(true)

func _draw_sport_gear(canvas: Node2D, world_position: Vector2) -> void:
	var attire := str(_style.attire)
	var jersey := Color("087f7a")
	var trim := Color("f5d35f")
	match attire:
		"trail_scout":
			jersey = Color("9a6138")
			trim = Color("f1d1a0")
		"moon_champion":
			jersey = Color("5547a9")
			trim = Color("d9c7ff")
		"firefly_hero":
			jersey = Color("162b4a")
			trim = Color("ffe04f")
	var jersey_points := _transformed_points(_body_joint, PackedVector2Array([
		Vector2(-21,-10),Vector2(-13,-20),Vector2(-5,-23),Vector2(0,-15),
		Vector2(6,-23),Vector2(15,-19),Vector2(22,-8),Vector2(20,15),
		Vector2(10,24),Vector2(-9,24),Vector2(-20,15),
	]), world_position)
	canvas.draw_colored_polygon(jersey_points, jersey)
	canvas.draw_polyline(PackedVector2Array([jersey_points[0],jersey_points[1],jersey_points[2],jersey_points[3],jersey_points[4],jersey_points[5],jersey_points[6]]),trim,2.2,true)
	var chest_center := world_position + to_local(_body_joint.to_global(Vector2(0,4)))
	canvas.draw_circle(chest_center,7.0 * float(_style.size_scale),trim)
	canvas.draw_circle(chest_center,3.2 * float(_style.size_scale),jersey.darkened(0.25))
	var headband := _transformed_points(_head_joint, PackedVector2Array([Vector2(-24,-15),Vector2(-11,-19),Vector2(2,-20),Vector2(15,-18),Vector2(25,-13)]),world_position)
	canvas.draw_polyline(headband,jersey,6.0 * float(_style.size_scale),true)
	canvas.draw_polyline(headband,trim,2.0 * float(_style.size_scale),true)
	var shine_left := world_position + to_local(_head_joint.to_global(Vector2(-18,-6)))
	var shine_right := world_position + to_local(_head_joint.to_global(Vector2(17,-7)))
	canvas.draw_circle(shine_left,3.2,Color(1,1,1,0.30))
	canvas.draw_circle(shine_right,2.4,Color(1,1,1,0.24))
	for contact in ground_contacts():
		canvas.draw_circle(world_position + contact,3.5,trim.lightened(0.12))

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
