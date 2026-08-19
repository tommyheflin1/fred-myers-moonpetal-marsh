#!/usr/bin/env python3
"""Validate exact Fred App Build 1 iPhone/iPad screenshot sets."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


EXPECTED = {
    "iphone-6.9": ((2868, 1320), "iphone69"),
    "ipad-13": ((2752, 2064), "ipad13"),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def validate(root: Path) -> dict[str, object]:
    root = root.resolve()
    errors: list[str] = []
    files: list[dict[str, object]] = []
    for folder, (expected_size, prefix) in EXPECTED.items():
        paths = sorted((root / folder).glob("*.png"))
        if len(paths) != 8:
            errors.append(f"{folder} must contain exactly eight PNG screenshots; found {len(paths)}")
        for path in paths:
            with Image.open(path) as image:
                actual_size = image.size
                if image.size != expected_size:
                    errors.append(f"wrong dimensions for {path.name}: {image.size}")
                if image.mode != "RGB":
                    errors.append(f"alpha or indexed color is not allowed: {path.name} mode={image.mode}")
                metadata = {str(key): str(value) for key, value in image.info.items()}
                metadata_text = json.dumps(metadata, sort_keys=True).lower()
                for prohibited in ("users\\", "users/", "tommy", "appdata", "onedrive"):
                    if prohibited in metadata_text:
                        errors.append(f"private path metadata found in {path.name}")
            if not path.name.startswith(prefix + "-"):
                errors.append(f"unexpected screenshot prefix: {path.name}")
            files.append({
                "device_set": folder,
                "file": path.name,
                "bytes": path.stat().st_size,
                "sha256": sha256(path),
                "width": actual_size[0],
                "height": actual_size[1],
                "mode": "RGB",
            })
    normalized = {"files": files, "screenshot_count": len(files)}
    return {
        "schema": "fred-app-store-screenshots-v1",
        "status": "PASS" if not errors else "FAIL",
        **normalized,
        "manifest_sha256": hashlib.sha256(json.dumps(normalized, separators=(",", ":"), sort_keys=True).encode()).hexdigest().upper(),
        "errors": sorted(set(errors)),
        "visual_inspection_required": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()
    try:
        report = validate(args.root)
    except (OSError, ValueError) as exc:
        print(f"APP_STORE_SCREENSHOTS_FAIL {exc}", file=sys.stderr)
        return 2
    rendered = json.dumps(report, indent=2, sort_keys=True)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
