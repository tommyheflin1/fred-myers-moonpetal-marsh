from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parents[1]
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    if not condition:
        raise SystemExit(f"Desktop owner handoff validation failed: {message}")
    checks += 1


launcher_path = ROOT / "tools" / "launch_desktop_owner_test.ps1"
installer_path = ROOT / "tools" / "install_desktop_owner_shortcut.ps1"
handoff_path = ROOT / "docs" / "DESKTOP_OWNER_TEST.md"
legacy_path = ROOT / "docs" / "M1_OWNER_TEST.md"
icon_png_path = ROOT / "godot" / "assets" / "art" / "fred-app-icon-v1.png"
icon_ico_path = ROOT / "godot" / "assets" / "art" / "fred-app-icon-v1.ico"

for path in (launcher_path, installer_path, handoff_path, legacy_path):
    check(path.is_file(), f"missing {path.relative_to(ROOT)}")
check(icon_png_path.is_file(), "square Fred icon master is missing")
check(icon_ico_path.is_file(), "multi-size Windows Fred icon is missing")

launcher = launcher_path.read_text(encoding="utf-8")
installer = installer_path.read_text(encoding="utf-8")
handoff = handoff_path.read_text(encoding="utf-8")
legacy = legacy_path.read_text(encoding="utf-8")

check("ExpectedCommit" in launcher, "launcher must accept an exact candidate")
check("ExpectedManifestHash" in launcher, "launcher must verify the installed manifest hash")
check("Get-FileHash" in launcher and "manifest.files" in launcher, "launcher must verify pinned candidate files")
check("288d87420c5694f80c071f00aa71a0b581f9f60c" in launcher, "Core tree guard is missing")
check("Godot_v4.7.1-stable_win64.exe" in launcher, "Godot runtime pin is missing")
check("Godot_v4.7.1-stable_win64_console.exe" in launcher, "Godot version preflight is missing")
check("IsolatedReview" in launcher and "fred-desktop-owner-review-" in launcher, "isolated fictional review mode is missing")
check("app_build_1_started = $false" in launcher, "launcher must identify the pre-Build-1 boundary")
check("Fred Myers Owner Test.lnk" in installer, "canonical shortcut name is missing")
check("Fred Myers M1 Owner Test.lnk" in installer, "legacy shortcut migration is missing")
check("Move-Item -LiteralPath" in installer, "installer must rename the existing link in place")
check("$fredShortcuts.Count -ne 1" in installer, "installer must fail closed on duplicates")
check("ExpectedCommit" in installer, "installer must pin the clean candidate")
check("status --porcelain=v1" in installer, "installer must reject a dirty checkout")
check("git.Source -C $projectRoot ls-files" in installer, "installer must inventory tracked candidate files")
check("fred-app-icon-v1.ico" in installer, "installer must use the Fred-branded Windows icon")
check("$shortcut.IconLocation" in installer, "installer must set the shortcut icon explicitly")
check("three lives" in handoff.lower(), "owner life acceptance path is missing")
check("same level" in handoff.lower(), "nonfatal life recovery acceptance is missing")
check("every tenth level" in handoff.lower(), "stackable fairy acceptance is missing")
check("right to left" in handoff.lower(), "alternating route acceptance is missing")
check("app build 1" in handoff.lower(), "Build 1 boundary is missing")
check("DESKTOP_OWNER_TEST.md" in legacy, "legacy owner document must point to the canonical handoff")

png = icon_png_path.read_bytes()
check(png[:8] == b"\x89PNG\r\n\x1a\n", "Fred icon master is not a PNG")
width, height = struct.unpack(">II", png[16:24])
check(width == height and width >= 1024, "Fred icon master must be square and at least 1024 pixels")

ico = icon_ico_path.read_bytes()
reserved, icon_type, icon_count = struct.unpack("<HHH", ico[:6])
check(reserved == 0 and icon_type == 1 and icon_count == 8, "Windows icon directory header is invalid")
ico_sizes = set()
for index in range(icon_count):
    width_byte, height_byte = struct.unpack_from("BB", ico, 6 + index * 16)
    ico_sizes.add((256 if width_byte == 0 else width_byte, 256 if height_byte == 0 else height_byte))
check(
    ico_sizes == {(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (96, 96), (128, 128), (256, 256)},
    f"unexpected Windows icon sizes: {sorted(ico_sizes)}",
)
project = (ROOT / "godot" / "project.godot").read_text(encoding="utf-8")
check('config/icon="res://assets/art/fred-app-icon-v1.png"' in project, "Godot project icon is not Fred branded")

for forbidden in ("git push", "gh pr create", "Export-PfxCertificate", "signtool"):
    check(forbidden.lower() not in launcher.lower(), f"launcher contains protected action {forbidden}")

print(f"Desktop owner handoff validation passed: {checks} checks")
