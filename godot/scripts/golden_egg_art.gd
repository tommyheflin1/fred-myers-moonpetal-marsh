extends RefCounted
## Original superhero Fred collectible; local generated texture, no network dependency.
## The secret room and reveal share this exact frog-medallion egg. No gameplay state.

const SILHOUETTE_SEGMENTS := 96
const LAYERS := 24
const HERO_TEXTURE = preload("res://assets/art/fred-superhero-golden-egg-v1.png")

static func outline(center: Vector2, size: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(SILHOUETTE_SEGMENTS + 1):
		var angle := TAU * float(i) / SILHOUETTE_SEGMENTS
		# Narrow crown, full lower shell; silhouette is recognizably an egg, not a coin.
		points.append(center + Vector2(cos(angle) * (86.0 + 15.0 * sin(angle)), sin(angle) * 126.0) * size)
	return points

static func ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(65):
		var angle := TAU * float(i) / 64.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	return points

static func draw_egg(canvas: CanvasItem, center: Vector2, size: float = 1.0, time: float = 0.0, reduced_motion: bool = true) -> void:
	if size <= 0.0:
		return
	# One cached texture, no viewport, particles, runtime image decoding or shader dependency.
	var extent := Vector2(224, 264) * size
	var shimmer := 1.0 if reduced_motion else 0.98 + 0.02 * sin(time * 0.7)
	canvas.draw_texture_rect(HERO_TEXTURE, Rect2(center - extent * 0.5, extent), false, Color(shimmer, shimmer, shimmer, 1.0))
	if not reduced_motion:
		# Restrained travelling rim highlights stay clear of Fred's face and controls.
		for index in range(3):
			var phase := time * 0.35 + float(index) * TAU / 3.0
			var at := center + Vector2(cos(phase) * 85, sin(phase) * 111) * size
			var strength := pow(maxf(0.0, sin(phase)), 8.0) * 0.3
			canvas.draw_line(at - Vector2(3, 0) * size, at + Vector2(3, 0) * size, Color(1, 0.96, 0.72, strength), size, true)
	return

static func draw_fallback(canvas: CanvasItem, center: Vector2, size: float = 1.0) -> void:
	if size <= 0.0:
		return
	canvas.draw_colored_polygon(ellipse(center + Vector2(0, 129) * size, Vector2(77, 7) * size), Color(0.0, 0.0, 0.0, 0.32))
	canvas.draw_colored_polygon(outline(center, size), Color("70410c"))
	# Nested contours provide a continuous warm-to-pale metallic volume, without textures.
	for layer in range(LAYERS):
		var t := float(layer) / float(LAYERS - 1)
		var gold := Color("b77a16").lerp(Color("fff1a4"), t)
		canvas.draw_colored_polygon(outline(center + Vector2(-18, -24) * size * t, size * (0.97 - t * 0.59)), gold)
	canvas.draw_polyline(outline(center, size), Color("ffe390"), 2.3 * size, true)
	canvas.draw_colored_polygon(ellipse(center + Vector2(-32, -81) * size, Vector2(13, 25) * size), Color(1.0, 0.98, 0.81, 0.65))
	# Recessed emerald enamel with concentric machined-gold edging.
	var badge := center + Vector2(0, 14) * size
	canvas.draw_circle(badge + Vector2(2, 4) * size, 69 * size, Color("89530c"))
	canvas.draw_circle(badge, 68 * size, Color("ffe898"))
	canvas.draw_circle(badge, 63 * size, Color("b78126"))
	canvas.draw_circle(badge, 60 * size, Color("092e2c"))
	canvas.draw_circle(badge - Vector2(3, 4) * size, 56 * size, Color("125245"))
	canvas.draw_arc(badge, 63 * size, PI * 1.08, PI * 1.91, 48, Color("fff7c4"), 2.0 * size, true)
	# Small lily leaves form a wreath, leaving the frog silhouette unmistakable.
	for side in [-1.0, 1.0]:
		for row in range(4):
			var leaf := badge + Vector2(side * (48 - row * 6), 15 + row * 9) * size
			canvas.draw_colored_polygon(PackedVector2Array([leaf, leaf + Vector2(side * 1, -12) * size, leaf + Vector2(side * 8, -5) * size, leaf + Vector2(side * 7, 2) * size]), Color("d5b654"))
	# Original superhero Fred: sweeping crimson cape, navy suit and a gold F crest.
	# No borrowed superhero insignia or external character assets.
	var cape := PackedVector2Array()
	for point in [Vector2(-18, -6), Vector2(-45, 16), Vector2(-48, 37), Vector2(-26, 31), Vector2(0, 54), Vector2(26, 31), Vector2(48, 37), Vector2(45, 16), Vector2(18, -6)]:
		cape.append(badge + point * size)
	canvas.draw_colored_polygon(cape, Color("9d233e"))
	canvas.draw_polyline(cape, Color("ff7961"), 1.8 * size, true)
	canvas.draw_line(badge + Vector2(-19, 8) * size, badge + Vector2(-36, 32) * size, Color("e24a4b"), 3 * size, true)
	canvas.draw_line(badge + Vector2(19, 8) * size, badge + Vector2(36, 32) * size, Color("e24a4b"), 3 * size, true)
	canvas.draw_colored_polygon(ellipse(badge + Vector2(0, 29) * size, Vector2(27, 23) * size), Color("163b59"))
	canvas.draw_colored_polygon(ellipse(badge + Vector2(0, 25) * size, Vector2(22, 17) * size), Color("246680"))
	var crest := badge + Vector2(0, 33) * size
	canvas.draw_colored_polygon(PackedVector2Array([crest + Vector2(-11, -10) * size, crest + Vector2(11, -10) * size, crest + Vector2(9, 4) * size, crest + Vector2(0, 12) * size, crest + Vector2(-9, 4) * size]), Color("ffe18a"))
	canvas.draw_line(crest + Vector2(-3, 5) * size, crest + Vector2(-3, -6) * size, Color("17384d"), 3 * size, true)
	canvas.draw_line(crest + Vector2(-3, -6) * size, crest + Vector2(5, -6) * size, Color("17384d"), 3 * size, true)
	canvas.draw_line(crest + Vector2(-3, -1) * size, crest + Vector2(3, -1) * size, Color("17384d"), 3 * size, true)
	# Broad frog jaw, raised eyes, confident smile and unmistakable domino mask.
	var face := badge + Vector2(0, -14) * size
	canvas.draw_colored_polygon(ellipse(face + Vector2(0, 7) * size, Vector2(42, 30) * size), Color("092d25"))
	canvas.draw_colored_polygon(ellipse(face, Vector2(40, 28) * size), Color("70b64c"))
	canvas.draw_colored_polygon(ellipse(face - Vector2(0, 5) * size, Vector2(35, 19) * size), Color("a0d864"))
	canvas.draw_colored_polygon(ellipse(face + Vector2(0, 15) * size, Vector2(29, 11) * size), Color("e4df88"))
	canvas.draw_line(face + Vector2(-25, -21) * size, face + Vector2(25, -21) * size, Color("122a43"), 12 * size, true)
	for side in [-1.0, 1.0]:
		var eye := face + Vector2(side * 24, -22) * size
		canvas.draw_circle(eye, 16 * size, Color("284e29"))
		canvas.draw_circle(eye - Vector2(0, 2) * size, 14 * size, Color("142d46"))
		canvas.draw_line(eye + Vector2(side * 8, -10) * size, eye + Vector2(side * 18, -15) * size, Color("142d46"), 5 * size, true)
		canvas.draw_circle(eye - Vector2(0, 3) * size, 9.2 * size, Color("fff1a0"))
		canvas.draw_colored_polygon(ellipse(eye - Vector2(0, 3) * size, Vector2(4, 7.5) * size), Color("09262a"))
		canvas.draw_circle(eye + Vector2(-2, -6) * size, 2.7 * size, Color("ffffff"))
		canvas.draw_circle(face + Vector2(side * 9, -1) * size, 1.8 * size, Color("426a30"))
	canvas.draw_arc(face + Vector2(0, -3) * size, 27 * size, 0.32, PI - 0.32, 36, Color("30512b"), 2.4 * size, true)
	# Moonpetal jewel and fixed star glints: no flashing, input or simulation side effects.
	var jewel := center + Vector2(0, -89) * size
	canvas.draw_colored_polygon(PackedVector2Array([jewel + Vector2(0, -14) * size, jewel + Vector2(10, 0) * size, jewel + Vector2(0, 14) * size, jewel + Vector2(-10, 0) * size]), Color("fff4bf"))
	canvas.draw_colored_polygon(PackedVector2Array([jewel + Vector2(0, -9) * size, jewel + Vector2(6, 0) * size, jewel + Vector2(0, 9) * size, jewel + Vector2(-6, 0) * size]), Color("42a285"))
	for glint in [Vector2(-53, -65), Vector2(66, 61)]:
		var at: Vector2 = center + glint * size
		canvas.draw_line(at - Vector2(0, 9) * size, at + Vector2(0, 9) * size, Color("fff9d5"), 2 * size, true)
		canvas.draw_line(at - Vector2(6, 0) * size, at + Vector2(6, 0) * size, Color("fff9d5"), 2 * size, true)
