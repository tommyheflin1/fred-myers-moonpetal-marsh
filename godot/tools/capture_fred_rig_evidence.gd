extends SceneTree

const AnimationCoordinator = preload("res://scripts/fred_animation_coordinator.gd")
const LeapTraversal = preload("res://scripts/leap_traversal.gd")
const DepthTraversal = preload("res://scripts/depth_traversal.gd")
const TongueTargeting = preload("res://scripts/tongue_targeting.gd")
const BoostLocomotion = preload("res://scripts/boost_locomotion.gd")
const SAVE_PREFIX := "user://m2_fred_rig_capture"
const BOARD_PATH := "user://m2_fred_rig_capture_board.json"

var game: Node2D

func _init() -> void:
	_capture.call_deferred()

func _capture() -> void:
	_clean()
	game = load("res://scripts/main.gd").new()
	game.saver = FredSaveAdapter.new(SAVE_PREFIX)
	game.leaderboard = FredLocalLeaderboard.new(BOARD_PATH)
	game.hazards_enabled = false
	game.countdown_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.menu_music.volume_db = -80.0
	game.chase_music.volume_db = -80.0
	game._start()
	game.predator = Vector2(1120,560)
	game.fred = Vector2(610,420)

	_show(_snapshot({"movement": Vector2.RIGHT, "moving": true}), "[AUTHORED RIG 1/7] ARTICULATED GROUND HOP")
	await _save("res://docs/evidence/m2-rig-ground-hop.png")

	_show(_snapshot({
		"movement": Vector2.LEFT,
		"moving": true,
		"leap_state": LeapTraversal.State.AIRBORNE,
		"leap_elapsed": LeapTraversal.AIRBORNE_SECONDS * 0.5,
	}), "[AUTHORED RIG 2/7] MIRRORED LEAP APEX")
	game.leap.state = LeapTraversal.State.AIRBORNE
	game.leap.elapsed = LeapTraversal.AIRBORNE_SECONDS * 0.5
	game.leap.visual_height = LeapTraversal.ARC_HEIGHT
	await _save("res://docs/evidence/m2-rig-leap-apex.png")

	game.leap.reset()
	game.depth.reset("underwater")
	game.session.set_underwater(true)
	_show(_snapshot({
		"movement": Vector2.RIGHT,
		"moving": true,
		"depth_state": DepthTraversal.State.UNDERWATER,
	}), "[AUTHORED RIG 3/7] UNDERWATER STEERING")
	await _save("res://docs/evidence/m2-rig-underwater.png")

	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.tongue.state = TongueTargeting.State.EXTENDING
	game.tongue.elapsed = 0.09
	game.tongue.target_point = game.fred + Vector2(170,-20)
	game.tongue.outcome = "hit"
	_show(_snapshot({
		"tongue_state": TongueTargeting.State.EXTENDING,
		"tongue_elapsed": 0.09,
	}), "[AUTHORED RIG 4/7] MOUTH + TONGUE ANCHOR")
	await _save("res://docs/evidence/m2-rig-tongue-anchor.png")

	game.tongue.reset()
	game.boost.state = BoostLocomotion.State.BURST
	_show(_snapshot({
		"movement": Vector2.RIGHT,
		"moving": true,
		"boost_state": BoostLocomotion.State.BURST,
	}), "[AUTHORED RIG 5/7] BOOST SILHOUETTE")
	await _save("res://docs/evidence/m2-rig-boost.png")

	game.reduced_motion = true
	root.get_window().size = Vector2i(960,540)
	await process_frame
	_show(_snapshot({
		"leap_state": LeapTraversal.State.AIRBORNE,
		"leap_elapsed": LeapTraversal.AIRBORNE_SECONDS * 0.28,
	}), "[AUTHORED RIG 6/7] REDUCED MOTION - SAME CUE")
	await _save("res://docs/evidence/m2-rig-reduced-motion-960x540.png")

	game.reduced_motion = false
	root.get_window().size = Vector2i(640,360)
	await process_frame
	game.leap.reset()
	game.depth.reset("surface")
	game.session.set_underwater(false)
	game.tongue.reset()
	game.boost.reset()
	game.animation.trigger_damage()
	game.animation.advance(_snapshot({"invulnerable": true}), false, false)
	game._set_feedback("[AUTHORED RIG 7/7] DAMAGE + CONSTRAINED HUD")
	game.queue_redraw()
	await _save("res://docs/evidence/m2-rig-damage-640x360.png")

	game.menu_music.stream = null
	game.chase_music.stream = null
	game.queue_free()
	await process_frame
	_clean()
	print("CAPTURED 7 M2 authored-rig screenshots")
	quit()

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

func _show(snapshot: Dictionary, message: String) -> void:
	game.animation.reset()
	game.animation.advance(snapshot, false, game.reduced_motion)
	game._set_feedback(message)
	game.queue_redraw()

func _save(path: String) -> void:
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		push_error("Screenshot image unavailable: " + path)
		quit(1)
		return
	var error := image.save_png(path)
	if error != OK:
		push_error("Screenshot save failed: " + path)
		quit(1)

func _clean() -> void:
	for suffix: String in [".json", ".backup.json", ".tmp.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PREFIX + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOARD_PATH))
