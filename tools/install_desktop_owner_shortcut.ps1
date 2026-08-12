[CmdletBinding()]
param(
    [ValidatePattern("^[0-9a-fA-F]{40}$")]
    [string]$ExpectedCommit = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $PSScriptRoot "launch_desktop_owner_test.ps1"
$icon = Join-Path $projectRoot "godot\assets\art\fred-app-icon-v3.ico"
$git = Get-Command "git.exe" -ErrorAction Stop
$gitRepoArgs = @("-c", "safe.directory=$projectRoot", "-C", $projectRoot)

if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "Fred owner launcher is missing: $launcher"
}
if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) {
    throw "Fred owner icon is missing: $icon"
}

$head = (& $git.Source @gitRepoArgs rev-parse HEAD).Trim().ToLowerInvariant()
$tree = (& $git.Source @gitRepoArgs rev-parse "HEAD^{tree}").Trim().ToLowerInvariant()
$branch = (& $git.Source @gitRepoArgs branch --show-current).Trim()
$coreTree = (& $git.Source @gitRepoArgs rev-parse "HEAD:godot/addons/mobile_game_core").Trim().ToLowerInvariant()
$statusLines = @(& $git.Source @gitRepoArgs status --porcelain=v1 --untracked-files=normal)
if ($statusLines.Count -ne 0) {
    throw "The Fred owner-test checkout must be clean before the desktop link is updated."
}
if ([string]::IsNullOrWhiteSpace($ExpectedCommit)) {
    $ExpectedCommit = $head
}
elseif ($ExpectedCommit.ToLowerInvariant() -ne $head) {
    throw "Expected commit does not match the clean Fred checkout."
}

$trackedFiles = @(& $git.Source @gitRepoArgs ls-files)
if ($LASTEXITCODE -ne 0 -or $trackedFiles.Count -eq 0) {
    throw "The Fred tracked-file inventory could not be read."
}
$fileEntries = foreach ($relativePath in $trackedFiles) {
    $candidatePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        throw "Tracked Fred file is missing: $relativePath"
    }
    [ordered]@{
        path = $relativePath.Replace("\", "/")
        sha256 = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
$manifestDirectory = Join-Path $projectRoot "builds\desktop-owner"
New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
$manifestPath = Join-Path $manifestDirectory "candidate.json"
[ordered]@{
    schema = "fred-desktop-owner-candidate-v1"
    candidate_commit = $head
    candidate_tree = $tree
    branch = $branch
    core_version = "0.5.1"
    core_tree = $coreTree
    save_schema = "fred_save v1"
    files = @($fileEntries)
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()

$desktop = if (-not [string]::IsNullOrWhiteSpace($env:OneDrive)) { Join-Path $env:OneDrive "Desktop" } else { "" }
if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path -LiteralPath $desktop -PathType Container)) {
    $desktop = Join-Path $env:USERPROFILE "Desktop"
}
if (-not (Test-Path -LiteralPath $desktop -PathType Container)) {
    throw "Windows Desktop folder was not found."
}

$legacyShortcut = Join-Path $desktop "Fred Myers M1 Owner Test.lnk"
$shortcutPath = Join-Path $desktop "Fred Myers Owner Test.lnk"
if ((Test-Path -LiteralPath $legacyShortcut -PathType Leaf) -and (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) {
    throw "Two Fred owner-test shortcuts already exist. Resolve the duplicate before updating either link."
}
if (Test-Path -LiteralPath $legacyShortcut -PathType Leaf) {
    Move-Item -LiteralPath $legacyShortcut -Destination $shortcutPath
}

$powerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShell
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`" -ExpectedCommit $ExpectedCommit -ExpectedManifestHash $manifestHash"
$shortcut.WorkingDirectory = $projectRoot
$shortcut.Description = "Fred Myers exact-candidate desktop owner test - Godot 4.7.1"
$shortcut.IconLocation = "$icon,0"
$shortcut.Save()

$verified = $shell.CreateShortcut($shortcutPath)
$fredShortcuts = @(Get-ChildItem -LiteralPath $desktop -Filter "Fred Myers*Owner Test.lnk")
if ($fredShortcuts.Count -ne 1) {
    throw "Expected exactly one Fred owner-test shortcut, found $($fredShortcuts.Count)."
}
if ($verified.TargetPath -ne $powerShell -or $verified.Arguments -notlike "*$launcher*" -or $verified.Arguments -notlike "*$ExpectedCommit*" -or $verified.Arguments -notlike "*$manifestHash*" -or $verified.IconLocation -notlike "*$icon*") {
    throw "Desktop shortcut verification failed."
}

[ordered]@{
    status = "UPDATED"
    shortcut = $shortcutPath
    candidate_commit = $ExpectedCommit
    candidate_manifest_sha256 = $manifestHash
    candidate_file_count = @($fileEntries).Count
    shortcut_count = $fredShortcuts.Count
    app_build_1_started = $true
} | ConvertTo-Json -Compress
