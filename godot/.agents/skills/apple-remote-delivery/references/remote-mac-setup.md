# Remote Mac Setup

This is the one-time setup for a dedicated remote Mac. The owner performs Apple sign-in, two-factor authentication, license acceptance, and any paid account action. Never place those credentials in chat, shell history, shared storage, or the repository.

## 1. Prepare the Mac and remote session

1. Use a supported macOS account with administrator access and at least 25 GiB free.
2. Enable only the owner's approved remote-desktop service. Keep FileVault, Gatekeeper, firewall, screen lock, and two-factor authentication enabled.
3. Keep long builds alive from Terminal with `caffeinate -dimsu -- <command>`. Scripts in this skill already use `caffeinate` for archive and upload.
4. Store source under a versioned working directory, not Desktop or Downloads. Store logs under the build's `builds/ios/apple-delivery` lane.

## 2. Install and initialize Xcode

1. Install the current approved Xcode from the Mac App Store. For this harness the minimum is Xcode 26 with iOS 26 SDK.
2. Launch Xcode once. Accept the license and allow required components to finish.
3. In **Xcode > Settings > Platforms**, install the iOS platform if it is absent.
4. In **Xcode > Settings > Accounts**, add the owner's Apple developer account, complete 2FA, select the correct team, and refresh profiles.
5. Verify in Terminal:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
xcodebuild -checkFirstLaunchStatus
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
```

If the iOS platform is still absent, use Xcode Settings first. `xcodebuild -downloadPlatform iOS` is an acceptable documented fallback.

## 3. Install Godot and export templates

1. Download the official Godot 4.7.1 macOS editor and place `Godot.app` in `/Applications`.
2. Open Godot once. Use **Editor > Manage Export Templates** to install the matching 4.7.1 stable templates.
3. Verify:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --version
test -d "$HOME/Library/Application Support/Godot/export_templates/4.7.1.stable"
```

Do not mix a newer editor with 4.7.1 templates for a release candidate.

## 4. Install the plugin build prerequisite

Game Center builds require SCons. Prefer the existing Python 3 installation. After the owner authorizes the install:

```bash
python3 --version
python3 -m pip install --user --upgrade scons
python3 -m site --user-base
scons --version
```

If `scons` is not on `PATH`, add the user-base `bin` directory to the shell profile and reopen Terminal. Do not introduce Homebrew solely for this step when Python 3 already works.

## 5. Transfer the exact source candidate

1. On the source computer run `tools/prepare_source_handoff.py` for the exact clean commit.
2. Transfer only the source bundle and its manifest through the owner's approved channel.
3. On the Mac compare `shasum -a 256 <bundle>` with the manifest before extracting.
4. Clone or extract into a new directory, check out the exact commit, and confirm `git status --porcelain` is empty.
5. Never transfer API keys, certificates, profiles, passwords, or 2FA codes with the source bundle.

## 6. Prove readiness

Run:

```bash
bash .agents/skills/apple-remote-delivery/scripts/apple_remote_doctor.sh "$PWD"
```

Continue only after `APPLE_REMOTE_DOCTOR_PASS`. A passing doctor proves local prerequisites and a signing identity; it does not authorize signing, upload, TestFlight distribution, review submission, or release.
