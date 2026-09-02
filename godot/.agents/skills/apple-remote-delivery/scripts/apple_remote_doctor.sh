#!/usr/bin/env bash
set -u

root="${1:-$PWD}"
failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }
need() { command -v "$1" >/dev/null 2>&1 && pass "tool:$1" || fail "tool:$1 missing"; }

[[ "$(uname -s)" == "Darwin" ]] && pass "host:macOS" || fail "host:macOS required"
[[ -f "$root/game/game.json" ]] && pass "game:definition" || fail "game:definition missing"
[[ -f "$root/export_presets.cfg" ]] && pass "game:export-presets" || fail "game:export-presets missing"

for tool in git python3 xcodebuild xcrun xcode-select security codesign shasum plutil caffeinate; do need "$tool"; done

if command -v xcodebuild >/dev/null 2>&1; then
  xcode_text="$(xcodebuild -version 2>/dev/null || true)"
  xcode_major="$(printf '%s\n' "$xcode_text" | awk 'NR==1 {split($2,v,"."); print v[1]}')"
  [[ "$xcode_major" =~ ^[0-9]+$ && "$xcode_major" -ge 26 ]] && pass "xcode:26+" || fail "xcode:26+ required; found ${xcode_text//$'\n'/ }"
  xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1 && pass "xcode:first-launch-complete" || fail "xcode:first-launch incomplete"
fi

if command -v xcrun >/dev/null 2>&1; then
  ios_sdk="$(xcrun --sdk iphoneos --show-sdk-version 2>/dev/null || true)"
  ios_major="${ios_sdk%%.*}"
  [[ "$ios_major" =~ ^[0-9]+$ && "$ios_major" -ge 26 ]] && pass "ios-sdk:26+" || fail "ios-sdk:26+ required; found ${ios_sdk:-none}"
fi

godot="$(command -v godot 2>/dev/null || true)"
if [[ -z "$godot" && -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then godot=/Applications/Godot.app/Contents/MacOS/Godot; fi
if [[ -n "$godot" ]]; then
  godot_version="$($godot --version 2>/dev/null || true)"
  [[ "$godot_version" == 4.7.1* ]] && pass "godot:4.7.1" || fail "godot:4.7.1 required; found $godot_version"
else
  fail "godot:4.7.1 missing"
fi

templates="$HOME/Library/Application Support/Godot/export_templates/4.7.1.stable"
[[ -d "$templates" ]] && pass "godot:export-templates" || fail "godot:export-templates missing at $templates"

if [[ -f "$root/game/game.json" ]] && command -v python3 >/dev/null 2>&1; then
  summary="$(python3 - "$root/game/game.json" <<'PY'
import json, sys
d=json.load(open(sys.argv[1], encoding='utf-8'))
print(f"{d.get('game_id','')}|{d.get('bundle_id','')}|{d.get('marketing_version','')}|{d.get('build_number','')}|{str(bool(d.get('capabilities',{}).get('game_center'))).lower()}")
PY
)"
  IFS='|' read -r game_id bundle_id version build game_center <<< "$summary"
  [[ -n "$game_id" && -n "$bundle_id" && -n "$version" && "$build" =~ ^[1-9][0-9]*$ ]] && pass "game:identity $game_id $bundle_id $version($build)" || fail "game:identity invalid"
  if [[ "$game_center" == true ]]; then
    need scons
    [[ -f "$root/tools/build_ios_gamecenter_plugin.sh" ]] && pass "game-center:plugin-build-tool" || fail "game-center:tools/build_ios_gamecenter_plugin.sh missing"
    [[ -f "$root/tools/validate_ios_gamecenter_plugin.py" ]] && pass "game-center:plugin-validator" || fail "game-center:tools/validate_ios_gamecenter_plugin.py missing"
  fi
fi

identity_count="$(security find-identity -v -p codesigning 2>/dev/null | awk '/valid identities found/ {print $1}' | tail -n 1)"
[[ "$identity_count" =~ ^[1-9][0-9]*$ ]] && pass "apple:signing-identity-present" || fail "apple:signing identity missing"

if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  [[ -z "$(git -C "$root" status --porcelain)" ]] && pass "git:clean" || fail "git:worktree dirty"
  pass "git:commit $(git -C "$root" rev-parse HEAD)"
else
  fail "git:repository missing"
fi

free_kb="$(df -Pk "$root" 2>/dev/null | awk 'NR==2 {print $4}')"
[[ "$free_kb" =~ ^[0-9]+$ && "$free_kb" -ge 26214400 ]] && pass "disk:25GiB-free" || fail "disk:25GiB free required"

if (( failures )); then
  printf 'APPLE_REMOTE_DOCTOR_FAIL failures=%d\n' "$failures"
  exit 1
fi
printf 'APPLE_REMOTE_DOCTOR_PASS signing=available upload=not-authorized release=not-authorized\n'
