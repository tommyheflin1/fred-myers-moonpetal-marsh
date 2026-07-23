class_name FredSaveFeedback
extends RefCounted

const DISPLAY_SECONDS := 15.0
const NEUTRAL := "[OFFLINE] Progress stays on this device."
const PANEL_BACKGROUND := Color("06151f")
const PANEL_BORDER := Color("e8fbff")
const PANEL_TEXT := Color("e8fbff")

static func load_message(result: Dictionary) -> String:
    if not result.get("ok", false):
        return "[SAVE BLOCKED] This adventure uses a different game version."
    match str(result.get("source", "default")):
        "primary":
            return "[RESTORED] Your saved adventure is ready."
        "backup":
            return "[RECOVERED] We found your safe backup."
        "temp":
            return "[RECOVERED] We finished your interrupted save."
        _:
            if result.get("reason") == "corrupt":
                return "[SAFE START] The old save was damaged, so we started safely."
            return "[NEW GAME] No saved adventure yet."

static func save_message(result: Dictionary, success_message: String) -> String:
    if result.get("ok", false):
        return "[SAVED] " + success_message
    match str(result.get("error", "")):
        "stale_checkpoint":
            return "[SAVE BLOCKED] A newer checkpoint is already safe."
        "unsupported_schema", "core_incompatible":
            return "[SAVE BLOCKED] This adventure uses a different game version."
        _:
            return "[SAVE BLOCKED] Progress was not changed. Try again soon."
