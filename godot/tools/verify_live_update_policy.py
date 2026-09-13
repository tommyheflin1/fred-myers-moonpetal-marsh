#!/usr/bin/env python3
"""Verify that a fail-closed app can obtain a usable live signed policy."""
from __future__ import annotations
import argparse, json, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

def validate(root: Path, opener=urllib.request.urlopen, now: int|None=None) -> list[str]:
    game=json.loads((root/"game/game.json").read_text(encoding="utf-8")); updates=game.get("updates",{}); errors=[]
    if updates.get("enabled") is not True: return []
    if updates.get("mode") != "mandatory_minimum_build" or updates.get("fail_closed") is not True: return ["enabled mandatory-update policy contract is invalid"]
    endpoint=updates.get("policy_origin","").rstrip("/")+updates.get("policy_path","")
    query=urllib.parse.urlencode({"bundle_id":game.get("bundle_id",""),"platform":"ios"})
    request=urllib.request.Request(f"{endpoint}?{query}",headers={"User-Agent":"FlinsUpdatePolicyGate/1.0"})
    try:
        with opener(request,timeout=30) as response: status=int(response.status); body=response.read(262144)
    except urllib.error.HTTPError as error: status=int(error.code); body=error.read(262144)
    except Exception as error: return [f"live mandatory-update policy request failed: {error}"]
    if status != 200: return [f"live mandatory-update policy returned HTTP {status}"]
    try: outer=json.loads(body); payload=json.loads(outer["policy_payload"])
    except (KeyError,TypeError,ValueError,json.JSONDecodeError): return ["live mandatory-update policy response is malformed"]
    for field in ("signature","key_id"):
        if not isinstance(outer.get(field),str) or not outer[field]: errors.append(f"live mandatory-update policy omits {field}")
    if payload.get("schema_version") != 1: errors.append("live mandatory-update policy schema mismatch")
    if payload.get("bundle_id") != game.get("bundle_id") or payload.get("platform") != "ios": errors.append("live mandatory-update policy app binding mismatch")
    minimum=payload.get("minimum_supported_build"); issued=payload.get("issued_at"); expires=payload.get("expires_at"); current=int(time.time()) if now is None else now
    if not isinstance(minimum,int) or minimum < 1: errors.append("live mandatory-update policy minimum build is invalid")
    if not isinstance(issued,int) or not isinstance(expires,int) or issued > current+300 or expires <= current or expires-issued > 1800: errors.append("live mandatory-update policy validity window is invalid")
    return errors

def main()->int:
    parser=argparse.ArgumentParser();parser.add_argument("--root",type=Path,default=Path.cwd());args=parser.parse_args();errors=validate(args.root.resolve())
    for error in errors: print("LIVE_UPDATE_POLICY_FAIL",error)
    if errors:return 1
    print("LIVE_UPDATE_POLICY_OK status=200 app_bound=true current=true signature_present=true");return 0
if __name__=="__main__":raise SystemExit(main())
