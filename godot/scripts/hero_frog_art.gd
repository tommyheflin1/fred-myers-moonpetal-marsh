class_name FredHeroFrogArt
extends RefCounted

const Surface = preload("res://scripts/character_surface.gd")
const HERO_STYLES := {
	"classic_fred": {"chest":1.0,"head":Vector2.ONE,"arm":1.0,"thigh":1.0,"eye":Vector2.ONE},
	"girl_hero": {"chest":0.94,"head":Vector2(1.02,1.10),"arm":0.91,"thigh":0.96,"eye":Vector2(1.08,1.12)},
	"boy_hero": {"chest":1.12,"head":Vector2(1.04,0.98),"arm":1.15,"thigh":1.10,"eye":Vector2(1.02,0.94)},
}

# Original marsh-superhero geometry. All measurements are cosmetic: the existing
# pose controller, contact markers, catalog IDs and collision rules stay authoritative.
const BUILDS := {
	"quick": {"chest":1.06,"torso":1.18,"head":Vector2(0.91,0.79),"arm":1.00,"thigh":1.00},
	"classic": {"chest":1.10,"torso":1.16,"head":Vector2(0.94,0.82),"arm":1.06,"thigh":1.04},
	"power": {"chest":1.18,"torso":1.12,"head":Vector2(0.88,0.78),"arm":1.24,"thigh":1.20},
	"pocket_hopper": {"chest":1.01,"torso":1.08,"head":Vector2(0.98,0.87),"arm":0.88,"thigh":0.92},
	"springy": {"chest":1.04,"torso":1.23,"head":Vector2(0.90,0.78),"arm":0.92,"thigh":1.06},
	"swift": {"chest":1.03,"torso":1.20,"head":Vector2(0.88,0.77),"arm":0.94,"thigh":0.96},
	"trail_fit": {"chest":1.12,"torso":1.17,"head":Vector2(0.92,0.80),"arm":1.10,"thigh":1.10},
	"strong": {"chest":1.22,"torso":1.16,"head":Vector2(0.87,0.77),"arm":1.30,"thigh":1.24},
}
const OUTFITS := {
	"marsh_runner": {"signature":"lotus sprint harness","shoulder":0.35,"bracer":0.72,"belt":"wrap","chest":"lotus"},
	"trail_scout": {"signature":"cross-body expedition armor","shoulder":0.70,"bracer":0.90,"belt":"pouches","chest":"compass"},
	"moon_champion": {"signature":"crescent guardian pauldrons","shoulder":1.12,"bracer":1.10,"belt":"sash","chest":"moon"},
	"firefly_hero": {"signature":"firefly tactical battle suit","shoulder":1.00,"bracer":1.20,"belt":"utility","chest":"firefly"},
	"pond_pilot": {"signature":"aviator rescue harness","shoulder":0.64,"bracer":1.00,"belt":"utility","chest":"wings"},
	"rain_ranger": {"signature":"storm-shell shoulder mantle","shoulder":1.18,"bracer":0.85,"belt":"wrap","chest":"drop"},
	"bug_catcher": {"signature":"field-scout bandolier","shoulder":0.58,"bracer":0.95,"belt":"pouches","chest":"beetle"},
	"star_jumper": {"signature":"star acrobat light armor","shoulder":0.90,"bracer":1.08,"belt":"sash","chest":"star"},
	"lily_lifeguard": {"signature":"buoyant marsh rescue suit","shoulder":0.86,"bracer":1.04,"belt":"rescue","chest":"rescue"},
	"petal_guardian": {"signature":"rose-petal layered guardian armor","shoulder":0.62,"bracer":0.82,"belt":"sash","chest":"petal"},
	"moon_blossom": {"signature":"butterfly moon-silk bow armor","shoulder":0.74,"bracer":0.88,"belt":"sash","chest":"butterfly"},
	"reed_sentinel": {"signature":"jade shield and plated trail armor","shoulder":1.24,"bracer":1.25,"belt":"utility","chest":"shield"},
	"storm_striker": {"signature":"cobalt lightning-strike gauntlets","shoulder":1.10,"bracer":1.30,"belt":"wrap","chest":"bolt"},
}

