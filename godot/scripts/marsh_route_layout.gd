class_name FredMarshRouteLayout
extends RefCounted

const CANVAS_SIZE := Vector2(1280.0, 720.0)
const PLAYFIELD_RECT := Rect2(15.0, 105.0, 1250.0, 530.0)
const OBJECTIVE_RECT := Rect2(280.0, 10.0, 500.0, 48.0)
const LIVES_RECT := Rect2(795.0, 10.0, 185.0, 48.0)
const PAUSE_RECT := Rect2(990.0, 10.0, 120.0, 56.0)
const HOME_RECT := Rect2(1125.0, 10.0, 125.0, 56.0)
# Two explicit, non-overlapping text bands prevent the top panels from
# covering metadata at wide phone/tablet aspect ratios.
const CAMPAIGN_TEXT_RECT := Rect2(18.0, 61.0, 760.0, 19.0)
const ROUTE_SUMMARY_RECT := Rect2(18.0, 82.0, 760.0, 20.0)
# The energy label and fill bar own separate right-side slots. No word is
# printed over a narrow box and neither slot shares space with route metadata.
const ENERGY_LABEL_RECT := Rect2(795.0, 73.0, 105.0, 24.0)
const ENERGY_RECT := Rect2(905.0, 76.0, 345.0, 18.0)
const DEPTH_STATUS_RECT := Rect2(515.0, 110.0, 250.0, 28.0)
# Feedback belongs in the empty footer, not over the safe-perch label or water.
const STATUS_TOUCH_RECT := Rect2(500.0, 642.0, 340.0, 42.0)
const STATUS_DESKTOP_RECT := Rect2(820.0, 642.0, 410.0, 42.0)
const TELEMETRY_ANCHOR := Vector2(25.0, 700.0)
const PAUSED_RESUME_RECT := Rect2(490.0, 410.0, 300.0, 65.0)
const TOUCH_ACTION_WHEEL_CENTER := Vector2(160.0, 570.0)
const TOUCH_ACTION_WHEEL_RADIUS := 112.0
const TOUCH_ACTION_WHEEL_RECT := Rect2(48.0, 458.0, 224.0, 224.0)
const TOUCH_CONTROL_PAD_CENTER := Vector2(1120.0, 585.0)
const TOUCH_CONTROL_PAD_RADIUS := 86.0
const TOUCH_CONTROL_PAD_RECT := Rect2(1034.0, 499.0, 172.0, 172.0)
const TOUCH_SAFE_EDGE_MARGIN := 36.0
const TOUCH_ACTOR_CLEARANCE := 64.0
const TOUCH_OVERLAY_ALPHA := 0.16
const TOUCH_CONTROL_ALPHA := 0.34
const TOUCH_CONTROL_ACTIVE_ALPHA := 0.68
const TOUCH_OUTLINE_ALPHA := 0.58
# Compatibility aliases keep existing layout consumers on one authoritative contract.
const TOUCH_MOVEMENT_RECT := TOUCH_CONTROL_PAD_RECT
const TOUCH_GUIDE_RECT := TOUCH_CONTROL_PAD_RECT
const TOUCH_ACTION_BAR_RECT := TOUCH_ACTION_WHEEL_RECT
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

static func start_point(base: Vector2, level: int) -> Vector2:
	var position := route_point(base, level)
	if is_reversed(level):
		position.x = TOUCH_CONTROL_PAD_CENTER.x
		position.y = minf(position.y, TOUCH_CONTROL_PAD_RECT.position.y - TOUCH_ACTOR_CLEARANCE)
	else:
		position.x = TOUCH_ACTION_WHEEL_CENTER.x
		position.y = minf(position.y, TOUCH_ACTION_WHEEL_RECT.position.y - TOUCH_ACTOR_CLEARANCE)
	return position

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
	return {
		"tongue": TOUCH_ACTION_WHEEL_CENTER + Vector2(-48.0, -48.0),
		"leap": TOUCH_ACTION_WHEEL_CENTER + Vector2(48.0, -48.0),
		"depth": TOUCH_ACTION_WHEEL_CENTER + Vector2(-48.0, 48.0),
		"boost": TOUCH_ACTION_WHEEL_CENTER + Vector2(48.0, 48.0),
	}

static func touch_radii() -> Dictionary:
	return {
		"tongue": 42.0,
		"leap": 42.0,
		"boost": 42.0,
		"depth": 42.0,
	}

static func touch_action_rects() -> Dictionary:
	var centers := touch_centers()
	var radii := touch_radii()
	var rects := {}
	for action: String in centers:
		var radius := float(radii[action])
		var center := Vector2(centers[action])
		rects[action] = Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	return {
		"tongue": rects.tongue,
		"leap": rects.leap,
		"depth": rects.depth,
		"boost": rects.boost,
	}

static func touch_movement_at(position: Vector2) -> bool:
	return position.distance_to(TOUCH_CONTROL_PAD_CENTER) <= TOUCH_CONTROL_PAD_RADIUS

static func clamp_touch_target(position: Vector2) -> Vector2:
	var delta := position - TOUCH_CONTROL_PAD_CENTER
	if delta.length() <= TOUCH_CONTROL_PAD_RADIUS:
		return position
	return TOUCH_CONTROL_PAD_CENTER + delta.normalized() * TOUCH_CONTROL_PAD_RADIUS

static func touch_movement_vector(position: Vector2) -> Vector2:
	var delta := clamp_touch_target(position) - TOUCH_CONTROL_PAD_CENTER
	if delta.length() < TOUCH_MOVEMENT_DEADZONE:
		return Vector2.ZERO
	return delta.normalized()

static func touch_action_at(position: Vector2, paused: bool = false) -> String:
	if HOME_RECT.has_point(position):
		return "home"
	if PAUSE_RECT.has_point(position):
		return "pause"
	if paused and PAUSED_RESUME_RECT.has_point(position):
		return "pause"
	var centers := touch_centers()
	var radii := touch_radii()
	for action: String in centers:
		if position.distance_to(Vector2(centers[action])) <= float(radii[action]):
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
		"campaign": CAMPAIGN_TEXT_RECT,
		"route_summary": ROUTE_SUMMARY_RECT,
		"energy_label": ENERGY_LABEL_RECT,
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
