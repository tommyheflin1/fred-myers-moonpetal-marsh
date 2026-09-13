#!/usr/bin/env python3
"""Verify exported Xcode AppIcon sources and compiled Assets.car renditions."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import subprocess
from pathlib import Path


def _png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) != 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not a PNG: {path}")
    return struct.unpack(">II", data[16:24])


def inspect_catalog(project_root: Path, export_root: Path) -> dict[str, object]:
    source = project_root / "assets/store/app-icon-1024.png"
    expected_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    catalogs = sorted(export_root.rglob("AppIcon.appiconset/Contents.json"))
    errors: list[str] = []
    if len(catalogs) != 1:
        errors.append(f"expected one AppIcon.appiconset; found {len(catalogs)}")
        return {"status": "FAIL", "errors": errors, "catalog_count": len(catalogs)}
    catalog = catalogs[0]
    payload = json.loads(catalog.read_text(encoding="utf-8"))
    filenames = sorted({item.get("filename") for item in payload.get("images", []) if item.get("filename")})
    missing = [name for name in filenames if not (catalog.parent / name).is_file()]
    matching: list[str] = []
    for name in filenames:
        path = catalog.parent / name
        if path.is_file() and _png_size(path) == (1024, 1024) and hashlib.sha256(path.read_bytes()).hexdigest() == expected_hash:
            matching.append(name)
    if missing:
        errors.append("catalog references missing icon files")
    if not matching:
        errors.append("catalog does not contain the approved exact 1024 icon")
    return {
        "status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "catalog_count": 1,
        "catalog": catalog.relative_to(export_root).as_posix(),
        "declared_file_count": len(filenames),
        "approved_1024_files": matching,
        "approved_source_sha256": expected_hash,
    }


def inspect_compiled(app: Path, command: list[str] | None = None) -> dict[str, object]:
    cars = sorted(app.rglob("Assets.car"))
    errors: list[str] = []
    if len(cars) != 1:
        errors.append(f"expected one Assets.car; found {len(cars)}")
        return {"status": "FAIL", "errors": errors, "assets_car_count": len(cars)}
    cmd = command or ["xcrun", "assetutil", "--info", str(cars[0])]
    completed = subprocess.run(cmd, check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        errors.append("assetutil inspection failed")
        entries: list[object] = []
    else:
        try:
            parsed = json.loads(completed.stdout)
            entries = parsed if isinstance(parsed, list) else [parsed]
        except json.JSONDecodeError:
            entries = []
            errors.append("assetutil returned invalid JSON")
    icon_entries = [entry for entry in entries if isinstance(entry, dict) and "appicon" in json.dumps(entry).lower()]
    if not icon_entries:
        errors.append("Assets.car contains no AppIcon renditions")
    return {
        "status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "assets_car_count": 1,
        "assets_car_sha256": hashlib.sha256(cars[0].read_bytes()).hexdigest(),
        "app_icon_rendition_count": len(icon_entries),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True, type=Path)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--xcode-export", type=Path)
    group.add_argument("--app", type=Path)
    args = parser.parse_args()
    try:
        report = inspect_catalog(args.project_root.resolve(), args.xcode_export.resolve()) if args.xcode_export else inspect_compiled(args.app.resolve())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print("IOS_ICON_ARTIFACT_FAIL", exc)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
