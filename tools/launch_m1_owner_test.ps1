[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotProject = Join-Path $projectRoot "godot"
$godotCommand = Get-Command "Godot_v4.7.1-stable_win64.exe" -ErrorAction SilentlyContinue
$godotConsole = Get-Command "Godot_v4.7.1-stable_win64_console.exe" -ErrorAction SilentlyContinue

if ($null -eq $godotCommand -or $null -eq $godotConsole) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "Godot 4.7.1 is required. Install or restore Godot 4.7.1, then run this launcher again.",
        "Fred Myers M1 Owner Test",
        "OK",
        "Error"
    ) | Out-Null
    exit 1
}

$version = & $godotConsole.Source --version
if ($LASTEXITCODE -ne 0 -or $version -notlike "4.7.1*") {
    throw "Expected Godot 4.7.1, but found: $version"
}

Start-Process -FilePath $godotCommand.Source -ArgumentList @("--path", "godot") -WorkingDirectory $projectRoot
