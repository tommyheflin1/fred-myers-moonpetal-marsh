#!/usr/bin/env bash
set -euo pipefail

project_root="${1:-}"
if [[ -z "$project_root" ]]; then
  echo "Usage: tools/build_ios_gamecenter_plugin.sh <project-root>" >&2
  exit 2
fi

project_root="$(cd "$project_root" && pwd)"
plugin_commit="fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"
godot_tag="4.7.1-stable"
plugin_patch_id="gamecenter-uiwindow-scene-v1"
plugin_patch_file="$project_root/tools/patches/gamecenter-uiwindow-scene-v1.patch"
plugin_patch_sha256="bdcc0f6dbdb199c62867c2a7aefc0397cac858113a6f893e047838b188c99ee2"
identity_patch_id=gamecenter-signed-identity-v1
identity_patch_file="$project_root/tools/patches/gamecenter-signed-identity-v1.patch"
identity_patch_sha256="6b4a33596a4719538ffef8747d5f84e0f0fcde1156fbb358256974c116f3690c"
keychain_patch_id=gamecenter-keychain-v1
keychain_patch_file="$project_root/tools/patches/gamecenter-keychain-v1.patch"
keychain_patch_sha256="15866e5e26ab29a83299411efe5a126a47782a95f0a04f9e873dc969b08b3fc0"
# A separate patched-source cache preserves earlier app release checkpoints.
source_root="${FLINS_IOS_PLUGIN_CACHE:-$HOME/Library/Caches/flins-ios/godot-ios-plugins-$plugin_commit-$keychain_patch_id}"
destination="$project_root/ios/plugins/gamecenter"

