#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: apple_delivery.sh <prepare|archive|upload|status> <project-root> <exact-commit>}"
root="$(cd "${2:?project root required}" && pwd)"
commit="${3:?exact commit required}"
skill="$root/.agents/skills/apple-remote-delivery"
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { echo "APPLE_DELIVERY_STOP invalid exact commit"; exit 2; }
[[ "$(git -C "$root" rev-parse HEAD)" == "$commit" ]] || { echo "APPLE_DELIVERY_STOP commit mismatch"; exit 2; }
[[ -z "$(git -C "$root" status --porcelain)" ]] || { echo "APPLE_DELIVERY_STOP worktree dirty"; exit 2; }

IFS='|' read -r game_id bundle version build game_center <<< "$(python3 - "$root/game/game.json" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
print('|'.join((d['game_id'], d['bundle_id'], d['marketing_version'], str(d['build_number']), str(bool(d.get('capabilities',{}).get('game_center'))).lower())))
PY
)"
lane="$root/builds/ios/apple-delivery/${version}-${build}"
checkpoint="$lane/checkpoint.json"
godot="$(command -v godot 2>/dev/null || true)"
[[ -n "$godot" ]] || godot=/Applications/Godot.app/Contents/MacOS/Godot

write_checkpoint() {
  local gate="$1"
  python3 "$root/tools/release_checkpoint.py" record --root "$root" --commit "$commit" --mode "$gate"
}

check_mode="$mode"
[[ "$check_mode" != prepare ]] || check_mode=preflight
python3 "$root/tools/release_checkpoint.py" check --root "$root" --commit "$commit" --mode "$check_mode"

case "$mode" in
  prepare)
    bash "$skill/scripts/apple_remote_doctor.sh" "$root"
    if [[ "$game_center" == true ]]; then
      bash "$root/tools/build_ios_gamecenter_plugin.sh" "$root"
      python3 "$root/tools/validate_ios_gamecenter_plugin.py" --project-root "$root"
    fi
    mkdir -p "$lane"
    export_root="$lane/Generated"
    rm -rf "$export_root"
    mkdir -p "$export_root"
    "$godot" --headless --path "$root" --editor --quit
    "$godot" --headless --path "$root" --export-debug "iOS Unsigned Preparation" "$export_root/Game"
    xcodeproj="$(find "$lane" -maxdepth 4 -name '*.xcodeproj' -print -quit)"
    [[ -n "$xcodeproj" ]] || { echo "APPLE_PREPARE_STOP Xcode project missing"; exit 3; }
    scheme="$(basename "$xcodeproj" .xcodeproj)"
    xcodebuild -project "$xcodeproj" -scheme "$scheme" -sdk iphonesimulator -configuration Debug -derivedDataPath "$lane/DerivedData" CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 build | tee "$lane/prepare.log"
    git -C "$root" ls-files --others --exclude-standard -z | while IFS= read -r -d '' generated; do
      [[ "$generated" == *.gd.uid ]] && git -C "$root" clean -f -- "$generated"
    done
    write_checkpoint prepared
    echo "APPLE_PREPARE_PASS version=$version build=$build commit=$commit signing=false"
    ;;
  archive)
    [[ "${APPLE_ARCHIVE_ACK:-}" == "ARCHIVE_BUILD_${build}" ]] || { echo "APPLE_ARCHIVE_STOP authorization required: APPLE_ARCHIVE_ACK=ARCHIVE_BUILD_${build}"; exit 2; }
    [[ "${APPLE_TEAM_ID:-}" =~ ^[A-Z0-9]{10}$ ]] || { echo "APPLE_ARCHIVE_STOP APPLE_TEAM_ID required"; exit 2; }
    [[ -f "$checkpoint" ]] || { echo "APPLE_ARCHIVE_STOP prepare checkpoint missing"; exit 3; }
    xcodeproj="$(find "$lane/Generated" -maxdepth 4 -name '*.xcodeproj' -print -quit)"
    scheme="$(basename "$xcodeproj" .xcodeproj)"
    archive="$lane/${game_id}.xcarchive"
    sed -i '' '/CODE_SIGN_IDENTITY =/d' "$xcodeproj/project.pbxproj"
    caffeinate -dimsu -- xcodebuild -project "$xcodeproj" -scheme "$scheme" -configuration Release -destination generic/platform=iOS -archivePath "$archive" DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive | tee "$lane/archive.log"
    app="$(find "$archive/Products/Applications" -maxdepth 1 -name '*.app' -print -quit)"
    [[ -n "$app" ]] || { echo "APPLE_ARCHIVE_STOP signed app missing"; exit 3; }
    forbidden_symbols="$(find "$app" -name '.symbols' -print -quit)"
    [[ -z "$forbidden_symbols" ]] || { echo "APPLE_ARCHIVE_STOP forbidden path in signed app: $forbidden_symbols"; exit 3; }
    codesign --verify --deep --strict --verbose=2 "$app"
    plist="$app/Info.plist"
    [[ "$(plutil -extract CFBundleIdentifier raw "$plist")" == "$bundle" ]]
    [[ "$(plutil -extract CFBundleShortVersionString raw "$plist")" == "$version" ]]
    [[ "$(plutil -extract CFBundleVersion raw "$plist")" == "$build" ]]
    if [[ "$game_center" == true ]]; then
      [[ "$(codesign -d --entitlements :- "$app" 2>/dev/null | plutil -extract 'com.apple.developer.game-center' raw -)" == true ]]
    fi
    write_checkpoint archived
    echo "APPLE_ARCHIVE_PASS version=$version build=$build signed=true upload=false"
    ;;
  upload)
    [[ "${APPLE_UPLOAD_ACK:-}" == "UPLOAD_BUILD_${build}" ]] || { echo "APPLE_UPLOAD_STOP authorization required: APPLE_UPLOAD_ACK=UPLOAD_BUILD_${build}"; exit 2; }
    archive="$lane/${game_id}.xcarchive"
    [[ -d "$archive" ]] || { echo "APPLE_UPLOAD_STOP archive missing"; exit 3; }
    cat > "$lane/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>method</key><string>app-store-connect</string><key>destination</key><string>upload</string><key>signingStyle</key><string>automatic</string><key>teamID</key><string>${APPLE_TEAM_ID:?APPLE_TEAM_ID required}</string></dict></plist>
EOF
    caffeinate -dimsu -- xcodebuild -exportArchive -archivePath "$archive" -exportPath "$lane/Upload" -exportOptionsPlist "$lane/ExportOptions.plist" -allowProvisioningUpdates | tee "$lane/upload.log"
    write_checkpoint upload-command-succeeded
    echo "APPLE_UPLOAD_COMMAND_SUCCEEDED version=$version build=$build processing=unverified release=not-authorized"
    ;;
  status)
    [[ -f "$checkpoint" ]] || { echo "APPLE_STATUS local checkpoint missing"; exit 3; }
    cat "$checkpoint"
    echo "APPLE_STATUS_ACTION verify exact bundle=$bundle version=$version build=$build in App Store Connect; processing and TestFlight are not inferred"
    ;;
  *) echo "APPLE_DELIVERY_STOP unsupported mode=$mode"; exit 2;;
esac
