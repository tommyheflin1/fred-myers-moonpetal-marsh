class_name GameConfig
extends Resource

@export var game_id: String = "com.example.game"
@export var display_name: String = "New Game"
@export var environment: String = "development"
@export var version: String = "0.1.0"
@export var build_number: int = 1
@export var save_schema: int = 1
@export var framework_version: String = "0.5.1"
@export var api_version: String = "v1"
@export var feature_flags: Dictionary = {}

func validate() -> PackedStringArray:
    var errors := PackedStringArray()
    if game_id.strip_edges().is_empty(): errors.append("game_id is required")
    if display_name.strip_edges().is_empty(): errors.append("display_name is required")
    if save_schema < 1: errors.append("save_schema must be positive")
    return errors
