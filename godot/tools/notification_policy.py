"""Conservative source/config tripwire; not a binary or device certification."""
from pathlib import Path
import re

SKIP = {".git", ".godot", "builds", "reports", "tests", "docs", "tools", ".agents", "node_modules"}
EXTENSIONS = {".gd", ".cs", ".swift", ".m", ".mm", ".h", ".cpp", ".java", ".kt", ".xml", ".plist", ".entitlements", ".json", ".godot", ".cfg", ".gdip"}
PATTERN = re.compile(
    r"UNUserNotificationCenter|UILocalNotification|registerForRemoteNotifications|"
    r"FirebaseMessaging|Firebase/Messaging|com\.google\.firebase\.messaging|OneSignal|"
    r"POST_NOTIFICATIONS|NotificationCompat|NotificationManager|"
    r"aps-environment|com\.apple\.developer\.usernotifications|remote-notification|"
    r"com\.apple\.usernotifications\.(?:service|content)-extension",
    re.IGNORECASE,
)

def validate(root: Path) -> list[str]:
    errors = []
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        if set(relative.parts) & SKIP or path.suffix.lower() not in EXTENSIONS:
            continue
        if path.is_symlink():
            errors.append(f"notification scan cannot verify symlink: {relative.as_posix()}")
        elif path.is_file():
            try:
                content = path.read_text(encoding="utf-8-sig")
                if PATTERN.search(content):
                    errors.append(f"prohibited notification API/capability: {relative.as_posix()}")
                if relative.as_posix() == "game/game.json":
                    import json
                    config = json.loads(content)
                    for section in (config, config.get("capabilities") or {}):
                        for key in ("notifications", "push_notifications", "local_notifications"):
                            if key in section and section[key] is not False:
                                errors.append(f"{key} must be absent or false")
            except (OSError, UnicodeError, ValueError):
                errors.append(f"notification scan unreadable input: {relative.as_posix()}")
    return errors
