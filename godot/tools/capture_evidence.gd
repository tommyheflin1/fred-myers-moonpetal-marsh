extends SceneTree

func _init() -> void:
    _capture.call_deferred()

func _capture() -> void:
    var game: Node2D = load("res://scripts/main.gd").new()
    game.saver = FredSaveAdapter.new("user://evidence_save")
    root.add_child(game)
    await process_frame; await process_frame
    _save("res://docs/evidence/m1-title.png")
    game._start(); await process_frame
    _save("res://docs/evidence/m1-lily-leap-greybox.png")
    game.session.set_underwater(true); game.save_feedback = "Underwater"; game.queue_redraw(); await process_frame
    _save("res://docs/evidence/m1-underwater.png")
    game.session.paused = true; game.queue_redraw(); await process_frame
    _save("res://docs/evidence/m1-pause.png")
    print("CAPTURED 4 M1 screenshots")
    quit()

func _save(path: String) -> void:
    var image := root.get_viewport().get_texture().get_image()
    if image == null:
        push_error("Screenshot image unavailable: " + path)
        quit(1)
        return
    var error := image.save_png(path)
    if error != OK:
        push_error("Screenshot save failed: " + path)
        quit(1)
