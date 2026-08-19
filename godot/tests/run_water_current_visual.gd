extends SceneTree

const ITERATIONS := 10000

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	_run.call_deferred()

func _stream_signature(stream: Dictionary) -> String:
	var point_parts: Array[String] = []
	for point: Vector2 in PackedVector2Array(stream.get("points", PackedVector2Array())):
		point_parts.append("%.3f,%.3f" % [point.x, point.y])
	return "%s|%.3f|%.3f" % [";".join(point_parts), float(stream.get("width", 0.0)), float(stream.get("foam", 0.0))]

func _run() -> void:
	var gentle := FredWaterCurrentVisual.profile(1, Vector2.ZERO, 0.0, 3.25, false)
	var gentle_repeat := FredWaterCurrentVisual.profile(1, Vector2.ZERO, 0.0, 3.25, false)
	var strong := FredWaterCurrentVisual.profile(72, Vector2(145.0, 18.0), 0.0, 3.25, false)
	var reversed := FredWaterCurrentVisual.profile(72, Vector2(-145.0, 0.0), 0.0, 3.25, false)
	var underwater := FredWaterCurrentVisual.profile(72, Vector2(145.0, 18.0), 1.0, 3.25, false)
	var reduced_a := FredWaterCurrentVisual.profile(72, Vector2(145.0, 18.0), 0.0, 3.25, true)
	var reduced_b := FredWaterCurrentVisual.profile(72, Vector2(145.0, 18.0), 0.0, 99.0, true)

	check(gentle == gentle_repeat, "current profile is deterministic")
	check(float(gentle.direction) > 0.0, "odd-level ambient current follows the route")
	check(float(FredWaterCurrentVisual.profile(2, Vector2.ZERO, 0.0, 1.0, false).direction) < 0.0, "even-level ambient current follows the reversed route")
	check(float(strong.direction) > 0.0 and float(reversed.direction) < 0.0, "current vector controls the visible flow direction")
	check(float(strong.intensity) > float(gentle.intensity), "stronger gameplay current produces stronger visual flow")
	check(float(strong.speed) > float(gentle.speed), "stronger gameplay current produces faster visual travel")
	check(float(strong.foam_ratio) > 0.0 and float(gentle.foam_ratio) == 0.0, "foam appears only when the current is strong enough")
	check(float(underwater.speed) < float(strong.speed), "underwater flow reads as denser and slower")
	check(Color(underwater.highlight) != Color(strong.highlight), "underwater current uses a distinct depth-aware reflection")
	check(reduced_a == reduced_b and float(reduced_a.motion_scale) == 0.0, "reduced motion freezes current animation")
	check(float(reduced_a.direction) == float(strong.direction), "reduced motion preserves current direction information")
	check(bool(strong.presentation_only) and not bool(strong.collision_mutation) and int(strong.save_fields) == 0, "current visual cannot mutate collision or saves")

	var lane_y_values: Dictionary = {}
	var length_values: Dictionary = {}
	for index in range(FredWaterCurrentVisual.STREAM_COUNT):
		var stream := FredWaterCurrentVisual.streamline(index, strong)
		check(bool(stream.valid), "stream %02d is valid" % index)
		var points: PackedVector2Array = stream.points
		check(points.size() == FredWaterCurrentVisual.POINTS_PER_STREAM, "stream %02d has a smooth seven-point curve" % index)
		var all_inside := true
		for point: Vector2 in points:
			all_inside = all_inside and point.is_finite() and FredWaterCurrentVisual.PLAYFIELD.grow(-16.0).has_point(point)
		check(all_inside, "stream %02d remains inside the marsh playfield" % index)
		check(float(stream.width) >= 1.0 and float(stream.width) <= 3.0, "stream %02d width remains restrained" % index)
		lane_y_values[roundi(points[0].y)] = true
		length_values[roundi(absf(points[-1].x - points[0].x))] = true
	check(lane_y_values.size() >= 7, "streamlines cover at least seven depth lanes")
	check(length_values.size() >= 5, "streamlines use varied natural lengths")
	check(not bool(FredWaterCurrentVisual.streamline(-1, strong).get("valid", true)), "negative stream index fails closed")
	check(not bool(FredWaterCurrentVisual.streamline(FredWaterCurrentVisual.STREAM_COUNT, strong).get("valid", true)), "out-of-range stream index fails closed")

	for index in range(8):
		var eddy := FredWaterCurrentVisual.eddy(index, strong)
		check(bool(eddy.valid) and float(eddy.sweep) > 0.0, "forward eddy %d follows the current" % index)
		check(float(eddy.radius) >= 38.0 and float(eddy.radius) <= 50.0, "eddy %d remains fitted to a lily pad" % index)
		check(bool(eddy.presentation_only), "eddy %d remains presentation-only" % index)
	check(float(FredWaterCurrentVisual.eddy(0, reversed).sweep) < 0.0, "reversed current flips the pad eddy")
	check(not bool(FredWaterCurrentVisual.eddy(-1, strong).get("valid", true)), "negative eddy index fails closed")

	var reference_hash := 0
	for trace in range(100):
		var trace_hash := 0
		for index in range(FredWaterCurrentVisual.STREAM_COUNT):
			trace_hash = hash([trace_hash, _stream_signature(FredWaterCurrentVisual.streamline(index, strong))])
		for index in range(8):
			trace_hash = hash([trace_hash, FredWaterCurrentVisual.eddy(index, strong)])
		if trace == 0:
			reference_hash = trace_hash
		check(trace_hash == reference_hash, "current visual trace %03d is identical" % (trace + 1))

	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var started := Time.get_ticks_msec()
	var checksum := 0
	for iteration in range(ITERATIONS):
		var flow := FredWaterCurrentVisual.profile(
			1 + iteration % 100,
			Vector2(float((iteration % 241) - 120), sin(float(iteration) * 0.01) * 25.0),
			float(iteration % 101) / 100.0,
			float(iteration) / 60.0,
			iteration % 13 == 0
		)
		checksum = hash([checksum, _stream_signature(FredWaterCurrentVisual.streamline(iteration % FredWaterCurrentVisual.STREAM_COUNT, flow)), FredWaterCurrentVisual.eddy(iteration % 8, flow)])
	var elapsed := Time.get_ticks_msec() - started
	var memory_growth := int(Performance.get_monitor(Performance.MEMORY_STATIC)) - memory_before
	check(checksum != 0, "10,000 current calculations produce a stable observation")
	check(elapsed < 2000, "10,000 current calculations remain time-bounded")
	check(memory_growth < 8 * 1024 * 1024, "10,000 current calculations remain memory-bounded")
	print("MEASURE water_current_updates=%d elapsed_ms=%d memory_growth_bytes=%d hash=%d" % [ITERATIONS, elapsed, memory_growth, checksum])

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("FredWaterCurrentVisual.profile"), "gameplay draws the typed current visual")
	check(main_source.contains("_draw_current_eddy"), "lily pads receive current eddies and wakes")
	check(not main_source.contains("var arrow := \">\""), "paper-like current arrow text is removed")
	check(not main_source.contains("arrow + arrow"), "repeated current chevrons cannot return")

	print("RESULT water_current_visual_passed=%d water_current_visual_failed=%d" % [passed, failed])
	quit(1 if failed else 0)
