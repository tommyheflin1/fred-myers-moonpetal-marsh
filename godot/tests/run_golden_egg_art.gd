extends SceneTree

const Art = preload("res://scripts/golden_egg_art.gd")
var checks := 0
var failures := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _init() -> void:
	var origin := Vector2(640, 330)
	var points := Art.outline(origin, 1.0)
	check(points.size() == 97, "smooth closed shell contour")
	check(points[0].is_equal_approx(points[-1]), "no visible seam in shell")
	var top_width := 0.0
	var lower_width := 0.0
	for point in points:
		check(point.is_finite(), "finite shell geometry")
		check(Rect2(540, 200, 200, 260).has_point(point), "shell stays clear of reveal name and controls")
		if point.y < origin.y - 50:
			top_width = maxf(top_width, absf(point.x - origin.x))
		if point.y > origin.y + 50:
			lower_width = maxf(lower_width, absf(point.x - origin.x))
	check(top_width < lower_width, "egg has tapered crown and fuller base")
	var small := Art.outline(origin, 0.62)
	for i in range(points.size()):
		check(small[i].is_equal_approx(origin + (points[i] - origin) * 0.62), "same artwork scales for secret room")
	check(Art.outline(origin, 1.0) == points, "art is deterministic and independent of time")
	var source := FileAccess.get_file_as_string("res://scripts/golden_egg_art.gd")
	check(not source.contains("http") and not source.contains("FileAccess"), "collectible uses bundled artwork without runtime downloads")
	check(Art.HERO_TEXTURE.get_width() > 500, "premium hero texture is imported at production resolution")
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	var egg_draw := main.split("func _draw_canonical_golden_egg(")[1].split("\nfunc ")[0]
	check(egg_draw.contains("GoldenEggArt.draw_egg(self, center, scale, visual_time, reduced_motion)"), "room and reveal share animated art and reduced-motion control")
	print("GOLDEN_EGG_ART: ", checks, " checks, ", failures, " failed")
	quit(1 if failures else 0)
