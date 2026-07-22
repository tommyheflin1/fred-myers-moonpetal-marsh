@tool
extends EditorPlugin

const CORE_VERSION := "0.5.1"

func _enter_tree() -> void:
    add_autoload_singleton("GameServices", "res://addons/mobile_game_core/services/game_services.gd")

func _exit_tree() -> void:
    remove_autoload_singleton("GameServices")
