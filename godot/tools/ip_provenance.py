#!/usr/bin/env python3
"""Read-only provenance audit and fail-closed release gate."""
from __future__ import annotations
import argparse, json, subprocess
from pathlib import Path

CATEGORIES={"SELF_GENERATED","PROJECT_GENERATED","OWNER_CREATED","OWNER_SUPPLIED","OWNER_EXPLICITLY_APPROVED","FAB_VERIFIED","SUNO_COMMERCIAL_VERIFIED","APPROVED_OPEN_SOURCE","APPROVED_PUBLIC_DOMAIN","APPROVED_CREATIVE_COMMONS","APPROVED_SYSTEM_OR_PLATFORM_RESOURCE","OTHER_EXPLICITLY_APPROVED_SOURCE"}
RISKS={"GREEN","YELLOW","ORANGE","RED"}
ASSET_EXT={".png",".jpg",".jpeg",".svg",".webp",".psd",".tif",".tiff",".fbx",".gltf",".glb",".blend",".obj",".mtl",".wav",".mp3",".ogg",".flac",".ttf",".otf",".woff",".woff2",".ase",".aseprite",".kra",".zip",".tar",".gz"}
DEPENDENCY_MANIFESTS={"package.json","requirements.txt","pyproject.toml","pom.xml","build.gradle","cargo.toml","go.mod","composer.json","plugin.cfg"}
IGNORE_PARTS={".git",".godot","node_modules","builds","exports",".pytest_cache","__pycache__","coverage","dist",".next"}
NON_PRODUCTION_PREFIXES={("docs","evidence")}
REQUIRED={"asset_id","asset_name","asset_type","application","source_category","source_name","creator_or_publisher","source_reference","date_introduced","license","commercial_use_status","modification_status","attribution_required","attribution_text","redistribution_restrictions","repository_exposure","verification_status","evidence_reference","notes","risk_status","owner_decision"}
PASS_DECISIONS={"ACCEPT_DOCUMENTED_RISK"}

def tracked_files(root:Path)->list[Path]:
    # A release candidate must be an exact, clean commit. Untracked research and
    # prototypes stay advisory/outside distribution until deliberately adopted.
    run=subprocess.run(["git","-c",f"safe.directory={root.as_posix()}","-C",str(root),"ls-files"],capture_output=True,text=True)
    names=run.stdout.splitlines() if run.returncode==0 else [str(p.relative_to(root)) for p in root.rglob("*") if p.is_file()]
    tracked=[]
    for name in names:
        parts=Path(name).parts
        if any(part in IGNORE_PARTS or part.startswith(".tmp") for part in parts): continue
        if any(tuple(parts[:len(prefix)])==prefix for prefix in NON_PRODUCTION_PREFIXES): continue
        tracked.append(root/name)
    return tracked

def decision_covers(registry:dict,item_id:str)->bool:
    for d in registry.get("owner_decisions",[]):
        if isinstance(d,dict) and d.get("asset_id")==item_id and d.get("decision") in PASS_DECISIONS and d.get("owner_approved") is True and str(d.get("reason","" )).strip(): return True
    return False

def classify(item:dict, dependency:bool=False)->list[dict]:
    out=[]; ident=str(item.get("asset_id") or item.get("dependency_id") or "UNKNOWN")
    missing=sorted((REQUIRED if not dependency else {"dependency_id","name","version","license","source_reference","commercial_compatibility","notice_required","notice_file","verification_status","risk_status","owner_decision"})-item.keys())
    if missing: out.append({"id":ident,"severity":"YELLOW","code":"REGISTRY_FIELDS_MISSING","reason":"missing: "+", ".join(missing),"certainty":"VERIFIED FACT"})
    risk=item.get("risk_status","YELLOW")
    if risk not in RISKS: out.append({"id":ident,"severity":"YELLOW","code":"INVALID_RISK","reason":"risk status is invalid","certainty":"VERIFIED FACT"}); risk="YELLOW"
    cat=item.get("source_category")
    if not dependency and cat not in CATEGORIES: out.append({"id":ident,"severity":"YELLOW","code":"UNKNOWN_PROVENANCE","reason":"source category is unapproved or unknown","certainty":"VERIFIED FACT"})
    if not dependency and cat=="FAB_VERIFIED" and (item.get("license") in {None,"","UNKNOWN"} or item.get("commercial_use_status")!="PERMITTED" or item.get("verification_status")!="VERIFIED"): out.append({"id":ident,"severity":"YELLOW","code":"FAB_LICENSE_REVIEW_REQUIRED","reason":"Fab listing does not have verified commercial license evidence","certainty":"VERIFIED FACT"})
    if not dependency and cat=="SUNO_COMMERCIAL_VERIFIED" and (item.get("commercial_use_status")!="PERMITTED" or item.get("verification_status")!="VERIFIED"): out.append({"id":ident,"severity":"YELLOW","code":"SUNO_LICENSE_REVIEW_REQUIRED","reason":"Suno commercial eligibility is unresolved","certainty":"VERIFIED FACT"})
    if not dependency and item.get("source_name") in {"Google Images","Reddit","Pinterest","YouTube","fan site","asset mirror","ripped resource","arbitrary internet"}: out.append({"id":ident,"severity":"RED","code":"UNAPPROVED_EXTERNAL_SOURCE","reason":"production material came from a prohibited unapproved source","certainty":"VERIFIED FACT"})
    if item.get("attribution_required") is True and not str(item.get("attribution_text","" )).strip(): out.append({"id":ident,"severity":"YELLOW","code":"ATTRIBUTION_MISSING","reason":"required attribution text is missing","certainty":"VERIFIED FACT"})
    if not dependency and item.get("repository_exposure")=="PUBLIC_RAW" and item.get("redistribution_restrictions") not in {"PERMITTED","NONE"}: out.append({"id":ident,"severity":"ORANGE","code":"PUBLIC_RAW_REDISTRIBUTION_RISK","reason":"raw asset is public without verified redistribution permission","certainty":"VERIFIED FACT"})
    if dependency:
        if item.get("license") in {None,"","UNKNOWN"}: out.append({"id":ident,"severity":"YELLOW","code":"DEPENDENCY_LICENSE_UNKNOWN","reason":"dependency license is unknown","certainty":"VERIFIED FACT"})
        if item.get("commercial_compatibility") not in {"COMPATIBLE","VERIFIED"}: out.append({"id":ident,"severity":"YELLOW" if item.get("commercial_compatibility")!="INCOMPATIBLE" else "RED","code":"DEPENDENCY_COMPATIBILITY_UNRESOLVED","reason":"commercial distribution compatibility is unresolved","certainty":"VERIFIED FACT"})
        if item.get("notice_required") is True and not str(item.get("notice_file","" )).strip(): out.append({"id":ident,"severity":"YELLOW","code":"DEPENDENCY_NOTICE_MISSING","reason":"required dependency notice is missing","certainty":"VERIFIED FACT"})
    if risk!="GREEN": out.append({"id":ident,"severity":risk,"code":"DECLARED_RISK","reason":"registry declares "+risk,"certainty":"VERIFIED FACT"})
    return out

