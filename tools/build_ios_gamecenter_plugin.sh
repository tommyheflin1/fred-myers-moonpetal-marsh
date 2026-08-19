#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-}"
[[ -n "$repo_root" ]] || { echo "Usage: tools/build_ios_gamecenter_plugin.sh <repo-root>" >&2; exit 2; }
repo_root="$(cd "$repo_root" && pwd)"
plugin_commit="fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"
godot_tag="4.7.1-stable"
source_root="${FRED_IOS_PLUGIN_CACHE:-$HOME/Library/Caches/fred-myers/godot-ios-plugins-$plugin_commit}"
destination="$repo_root/godot/ios/plugins/gamecenter"

for tool in git python3 scons xcodebuild shasum; do command -v "$tool" >/dev/null || { echo "$tool is required." >&2; exit 1; }; done
if [[ -d "$destination" ]]; then
  python3 "$repo_root/tools/validate_ios_gamecenter_plugin.py" --project-root "$repo_root"
  exit 0
fi
if [[ ! -d "$source_root/.git" ]]; then
  mkdir -p "$(dirname "$source_root")"
  git clone --filter=blob:none --no-checkout https://github.com/godot-sdk-integrations/godot-ios-plugins.git "$source_root"
fi
git -C "$source_root" fetch --quiet origin "$plugin_commit"
git -C "$source_root" checkout --detach "$plugin_commit"
[[ "$(git -C "$source_root" rev-parse HEAD)" == "$plugin_commit" ]] || { echo "Plugin source commit mismatch." >&2; exit 1; }
git -C "$source_root" submodule update --init godot
git -C "$source_root/godot" fetch --quiet --tags origin "$godot_tag"
git -C "$source_root/godot" checkout --detach "$godot_tag"
[[ "$(git -C "$source_root/godot" describe --tags --exact-match)" == "$godot_tag" ]] || { echo "Godot source tag mismatch." >&2; exit 1; }
mkdir -p "$source_root/bin"
jobs="${FRED_IOS_PLUGIN_JOBS:-4}"
(cd "$source_root/godot" && scons platform=ios target=template_debug -j"$jobs")
(cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release_debug 4.0)
(cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release 4.0)
staging="$(mktemp -d "${TMPDIR:-/tmp}/fred-gamecenter.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/gamecenter"
cp "$source_root/plugins/gamecenter/gamecenter.gdip" "$staging/gamecenter/"
cp -R "$source_root/bin/gamecenter.release_debug.xcframework" "$staging/gamecenter/gamecenter.debug.xcframework"
cp -R "$source_root/bin/gamecenter.release.xcframework" "$staging/gamecenter/"
cp "$source_root/LICENCE" "$staging/gamecenter/LICENSE.godot-ios-plugins.txt"
{
  echo "source=https://github.com/godot-sdk-integrations/godot-ios-plugins.git"
  echo "source_commit=$plugin_commit"
  echo "godot_tag=$godot_tag"
  echo "built_with=$(xcodebuild -version | tr '\n' ' ')"
} > "$staging/gamecenter/PROVENANCE.txt"
mkdir -p "$(dirname "$destination")"
mv "$staging/gamecenter" "$destination"
python3 "$repo_root/tools/validate_ios_gamecenter_plugin.py" --project-root "$repo_root"
echo "IOS_GAMECENTER_PLUGIN_READY source=$plugin_commit godot=$godot_tag"
