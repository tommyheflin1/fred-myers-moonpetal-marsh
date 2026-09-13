"""Create owner-authorized, dimension-only Apple badge copies; preserve originals."""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    originals = json.loads((ROOT / "docs/artwork-drafts/ACHIEVEMENT_ORIGINALS.json").read_text())
    catalog = json.loads((ROOT / "docs/BUILD_11_APPLE_ACHIEVEMENT_RECORDS.json").read_text())
    names = {record["id"]: record["name"] for record in catalog["records"]}
    output = ROOT / "godot/assets/store/game-center"
    output.mkdir(parents=True, exist_ok=True)
    entries = []
    sheet = Image.new("RGB", (1100, 1220), "#07232d")
    draw = ImageDraw.Draw(sheet)
    for index, entry in enumerate(originals["entries"]):
        source = ROOT / entry["original_path"]
        before = source.read_bytes()
        assert hashlib.sha256(before).hexdigest() == entry["sha256"], source
        with Image.open(io.BytesIO(before)) as image:
            assert image.size == (1254, 1254) and image.mode == "RGB", source
            resized = image.resize((1024, 1024), Image.Resampling.LANCZOS)
        buffer = io.BytesIO()
        resized.save(buffer, format="PNG", optimize=True)
        data = buffer.getvalue()
        destination = output / f"campaign-{entry['level']:03d}-v1.png"
        if destination.exists():
            assert destination.read_bytes() == data, f"Refusing overwrite: {destination}"
        else:
            destination.write_bytes(data)
        with Image.open(destination) as check:
            check.load()
            assert check.size == (1024, 1024) and check.mode == "RGB"
        assert source.read_bytes() == before, "Original changed"
        entries.append({"id": entry["achievement_id"], "name": names[entry["achievement_id"]],
                        "level": entry["level"], "source": entry["original_path"],
                        "source_sha256": entry["sha256"],
                        "image": destination.relative_to(ROOT / "godot").as_posix(),
                        "image_sha256": hashlib.sha256(data).hexdigest(),
                        "dimensions": [1024, 1024], "mode": "RGB", "bytes": len(data)})
        x, y = (index % 5) * 220 + 10, (index // 5) * 244 + 6
        sheet.paste(resized.resize((200, 200), Image.Resampling.LANCZOS), (x, y))
        draw.text((x, y + 204), f"{entry['level']:03d}  {names[entry['achievement_id']]}", fill="white")
    assert len(entries) == 25 and len({e["image_sha256"] for e in entries}) == 25
    sheet.save(ROOT / "docs/artwork-drafts/achievement-size-review.png")
    print(json.dumps({"schema": "fred-achievement-apple-artwork-v1",
                      "operation": "Pillow LANCZOS1254to1024; no crop, retouch, regeneration or alpha",
                      "originals_preserved": True, "entries": entries}, indent=2))


if __name__ == "__main__":
    main()
