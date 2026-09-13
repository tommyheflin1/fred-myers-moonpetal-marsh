"""Use an explicit app-owned App Store profile in the existing Apple release lane."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import plistlib
import re
import subprocess


def settings(config: dict, game: dict, team: str) -> tuple[str, str]:
    if not re.fullmatch(r"[A-Z0-9]{10}", team) or team != config.get("team_id"):
        raise ValueError("signing team differs from reviewed release configuration")
    if config.get("bundle_id") != game.get("bundle_id"):
        raise ValueError("signing bundle differs from game identity")
    style = config.get("signing_style", "automatic")
    uuid = config.get("app_store_profile_uuid", "")
    name = config.get("app_store_profile_name", "")
    if style not in {"automatic", "manual"}:
        raise ValueError("unsupported signing style")
    if uuid and not re.fullmatch(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", str(uuid)):
        raise ValueError("invalid App Store profile UUID")
    if name and (not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 ._-]{0,127}", name)):
        raise ValueError("invalid exact App Store profile name")
    if style == "manual" and bool(uuid) == bool(name):
        raise ValueError("manual signing requires exactly one explicit App Store profile UUID or name")
    if style == "automatic" and (uuid or name):
        raise ValueError("manual profile cannot be mixed with automatic signing")
    upload_method(config)
    return style, uuid or name


def upload_method(config: dict) -> str:
    method = config.get("upload_method", "xcode")
    if method not in {"xcode", "altool"}:
        raise ValueError("unsupported existing upload method")
    if method == "altool" and config.get("signing_style") != "manual":
        raise ValueError("established altool lane requires explicit manual signing")
    return method


def validate_profile(profile: dict, config: dict, game: dict, identities: str, now: datetime) -> str:
    team = config["team_id"]
    style, uuid = settings(config, game, team)
    matches = (profile.get("UUID", "").lower() == uuid.lower() if config.get("app_store_profile_uuid")
               else profile.get("Name") == uuid)
    if style != "manual" or not matches:
        raise ValueError("installed profile UUID mismatch")
    if not re.fullmatch(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", str(profile.get("UUID", ""))):
        raise ValueError("installed profile has no valid UUID")
    ent = profile.get("Entitlements", {})
    if profile.get("TeamIdentifier") != [team] or ent.get("application-identifier") != f"{team}.{game['bundle_id']}":
        raise ValueError("installed profile does not belong to this exact app/team")
    if ent.get("get-task-allow") is not False or "ProvisionedDevices" in profile or profile.get("ProvisionsAllDevices"):
        raise ValueError("profile is not an App Store distribution profile")
    expiry = profile.get("ExpirationDate")
    if not isinstance(expiry, datetime) or expiry.replace(tzinfo=timezone.utc) <= now.astimezone(timezone.utc):
        raise ValueError("App Store profile is expired or has no valid expiration")
    if game.get("capabilities", {}).get("game_center") and ent.get("com.apple.developer.game-center") is not True:
        raise ValueError("App Store profile lacks required Game Center entitlement")
    fingerprints = {hashlib.sha1(cert).hexdigest().upper() for cert in profile.get("DeveloperCertificates", []) if isinstance(cert, bytes)}
    matches = re.findall(r'([A-F0-9]{40})\s+"Apple Distribution:[^"\n]*\(' + re.escape(team) + r'\)"', identities)
    if not fingerprints.intersection(matches):
        raise ValueError("profile has no matching installed Apple Distribution private-key identity")
    return profile["UUID"]


def installed_profile(config: dict, game: dict) -> str:
    paths = []
    for relative in ("Library/Developer/Xcode/UserData/Provisioning Profiles", "Library/MobileDevice/Provisioning Profiles"):
        paths.extend((Path.home() / relative).glob("*.mobileprovision"))
    matches = {}
    for path in paths:
        # Never print or persist the provisioning envelope, certificates, or keys.
        result = subprocess.run(["security", "cms", "-D", "-i", str(path)], capture_output=True)
        if result.returncode:
            continue
        try:
            profile = plistlib.loads(result.stdout)
        except (ValueError, plistlib.InvalidFileException):
            continue
        match = (str(profile.get("UUID", "")).lower() == str(config["app_store_profile_uuid"]).lower()
                 if config.get("app_store_profile_uuid") else profile.get("Name") == config.get("app_store_profile_name"))
        if match:
            matches[hashlib.sha256(result.stdout).hexdigest()] = profile
    if len(matches) != 1:
        raise ValueError("exact App Store profile missing or ambiguous; preserve existing signing setup")
    result = subprocess.run(["security", "find-identity", "-v", "-p", "codesigning"], capture_output=True, text=True, check=True)
    return validate_profile(next(iter(matches.values())), config, game, result.stdout, datetime.now(timezone.utc))


def archive_arguments(style: str, team: str, uuid: str) -> list[str]:
    if style == "manual":
        return [f"DEVELOPMENT_TEAM={team}", "CODE_SIGN_STYLE=Manual", "CODE_SIGN_IDENTITY=Apple Distribution", f"PROVISIONING_PROFILE_SPECIFIER={uuid}"]
    return [f"DEVELOPMENT_TEAM={team}", "CODE_SIGN_STYLE=Automatic", "-allowProvisioningUpdates"]


def export_options(style: str, team: str, bundle: str, uuid: str, method: str = "xcode") -> dict:
    if method not in {"xcode", "altool"}:
        raise ValueError("unsupported existing upload method")
    result = {"method": "app-store-connect", "destination": "export" if method == "altool" else "upload", "signingStyle": style,
              "teamID": team, "manageAppVersionAndBuildNumber": False}
    if style == "manual":
        result.update(signingCertificate="Apple Distribution", provisioningProfiles={bundle: uuid})
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["archive-arguments", "export-options", "upload-method", "upload-credentials"])
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--team", required=True)
    args = parser.parse_args()
    try:
        root = args.root.resolve()
        config = json.loads((root / "tools/ios_release_config.json").read_text(encoding="utf-8"))
        game = json.loads((root / "game/game.json").read_text(encoding="utf-8"))
        style, uuid = settings(config, game, args.team)
        if args.mode == "upload-method":
            print(upload_method(config))
            return 0
        if args.mode == "upload-credentials":
            if upload_method(config) != "altool":
                raise ValueError("API upload credentials requested outside the configured lane")
            key_id, issuer = str(config.get("api_key_id", "")), str(config.get("api_issuer_id", ""))
            if not re.fullmatch(r"[A-Z0-9]{10}", key_id) or not re.fullmatch(r"[0-9a-fA-F-]{36}", issuer):
                raise ValueError("invalid configured App Store API identity")
            expected = f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8"
            if config.get("api_key_path") != expected or not Path(expected).expanduser().is_file():
                raise ValueError("existing App Store API key missing from its established external location")
            print(key_id)
            print(issuer)
            return 0
        if style == "manual":
            uuid = installed_profile(config, game)
        if args.mode == "archive-arguments":
            print("\n".join(archive_arguments(style, args.team, uuid)))
        else:
            version, build = str(game["marketing_version"]), game["build_number"]
            if not re.fullmatch(r"[0-9]+\.[0-9]+(?:\.[0-9]+)?", version) or type(build) is not int or build < 1:
                raise ValueError("invalid release lane identity")
            path = root / "builds/ios/apple-delivery" / f"{version}-{build}" / "ExportOptions.plist"
            path.write_bytes(plistlib.dumps(export_options(style, args.team, game["bundle_id"], uuid, upload_method(config))))
            print(f"APPLE_EXPORT_OPTIONS_PASS signing={style} automatic_build_increment=false")
        return 0
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as exc:
        # No subprocess stdout, profile content or signing material is logged.
        print(f"APPLE_SIGNING_STOP {exc}", file=__import__("sys").stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