command -v git >/dev/null || { echo "git is required." >&2; exit 1; }
command -v python3 >/dev/null || { echo "Python 3 is required." >&2; exit 1; }
command -v scons >/dev/null || { echo "SCons is required." >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode is required." >&2; exit 1; }
command -v shasum >/dev/null || { echo "shasum is required." >&2; exit 1; }
[[ -f "$plugin_patch_file" ]] || { echo "Game Center compatibility patch is missing." >&2; exit 1; }
[[ -f "$identity_patch_file" ]] || { echo "Game Center signed-identity patch is missing." >&2; exit 1; }
[[ -f "$keychain_patch_file" ]] || { echo "Game Center Keychain patch is missing." >&2; exit 1; }
[[ "$(shasum -a 256 "$plugin_patch_file" | awk '{print $1}')" == "$plugin_patch_sha256" ]] || { echo "Game Center compatibility patch hash mismatch." >&2; exit 1; }
[[ "$(shasum -a 256 "$identity_patch_file" | awk '{print $1}')" == "$identity_patch_sha256" ]] || { echo "Game Center signed-identity patch hash mismatch." >&2; exit 1; }
[[ "$(shasum -a 256 "$keychain_patch_file" | awk '{print $1}')" == "$keychain_patch_sha256" ]] || { echo "Game Center Keychain patch hash mismatch." >&2; exit 1; }

if [[ -d "$destination" ]]; then
  python3 "$project_root/tools/validate_ios_gamecenter_plugin.py" --project-root "$project_root"
  exit 0
fi

fresh_clone=0
if [[ ! -d "$source_root/.git" ]]; then
  mkdir -p "$(dirname "$source_root")"
  git clone --filter=blob:none --no-checkout https://github.com/godot-sdk-integrations/godot-ios-plugins.git "$source_root"
  fresh_clone=1
fi

git -C "$source_root" fetch --quiet origin "$plugin_commit"
if [[ "$fresh_clone" == 1 ]]; then
  # A --no-checkout clone reports every tracked path as deleted until its first
  # checkout. Populate the pinned tree before applying the dirty-cache guard so
  # a brand-new isolated cache is not mistaken for an already-patched cache.
  git -C "$source_root" checkout --detach "$plugin_commit"
fi
if [[ -n "$(git -C "$source_root" status --porcelain --ignore-submodules=all)" ]]; then
  git -C "$source_root" apply --reverse --check "$keychain_patch_file"
  git -C "$source_root" apply --reverse "$keychain_patch_file"
  git -C "$source_root" apply --reverse --check "$identity_patch_file"
  git -C "$source_root" apply --reverse "$identity_patch_file"
  git -C "$source_root" apply --reverse --check "$plugin_patch_file"
  git -C "$source_root" apply --reverse "$plugin_patch_file"
fi
[[ -z "$(git -C "$source_root" status --porcelain --ignore-submodules=all)" ]] || { echo "Plugin cache has unrelated changes; preserve it and use a fresh cache." >&2; exit 1; }
git -C "$source_root" checkout --detach "$plugin_commit"
[[ "$(git -C "$source_root" rev-parse HEAD)" == "$plugin_commit" ]] || { echo "Plugin source commit mismatch." >&2; exit 1; }
git -C "$source_root" apply --check "$plugin_patch_file"
git -C "$source_root" apply "$plugin_patch_file"
git -C "$source_root" apply --check "$identity_patch_file"
git -C "$source_root" apply "$identity_patch_file"
git -C "$source_root" apply --check "$keychain_patch_file"
git -C "$source_root" apply "$keychain_patch_file"
grep -q "gamecenter_presentation_controller" "$source_root/plugins/gamecenter/game_center.mm" || { echo "Game Center compatibility patch did not apply." >&2; exit 1; }
[[ "$(grep -c 'gamecenter_presentation_controller();' "$source_root/plugins/gamecenter/game_center.mm")" == "2" ]] || { echo "Game Center compatibility patch must cover authentication and presentation." >&2; exit 1; }

git -C "$source_root" submodule update --init godot
git -C "$source_root/godot" fetch --quiet --tags origin "$godot_tag"
git -C "$source_root/godot" checkout --detach "$godot_tag"
[[ "$(git -C "$source_root/godot" describe --tags --exact-match)" == "$godot_tag" ]] || { echo "Godot source tag mismatch." >&2; exit 1; }

build_jobs="${FLINS_IOS_PLUGIN_JOBS:-4}"
(cd "$source_root/godot" && scons platform=ios target=template_debug -j"$build_jobs")
(cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release_debug 4.0)
(cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release 4.0)

staging="$(mktemp -d "${TMPDIR:-/tmp}/flins-gamecenter.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/gamecenter"
cp "$source_root/plugins/gamecenter/gamecenter.gdip" "$staging/gamecenter/"
cp -R "$source_root/bin/gamecenter.release_debug.xcframework" "$staging/gamecenter/gamecenter.debug.xcframework"
cp -R "$source_root/bin/gamecenter.release.xcframework" "$staging/gamecenter/"
cp "$source_root/LICENCE" "$staging/gamecenter/LICENSE.godot-ios-plugins.txt"
find "$staging/gamecenter" -name '.symbols' -prune -exec rm -rf -- {} +
{
  echo "source=https://github.com/godot-sdk-integrations/godot-ios-plugins.git"
  echo "source_commit=$plugin_commit"
  echo "godot_tag=$godot_tag"
  echo "patch_id=$plugin_patch_id"
  echo "patch_sha256=$plugin_patch_sha256"
  echo "identity_patch_id=$identity_patch_id"
  echo "identity_patch_sha256=$identity_patch_sha256"
  echo "keychain_patch_id=$keychain_patch_id"
  echo "keychain_patch_sha256=$keychain_patch_sha256"
  echo "built_with=$(xcodebuild -version | tr '\n' ' ')"
} > "$staging/gamecenter/PROVENANCE.txt"
mkdir -p "$(dirname "$destination")"
mv "$staging/gamecenter" "$destination"

python3 "$project_root/tools/validate_ios_gamecenter_plugin.py" --project-root "$project_root"
echo "IOS_GAMECENTER_PLUGIN_READY source=$plugin_commit godot=$godot_tag patch=$plugin_patch_id destination=$destination"
