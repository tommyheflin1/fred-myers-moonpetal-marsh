#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, re
from pathlib import Path

COMMIT="fbdbc317fe2ab422ef9bf5fb07f876eb2e773bcb"; TAG="4.7.1-stable"; PATCH_ID="gamecenter-uiwindow-scene-v1"; PATCH_SHA="bdcc0f6dbdb199c62867c2a7aefc0397cac858113a6f893e047838b188c99ee2"

def validate(root: Path) -> list[str]:
    errors=[]; plugin=root/"ios/plugins/gamecenter"; patch=root/"tools/patches/gamecenter-uiwindow-scene-v1.patch"
    for path in (plugin/"gamecenter.gdip",plugin/"PROVENANCE.txt",plugin/"LICENSE.godot-ios-plugins.txt",patch):
        if not path.is_file(): errors.append(f"missing {path.relative_to(root).as_posix()}")
    if patch.is_file() and hashlib.sha256(patch.read_bytes()).hexdigest()!=PATCH_SHA: errors.append("Game Center patch hash mismatch")
    provenance=(plugin/"PROVENANCE.txt").read_text(encoding="utf-8") if (plugin/"PROVENANCE.txt").is_file() else ""
    for value,label in ((f"source_commit={COMMIT}","commit"),(f"godot_tag={TAG}","tag"),(f"patch_id={PATCH_ID}","patch"),(f"patch_sha256={PATCH_SHA}","patch hash")):
        if value not in provenance: errors.append(f"Game Center provenance {label} mismatch")
    for target in ("debug","release"):
        framework=plugin/f"gamecenter.{target}.xcframework"
        if not (framework/"Info.plist").is_file() or len(list(framework.rglob("*.a")))<2: errors.append(f"Game Center {target} framework lacks device/simulator contract")
    preset=(root/"export_presets.cfg").read_text(encoding="utf-8")
    for line in ("capabilities/game_center=true","plugins/GameCenter=true"):
        if not re.search(rf"(?m)^{re.escape(line)}$",preset): errors.append(f"iOS export missing {line}")
    return errors

def main()->int:
    p=argparse.ArgumentParser(); p.add_argument("--project-root",type=Path,default=Path.cwd()); root=p.parse_args().project_root.resolve(); errors=validate(root)
    print(json.dumps({"status":"FAIL" if errors else "PASS","errors":errors,"plugin_commit":COMMIT,"patch_id":PATCH_ID},indent=2,sort_keys=True)); return 1 if errors else 0
if __name__=="__main__": raise SystemExit(main())
