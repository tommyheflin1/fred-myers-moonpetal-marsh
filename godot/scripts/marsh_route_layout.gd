class_name FredMarshRouteLayout
extends RefCounted

const CANVAS_SIZE := Vector2(1280.0, 720.0)
const PLAYFIELD_RECT := Rect2(15.0, 105.0, 1250.0, 530.0)
const OBJECTIVE_RECT := Rect2(280.0, 14.0, 500.0, 56.0)
const LIVES_RECT := Rect2(795.0, 14.0, 185.0, 56.0)
const PAUSE_RECT := Rect2(990.0, 14.0, 120.0, 56.0)
const HOME_RECT := Rect2(1125.0, 14.0, 125.0, 56.0)
const ENERGY_RECT := Rect2(900.0, 78.0, 330.0, 18.0)
const STATUS_TOUCH_RECT := Rect2(340.0, 568.0, 500.0, 42.0)
const STATUS_DESKTOP_RECT := Rect2(820.0, 642.0, 410.0, 42.0)
const TELEMETRY_ANCHOR := Vector2(25.0, 700.0)
const TOUCH_MOVEMENT_RECT := Rect2(25.0, 115.0, 1230.0, 495.0)
const TOUCH_GUIDE_RECT := Rect2(20.0, 620.0, 310.0, 88.0)
const TOUCH_ACTION_BAR_RECT := Rect2(340.0, 620.0, 910.0, 88.0)
const TOUCH_MOVEMENT_DEADZONE := 18.0

const BACKGROUND_LABELS: Array[String] = [
	"Firefly Glade",
	"Moonlit Channel",
	"Mistflower Reach",
	"Rainleaf Basin",
	"Cattail Crossing",
	"Starwater Hollow",
]
const BACKGROUND_TINTS: Array[Color] = [
	Color("e6fff0"),
	Color("d8ecff"),
	Color("f0ddff"),
	Color("d9fff9"),
	Color("fff1d6"),
	Color("e0e8ff"),
]
const BACKGROUND_OVERLAYS: Array[Color] = [
	Color(0.08, 0.31, 0.18, 0.12),
	Color(0.06, 0.18, 0.42, 0.16),
	Color(0.31, 0.13, 0.39, 0.15),
	Color(0.03, 0.34, 0.32, 0.14),
	Color(0.31, 0.21, 0.08, 0.13),
	Color(0.11, 0.12, 0.38, 0.16),
]

const FORMATION_LABELS: Array[String] = [
	"River Arc",
	"Zigzag Sprint",
	"Moon Ring",
	"Cross Current",
	"Firefly Spiral",
	"Island Scatter",
]

static func is_reversed(level: int) -> bool:
	return maxi(1, level) % 2 == 0

static func route_point(point: Vector2, level: int) -> Vector2:
	if not is_reversed(level):
		return point
	return Vector2(CANVAS_SIZE.x - point.x, point.y)

static func route_direction(level: int) -> Vector2:
	return Vector2.LEFT if is_reversed(level) else Vector2.RIGHT

static func route_label(level: int) -> String:
	return "RIGHT TO LEFT" if is_reversed(level) else "LEFT TO RIGHT"

static func formation_variant(level: int) -> int:
	return posmod(maxi(1, level) - 1, FORMATION_LABELS.size())

static func formation_label(level: int) -> String:
	return FORMATION_LABELS[formation_variant(level)]

static func pad_point(base: Vector2, index: int, level: int) -> Vector2:
	var offsets: Array[Vector2]
	match formation_variant(level):
		1:
			offsets = [Vector2(0,0),Vector2(5,-85),Vector2(-10,35),Vector2(15,-105),Vector2(-5,45),Vector2(12,-55),Vector2(0,0)]
		2:
			offsets = [Vector2(0,0),Vector2(95,-20),Vector2(105,-150),Vector2(0,-165),Vector2(-115,20),Vector2(-70,105),Vector2(0,0)]
		3:
			offsets = [Vector2(0,0),Vector2(105,45),Vector2(-60,-135),Vector2(95,85),Vector2(-95,-80),Vector2(45,80),Vector2(0,0)]
		4:
			offsets = [Vector2(0,0),Vector2(75,-70),Vector2(120,-120),Vector2(70,70),Vector2(-60,145),Vector2(-45,90),Vector2(0,0)]
		5:
			offsets = [Vector2(0,0),Vector2(65,60),Vector2(-45,-100),Vector2(120,70),Vector2(-120,115),Vector2(-25,-70),Vector2(0,0)]
		_:
			offsets = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
	var safe_index := clampi(index, 0, offsets.size() - 1)
	return route_point((base + offsets[safe_index]).clamp(Vector2(90,155), Vector2(1190,590)), level)

