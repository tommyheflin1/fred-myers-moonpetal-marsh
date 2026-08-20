#!/usr/bin/env bash
set -euo pipefail

expected_commit="${1:-}"
[[ -n "$expected_commit" ]] || { echo "Usage: tools/ios_validation_handoff.sh <exact-commit>" >&2; exit 2; }
repo_root="$(pwd)"
for tool in godot git python3 xcodebuild xcrun shasum plutil; do command -v "$tool" >/dev/null || { echo "$tool is required." >&2; exit 1; }; done
actual_commit="$(git rev-parse HEAD)"
[[ "$actual_commit" == "$expected_commit" ]] || { echo "Expected $expected_commit but checkout is $actual_commit." >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "Working tree must be clean." >&2; exit 1; }
godot_version="$(godot --version)"
[[ "$godot_version" == 4.7.1* ]] || { echo "Godot 4.7.1 is required; found $godot_version." >&2; exit 1; }
xcode_major="$(xcodebuild -version | awk 'NR==1 {split($2,v,"."); print v[1]}')"
[[ "$xcode_major" -ge 26 ]] || { echo "Xcode 26 or later is required." >&2; exit 1; }
ios_sdk="$(xcrun --sdk iphoneos --show-sdk-version)"
[[ "${ios_sdk%%.*}" -ge 26 ]] || { echo "iOS SDK 26 or later is required." >&2; exit 1; }
python3 tools/validate_ios_preparation.py
bash tools/build_ios_gamecenter_plugin.sh "$repo_root"
python3 tools/validate_ios_gamecenter_plugin.py --project-root "$repo_root"

team_id="${FRED_APPLE_TEAM_ID:-}"
[[ "$team_id" =~ ^[A-Z0-9]{10}$ ]] || { echo "FRED_APPLE_TEAM_ID must be the authenticated Mac's 10-character team ID." >&2; exit 1; }
staging_root="$(mktemp -d "${TMPDIR:-/tmp}/fred-ios-export.XXXXXX")"
trap 'rm -rf "$staging_root"' EXIT
git archive HEAD | tar -x -C "$staging_root"
mkdir -p "$staging_root/godot/ios/plugins"
cp -R godot/ios/plugins/gamecenter "$staging_root/godot/ios/plugins/"
python3 - "$staging_root/godot/export_presets.cfg" "$team_id" <<'PY'
from pathlib import Path
import re
import sys

preset = Path(sys.argv[1])
team = sys.argv[2]
text = preset.read_text(encoding="utf-8")
replacements = {
    'application/bundle_identifier="com.flinsvault.fredmyers.dev"': 'application/bundle_identifier="com.flinsvault.fredmyers"',
    'application/app_store_team_id=""': f'application/app_store_team_id="{team}"',
}
for original, replacement in replacements.items():
    if text.count(original) != 1:
        raise SystemExit(f"Expected exactly one staged iOS value: {original}")
    text = text.replace(original, replacement)
preset.write_text(text, encoding="utf-8")
PY

output="$repo_root/builds/ios/FredMyers"
export_root="$repo_root/builds/ios"
[[ ! -e "$output" ]] || { echo "$output already exists; archive it and rerun from a clean evidence state." >&2; exit 1; }
evidence="$repo_root/builds/ios/evidence"
mkdir -p "$repo_root/builds/ios" "$evidence"
godot --headless --path "$staging_root/godot" --editor --quit
godot --headless --path "$staging_root/godot" --export-debug "iOS Unsigned Preparation" "$output"
project="$(find "$export_root" -maxdepth 2 -name '*.xcodeproj' -print -quit)"
[[ -n "$project" ]] || { echo "Export completed but no Xcode project was found." >&2; exit 1; }
grep -R -q 'gamecenter' "$export_root" || { echo "Export is missing the native Game Center plugin." >&2; exit 1; }
python3 tools/prepare_ios_gamecenter_entitlements.py --xcode-project "$project"
python3 tools/prepare_ios_export_compliance.py --export-root "$output"
privacy_manifest="$(find "$output" -name 'PrivacyInfo.xcprivacy' -print -quit)"
[[ -n "$privacy_manifest" ]] || { echo "Generated export is missing PrivacyInfo.xcprivacy." >&2; exit 1; }
plutil -lint "$privacy_manifest"
! grep -q '\$priv_' "$privacy_manifest" || { echo "Privacy manifest still contains an unresolved template value." >&2; exit 1; }
scheme="$(basename "$project" .xcodeproj)"
derived="${TMPDIR:-/tmp}/fred-myers-derived-${actual_commit:0:12}"
xcodebuild -project "$project" -scheme "$scheme" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO -derivedDataPath "$derived" build
manifest="$evidence/${actual_commit}-unsigned-export.sha256"
find "$export_root" -path "$evidence" -prune -o -type f -print0 | sort -z | xargs -0 shasum -a 256 > "$manifest"
{
  echo "commit=$actual_commit"
  echo "godot=$godot_version"
  echo "macos=$(sw_vers -productVersion)"
  echo "xcode=$(xcodebuild -version | tr '\n' ' ')"
  echo "ios_sdk=$ios_sdk"
  echo "project=$project"
  echo "scheme=$scheme"
  echo "bundle_identifier=com.flinsvault.fredmyers"
  echo "short_version=1.0"
  echo "build_number=1"
  echo "game_center=true"
  echo "uses_non_exempt_encryption=false"
  echo "privacy_manifest=$privacy_manifest"
  echo "manifest=$manifest"
} > "$evidence/${actual_commit}-toolchain.txt"
echo "IOS_UNSIGNED_VALIDATION_PASS commit=$actual_commit project=$project signing=disabled upload=none"
