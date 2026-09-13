#!/usr/bin/env python3
from __future__ import annotations
import argparse, json
from pathlib import Path

def main()->int:
    p=argparse.ArgumentParser(); p.add_argument("--root",type=Path,default=Path.cwd()); a=p.parse_args(); root=a.root.resolve()
    registry=json.loads((root/"governance/asset_registry.json").read_text(encoding="utf-8")); lines=["# Attributions and notices",""]
    items=[]
    for x in registry.get("assets",[]):
        if x.get("attribution_required") is True and str(x.get("attribution_text","" )).strip(): items.append((x.get("asset_name",x.get("asset_id","Asset")),x["attribution_text"]))
    for x in registry.get("dependencies",[]):
        if x.get("notice_required") is True and str(x.get("notice_file","" )).strip(): items.append((x.get("name",x.get("dependency_id","Dependency")),f"See {x['notice_file']}"))
    if not items: lines += ["No attribution-bearing production assets or dependencies are registered yet."]
    else:
        for name,notice in items: lines += [f"## {name}","",notice,""]
    (root/"governance/ATTRIBUTIONS.md").write_text("\n".join(lines).rstrip()+"\n",encoding="utf-8")
    print(f"ATTRIBUTIONS_OK entries={len(items)}")
    return 0
if __name__=="__main__": raise SystemExit(main())