static func bug_point(base: Vector2, index: int, level: int) -> Vector2:
	var offsets: Array[Vector2]
	match formation_variant(level):
		1: offsets = [Vector2(90,-65),Vector2(-50,95),Vector2(-70,-20)]
		2: offsets = [Vector2(135,35),Vector2(95,-115),Vector2(-145,110)]
		3: offsets = [Vector2(120,90),Vector2(-135,-95),Vector2(70,125)]
		4: offsets = [Vector2(75,-105),Vector2(125,95),Vector2(-110,120)]
		5: offsets = [Vector2(130,75),Vector2(-115,-115),Vector2(65,135)]
		_: offsets = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
	var safe_index := clampi(index, 0, offsets.size() - 1)
	return route_point((base + offsets[safe_index]).clamp(Vector2(80,145), Vector2(1200,585)), level)

static func safe_point(base: Vector2, level: int) -> Vector2:
	var offsets := [Vector2.ZERO,Vector2(-90,-40),Vector2(110,-135),Vector2(-120,-115),Vector2(70,-180),Vector2(-160,-65)]
	return route_point((base + offsets[formation_variant(level)]).clamp(Vector2(110,180), Vector2(1170,590)), level)

static func background_variant(level: int) -> int:
	return posmod(maxi(1, level) - 1, BACKGROUND_LABELS.size())

static func background_label(level: int) -> String:
	return BACKGROUND_LABELS[background_variant(level)]

static func background_tint(level: int) -> Color:
	return BACKGROUND_TINTS[background_variant(level)]

static func background_overlay(level: int) -> Color:
	return BACKGROUND_OVERLAYS[background_variant(level)]

static func status_rect(touch_visible: bool) -> Rect2:
	return STATUS_TOUCH_RECT if touch_visible else STATUS_DESKTOP_RECT

static func touch_centers() -> Dictionary:
	var rects := touch_action_rects()
	return {
		"tongue": Rect2(rects.tongue).get_center(),
		"leap": Rect2(rects.leap).get_center(),
		"boost": Rect2(rects.boost).get_center(),
		"depth": Rect2(rects.depth).get_center(),
	}

static func touch_radii() -> Dictionary:
	return {
		"tongue": 42.0,
		"leap": 42.0,
		"boost": 42.0,
		"depth": 42.0,
	}

static func touch_action_rects() -> Dictionary:
	return {
		"tongue": Rect2(350.0, 622.0, 205.0, 84.0),
		"leap": Rect2(575.0, 622.0, 205.0, 84.0),
		"boost": Rect2(800.0, 622.0, 205.0, 84.0),
		"depth": Rect2(1025.0, 622.0, 205.0, 84.0),
	}

static func touch_movement_at(position: Vector2) -> bool:
	return TOUCH_MOVEMENT_RECT.has_point(position)

static func clamp_touch_target(position: Vector2) -> Vector2:
	return position.clamp(
		TOUCH_MOVEMENT_RECT.position,
		TOUCH_MOVEMENT_RECT.end - Vector2.ONE
	)

static func touch_action_at(position: Vector2) -> String:
	if HOME_RECT.has_point(position):
		return "home"
	if PAUSE_RECT.has_point(position):
		return "pause"
	var rects := touch_action_rects()
	for action: String in rects:
		if Rect2(rects[action]).has_point(position):
			return action
	if touch_movement_at(position):
		return "steer"
	return ""

static func essential_rects(touch_visible: bool) -> Dictionary:
	return {
		"objective": OBJECTIVE_RECT,
		"lives": LIVES_RECT,
		"pause": PAUSE_RECT,
		"home": HOME_RECT,
		"energy": ENERGY_RECT,
		"status": status_rect(touch_visible),
		"touch_guide": TOUCH_GUIDE_RECT if touch_visible else Rect2(),
		"touch_actions": TOUCH_ACTION_BAR_RECT if touch_visible else Rect2(),
	}

static func rect_inside_canvas(rect: Rect2, margin: float = 0.0) -> bool:
	var bounds := Rect2(
		Vector2(margin, margin),
		CANVAS_SIZE - Vector2(margin, margin) * 2.0
	)
	return bounds.encloses(rect)

static func circles_overlap(
	center_a: Vector2,
	radius_a: float,
	center_b: Vector2,
	radius_b: float,
	gap: float = 8.0
) -> bool:
	return center_a.distance_to(center_b) < radius_a + radius_b + gap
