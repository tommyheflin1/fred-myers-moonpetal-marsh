extends SceneTree

const Main = preload("res://scripts/main.gd")
const Labels = preload("res://scripts/marsh_label_layout.gd")
const Layout = preload("res://scripts/marsh_route_layout.gd")
const Intensity = preload("res://scripts/level_intensity.gd")
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)

func _init() -> void:
	var game: Node2D = Main.new()
	var font := ThemeDB.fallback_font
	var cameras: Array[Vector2] = [Vector2.ZERO,Vector2(-26,-26),Vector2(-26,26),Vector2(26,-26),Vector2(26,26)]
	for level in range(1,101):
		game.level_number = level
		game.level_profile = Intensity.profile(level)
		for touch: bool in [false,true]:
			game.touch_controls_visible = touch
			var input: Dictionary = game._world_label_inputs()
			var before := var_to_bytes(input)
			var plan: Array[Dictionary] = game._world_label_plan()
			check(plan.size() == 5+int(game.level_profile.whirlpool_count)+(1 if level%10 == 0 else 0), "all labels retained level %d touch=%s"%[level,touch])
			check(before == var_to_bytes(input), "layout does not mutate requests")
			check(var_to_bytes(plan) == var_to_bytes(Labels.arrange(input.requests,input.scenery,input.reserved,input.allowed)), "cached layout agrees with deterministic fresh layout")
			if plan.is_empty():
				continue
			for label in plan:
				check(Rect2(input.allowed).encloses(label.envelope), "entire motion envelope remains in the allowed playfield")
				var clear := true
				for reserved: Rect2 in input.reserved:
					clear = clear and not Rect2(label.envelope).intersects(reserved)
				for other in plan:
					if label.id != other.id:
						clear = clear and not Rect2(label.envelope).intersects(other.envelope)
				check(clear, "text envelopes never collide with UI or another caption")
				if str(label.id).begins_with("whirlpool"):
					check(not Rect2(label.envelope).intersects(input.scenery[0].rect), "whirlpool caption clears safe-perch artwork level %d"%level)
			var plan_bytes := var_to_bytes(plan)
			var snapshots_clear := true
			var actual_in_envelope := true
			for calm: bool in [false,true]:
				game.reduced_motion = calm
				for tick in 61:
					game.simulation_time = tick * 10.1
					game.visual_time = tick * 9.1
					var snapshot: Array[Dictionary] = game._world_label_snapshot()
					for label in snapshot:
						actual_in_envelope = actual_in_envelope and Rect2(label.envelope).grow(0.001).encloses(label.rect)
						for camera in cameras:
							var screen_rect := Rect2(Vector2(label.rect.position)+camera,Vector2(label.rect.size))
							snapshots_clear = snapshots_clear and Layout.PLAYFIELD_RECT.encloses(screen_rect)
							if touch:
								snapshots_clear = snapshots_clear and not screen_rect.intersects(Layout.TOUCH_ACTION_WHEEL_RECT) and not screen_rect.intersects(Layout.TOUCH_CONTROL_PAD_RECT)
			check(actual_in_envelope, "actual flight/hover/pulse captions fit the level envelope")
			check(snapshots_clear, "sampled captions remain clear at camera extremes")
			check(plan_bytes == var_to_bytes(game._world_label_plan()), "motion and reduced motion cannot reshuffle caption slots")
		# Every existing chapter message must remain whole in the same footer box.
		var message := "[NEW TWIST] " + str(game.level_profile.new_twist)
		var footer := Labels.footer(message,font,15,Layout.STATUS_TOUCH_RECT.size-Vector2(16,6))
		check(footer.valid and footer.complete and " ".join(footer.lines) == message, "full chapter message fits level %d"%level)
		_check_footer(footer,font,Layout.STATUS_TOUCH_RECT.size-Vector2(16,6))
	game.level_number = 71
	game.level_profile = Intensity.profile(71)
	game.touch_controls_visible = true
	game.simulation_time = 1.2
	var snapshot: Array[Dictionary] = game._world_label_snapshot()
	var shifted := false
	for label in snapshot:
		if label.id == "whirlpool1":
			shifted = label.moved and not Rect2(label.rect).intersects(game._world_label_inputs().scenery[0].rect)
	check(shifted, "Level 71 second-whirlpool regression no longer hides under the perch")
	var save_before := JSON.stringify(game.session.to_save())
	var state_before: Array = [game.fred,game.predator,game.secondary_predators.duplicate(),game.level_number,game.simulation_time,game.collected.duplicate()]
	var started := Time.get_ticks_msec()
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for iteration in 10000:
		game._world_label_snapshot()
	var elapsed := Time.get_ticks_msec()-started
	var growth := int(Performance.get_monitor(Performance.MEMORY_STATIC))-memory_before
	check(elapsed < 5000 and growth < 1024*1024, "snapshot cache is bounded to one level and retains no growing history")
	check(save_before == JSON.stringify(game.session.to_save()) and state_before == [game.fred,game.predator,game.secondary_predators,game.level_number,game.simulation_time,game.collected], "caption drawing data never alters gameplay or saves")
	var full_count: int = game._world_label_snapshot().size()
	game.collected.append(0)
	check(game._world_label_snapshot().size() == full_count-1, "collected bug caption disappears without moving other slots")
	game.level_number = 70
	game.level_profile = Intensity.profile(70)
	game.fairy_collected = false
	full_count = game._world_label_snapshot().size()
	game.fairy_collected = true
	check(game._world_label_snapshot().size() == full_count-1, "collected fairy caption disappears")
	game.free()
	for message: String in ["[PAUSED] Your last checkpoint is safe.","[OFFLINE] Progress stays on this device.","[SAVE BLOCKED] This adventure uses a different game version.","[RECOVERED] We finished your interrupted save.","[SAFE START] The old save was damaged, so we started safely."]:
		var footer := Labels.footer(message,font,15,Layout.STATUS_TOUCH_RECT.size-Vector2(16,6))
		check(footer.valid and footer.complete and " ".join(footer.lines) == message,"full feedback meaning is preserved: "+message+" "+JSON.stringify(footer))
		_check_footer(footer,font,Layout.STATUS_TOUCH_RECT.size-Vector2(16,6))
	var huge := Labels.footer("[NOTICE] "+"a deliberately long fictional message ".repeat(20),font,15,Vector2(324,34))
	check(huge.valid and not huge.complete and str(huge.lines[-1]).ends_with("…"), "exceptional long feedback has visible ellipsis instead of silent clipping")
	_check_footer(huge,font,Vector2(324,34))
	var huge_word := Labels.footer("X".repeat(200),font,15,Vector2(324,34))
	_check_footer(huge_word,font,Vector2(324,34))
	check(not Labels.footer("test",font,15,Vector2(2,2)).valid,"unreadably small box fails closed")
	check(Labels.arrange([{}],[],[],Layout.PLAYFIELD_RECT).is_empty(),"missing label fields fail closed")
	check(Labels.arrange([],[],[],Rect2(Vector2(NAN,0),Vector2(100,100))).is_empty(),"nonfinite canvas fails closed")
	print("MEASURE label_snapshots=10000 elapsed_ms=%d memory_growth_bytes=%d"%[elapsed,growth])
	print("RESULT marsh_label_layout_passed=%d marsh_label_layout_failed=%d"%[passed,failed])
	quit(1 if failed else 0)

func _check_footer(layout: Dictionary, font: Font, available: Vector2) -> void:
	if not bool(layout.get("valid",false)):
		check(false,"footer has a readable layout")
		return
	var fits: bool = layout.lines.size() <= 2 and int(layout.size) >= 13 and layout.lines.size()*float(layout.line_height) <= available.y
	for line: String in layout.lines:
		fits = fits and font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,layout.size).x <= available.x
	check(fits,"footer keeps every glyph inside its existing box at readable size")
