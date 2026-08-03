from __future__ import annotations

import configparser
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
PRESET_PATH = ROOT / "godot" / "export_presets.cfg"
PROJECT_PATH = ROOT / "godot" / "project.godot"
EXPECTED = {
    "name": '"Android Development"',
    "platform": '"Android"',
    "export_path": '"../builds/android/fred-myers-app-build-1-debug.apk"',
    "exclude_filter": '"tests/**,tools/**,docs/evidence/**"',
    "package/unique_name": '"com.flinsappvault.fredmyers.dev"',
    "package/name": '"Fred Myers App Build 1"',
    "version/code": "20101",
    "version/name": '"0.2.1-app-build-1"',
    "gradle_build/min_sdk": '""',
    "gradle_build/target_sdk": '""',
    "architectures/arm64-v8a": "true",
    "architectures/x86_64": "true",
    "architectures/armeabi-v7a": "false",
    "architectures/x86": "false",
    "screen/immersive_mode": "true",
    "screen/edge_to_edge": "false",
    "user_data_backup/allow": "false",
    "permissions/custom_permissions": "PackedStringArray()",
}


def load_preset() -> configparser.ConfigParser:
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.optionxform = str
    parser.read(PRESET_PATH, encoding="utf-8")
    return parser


def require(actual: str | None, expected: str, label: str) -> None:
    if actual != expected:
        raise SystemExit(f"Unexpected {label}: {actual!r}; expected {expected!r}")


def main() -> None:
    if not PRESET_PATH.is_file():
        raise SystemExit("Android export preset is missing")

    preset = load_preset()
    if "preset.0" not in preset or "preset.0.options" not in preset:
        raise SystemExit("Android Development preset sections are missing")

    identity = preset["preset.0"]
    options = preset["preset.0.options"]
    for key in ("name", "platform", "export_path", "exclude_filter"):
        require(identity.get(key), EXPECTED[key], key)
    for key, expected in EXPECTED.items():
        if key in {"name", "platform", "export_path", "exclude_filter"}:
            continue
        require(options.get(key), expected, key)

    if identity.get("runnable") != "true":
        raise SystemExit("Android Development preset must be runnable")
    if options.get("package/signed") != "true":
        raise SystemExit("Debug APK must use Godot's normal debug signing path")

    forbidden_signing = (
        "keystore/release",
        "keystore/release_user",
        "keystore/release_password",
    )
    for key in forbidden_signing:
        if options.get(key, "").strip('"'):
            raise SystemExit(f"Production signing field must remain empty: {key}")

    enabled_permissions = [
        key
        for key, value in options.items()
        if key.startswith("permissions/")
        and key != "permissions/custom_permissions"
        and value.lower() == "true"
    ]
    if enabled_permissions:
        raise SystemExit(
            "Android development preset enables permissions: "
            + ", ".join(sorted(enabled_permissions))
        )

    project = PROJECT_PATH.read_text(encoding="utf-8")
    required_project_lines = (
        'config/icon="res://assets/art/fred-app-icon-v2.png"',
        'window/handheld/orientation=0',
        'renderer/rendering_method.mobile="gl_compatibility"',
        'textures/vram_compression/import_etc2_astc=true',
        'window/stretch/mode="canvas_items"',
        'window/stretch/aspect="keep"',
    )
    for line in required_project_lines:
        if line not in project:
            raise SystemExit(f"Missing Android project contract: {line}")

    if not re.search(r"^builds/$", (ROOT / ".gitignore").read_text(encoding="utf-8"), re.M):
        raise SystemExit("Local Android build output is not ignored")

    secret_suffixes = {".jks", ".keystore", ".pem", ".p12"}
    leaked = [
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and path.suffix.lower() in secret_suffixes
        and ".git" not in path.parts
        and "builds" not in path.parts
    ]
    if leaked:
        raise SystemExit("Signing or secret files are present: " + ", ".join(leaked))

    print(
        "Android export validation passed: "
        "com.flinsappvault.fredmyers.dev, version 0.2.1-app-build-1 (20101), "
        "landscape, built-in-template SDK policy, arm64+x86_64, "
        "no requested permissions"
    )


if __name__ == "__main__":
    main()
