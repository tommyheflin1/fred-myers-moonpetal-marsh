#!/usr/bin/env bash
set -euo pipefail

expected_commit="${1:-}"
[[ -n "$expected_commit" ]] || { echo "Usage: tools/run_fred_app_build_1_macos.sh <exact-commit>" >&2; exit 2; }
[[ "${FRED_TESTFLIGHT_UPLOAD_ACK:-}" == "UPLOAD_BUILD_1" ]] || {
  echo "Set FRED_TESTFLIGHT_UPLOAD_ACK=UPLOAD_BUILD_1 only for the owner-approved TestFlight upload." >&2
  exit 2
}
for tool in git python3 xcodebuild security codesign; do command -v "$tool" >/dev/null || { echo "$tool is required." >&2; exit 1; }; done
[[ "$(git rev-parse HEAD)" == "$expected_commit" ]] || { echo "Exact source commit mismatch." >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "Source tree must be clean." >&2; exit 1; }
team_id="$(security find-identity -v -p codesigning | sed -nE 's/.*Apple Distribution:.*\(([A-Z0-9]{10})\).*/\1/p' | head -n 1)"
if [[ -z "$team_id" ]]; then
  team_id="$(security find-identity -v -p codesigning | sed -nE 's/.*Apple Development:.*\(([A-Z0-9]{10})\).*/\1/p' | head -n 1)"
fi
[[ "$team_id" =~ ^[A-Z0-9]{10}$ ]] || { echo "An Apple signing identity was not detected." >&2; exit 1; }
export FRED_APPLE_TEAM_ID="$team_id"
bash tools/ios_validation_handoff.sh "$expected_commit"
project="$(find builds/ios/FredMyers -maxdepth 2 -name '*.xcodeproj' -print -quit)"
[[ -n "$project" ]] || { echo "Validated Xcode project is missing." >&2; exit 1; }
scheme="$(basename "$project" .xcodeproj)"
archive="$PWD/builds/ios/FredMyers-AppBuild1.xcarchive"
export_dir="$PWD/builds/ios/AppBuild1-upload"
xcodebuild -project "$project" -scheme "$scheme" -configuration Release -destination 'generic/platform=iOS' -archivePath "$archive" DEVELOPMENT_TEAM="$team_id" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive
app="$(find "$archive/Products/Applications" -maxdepth 1 -name '*.app' -print -quit)"
[[ -n "$app" ]] || { echo "Signed app is missing from the archive." >&2; exit 1; }
codesign --verify --deep --strict --verbose=2 "$app"
entitlements="$PWD/builds/ios/AppBuild1-entitlements.plist"
codesign -d --entitlements :- "$app" > "$entitlements" 2>/dev/null
/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.game-center' "$entitlements" 2>/dev/null | grep -q true
options="$PWD/builds/ios/AppBuild1-ExportOptions.plist"
cat > "$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>$team_id</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
EOF
mkdir -p "$export_dir"
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$export_dir" -exportOptionsPlist "$options" -allowProvisioningUpdates
echo "FRED_APP_BUILD_1_UPLOAD_SUCCEEDED commit=$expected_commit bundle=com.flinsvault.fredmyers version=1.0 build=1"
