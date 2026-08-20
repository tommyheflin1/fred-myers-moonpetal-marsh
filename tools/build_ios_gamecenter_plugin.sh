#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-}"
[[ -n "$repo_root" ]] || { echo "Usage: tools/build_ios_gamecenter_plugin.sh <repo-root>" >&2; exit 2; }
repo_root="$(cd "$repo_root" && pwd)"
plugin_commit="fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"
presentation_patch_commit="58c7b86054d9fe2eb7c7a0095153df8db64096aa"
score_patch_commit="2824fadd0e20a3cdcc12650d01c3c5934f7fd4ca"
fred_event_patch_version="fred-gamecenter-events-v1"
godot_tag="4.7.1-stable"
source_root="${FRED_IOS_PLUGIN_CACHE:-$HOME/Library/Caches/fred-myers/godot-ios-plugins-$plugin_commit}"
destination="$repo_root/godot/ios/plugins/gamecenter"

for tool in git python3 scons xcodebuild shasum; do command -v "$tool" >/dev/null || { echo "$tool is required." >&2; exit 1; }; done
if [[ -d "$destination" ]]; then
  if python3 "$repo_root/tools/validate_ios_gamecenter_plugin.py" --project-root "$repo_root"; then
    exit 0
  fi
  rm -rf -- "$destination"
fi
if [[ ! -d "$source_root/.git" ]]; then
  mkdir -p "$(dirname "$source_root")"
  git clone --filter=blob:none --no-checkout https://github.com/godot-sdk-integrations/godot-ios-plugins.git "$source_root"
fi
git -C "$source_root" fetch --quiet origin "$plugin_commit"
git -C "$source_root" checkout --detach "$plugin_commit"
[[ "$(git -C "$source_root" rev-parse HEAD)" == "$plugin_commit" ]] || { echo "Plugin source commit mismatch." >&2; exit 1; }
git -C "$source_root" restore --source="$plugin_commit" --staged --worktree plugins/gamecenter
for patch_spec in \
  "refs/pull/100/head:$presentation_patch_commit" \
  "refs/pull/102/head:$score_patch_commit"; do
  patch_ref="${patch_spec%%:*}"
  expected_patch="${patch_spec##*:}"
  git -C "$source_root" fetch --quiet origin "$patch_ref"
  actual_patch="$(git -C "$source_root" rev-parse FETCH_HEAD)"
  [[ "$actual_patch" == "$expected_patch" ]] || { echo "Game Center upstream patch mismatch for $patch_ref." >&2; exit 1; }
  git -C "$source_root" show --format= "$actual_patch" -- plugins/gamecenter/game_center.mm | git -C "$source_root" apply --check -
  git -C "$source_root" show --format= "$actual_patch" -- plugins/gamecenter/game_center.mm | git -C "$source_root" apply -
done
python3 "$repo_root/tools/patch_ios_gamecenter_events.py" "$source_root/plugins/gamecenter/game_center.mm"
git -C "$source_root" submodule update --init godot
git -C "$source_root/godot" fetch --quiet --tags origin "$godot_tag"
git -C "$source_root/godot" checkout --detach "$godot_tag"
[[ "$(git -C "$source_root/godot" describe --tags --exact-match)" == "$godot_tag" ]] || { echo "Godot source tag mismatch." >&2; exit 1; }
mkdir -p "$source_root/bin"
jobs="${FRED_IOS_PLUGIN_JOBS:-4}"
(cd "$source_root/godot" && scons platform=ios target=template_debug -j"$jobs")
debug_framework="$source_root/bin/gamecenter.release_debug.xcframework"
release_framework="$source_root/bin/gamecenter.release.xcframework"
patch_stamp="$source_root/bin/.fred-gamecenter-patch-set"
patch_fingerprint="$presentation_patch_commit $score_patch_commit $fred_event_patch_version"
if [[ -f "$debug_framework/Info.plist" && -f "$release_framework/Info.plist" \
  && "$(find "$debug_framework" -name '*.a' -print | wc -l | tr -d ' ')" -ge 2 \
  && "$(find "$release_framework" -name '*.a' -print | wc -l | tr -d ' ')" -ge 2 \
  && -f "$patch_stamp" && "$(cat "$patch_stamp")" == "$patch_fingerprint" ]]; then
  echo "IOS_GAMECENTER_PLUGIN_CACHE_REUSED source=$plugin_commit godot=$godot_tag"
else
  rm -rf -- "$debug_framework" "$release_framework"
  (cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release_debug 4.0)
  (cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release 4.0)
  printf '%s' "$patch_fingerprint" > "$patch_stamp"
fi
staging="$(mktemp -d "${TMPDIR:-/tmp}/fred-gamecenter.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/gamecenter"
cp "$source_root/plugins/gamecenter/gamecenter.gdip" "$staging/gamecenter/"
cp -R "$debug_framework" "$staging/gamecenter/gamecenter.debug.xcframework"
cp -R "$release_framework" "$staging/gamecenter/"
cp "$source_root/LICENCE" "$staging/gamecenter/LICENSE.godot-ios-plugins.txt"
{
  echo "source=https://github.com/godot-sdk-integrations/godot-ios-plugins.git"
  echo "source_commit=$plugin_commit"
  echo "presentation_patch_commit=$presentation_patch_commit"
  echo "score_patch_commit=$score_patch_commit"
  echo "fred_event_patch_version=$fred_event_patch_version"
  echo "godot_tag=$godot_tag"
  echo "built_with=$(xcodebuild -version | tr '\n' ' ')"
} > "$staging/gamecenter/PROVENANCE.txt"
mkdir -p "$(dirname "$destination")"
mv "$staging/gamecenter" "$destination"
python3 "$repo_root/tools/validate_ios_gamecenter_plugin.py" --project-root "$repo_root"
echo "IOS_GAMECENTER_PLUGIN_READY source=$plugin_commit godot=$godot_tag"
