from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "validate_physical_android_device.ps1"
TEST = ROOT / "tools" / "tests" / "test_physical_android_preflight.ps1"
REPORT = ROOT / "docs" / "M2_PHYSICAL_ANDROID_OWNER_HANDOFF.md"

REQUIRED_SCRIPT_TOKENS = (
    '"DEVICE_NOT_CONNECTED"',
    '"UNVERIFIED"',
    '"MULTIPLE_DEVICES_AMBIGUOUS"',
    '"EXPLICIT_SERIAL_NOT_FOUND"',
    '"APK_HASH_MISMATCH"',
    '"APK_PACKAGE_MISMATCH"',
    '"DEVICE_API_UNSUPPORTED"',
    '"DEVICE_ABI_UNSUPPORTED"',
    "-AcknowledgeOwnerDevice",
    "-AcknowledgeSaveRisk",
    '"logcat", "--pid"',
    'install", "--no-streaming"',
)
FORBIDDEN_MUTATION_TOKENS = (
    '"uninstall"',
    '"clear"',
    '"root"',
    '"reboot"',
    '"remount"',
    '"disable-verity"',
    'install", "-d"',
)


def main() -> None:
    missing = [path.relative_to(ROOT).as_posix() for path in (SCRIPT, TEST, REPORT) if not path.is_file()]
    if missing:
        raise SystemExit("Missing physical Android handoff artifacts: " + ", ".join(missing))

    script = SCRIPT.read_text(encoding="utf-8")
    missing_tokens = [token for token in REQUIRED_SCRIPT_TOKENS if token not in script]
    if missing_tokens:
        raise SystemExit("Missing physical-device safety contract: " + ", ".join(missing_tokens))
    forbidden = [token for token in FORBIDDEN_MUTATION_TOKENS if token.lower() in script.lower()]
    if forbidden:
        raise SystemExit("Forbidden Android device mutation token: " + ", ".join(forbidden))
    if script.count("$ExpectedApkSha256") < 2:
        raise SystemExit("APK hash guard is not enforced")
    if "if ($TestMode -and $Mode -ne \"Preflight\")" not in script:
        raise SystemExit("Test fixtures are not restricted to read-only preflight")

    print(
        "Physical Android handoff validation passed: hash/package guard, "
        "explicit serial selection, acknowledgement gates, app-scoped diagnostics, "
        "and no uninstall/clear-data/root/downgrade path"
    )


if __name__ == "__main__":
    main()
