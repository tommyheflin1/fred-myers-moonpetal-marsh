from __future__ import annotations

import importlib.util
import plistlib
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def load(name: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / "tools" / f"{name}.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


entitlements = load("prepare_ios_gamecenter_entitlements")
compliance = load("prepare_ios_export_compliance")
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    if not condition:
        raise SystemExit(f"iOS export helper test failed: {message}")
    checks += 1


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    project = root / "FredMyers.xcodeproj"
    project.mkdir()
    pbxproj = project / "project.pbxproj"
    pbxproj.write_text("\t\tPRODUCT_BUNDLE_IDENTIFIER = com.flinsvault.fredmyers;\n", encoding="utf-8")
    report = entitlements.prepare_project(project)
    check(report["status"] == "PASS", "entitlement helper did not pass")
    check(report["game_center"] is True, "Game Center entitlement is missing")
    check("CODE_SIGN_ENTITLEMENTS = FredMyers.entitlements;" in pbxproj.read_text(encoding="utf-8"), "project reference missing")
    payload = plistlib.loads((root / "FredMyers.entitlements").read_bytes())
    check(payload["com.apple.developer.game-center"] is True, "entitlement value is not true")

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    project = root / "FredMyers.xcodeproj"
    project.mkdir()
    pbxproj = project / "project.pbxproj"
    pbxproj.write_text(
        "\t\tCODE_SIGN_ENTITLEMENTS = FredMyers/FredMyers.entitlements;\n"
        "\t\tPRODUCT_BUNDLE_IDENTIFIER = com.flinsvault.fredmyers;\n",
        encoding="utf-8",
    )
    report = entitlements.prepare_project(project)
    nested = root / "FredMyers" / "FredMyers.entitlements"
    check(report["status"] == "PASS", "Godot nested entitlement path did not pass")
    check(nested.is_file(), "Godot nested entitlement file was not preserved")
    check(plistlib.loads(nested.read_bytes())["com.apple.developer.game-center"] is True, "nested entitlement value is not true")

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    app = root / "FredMyers" / "Info.plist"
    app.parent.mkdir()
    app.write_bytes(plistlib.dumps({"CFBundlePackageType": "APPL"}, fmt=plistlib.FMT_XML))
    report = compliance.prepare_export(root)
    check(report["status"] == "PASS", "export compliance helper did not pass")
    check(report["uses_non_exempt_encryption"] is False, "encryption declaration must be false")
    check(plistlib.loads(app.read_bytes())["ITSAppUsesNonExemptEncryption"] is False, "plist encryption key missing")

validation_handoff = (ROOT / "tools" / "ios_validation_handoff.sh").read_text(encoding="utf-8")
build_handoff = (ROOT / "tools" / "run_fred_app_build_3_macos.sh").read_text(encoding="utf-8")
package_handoff = (ROOT / "tools" / "prepare_ios_handoff.py").read_text(encoding="utf-8")
plugin_handoff = (ROOT / "tools" / "build_ios_gamecenter_plugin.sh").read_text(encoding="utf-8")
gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
check(
    'find "$export_root" -maxdepth 2 -name \'*.xcodeproj\'' in validation_handoff,
    "validation handoff must discover Godot's sibling Xcode project",
)
check(
    'find "$export_root" -name \'PrivacyInfo.xcprivacy\'' in validation_handoff,
    "validation handoff must accept Godot's sibling privacy manifest",
)
check(
    "simulator_members=\"$(ar -t \"$simulator_engine\")\"" in validation_handoff
    and 'ARCHS="$simulator_arch"' in validation_handoff
    and 'EXCLUDED_ARCHS="$simulator_excluded"' in validation_handoff,
    "validation handoff must build the simulator architecture present in Godot's archive",
)
check(
    "find builds/ios -maxdepth 2 -name '*.xcodeproj'" in build_handoff,
    "signed-build handoff must discover Godot's sibling Xcode project",
)
check(
    'CODE_SIGN_STYLE=Manual' in build_handoff
    and 'CODE_SIGN_IDENTITY="Apple Distribution"' in build_handoff
    and 'PROVISIONING_PROFILE_SPECIFIER="$profile_name"' in build_handoff
    and '<key>signingStyle</key><string>manual</string>' in build_handoff
    and '<key>com.flinsvault.fredmyers</key><string>$profile_name</string>' in build_handoff,
    "signed-build handoff must use the Fred App Store distribution profile",
)
check(
    "UPLOAD_BUILD_3" in build_handoff
    and "FredMyers-AppBuild3.xcarchive" in build_handoff
    and 'xcrun altool --upload-app' in build_handoff
    and '<key>destination</key><string>export</string>' in build_handoff
    and "version=1.0 build=3" in build_handoff,
    "signed-build handoff must be locked to Fred Build 3 and the proven API-key upload lane",
)
check(
    "fred-myers-app-build-3.bundle" in package_handoff
    and "RUN-FRED-APP-BUILD-3.command" in package_handoff
    and '\"build_number\": \"3\"' in package_handoff,
    "transfer package must identify Build 3 throughout",
)
check(
    "IOS_GAMECENTER_PLUGIN_CACHE_REUSED" in plugin_handoff
    and 'rm -rf -- "$debug_framework" "$release_framework"' in plugin_handoff,
    "Game Center plugin handoff must reuse complete cache output and replace only incomplete generated frameworks",
)
check(
    "godot/ios/" in gitignore,
    "generated iOS plugin cache must not make exact-source reruns dirty",
)

print(f"iOS export helper tests passed: {checks} checks")
