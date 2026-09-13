"""Static regression guards for the established Fred upload implementation.

These do not prove macOS signing, an IPA export, or Apple acceptance.
"""
from pathlib import Path
import importlib.util
import json

ROOT = Path(__file__).resolve().parents[2]
text = (ROOT / "godot/.agents/skills/apple-remote-delivery/scripts/apple_delivery.sh").read_text()
required = (
    "set -euo pipefail",
    'ios_signing.py" archive-arguments',
    "--export-release",
    "scan_ios_app_bundle.py",
    "APPLE_ARCHIVE_ACK",
    "APPLE_UPLOAD_ACK",
    "exported IPA lost Game Center entitlement",
    "xcrun altool --validate-app",
    "xcrun altool --upload-app",
)
for fragment in required:
    assert fragment in text, f"Fred release safeguard missing: {fragment}"
assert text.index("exported IPA lost") < text.index("xcrun altool --validate-app") < text.index("xcrun altool --upload-app")
spec = importlib.util.spec_from_file_location("fred_ios_signing", ROOT / "godot/tools/ios_signing.py")
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)
config = json.loads((ROOT / "godot/tools/ios_release_config.json").read_text())
game = json.loads((ROOT / "godot/game/game.json").read_text())
style, profile = signing.settings(config, game, config["team_id"])
assert style == "manual" and profile == "Fred Myers App Store Game Center 2026"
assert signing.upload_method(config) == "altool"
args = signing.archive_arguments(style, config["team_id"], profile)
assert "CODE_SIGN_STYLE=Manual" in args and "CODE_SIGN_IDENTITY=Apple Distribution" in args
options = signing.export_options(style, config["team_id"], game["bundle_id"], profile, signing.upload_method(config))
assert options["destination"] == "export" and options["manageAppVersionAndBuildNumber"] is False
assert options["provisioningProfiles"] == {game["bundle_id"]: profile}
print(f"Fred release lane static guards passed: {len(required) + 6} checks; Mac/Apple unverified")
