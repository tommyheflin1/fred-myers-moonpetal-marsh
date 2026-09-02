#!/usr/bin/env python3
"""Prepare, sync, and verify an app-specific website privacy policy."""
from __future__ import annotations

import argparse, json, re, urllib.request
from datetime import date
from pathlib import Path

ORIGIN = "https://theflinsappvaultllc.com"

def load_game(root: Path) -> dict:
    return json.loads((root / "game/game.json").read_text(encoding="utf-8"))

def validate(game: dict, require_approved: bool = False) -> list[str]:
    errors=[]; game_id=str(game.get("game_id", "")); privacy=game.get("privacy", {})
    if privacy.get("policy_url") != f"{ORIGIN}/{game_id}/privacy": errors.append("policy URL must use the app-specific website route")
    if not re.fullmatch(r"[a-z0-9.-]{8,128}", str(privacy.get("policy_version", ""))): errors.append("policy version is invalid")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(privacy.get("effective_date", ""))): errors.append("effective date must be YYYY-MM-DD")
    if privacy.get("review_status") not in {"draft", "approved"}: errors.append("privacy review status must be draft or approved")
    if require_approved and privacy.get("review_status") != "approved": errors.append("owner-approved privacy inventory is required before Apple preflight")
    capabilities=game.get("capabilities", {})
    for field in ("game_center", "golden_eggs"):
        if bool(privacy.get(field)) != bool(capabilities.get(field)): errors.append(f"privacy {field} differs from enabled capability")
    for field in ("local_data", "excluded_data"):
        values=privacy.get(field)
        if not isinstance(values, list) or not values or any(not isinstance(v,str) or not v.strip() for v in values): errors.append(f"privacy {field} inventory is invalid")
    return errors

def registry_entry(game: dict) -> dict:
    p=game["privacy"]
    return {"id":game["game_id"],"name":game["display_name"],"effectiveDate":date.fromisoformat(p["effective_date"]).strftime("%B %-d, %Y") if __import__('os').name != 'nt' else date.fromisoformat(p["effective_date"]).strftime("%B %d, %Y").replace(" 0"," "),"policyVersion":p["policy_version"],"localData":p["local_data"],"gameCenter":p["game_center"],"goldenEggs":p["golden_eggs"],"paidDownload":p["paid_download"],"excludedData":p["excluded_data"]}

def sync_website(game: dict, website: Path) -> None:
    path=website/"app/appPrivacyPolicies.json"; data=json.loads(path.read_text(encoding="utf-8")); data[game["game_id"]]=registry_entry(game); path.write_text(json.dumps(dict(sorted(data.items())),indent=2)+"\n",encoding="utf-8")

def verify_live(game: dict) -> None:
    privacy=game["privacy"]; request=urllib.request.Request(privacy["policy_url"],headers={"User-Agent":"FlinsPrivacyGate/1.0"})
    with urllib.request.urlopen(request,timeout=30) as response: body=response.read(262144).decode("utf-8",errors="replace")
    if response.status != 200 or f'data-policy-id="{game["game_id"]}"' not in body or f'data-policy-version="{privacy["policy_version"]}"' not in body: raise RuntimeError("live app privacy policy identity/version mismatch")

def main()->int:
    p=argparse.ArgumentParser(); p.add_argument("mode",choices=["prepare","sync","verify"]); p.add_argument("--root",type=Path,default=Path.cwd()); p.add_argument("--website-root",type=Path); a=p.parse_args(); root=a.root.resolve(); game=load_game(root)
    errors=validate(game,require_approved=a.mode in {"sync","verify"})
    if errors:
        for error in errors: print("PRIVACY_POLICY_FAIL",error)
        return 1
    if a.mode=="prepare":
        out=root/"builds/privacy"/f'{game["game_id"]}.json'; out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(registry_entry(game),indent=2)+"\n",encoding="utf-8"); print(f"PRIVACY_POLICY_PREPARED {out}")
    elif a.mode=="sync":
        if not a.website_root: print("PRIVACY_POLICY_FAIL --website-root required"); return 1
        sync_website(game,a.website_root.resolve()); print("PRIVACY_POLICY_SYNCED deployment=not-performed")
    else:
        try: verify_live(game)
        except Exception as exc: print(f"PRIVACY_POLICY_FAIL {exc}"); return 1
        print("PRIVACY_POLICY_LIVE_OK app_specific=true version_exact=true")
    return 0
if __name__=="__main__": raise SystemExit(main())
