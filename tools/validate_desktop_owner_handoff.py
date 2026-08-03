from pathlib import Path


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

for path in (launcher_path, installer_path, handoff_path, legacy_path):
    check(path.is_file(), f"missing {path.relative_to(ROOT)}")

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
check("three lives" in handoff.lower(), "owner life acceptance path is missing")
check("same level" in handoff.lower(), "nonfatal life recovery acceptance is missing")
check("every tenth level" in handoff.lower(), "stackable fairy acceptance is missing")
check("right to left" in handoff.lower(), "alternating route acceptance is missing")
check("app build 1" in handoff.lower(), "Build 1 boundary is missing")
check("DESKTOP_OWNER_TEST.md" in legacy, "legacy owner document must point to the canonical handoff")

for forbidden in ("git push", "gh pr create", "Export-PfxCertificate", "signtool"):
    check(forbidden.lower() not in launcher.lower(), f"launcher contains protected action {forbidden}")

print(f"Desktop owner handoff validation passed: {checks} checks")
