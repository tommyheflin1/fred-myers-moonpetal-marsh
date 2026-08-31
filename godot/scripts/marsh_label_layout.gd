class_name FredMarshLabelLayout
extends RefCounted

# App-owned presentation only. A level-wide movement envelope keeps captions
# from hopping between slots as bugs fly, lilies drift, or the camera follows.
const MAX_LABELS := 9
const MAX_OBSTACLES := 32
const GAP := 3.0
const FALLBACK_STEP := Vector2(32,24)

static func text_rect(anchor: Vector2, size: Vector2, ascent: float) -> Rect2:
	return Rect2(anchor - Vector2(size.x * 0.5, ascent), size).grow(1.0)

static func _fits(rect: Rect2, allowed: Rect2, hard: Array[Rect2]) -> bool:
	if not allowed.encloses(rect):
		return false
	for blocked in hard:
		if rect.grow(GAP).intersects(blocked):
			return false
	return true

static func arrange(requests: Array[Dictionary], scenery: Array[Dictionary], reserved: Array[Rect2], allowed: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if requests.size() > MAX_LABELS or scenery.size() > MAX_OBSTACLES or reserved.size() > MAX_OBSTACLES or not allowed.position.is_finite() or not allowed.size.is_finite() or allowed.size.x <= 0 or allowed.size.y <= 0:
		return result
	var hard: Array[Rect2] = reserved.duplicate()
	var ids: Array[String] = []
	for request in requests:
		if not request.has_all(["id","center","travel","offset","size","ascent","options"]):
			return []
		var id := str(request.id)
		var center := Vector2(request.center)
		var travel := Vector2(request.travel)
		var size := Vector2(request.size)
		var preferred := Vector2(request.offset)
		var ascent := float(request.ascent)
		if id.is_empty() or id in ids or not center.is_finite() or not travel.is_finite() or not size.is_finite() or not preferred.is_finite() or not is_finite(ascent) or travel.x < 0 or travel.y < 0 or size.x <= 0 or size.y <= 0 or ascent < 0 or ascent > size.y:
			return []
		ids.append(id)
		var candidates := PackedVector2Array([preferred])
		if not bool(request.get("fixed", false)):
			if request.options.size() > 16:
				return []
			candidates.append_array(request.options)
			for row in range(-4,5):
				for column in range(-4,5):
					candidates.append(Vector2(column,row) * FALLBACK_STEP)
		var best := {}
		var score := INF
		for offset in candidates:
			if not offset.is_finite():
				return []
			var box := text_rect(center + offset, size, ascent)
			var envelope := Rect2(box.position - travel, box.size + travel * 2)
			if not _fits(envelope, allowed, hard):
				continue
			var overlap := 0.0
			for obstacle in scenery:
				if bool(request.get("fixed", false)) and str(obstacle.id) == id:
					continue
				var intersection := envelope.grow(GAP).intersection(Rect2(obstacle.rect))
				overlap += intersection.get_area()
			var candidate_score := overlap * 1000 + offset.distance_to(preferred)
			if candidate_score < score:
				score = candidate_score
				best = request.duplicate()
				best.offset = offset
				best.envelope = envelope
				best.scenery_overlap = overlap
				best.moved = offset.distance_to(preferred) > 1.0
				if score == 0:
					break
		if best.is_empty():
			# Never silently overlap another caption or a touch control.
			return []
		result.append(best)
		hard.append(best.envelope)
	return result

static func _wrap(text: String, font: Font, size: int, width: float) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in text.split(" ", false):
		var proposed := word if current.is_empty() else current + " " + word
		if not current.is_empty() and font.get_string_size(proposed, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			lines.append(current)
			current = word
		else:
			current = proposed
	if not current.is_empty():
		lines.append(current)
	return lines

static func footer(text: String, font: Font, requested_size: int, available: Vector2) -> Dictionary:
	if font == null or not available.is_finite() or available.x < 30 or available.y < 15:
		return {"valid":false}
	var chosen := clampi(requested_size,13,24)
	var lines: Array[String] = []
	var complete := false
	for size in range(chosen,12,-1):
		lines = _wrap(text, font, size, available.x)
		chosen = size
		var widest := 0.0
		for line in lines:
			widest = maxf(widest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
		if lines.size() <= 2 and lines.size() * font.get_height(size) <= available.y and widest <= available.x:
			complete = true
			break
	if not complete:
		# Only exceptional overlong messages are ellipsized. Never clip a word
		# silently, change the stored feedback, or shrink below 13 logical pixels.
		var capacity := mini(2, int(available.y / font.get_height(chosen)))
		if capacity < 1:
			return {"valid":false}
		lines.resize(mini(lines.size(),capacity))
		for index in lines.size():
			var shortened := lines[index]
			var suffix := "…" if index == lines.size()-1 else ""
			while not shortened.is_empty() and font.get_string_size(shortened+suffix,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen).x > available.x:
				shortened = shortened.left(shortened.length()-1)
			if not suffix.is_empty() and shortened.contains(" "):
				shortened = shortened.left(shortened.rfind(" "))
			lines[index] = shortened.strip_edges() + suffix
	return {"valid":true,"lines":lines,"size":chosen,"line_height":font.get_height(chosen),"ascent":font.get_ascent(chosen),"complete":complete}