# Fixed art marks, not random state: markings stay attached through every pose.
# Keep the central nose and mouth clear at phone scale.
const FACE_MARKS := [
	Vector4(-22,-10,2.9,1.6),Vector4(-18,-12,1.5,0.8),Vector4(-23,-5,1.6,1.1),
	Vector4(-19,-3,2.1,1.2),Vector4(-24,1,1.5,1.8),Vector4(-20,5,1.6,0.9),
	Vector4(-16,2,1.1,0.6),Vector4(-13,-11,0.9,0.6),Vector4(-8,-13,1.1,0.6),
	Vector4(22,-10,2.5,1.5),Vector4(18,-12,1.6,0.9),Vector4(23,-4,1.8,1.1),
	Vector4(19,-1,2.0,1.3),Vector4(24,2,1.3,1.5),Vector4(20,6,1.9,0.8),
	Vector4(16,3,1.0,0.7),Vector4(12,-11,1.1,0.6),Vector4(7,-14,0.9,0.6),
]

static func skin_patch(mark: Vector4, variation: int) -> PackedVector2Array:
	if not mark.is_finite() or mark.z <= 0 or mark.w <= 0 or maxf(mark.z,mark.w) > 4:
		return PackedVector2Array()
	var points := PackedVector2Array()
	for index in 10:
		var angle := TAU*float(index)/10.0
		var irregularity := 0.80+float(posmod(index*7+variation*3,5))*0.05
		points.append(Vector2(mark.x,mark.y)+Vector2(cos(angle)*mark.z,sin(angle)*mark.w)*irregularity)
	return Surface.rounded_contour(points)

