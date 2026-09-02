#!/usr/bin/env python3
"""Authenticate and verify an exact build through the App Store Connect API."""
from __future__ import annotations

import argparse, base64, json, os, plistlib, subprocess, time, urllib.parse, urllib.request
from pathlib import Path


def b64(value: bytes) -> str: return base64.urlsafe_b64encode(value).decode().rstrip("=")

def read_length(data: bytes, index: int) -> tuple[int, int]:
    first=data[index]; index+=1
    if first < 0x80: return first,index
    count=first & 0x7f
    if count == 0 or count > 4: raise SystemExit("APPLE_AUTH_FAIL unsupported ECDSA length")
    return int.from_bytes(data[index:index+count],"big"), index+count

def der_to_raw(signature: bytes) -> bytes:
    if not signature or signature[0] != 0x30: raise SystemExit("APPLE_AUTH_FAIL invalid ECDSA sequence")
    sequence_length,index=read_length(signature,1)
    if index+sequence_length != len(signature): raise SystemExit("APPLE_AUTH_FAIL invalid ECDSA sequence length")
    values=[]
    for _ in range(2):
        if signature[index] != 0x02: raise SystemExit("APPLE_AUTH_FAIL invalid ECDSA integer")
        length,index=read_length(signature,index+1); value=int.from_bytes(signature[index:index+length],"big"); index+=length
        values.append(value.to_bytes(32,"big"))
    if index != len(signature): raise SystemExit("APPLE_AUTH_FAIL ECDSA trailing data")
    return b"".join(values)

def token(config: dict) -> str:
    now = int(time.time())
    header = b64(json.dumps({"alg":"ES256","kid":config["api_key_id"],"typ":"JWT"}, separators=(",",":"), sort_keys=True).encode())
    claims = b64(json.dumps({"iss":config["api_issuer_id"],"iat":now,"exp":now+900,"aud":"appstoreconnect-v1"}, separators=(",",":"), sort_keys=True).encode())
    unsigned = f"{header}.{claims}"
    key = Path(os.path.expanduser(config["api_key_path"])).resolve()
    if not key.is_file() or key.stat().st_size < 100: raise SystemExit("APPLE_AUTH_FAIL private key missing outside repository")
    signature = subprocess.run(["openssl","dgst","-sha256","-sign",str(key)], input=unsigned.encode(), capture_output=True, check=True).stdout
    return f"{unsigned}.{b64(der_to_raw(signature))}"

def request(config: dict, endpoint: str, query: dict | None=None) -> dict:
    url="https://api.appstoreconnect.apple.com"+endpoint
    if query: url += "?"+urllib.parse.urlencode(query)
    req=urllib.request.Request(url, headers={"Authorization":"Bearer "+token(config),"Accept":"application/json"})
    with urllib.request.urlopen(req, timeout=30) as response: return json.loads(response.read())

def classify_build(payload: dict, game: dict) -> tuple[dict, int]:
    versions={x["id"]:x.get("attributes",{}).get("version") for x in payload.get("included",[]) if x.get("type")=="preReleaseVersions"}
    for item in payload.get("data",[]):
        relation=item.get("relationships",{}).get("preReleaseVersion",{}).get("data") or {}
        attrs=item.get("attributes",{})
        if versions.get(relation.get("id")) != game["marketing_version"] or attrs.get("version") != str(game["build_number"]):
            continue
        state=attrs.get("processingState")
        ready=state == "VALID" and attrs.get("expired") is False
        failed=state in {"FAILED", "INVALID"} or attrs.get("expired") is True
        status="APPLE_PROCESSED" if ready else "APPLE_PROCESSING_FAILED" if failed else "APPLE_PROCESSING_PENDING"
        return {"status":status,"apple_build_id":item.get("id"),"version":game["marketing_version"],"build":str(game["build_number"]),"processing_state":state,"processing_verified":ready,"release_authorized":False}, 0 if ready else 2 if failed else 3
    return {"status":"APPLE_NOT_RECEIVED","release_authorized":False}, 3


def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("--root",type=Path,default=Path.cwd()); parser.add_argument("--authenticate-only",action="store_true")
    args=parser.parse_args(); root=args.root.resolve()
    config=json.loads((root/"tools/ios_release_config.json").read_text(encoding="utf-8")); game=json.loads((root/"game/game.json").read_text(encoding="utf-8"))
    app=request(config, f"/v1/apps/{config['app_store_app_id']}")
    attrs=app.get("data",{}).get("attributes",{})
    if attrs.get("bundleId") != game["bundle_id"]: raise SystemExit("APPLE_AUTH_FAIL App Store app identity mismatch")
    if args.authenticate_only:
        print("APPLE_AUTH_PASS app_identity=exact private_key_contents_logged=false")
        return 0
    payload=request(config,"/v1/builds",{"filter[app]":config["app_store_app_id"],"filter[version]":str(game["build_number"]),"include":"preReleaseVersion","limit":"10","sort":"-uploadedDate"})
    result, code=classify_build(payload, game)
    print(json.dumps(result,indent=2,sort_keys=True))
    return code

if __name__ == "__main__": raise SystemExit(main())
