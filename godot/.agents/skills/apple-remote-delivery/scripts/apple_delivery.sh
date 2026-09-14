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
encryption_declaration="$(python3 - "$root/tools/ios_release_config.json" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding='utf-8')).get('uses_non_exempt_encryption')
print('true' if value is True else 'false' if value is False else 'pending')
PY
)"
[[ "$encryption_declaration" != pending ]] || { echo "APPLE_DELIVERY_STOP export compliance declaration requires owner/legal review"; exit 2; }
lane="$root/builds/ios/apple-delivery/${version}-${build}"
checkpoint="$lane/checkpoint.json"
godot="$(command -v godot 2>/dev/null || true)"
[[ -n "$godot" ]] || godot=/Applications/Godot.app/Contents/MacOS/Godot

write_checkpoint() {
  local gate="$1"
  python3 "$root/tools/release_checkpoint.py" record --root "$root" --commit "$commit" --mode "$gate"
}

codesign_entitlement_is_true() {
  local app="$1"
  local key="$2"
  codesign -d --entitlements :- "$app" 2>/dev/null | python3 -c 'import plistlib, sys; payload = plistlib.loads(sys.stdin.buffer.read()); raise SystemExit(0 if payload.get(sys.argv[1]) is True else 1)' "$key"
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
    # This export is later archived. Its PCK must not contain debug-only behavior.
    "$godot" --headless --path "$root" --export-release "iOS Unsigned Preparation" "$export_root/Game"
    python3 "$root/tools/verify_ios_icon_artifacts.py" --project-root "$root" --xcode-export "$export_root"
    python3 "$root/tools/validate_ios_privacy_manifest.py" --stage "$export_root"
    python3 "$root/tools/prepare_ios_export_compliance.py" --export-root "$export_root" --uses-non-exempt-encryption "$encryption_declaration"
    xcodeproj="$(find "$lane" -maxdepth 4 -name '*.xcodeproj' -print -quit)"
    [[ -n "$xcodeproj" ]] || { echo "APPLE_PREPARE_STOP Xcode project missing"; exit 3; }
    scheme="$(basename "$xcodeproj" .xcodeproj)"
    xcodebuild -project "$xcodeproj" -scheme "$scheme" -sdk iphonesimulator -configuration Release -derivedDataPath "$lane/DerivedData" CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 build | tee "$lane/prepare.log"
    unsigned_app="$(find "$lane/DerivedData/Build/Products" -type d -name '*.app' -print -quit)"
    [[ -n "$unsigned_app" ]] || { echo "APPLE_PREPARE_STOP unsigned app missing"; exit 3; }
    python3 "$root/tools/scan_ios_app_bundle.py" --project-root "$root" --app "$unsigned_app" --stage unsigned
    python3 "$root/tools/verify_ios_icon_artifacts.py" --project-root "$root" --app "$unsigned_app"
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
    signing_lines="$(python3 "$root/tools/ios_signing.py" archive-arguments --root "$root" --team "$APPLE_TEAM_ID")"
    signing_args=()
    while IFS= read -r argument; do signing_args+=("$argument"); done <<< "$signing_lines"
    caffeinate -dimsu -- xcodebuild -project "$xcodeproj" -scheme "$scheme" -configuration Release -destination generic/platform=iOS -archivePath "$archive" "${signing_args[@]}" archive | tee "$lane/archive.log"
    app="$(find "$archive/Products/Applications" -maxdepth 1 -name '*.app' -print -quit)"
    [[ -n "$app" ]] || { echo "APPLE_ARCHIVE_STOP signed app missing"; exit 3; }
    forbidden_symbols="$(find "$app" -name '.symbols' -print -quit)"
    [[ -z "$forbidden_symbols" ]] || { echo "APPLE_ARCHIVE_STOP forbidden path in signed app: $forbidden_symbols"; exit 3; }
    codesign --verify --deep --strict --verbose=2 "$app"
    python3 "$root/tools/scan_ios_app_bundle.py" --project-root "$root" --app "$app" --stage signed
    python3 "$root/tools/verify_ios_icon_artifacts.py" --project-root "$root" --app "$app"
    plist="$app/Info.plist"
    [[ "$(plutil -extract CFBundleIdentifier raw "$plist")" == "$bundle" ]]
    [[ "$(plutil -extract CFBundleShortVersionString raw "$plist")" == "$version" ]]
    [[ "$(plutil -extract CFBundleVersion raw "$plist")" == "$build" ]]
    [[ "$(plutil -extract ITSAppUsesNonExemptEncryption raw "$plist")" == "$encryption_declaration" ]]
    if [[ "$game_center" == true ]]; then
      codesign_entitlement_is_true "$app" 'com.apple.developer.game-center'
    fi
    write_checkpoint archived
    echo "APPLE_ARCHIVE_PASS version=$version build=$build signed=true upload=false"
    ;;
  upload)
    [[ "${APPLE_UPLOAD_ACK:-}" == "UPLOAD_BUILD_${build}" ]] || { echo "APPLE_UPLOAD_STOP authorization required: APPLE_UPLOAD_ACK=UPLOAD_BUILD_${build}"; exit 2; }
    archive="$lane/${game_id}.xcarchive"
    [[ -d "$archive" ]] || { echo "APPLE_UPLOAD_STOP archive missing"; exit 3; }
    python3 "$root/tools/ios_signing.py" export-options --root "$root" --team "${APPLE_TEAM_ID:?APPLE_TEAM_ID required}"
    upload_method="$(python3 "$root/tools/ios_signing.py" upload-method --root "$root" --team "$APPLE_TEAM_ID")"
    if [[ "$upload_method" == altool ]]; then
      # Preserve the already-established manual export/validate/altool sequence.
      # Credentials stay in their existing external location; never copy or reset them.
      credential_lines="$(python3 "$root/tools/ios_signing.py" upload-credentials --root "$root" --team "$APPLE_TEAM_ID")"
      credentials=()
      while IFS= read -r argument; do credentials+=("$argument"); done <<< "$credential_lines"
      [[ ${#credentials[@]} == 2 ]] || { echo "APPLE_UPLOAD_STOP API identity unavailable"; exit 3; }
      caffeinate -dimsu -- xcodebuild -exportArchive -archivePath "$archive" -exportPath "$lane/Upload" -exportOptionsPlist "$lane/ExportOptions.plist" | tee "$lane/export.log"
      ipa="$(find "$lane/Upload" -maxdepth 1 -name '*.ipa' -print -quit)"
      [[ -n "$ipa" ]] || { echo "APPLE_UPLOAD_STOP exported IPA missing"; exit 3; }
      ipa_check="$(mktemp -d "$lane/ExportedAppCheck.XXXXXX")"
      ditto -x -k "$ipa" "$ipa_check"
      exported_app="$(find "$ipa_check/Payload" -maxdepth 1 -name '*.app' -print -quit)"
      [[ -n "$exported_app" ]] || { echo "APPLE_UPLOAD_STOP exported app missing"; exit 3; }
      codesign --verify --deep --strict "$exported_app"
      python3 "$root/tools/scan_ios_app_bundle.py" --project-root "$root" --app "$exported_app" --stage signed
      [[ "$(plutil -extract CFBundleIdentifier raw "$exported_app/Info.plist")" == "$bundle" ]]
      [[ "$(plutil -extract CFBundleShortVersionString raw "$exported_app/Info.plist")" == "$version" ]]
      [[ "$(plutil -extract CFBundleVersion raw "$exported_app/Info.plist")" == "$build" ]]
      if [[ "$game_center" == true ]]; then
        codesign_entitlement_is_true "$exported_app" 'com.apple.developer.game-center' || {
          echo "APPLE_UPLOAD_STOP exported IPA lost Game Center entitlement"; exit 3;
        }
      fi
      xcrun altool --validate-app -f "$ipa" -t ios --apiKey "${credentials[0]}" --apiIssuer "${credentials[1]}" | tee "$lane/validate.log"
      caffeinate -dimsu -- xcrun altool --upload-app -f "$ipa" -t ios --apiKey "${credentials[0]}" --apiIssuer "${credentials[1]}" | tee "$lane/upload.log"
    else
      caffeinate -dimsu -- xcodebuild -exportArchive -archivePath "$archive" -exportPath "$lane/Upload" -exportOptionsPlist "$lane/ExportOptions.plist" -allowProvisioningUpdates | tee "$lane/upload.log"
    fi
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
