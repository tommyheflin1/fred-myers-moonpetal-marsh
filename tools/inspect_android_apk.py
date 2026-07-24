from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import zipfile


REQUIRED_NATIVE_FILES = {
    "lib/arm64-v8a/libgodot_android.so",
    "lib/x86_64/libgodot_android.so",
}
FORBIDDEN_PREFIXES = (
    "assets/tests/",
    "assets/tools/",
    "assets/docs/evidence/",
    ".git/",
    "assets/.git/",
)
FORBIDDEN_SUFFIXES = (".jks", ".keystore", ".pem", ".p12", ".env")
TEXT_SUFFIXES = (
    ".cfg",
    ".json",
    ".md",
    ".remap",
    ".txt",
    ".xml",
)
SENSITIVE_PATTERNS = (
    re.compile(rb"C:\\Users\\", re.I),
    re.compile(rb"/Users/[^/]+/", re.I),
    re.compile(rb"sk-[A-Za-z0-9_-]{16,}"),
    re.compile(rb"(?:token|password|secret)\s*[:=]\s*[\"'][^\"']{8,}", re.I),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    args = parser.parse_args()
    apk = args.apk.resolve()
    if not apk.is_file():
        raise SystemExit(f"APK does not exist: {apk}")

    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        name_set = set(names)
        missing_native = sorted(REQUIRED_NATIVE_FILES - name_set)
        if missing_native:
            raise SystemExit("Missing Android architectures: " + ", ".join(missing_native))

        forbidden_names = sorted(
            name
            for name in names
            if name.startswith(FORBIDDEN_PREFIXES)
            or name.lower().endswith(FORBIDDEN_SUFFIXES)
        )
        if forbidden_names:
            raise SystemExit("Forbidden APK content: " + ", ".join(forbidden_names[:20]))

        sensitive_hits: list[str] = []
        scanned_entries = 0
        for info in archive.infolist():
            if info.file_size > 5 * 1024 * 1024:
                continue
            if not info.filename.lower().endswith(TEXT_SUFFIXES):
                continue
            scanned_entries += 1
            payload = archive.read(info)
            if any(pattern.search(payload) for pattern in SENSITIVE_PATTERNS):
                sensitive_hits.append(info.filename)
        if sensitive_hits:
            raise SystemExit(
                "Sensitive data or private path in APK: " + ", ".join(sensitive_hits)
            )

        compressed_bytes = sum(info.compress_size for info in archive.infolist())
        uncompressed_bytes = sum(info.file_size for info in archive.infolist())

    print(
        "APK content validation passed: "
        f"entries={len(names)}, scanned_text_entries={scanned_entries}, "
        f"compressed_payload_bytes={compressed_bytes}, "
        f"uncompressed_payload_bytes={uncompressed_bytes}, "
        "arm64+x86_64, no tests/tools/evidence/source-control/secret/private-path content"
    )
    print(f"APK sha256={sha256(apk)} size_bytes={apk.stat().st_size}")


if __name__ == "__main__":
    main()
