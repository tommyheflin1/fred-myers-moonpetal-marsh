class_name FredMarshRouteLayout
extends RefCounted

const CANVAS_SIZE := Vector2(1280.0, 720.0)
const PLAYFIELD_RECT := Rect2(15.0, 105.0, 1250.0, 530.0)
const OBJECTIVE_RECT := Rect2(300.0, 14.0, 550.0, 56.0)
const LIVES_RECT := Rect2(870.0, 14.0, 210.0, 56.0)
const PAUSE_RECT := Rect2(1090.0, 14.0, 160.0, 56.0)
const ENERGY_RECT := Rect2(900.0, 78.0, 330.0, 18.0)
const STATUS_TOUCH_RECT := Rect2(340.0, 642.0, 500.0, 42.0)
const STATUS_DESKTOP_RECT := Rect2(820.0, 642.0, 410.0, 42.0)
const TELEMETRY_ANCHOR := Vector2(25.0, 700.0)
const DPAD_CENTER := Vector2(150.0, 545.0)
const DPAD_OFFSET := 58.0
const DPAD_RADIUS := 34.0

const BACKGROUND_LABELS: Array[String] = [
	"Firefly Glade",
	"Moonlit Channel",
	"Mistflower Reach",
	"Rainleaf Basin",
]
const BACKGROUND_TINTS: Array[Color] = [
	Color("e6fff0"),
	Color("d8ecff"),
	Color("f0ddff"),
	Color("d9fff9"),
]
const BACKGROUND_OVERLAYS: Array[Color] = [
	Color(0.08, 0.31, 0.18, 0.12),
	Color(0.06, 0.18, 0.42, 0.16),
	Color(0.31, 0.13, 0.39, 0.15),
	Color(0.03, 0.34, 0.32, 0.14),
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
		"tongue": Vector2(1160.0, 460.0),
		"leap": Vector2(1040.0, 580.0),
		"depth": Vector2(935.0, 470.0),
		"boost": Vector2(1160.0, 595.0),
	}

static func touch_radii() -> Dictionary:
	return {
		"tongue": 48.0,
		"leap": 48.0,
		"depth": 46.0,
		"boost": 48.0,
	}

static func touch_action_at(position: Vector2) -> String:
	if PAUSE_RECT.has_point(position):
		return "pause"
	if position.x < 320.0 and position.y > 390.0:
		var delta := position - DPAD_CENTER
		if delta.length() <= 150.0:
			if absf(delta.x) > absf(delta.y):
				return "right" if delta.x >= 0.0 else "left"
			return "down" if delta.y >= 0.0 else "up"
	var centers := touch_centers()
	var radii := touch_radii()
	for action: String in centers:
		if position.distance_to(Vector2(centers[action])) <= float(radii[action]) + 12.0:
			return action
	return ""

static func essential_rects(touch_visible: bool) -> Dictionary:
	return {
		"objective": OBJECTIVE_RECT,
		"lives": LIVES_RECT,
		"pause": PAUSE_RECT,
		"energy": ENERGY_RECT,
		"status": status_rect(touch_visible),
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
