#!/usr/bin/env bash
set -euo pipefail

expected_commit="${1:-}"
[[ -n "$expected_commit" ]] || { echo "Usage: tools/run_fred_app_build_4_macos.sh <exact-commit>" >&2; exit 2; }
[[ "${FRED_TESTFLIGHT_UPLOAD_ACK:-}" == "UPLOAD_BUILD_4" ]] || {
  echo "Set FRED_TESTFLIGHT_UPLOAD_ACK=UPLOAD_BUILD_4 only for the owner-approved TestFlight Build 4 upload." >&2
  exit 2
}
if [[ "$(uname -s)" == "Darwin" && "${FRED_IOS_CAFFEINATED:-0}" != "1" ]]; then
  command -v caffeinate >/dev/null || { echo "caffeinate is required." >&2; exit 1; }
  exec caffeinate -dimsu env FRED_IOS_CAFFEINATED=1 FRED_TESTFLIGHT_UPLOAD_ACK=UPLOAD_BUILD_4 \
    bash "$0" "$expected_commit"
fi

for tool in git python3 xcodebuild xcrun security codesign shasum plutil; do
  command -v "$tool" >/dev/null || { echo "$tool is required." >&2; exit 1; }
done
[[ "$(git rev-parse HEAD)" == "$expected_commit" ]] || { echo "Exact source commit mismatch." >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "Source tree must be clean." >&2; exit 1; }

team_id="$(security find-identity -v -p codesigning | sed -nE 's/.*Apple Distribution:.*\(([A-Z0-9]{10})\).*/\1/p' | head -n 1)"
[[ "$team_id" =~ ^[A-Z0-9]{10}$ ]] || { echo "An Apple Distribution identity was not detected." >&2; exit 1; }
export FRED_APPLE_TEAM_ID="$team_id"

api_key_id="${FRED_APP_STORE_API_KEY_ID:-AQX2CFYPVZ}"
api_issuer_id="${FRED_APP_STORE_API_ISSUER_ID:-de911c2a-77f4-4b17-9c05-f25feef339e8}"
api_key_path="${FRED_APP_STORE_API_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${api_key_id}.p8}"
[[ -s "$api_key_path" ]] || { echo "The existing App Store Connect API key is unavailable at the configured path." >&2; exit 1; }
[[ "$(basename "$api_key_path")" == "AuthKey_${api_key_id}.p8" ]] || { echo "App Store Connect API key filename mismatch." >&2; exit 1; }

profile_name="${FRED_APP_STORE_PROFILE_NAME:-Fred Myers App Store Game Center 2026}"
bash tools/ios_validation_handoff.sh "$expected_commit"
project="$(find builds/ios -maxdepth 2 -name '*.xcodeproj' -print -quit)"
[[ -n "$project" ]] || { echo "Validated Xcode project is missing." >&2; exit 1; }
scheme="$(basename "$project" .xcodeproj)"
archive="$PWD/builds/ios/FredMyers-AppBuild4.xcarchive"
export_dir="$PWD/builds/ios/AppBuild4-upload"

xcodebuild -project "$project" -scheme "$scheme" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$archive" \
  DEVELOPMENT_TEAM="$team_id" CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  PROVISIONING_PROFILE_SPECIFIER="$profile_name" archive

app="$(find "$archive/Products/Applications" -maxdepth 1 -name '*.app' -print -quit)"
[[ -n "$app" ]] || { echo "Signed app is missing from the archive." >&2; exit 1; }
codesign --verify --deep --strict --verbose=2 "$app"
info_plist="$app/Info.plist"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info_plist")" == "com.flinsvault.fredmyers" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist")" == "1.0" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$info_plist")" == "4" ]]

entitlements="$PWD/builds/ios/AppBuild4-entitlements.plist"
codesign -d --entitlements :- "$app" > "$entitlements" 2>/dev/null
/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.game-center' "$entitlements" 2>/dev/null | grep -q true

options="$PWD/builds/ios/AppBuild4-ExportOptions.plist"
cat > "$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>teamID</key><string>$team_id</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Apple Distribution</string>
  <key>provisioningProfiles</key><dict>
    <key>com.flinsvault.fredmyers</key><string>$profile_name</string>
  </dict>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
EOF
mkdir -p "$export_dir"
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$export_dir" -exportOptionsPlist "$options"
ipa="$(find "$export_dir" -maxdepth 1 -name '*.ipa' -print -quit)"
[[ -n "$ipa" ]] || { echo "Signed IPA is missing from the export." >&2; exit 1; }
ipa_sha256="$(shasum -a 256 "$ipa" | awk '{print $1}')"
upload_log="$export_dir/AppBuild4-upload.log"
xcrun altool --upload-app -f "$ipa" -t ios --apiKey "$api_key_id" \
  --apiIssuer "$api_issuer_id" --output-format json 2>&1 | tee "$upload_log"

echo "FRED_APP_BUILD_4_UPLOAD_SUCCEEDED commit=$expected_commit bundle=com.flinsvault.fredmyers version=1.0 build=4 ipa=$ipa ipa_sha256=$ipa_sha256"
