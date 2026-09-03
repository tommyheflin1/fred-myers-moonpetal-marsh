extends SceneTree
const RunState = preload("res://scripts/golden_egg_run_state.gd")
var passed := 0
var failed := 0
const POS := Vector2(150,160)

func _init() -> void:
	var state = fresh()
	check(state.phase == RunState.Phase.TONGUES, "Level 5 starts eligible without revealing room")
	check(RunState.ACTIVATION_ZONE.has_point(Vector2(70,120)) and RunState.ACTIVATION_ZONE.has_point(Vector2(285,260)), "activation area is forgiving rather than pixel exact")
	check(not RunState.ACTIVATION_ZONE.has_point(Vector2(400,300)), "activation area stays near far-left top wall")
	for i in 3: state.note_tongue_complete(5,POS,Vector2.UP)
	check(state.phase == RunState.Phase.JUMPS and state.tongue_count == 3, "three distinct accepted tongue completions advance")
	for i in 4: state.note_valid_surface_jump(5,POS,Vector2.UP)
	check(state.phase == RunState.Phase.DIVES and state.jump_count == 4, "four completed jumps advance")
	for i in 2:
		state.note_dive_started(5,POS,Vector2.UP)
		state.note_surface_complete(5,POS,Vector2.UP)
	check(state.phase == RunState.Phase.ARMED and state.dive_count == 2, "two complete dive and surface cycles arm door")
	check(not state.try_upward_wall_boost(5,POS,Vector2.RIGHT), "non-upward boost cannot open door")
	check(state.phase == RunState.Phase.TONGUES, "wrong alignment resets sequence")
	state = armed()
	check(state.try_upward_wall_boost(5,POS,Vector2.UP) and state.phase == RunState.Phase.ROOM, "valid upward wall boost opens room")
	check(state.touch_egg() and state.phase == RunState.Phase.REVEALED, "egg contact alone enters existing question flow")
	state = fresh(); state.note_valid_surface_jump(5,POS,Vector2.UP)
	check(state.phase == RunState.Phase.TONGUES and state.jump_count == 0, "wrong order resets cleanly")
	state = fresh(); state.note_tongue_complete(5,POS,Vector2.UP); state.observe_position(5,Vector2(500,300),Vector2.UP)
	check(state.tongue_count == 0, "leaving zone resets progress")
	state = fresh(); state.note_food_collected(5)
	check(state.phase == RunState.Phase.INVALID and not state.foodless_level_five, "normal food permanently invalidates Level 5 attempt")
	state = fresh(); state.note_death("test")
	check(state.phase == RunState.Phase.INVALID and not state.deathless, "lost life invalidates run")
	state = fresh(); state.note_pause(5)
	check(state.phase == RunState.Phase.TONGUES and state.tongue_count == 0, "pause resets transient sequence")
	state = fresh(); state.note_level_restart(5)
	check(state.phase == RunState.Phase.TONGUES, "level restart resets sequence")
	state = fresh()
	check(not state.touch_egg() and not state.eligible_for_reveal(), "room and egg are unavailable before door")
	check(state.snapshot().format == 2 and state.evidence().level == 5, "new guard and evidence identify Level 5 contract")
	print("RESULT golden_egg_level5_passed=%d golden_egg_level5_failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func fresh():
	var state = RunState.new("user://golden-level5-test.json")
	state.begin_level_one("fixture")
	for level in range(2,6): state.advance_level(level-1,level)
	return state

func armed():
	var state = fresh()
	for i in 3: state.note_tongue_complete(5,POS,Vector2.UP)
	for i in 4: state.note_valid_surface_jump(5,POS,Vector2.UP)
	for i in 2:
		state.note_dive_started(5,POS,Vector2.UP)
		state.note_surface_complete(5,POS,Vector2.UP)
	return state

func check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error(label)