def audit(root:Path)->dict:
    path=root/"governance/asset_registry.json"; findings=[]
    if not path.is_file():
        registry={"assets":[],"dependencies":[],"owner_decisions":[]}; findings.append({"id":"registry","severity":"YELLOW","code":"REGISTRY_MISSING","reason":"asset registry is missing","certainty":"VERIFIED FACT"})
    else:
        try: registry=json.loads(path.read_text(encoding="utf-8"))
        except Exception as e: return {"application":root.name,"root":str(root),"findings":[{"id":"registry","severity":"RED","code":"REGISTRY_INVALID","reason":str(e),"certainty":"VERIFIED FACT"}]}
    registered={str(x.get("path","" )).replace("\\","/") for x in registry.get("assets",[]) if isinstance(x,dict)}
    for item in registry.get("assets",[]):
        if isinstance(item,dict):
            for f in classify(item): f["path"]=item.get("path","UNKNOWN"); findings.append(f)
    for item in registry.get("dependencies",[]):
        if isinstance(item,dict):
            for f in classify(item,True): f["path"]=item.get("manifest_path","UNKNOWN"); findings.append(f)
    dependency_paths={str(x.get("manifest_path","" )).replace("\\","/") for x in registry.get("dependencies",[]) if isinstance(x,dict)}
    for file in tracked_files(root):
        rel=file.relative_to(root).as_posix()
        if file.suffix.lower() in ASSET_EXT and rel not in registered:
            findings.append({"id":"unregistered:"+rel,"path":rel,"severity":"YELLOW","code":"UNREGISTERED_PRODUCTION_ASSET","reason":"material asset has no registry entry; provenance and license are UNKNOWN","certainty":"VERIFIED FACT"})
        if file.name.lower() in DEPENDENCY_MANIFESTS and rel not in dependency_paths:
            findings.append({"id":"dependency-manifest:"+rel,"path":rel,"severity":"YELLOW","code":"UNREGISTERED_DEPENDENCY_MANIFEST","reason":"dependency manifest has no registry entries; license compatibility and notice obligations are UNKNOWN","certainty":"VERIFIED FACT"})
    for f in findings: f["owner_decision_recorded"]=decision_covers(registry,f["id"])
    return {"application":registry.get("application",root.name),"root":str(root),"repository_visibility":registry.get("repository_visibility","UNKNOWN"),"findings":findings}

def release_errors(report:dict)->list[str]:
    errors=[]
    for f in report["findings"]:
        if f["severity"]=="RED": errors.append(f"{f['id']}: unresolved RED {f['code']}")
        elif f["severity"] in {"YELLOW","ORANGE"} and not f.get("owner_decision_recorded"): errors.append(f"{f['id']}: {f['severity']} requires explicit owner decision")
    return sorted(set(errors))

def main()->int:
    p=argparse.ArgumentParser(); p.add_argument("mode",choices=["audit","release"]); p.add_argument("--root",type=Path,default=Path.cwd()); p.add_argument("--json-out",type=Path); a=p.parse_args()
    report=audit(a.root.resolve())
    if a.json_out: a.json_out.parent.mkdir(parents=True,exist_ok=True); a.json_out.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2))
    errors=release_errors(report) if a.mode=="release" else []
    if errors:
        for e in errors: print("IP_PROVENANCE_RELEASE_FAIL",e)
        return 1
    posture="advisory-development-validation" if a.mode=="audit" else "fail-closed-production-release"
    print(f"IP_PROVENANCE_OK mode={a.mode} posture={posture} legal_opinion=false")
    return 0
if __name__=="__main__": raise SystemExit(main())