static func organic_curve(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 2 or points.size() > 12:
		return result
	for point in points:
		if not point.is_finite(): return result
	for index in points.size()-1:
		var a := points[maxi(index-1,0)]
		var b := points[index]
		var c := points[index+1]
		var d := points[mini(index+2,points.size()-1)]
		for step in 4:
			var t := float(step)/4.0
			result.append(0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
	result.append(points[-1])
	return result

static func badge_colors(points: PackedVector2Array, base: Color) -> PackedColorArray:
	var colors := PackedColorArray()
	for point in points:
		var shade := clampf((point.y+point.x*0.3+1.0)/17.0,0,1)
		var color := base.lightened(0.28).lerp(base.darkened(0.38),shade)
		color.a = base.a
		colors.append(color)
	return colors

static func build(id: String, hero_style: String = "classic_fred") -> Dictionary:
	var result := Dictionary(BUILDS.get(id,BUILDS.quick)).duplicate(true)
	var style: Dictionary = HERO_STYLES.get(hero_style,HERO_STYLES.classic_fred)
	for key: String in ["chest","head","arm","thigh"]:
		result[key] *= style[key]
	return result

static func outfit(id: String) -> Dictionary:
	return Dictionary(OUTFITS.get(id,OUTFITS.marsh_runner)).duplicate(true)

static func upper_arm(points: PackedVector2Array, girth: float) -> PackedVector2Array:
	if points.size() != 3 or not is_finite(girth) or girth <= 0:
		return PackedVector2Array()
	return segment(points[0],points[1],7.2*girth,8.2*girth,5.5*girth)

static func forearm(points: PackedVector2Array, girth: float) -> PackedVector2Array:
	if points.size() != 3 or not is_finite(girth) or girth <= 0:
		return PackedVector2Array()
	return segment(points[1],points[2],5.5*girth,6.8*girth,4.0*girth)

static func segment(start: Vector2, end: Vector2, shoulder: float, belly: float, wrist: float) -> PackedVector2Array:
	if not start.is_finite() or not end.is_finite() or start.is_equal_approx(end) or not is_finite(shoulder+belly+wrist) or minf(shoulder,minf(belly,wrist)) <= 0:
		return PackedVector2Array()
	var direction := (end-start).normalized()
	var normal := Vector2(-direction.y,direction.x)
	var middle := start.lerp(end,0.42)
	return Surface.rounded_contour(PackedVector2Array([
		start-direction*2+normal*shoulder,start-direction*3-normal*shoulder,
		middle-normal*belly,end-normal*wrist,end+direction*2,
		end+normal*wrist,middle+normal*belly,
	]))

static func hand_web(hand: Vector2, forward: Vector2) -> PackedVector2Array:
	var normal := Vector2(-forward.y,forward.x)
	return PackedVector2Array([hand-normal*4,hand+forward*6.7-normal*5.5,
		hand+forward*8.5,hand+forward*6.7+normal*5.5,hand+normal*4])

static func suit(hem: float) -> PackedVector2Array:
	return Surface.rounded_contour(PackedVector2Array([
		Vector2(-26,-5),Vector2(-21,-10),Vector2(-12,-7),Vector2(-7,0),Vector2(0,8),
		Vector2(7,0),Vector2(12,-7),Vector2(21,-10),Vector2(26,-5),Vector2(24,8),
		Vector2(18,hem),Vector2(9,hem+3),Vector2(0,hem+1),Vector2(-9,hem+3),
		Vector2(-18,hem),Vector2(-24,8),
	]))

static func chest_panel(side: float, kind: String) -> PackedVector2Array:
	var outer := 23.0
	var bottom := 14.0
	if kind == "rescue":
		outer = 25.0
		bottom = 19.0
	elif kind in ["lotus","star"]:
		outer = 20.0
	elif kind == "drop":
		bottom = 17.0
	var result := PackedVector2Array()
	for point: Vector2 in [Vector2(4,6),Vector2(11,-2),Vector2(outer,-4),Vector2(outer+1,5),Vector2(18,bottom),Vector2(5,bottom-2)]:
		result.append(Vector2(point.x*side,point.y))
	return Surface.rounded_contour(result)

static func shoulder_panel(center: Vector2, side: float, strength: float, kind: String) -> PackedVector2Array:
	var result := PackedVector2Array()
	var width := 7.0+strength*4.0
	for point: Vector2 in [Vector2(-6,-6),Vector2(1,-8),Vector2(width,-3),Vector2(width+1,4),Vector2(6,8),Vector2(-5,4)]:
		if kind == "star" and point.x > width-1:
			point.x += 2.0
		result.append(center+Vector2(point.x*side,point.y))
	return Surface.rounded_contour(result)

static func emblem(kind: String) -> PackedVector2Array:
	match kind:
		"petal": return PackedVector2Array([Vector2(0,0),Vector2(3,4),Vector2(7,3),Vector2(6,8),Vector2(3,12),Vector2(0,14),Vector2(-3,12),Vector2(-6,8),Vector2(-7,3),Vector2(-3,4)])
		"butterfly": return PackedVector2Array([Vector2(0,5),Vector2(6,0),Vector2(8,3),Vector2(5,8),Vector2(7,12),Vector2(4,14),Vector2(0,10),Vector2(-4,14),Vector2(-7,12),Vector2(-5,8),Vector2(-8,3),Vector2(-6,0)])
		"shield": return PackedVector2Array([Vector2(-7,1),Vector2(0,-1),Vector2(7,1),Vector2(6,9),Vector2(0,15),Vector2(-6,9)])
		"bolt": return PackedVector2Array([Vector2(1,-1),Vector2(7,-1),Vector2(2,5),Vector2(7,5),Vector2(-4,15),Vector2(-1,8),Vector2(-6,8)])
		"lotus": return PackedVector2Array([Vector2(-7,9),Vector2(-4,3),Vector2(-1,6),Vector2(0,0),Vector2(3,5),Vector2(7,3),Vector2(5,10),Vector2(0,13)])
		"compass": return PackedVector2Array([Vector2(0,0),Vector2(3,5),Vector2(7,7),Vector2(2,9),Vector2(0,14),Vector2(-2,9),Vector2(-7,7),Vector2(-3,5)])
		"moon": return PackedVector2Array([Vector2(4,0),Vector2(-2,1),Vector2(-6,6),Vector2(-4,12),Vector2(2,14),Vector2(6,10),Vector2(0,10),Vector2(-2,6),Vector2(0,2)])
		"firefly": return PackedVector2Array([Vector2(0,1),Vector2(3,4),Vector2(8,2),Vector2(6,8),Vector2(3,8),Vector2(1,14),Vector2(-1,14),Vector2(-3,8),Vector2(-6,8),Vector2(-8,2),Vector2(-3,4)])
		"wings": return PackedVector2Array([Vector2(-10,3),Vector2(-4,4),Vector2(0,7),Vector2(4,4),Vector2(10,3),Vector2(7,9),Vector2(2,10),Vector2(0,13),Vector2(-2,10),Vector2(-7,9)])
		"drop": return PackedVector2Array([Vector2(0,0),Vector2(6,8),Vector2(5,12),Vector2(0,15),Vector2(-5,12),Vector2(-6,8)])
		"beetle": return PackedVector2Array([Vector2(-3,0),Vector2(0,3),Vector2(3,0),Vector2(3,5),Vector2(6,8),Vector2(5,12),Vector2(0,15),Vector2(-5,12),Vector2(-6,8),Vector2(-3,5)])
		"star": return PackedVector2Array([Vector2(0,-1),Vector2(2,5),Vector2(8,5),Vector2(3,9),Vector2(5,15),Vector2(0,11),Vector2(-5,15),Vector2(-3,9),Vector2(-8,5),Vector2(-2,5)])
		_: return PackedVector2Array([Vector2(-2,1),Vector2(2,1),Vector2(2,5),Vector2(6,5),Vector2(6,9),Vector2(2,9),Vector2(2,13),Vector2(-2,13),Vector2(-2,9),Vector2(-6,9),Vector2(-6,5),Vector2(-2,5)])
