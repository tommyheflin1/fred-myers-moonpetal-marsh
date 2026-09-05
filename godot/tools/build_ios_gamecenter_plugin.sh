#!/usr/bin/env bash
set -euo pipefail
root="${1:?usage: build_ios_gamecenter_plugin.sh <project-root>}"; root="$(cd "$root" && pwd)"
commit="fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"; tag="4.7.1-stable"
patch="$root/tools/patches/gamecenter-uiwindow-scene-v1.patch"; patch_sha="bdcc0f6dbdb199c62867c2a7aefc0397cac858113a6f893e047838b188c99ee2"
identity_patch="$root/tools/patches/gamecenter-signed-identity-v1.patch"; identity_patch_sha="64de6a5dba83f854dcbce981ab1ca8de81c44793e10e76195fbba1a38a899b66"
source_root="${FLINS_IOS_PLUGIN_CACHE:-$HOME/Library/Caches/flins-mobile-game/godot-ios-plugins-$commit}"
destination="$root/ios/plugins/gamecenter"
for tool in git python3 scons xcodebuild shasum; do command -v "$tool" >/dev/null || { echo "$tool is required" >&2; exit 1; }; done
[[ -f "$patch" && "$(shasum -a 256 "$patch" | awk '{print $1}')" == "$patch_sha" ]] || { echo "Game Center patch missing or hash mismatch" >&2; exit 1; }
[[ -f "$identity_patch" && "$(shasum -a 256 "$identity_patch" | awk '{print $1}')" == "$identity_patch_sha" ]] || { echo "Game Center identity patch missing or hash mismatch" >&2; exit 1; }
if [[ -d "$destination" ]]; then python3 "$root/tools/validate_ios_gamecenter_plugin.py" --project-root "$root"; exit 0; fi
if [[ ! -d "$source_root/.git" ]]; then mkdir -p "$(dirname "$source_root")"; git clone --filter=blob:none --no-checkout https://github.com/godot-sdk-integrations/godot-ios-plugins.git "$source_root"; fi
git -C "$source_root" fetch --quiet origin "$commit"; git -C "$source_root" checkout --detach "$commit"; git -C "$source_root" reset --hard "$commit" >/dev/null
git -C "$source_root" apply --check "$patch"; git -C "$source_root" apply "$patch"
git -C "$source_root" apply --check "$identity_patch"; git -C "$source_root" apply "$identity_patch"
[[ "$(grep -c 'gamecenter_presentation_controller();' "$source_root/plugins/gamecenter/game_center.mm")" == "2" ]] || { echo "patch must cover authentication and leaderboard presentation" >&2; exit 1; }
git -C "$source_root" submodule update --init godot; git -C "$source_root/godot" fetch --quiet --tags origin "$tag"; git -C "$source_root/godot" checkout --detach "$tag"
(cd "$source_root/godot" && scons platform=ios target=template_debug -j"${FLINS_IOS_PLUGIN_JOBS:-4}")
(cd "$source_root" && ./scripts/generate_xcframework.sh gamecenter release_debug 4.0 && ./scripts/generate_xcframework.sh gamecenter release 4.0)
staging="$(mktemp -d "${TMPDIR:-/tmp}/flins-gamecenter.XXXXXX")"; trap 'rm -rf "$staging"' EXIT; mkdir -p "$staging/gamecenter"
cp "$source_root/plugins/gamecenter/gamecenter.gdip" "$staging/gamecenter/"; cp -R "$source_root/bin/gamecenter.release_debug.xcframework" "$staging/gamecenter/gamecenter.debug.xcframework"; cp -R "$source_root/bin/gamecenter.release.xcframework" "$staging/gamecenter/"; cp "$source_root/LICENCE" "$staging/gamecenter/LICENSE.godot-ios-plugins.txt"
find "$staging/gamecenter" -type d -name '.symbols' -prune -exec rm -rf -- {} +
printf 'source_commit=%s\ngodot_tag=%s\npatch_id=gamecenter-uiwindow-scene-v1\npatch_sha256=%s\nidentity_patch_id=gamecenter-signed-identity-v1\nidentity_patch_sha256=%s\n' "$commit" "$tag" "$patch_sha" "$identity_patch_sha" > "$staging/gamecenter/PROVENANCE.txt"
mkdir -p "$(dirname "$destination")"; mv "$staging/gamecenter" "$destination"; python3 "$root/tools/validate_ios_gamecenter_plugin.py" --project-root "$root"
