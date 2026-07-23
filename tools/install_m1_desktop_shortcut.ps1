[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $PSScriptRoot "launch_m1_owner_test.ps1"
$desktop = Join-Path $env:OneDrive "Desktop"

if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "Fred owner launcher is missing: $launcher"
}
if ([string]::IsNullOrWhiteSpace($env:OneDrive) -or -not (Test-Path -LiteralPath $desktop -PathType Container)) {
    $desktop = Join-Path $env:USERPROFILE "Desktop"
}
if (-not (Test-Path -LiteralPath $desktop -PathType Container)) {
    throw "Windows Desktop folder was not found."
}

$shortcutPath = Join-Path $desktop "Fred Myers M1 Owner Test.lnk"
$powerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShell
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
$shortcut.WorkingDirectory = $projectRoot
$shortcut.Description = "Local Fred Myers M1 owner test - Godot 4.7.1"
$shortcut.Save()

$verified = $shell.CreateShortcut($shortcutPath)
if ($verified.TargetPath -ne $powerShell -or $verified.Arguments -notlike "*$launcher*") {
    throw "Desktop shortcut verification failed."
}

Write-Output $shortcutPath
