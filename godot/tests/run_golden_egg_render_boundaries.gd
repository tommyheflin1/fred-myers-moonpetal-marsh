extends SceneTree

# Fixture-only rendered review; no discovery solution, identity or live service.
const Main = preload("res://scripts/main.gd")
var checks := 0
var failures := 0

class ObservedMain:
	extends "res://scripts/main.gd"
	var hud_draws := 0
	var egg_draws := 0
	func _draw_gameplay_hud() -> void:
		hud_draws += 1
		super._draw_gameplay_hud()
	func _draw_canonical_golden_egg(center: Vector2, scale: float = 1.0) -> void:
		egg_draws += 1
		super._draw_canonical_golden_egg(center, scale)

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var level := source.split("func _draw_level() -> void:")[1].split("\nfunc ")[0]
	var egg := source.split("func _draw_canonical_golden_egg(")[1].split("\nfunc ")[0]
	var title := source.split("func _draw_title() -> void:")[1].split("\nfunc ")[0]
	check(not title.contains("GOLDEN") and not title.contains("golden_"), "title renders no discovery entry point even with saved pending state")
	check(level.count("_draw_gameplay_hud()") == 2, "ordinary route and room both draw gameplay HUD")
	check(not egg.contains("PAUSE_RECT") and not egg.contains("_status_panel") and not egg.contains("_draw_gameplay_hud"), "egg artwork never draws gameplay controls or feedback")
	check(not Main.GOLDEN_EGG_PUBLIC_RECT.intersects(Main.GOLDEN_EGG_PRIVATE_RECT), "privacy choices do not overlap")
	check(not Main.GOLDEN_EGG_HUNT_RECT.intersects(Main.GOLDEN_EGG_RETURN_RECT), "website and return actions do not overlap")
	check(not title.contains("LICENSES"), "title does not publicize bundled legal notices")
	if DisplayServer.get_name() != "headless":
		var game := ObservedMain.new()
		game.audio_enabled = false
		game.hazards_enabled = false
		game.countdown_enabled = false
		root.add_child(game)
		await process_frame
		game.set_process(false)
		game.screen = Main.Screen.TITLE
		game.golden_pending_review_available = true
		await _frame(game, "title", false, false)
		game._start()
		await _frame(game, "gameplay", true, false)
		game.screen = Main.Screen.GOLDEN_EGG
		await _frame(game, "egg-reveal", false, true)
		game._return_to_level_five()
		await _frame(game, "level5-return", true, false)
		check(game.level_number == 5 and not game.session.paused, "return restores active Level 5 beginning")
		game.queue_free()
		await process_frame
	print("GOLDEN_EGG_RENDER_BOUNDARIES: ", checks, " checks, ", failures, " failed")
	quit(1 if failures else 0)

func _frame(game: ObservedMain, label: String, hud_expected: bool, egg_expected: bool) -> void:
	var before_hud := game.hud_draws
	var before_egg := game.egg_draws
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	check((game.hud_draws > before_hud) == hud_expected, label + " has exactly the intended HUD boundary")
	check((game.egg_draws > before_egg) == egg_expected, label + " has exactly the intended egg-art boundary")
	if OS.get_cmdline_user_args().has("--capture-boundaries"):
		var directory := ProjectSettings.globalize_path("res://builds/reveal-boundary-review")
		DirAccess.make_dir_recursive_absolute(directory)
		check(root.get_texture().get_image().save_png(directory.path_join(label + ".png")) == OK, label + " captured from real renderer")
