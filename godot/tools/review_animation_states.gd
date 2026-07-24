extends SceneTree

const AnimationCoordinator = preload("res://scripts/fred_animation_coordinator.gd")
const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")
const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const SAVE_PREFIX := "user://m2_animation_visible_review"
const BOARD_PATH := "user://m2_animation_visible_review_board.json"

var game: Node2D
var review_index := 0

func _init() -> void:
	_review.call_deferred()

func _review() -> void:
	_clean()
	root.get_window().title = "Fred M2 Animation Coordinator Review"
	game = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start()
	game.predator = Vector2(1120,560)
	game.fred = Vector2(610,420)
	if "--reduced-motion" in OS.get_cmdline_user_args():
		game.reduced_motion = true
	while true:
		_show_next()
		await create_timer(2.25).timeout

func _show_next() -> void:
	var cases: Array[Dictionary] = [
		{"label": "PERCHED", "snapshot": _snapshot({})},
		{"label": "GROUND HOP RIGHT", "snapshot": _snapshot({"movement": Vector2.RIGHT, "moving": true})},
		{"label": "REVERSAL LEFT", "snapshot": _snapshot({"movement": Vector2.LEFT, "moving": true})},
		{"label": "LEAP READY", "snapshot": _snapshot({"leap_state": LeapTraversal.State.AIRBORNE, "leap_elapsed": 0.02})},
		{"label": "LEAP ASCENT", "snapshot": _snapshot({"leap_state": LeapTraversal.State.AIRBORNE, "leap_elapsed": 0.20})},
		{"label": "LEAP APEX", "snapshot": _snapshot({"leap_state": LeapTraversal.State.AIRBORNE, "leap_elapsed": 0.36})},
		{"label": "LEAP DESCENT", "snapshot": _snapshot({"leap_state": LeapTraversal.State.AIRBORNE, "leap_elapsed": 0.62})},
		{"label": "LANDING", "snapshot": _snapshot({"leap_state": LeapTraversal.State.LANDING})},
		{"label": "DIVING", "snapshot": _snapshot({"depth_state": DepthTraversal.State.DIVING})},
		{"label": "DEEP SWIM", "snapshot": _snapshot({"depth_state": DepthTraversal.State.UNDERWATER, "movement": Vector2.RIGHT, "moving": true})},
		{"label": "SURFACING", "snapshot": _snapshot({"depth_state": DepthTraversal.State.SURFACING})},
		{"label": "TONGUE WIND-UP", "snapshot": _snapshot({"tongue_state": TongueTargeting.State.EXTENDING, "tongue_elapsed": 0.01})},
		{"label": "TONGUE SNAP", "snapshot": _snapshot({"tongue_state": TongueTargeting.State.EXTENDING, "tongue_elapsed": 0.09})},
		{"label": "TONGUE RETURN", "snapshot": _snapshot({"tongue_state": TongueTargeting.State.RECOVERING})},
		{"label": "BOOST BURST", "snapshot": _snapshot({"boost_state": BoostLocomotion.State.BURST, "movement": Vector2.RIGHT, "moving": true})},
		{"label": "BOOST", "snapshot": _snapshot({"boost_state": BoostLocomotion.State.SUSTAIN, "movement": Vector2.RIGHT, "moving": true})},
		{"label": "EXHAUSTED", "snapshot": _snapshot({"boost_state": BoostLocomotion.State.EXHAUSTED})},
		{"label": "RECOVERING", "snapshot": _snapshot({"boost_state": BoostLocomotion.State.RECOVERING})},
		{"label": "DAMAGE", "snapshot": _snapshot({"invulnerable": true}), "damage": true},
		{"label": "FAILURE", "snapshot": _snapshot({"failed": true})},
	]
	var selected: Dictionary = cases[review_index % cases.size()]
	review_index += 1
	_reset_visual_components()
	game.animation.reset()
	if bool(selected.get("damage", false)):
		game.animation.trigger_damage()
	game.animation.advance(Dictionary(selected.snapshot), false, game.reduced_motion)
	_apply_visual_fixture(Dictionary(selected.snapshot))
	game._set_feedback("[ANIM %02d/%02d] %s | %s" % [
		((review_index - 1) % cases.size()) + 1,
		cases.size(),
		selected.label,
		"REDUCED" if game.reduced_motion else "NORMAL",
	])
	game.queue_redraw()

func _snapshot(changes: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"movement": Vector2.ZERO,
		"moving": false,
		"on_perch": true,
		"leap_state": LeapTraversal.State.GROUNDED,
		"leap_elapsed": 0.0,
		"depth_state": DepthTraversal.State.SURFACE,
		"depth_amount": 0.0,
		"tongue_state": TongueTargeting.State.READY,
		"tongue_elapsed": 0.0,
		"boost_state": BoostLocomotion.State.READY,
		"invulnerable": false,
		"failed": false,
	}
	snapshot.merge(changes, true)
	return snapshot

func _reset_visual_components() -> void:
	game.leap.reset()
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.tongue.reset()
	game.boost.reset()

func _apply_visual_fixture(snapshot: Dictionary) -> void:
	game.leap.state = int(snapshot.leap_state)
	game.leap.elapsed = float(snapshot.leap_elapsed)
	if game.leap.state == LeapTraversal.State.AIRBORNE:
		var progress := clampf(game.leap.elapsed / LeapTraversal.AIRBORNE_SECONDS, 0.0, 1.0)
		game.leap.visual_height = sin(progress * PI) * LeapTraversal.ARC_HEIGHT
	game.depth.state = int(snapshot.depth_state)
	game.depth.depth = 1.0 if game.depth.state == DepthTraversal.State.UNDERWATER else (0.5 if game.depth.state in [DepthTraversal.State.DIVING, DepthTraversal.State.SURFACING] else 0.0)
	game.session.set_underwater(game.depth.state == DepthTraversal.State.UNDERWATER)
	game.tongue.state = int(snapshot.tongue_state)
	game.tongue.elapsed = float(snapshot.tongue_elapsed)
	if game.tongue.state != TongueTargeting.State.READY:
		game.tongue.target_point = game.fred + Vector2(170,-20)
		game.tongue.outcome = "hit"
	game.boost.state = int(snapshot.boost_state)

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
