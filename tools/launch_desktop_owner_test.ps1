[CmdletBinding()]
param(
    [ValidatePattern("^[0-9a-fA-F]{7,40}$")]
    [string]$ExpectedCommit = "",
    [ValidatePattern("^[0-9a-fA-F]{64}$")]
    [string]$ExpectedManifestHash = "",
    [switch]$PreflightOnly,
    [switch]$IsolatedReview,
    [switch]$ReducedMotion
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotProject = Join-Path $projectRoot "godot"
$manifestPath = Join-Path $projectRoot "builds\desktop-owner\candidate.json"
$expectedCoreTree = "288d87420c5694f80c071f00aa71a0b581f9f60c"
$reviewRoot = $null

function Show-OwnerError {
    param([string]$Message)

    if (-not $PreflightOnly) {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            $Message,
            "Fred Myers Owner Test",
            "OK",
            "Error"
        ) | Out-Null
    }
}

try {
    $godotCommand = Get-Command "Godot_v4.7.1-stable_win64.exe" -ErrorAction Stop
    $godotConsole = Get-Command "Godot_v4.7.1-stable_win64_console.exe" -ErrorAction Stop

    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "The Fred candidate manifest is missing. Ask Codex to refresh the owner-test link."
    }
    $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not [string]::IsNullOrWhiteSpace($ExpectedManifestHash) -and $manifestHash -ne $ExpectedManifestHash.ToLowerInvariant()) {
        throw "The Fred candidate manifest changed. Ask Codex to refresh the owner-test link."
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $head = ([string]$manifest.candidate_commit).ToLowerInvariant()
    $tree = ([string]$manifest.candidate_tree).ToLowerInvariant()
    $branch = [string]$manifest.branch
    $coreTree = ([string]$manifest.core_tree).ToLowerInvariant()

    if (-not [string]::IsNullOrWhiteSpace($ExpectedCommit)) {
        $expected = $ExpectedCommit.ToLowerInvariant()
        if (-not $head.StartsWith($expected) -and -not $expected.StartsWith($head)) {
            throw "This desktop link is pinned to a different Fred candidate. Ask Codex to refresh the owner-test link."
        }
    }
    if ($coreTree -ne $expectedCoreTree) {
        throw "The Mobile Game Core 0.5.1 tree does not match the accepted Fred pin."
    }
    foreach ($entry in @($manifest.files)) {
        $relativePath = ([string]$entry.path).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
        $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $relativePath))
        if (-not $candidatePath.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "The Fred candidate manifest contains an unsafe path."
        }
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
            throw "A pinned Fred candidate file is missing: $($entry.path)"
        }
        $actualHash = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
            throw "A pinned Fred candidate file changed: $($entry.path). Ask Codex to refresh the owner-test link."
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $godotProject "project.godot") -PathType Leaf)) {
        throw "The Fred Godot project is missing."
    }

    $version = (& $godotConsole.Source --version).Trim()
    if ($LASTEXITCODE -ne 0 -or $version -notlike "4.7.1*") {
        throw "Expected Godot 4.7.1, but found: $version"
    }

    $preflight = [ordered]@{
        status = "READY"
        candidate_commit = $head
        candidate_tree = $tree
        branch = $branch
        candidate_files_match = $true
        candidate_manifest_sha256 = $manifestHash
        candidate_file_count = @($manifest.files).Count
        godot_version = $version
        core_version = "0.5.1"
        core_tree = $coreTree
        save_schema = "fred_save v1"
        save_mode = if ($IsolatedReview) { "isolated-fictional" } else { "owner-progress" }
        reduced_motion = [bool]$ReducedMotion
        launch_performed = $false
        app_build_1_started = $true
    }

    if ($PreflightOnly) {
        $preflight | ConvertTo-Json -Compress
        exit 0
    }

    # Keep the project argument relative to the verified working directory so
    # Windows PowerShell 5.1 cannot split the App Vault path at spaces.
    $arguments = @("--path", "godot", "--resolution", "1280x720", "--", "--show-touch-controls")
    if ($ReducedMotion) {
        $arguments += "--reduced-motion"
    }

    $originalAppData = $env:APPDATA
    $originalLocalAppData = $env:LOCALAPPDATA
    if ($IsolatedReview) {
        $reviewRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("fred-desktop-owner-review-" + [Guid]::NewGuid().ToString("N"))
        $env:APPDATA = Join-Path $reviewRoot "Roaming"
        $env:LOCALAPPDATA = Join-Path $reviewRoot "Local"
        New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
        New-Item -ItemType Directory -Path $env:LOCALAPPDATA -Force | Out-Null
    }

    try {
        $process = Start-Process -FilePath $godotCommand.Source -ArgumentList $arguments -WorkingDirectory $projectRoot -PassThru
        $preflight.launch_performed = $true
        if ($IsolatedReview) {
            $process.WaitForExit()
        }
    }
    finally {
        if ($IsolatedReview) {
            $env:APPDATA = $originalAppData
            $env:LOCALAPPDATA = $originalLocalAppData
            if ($null -ne $reviewRoot -and (Test-Path -LiteralPath $reviewRoot -PathType Container)) {
                [System.IO.Directory]::Delete("\\?\" + [System.IO.Path]::GetFullPath($reviewRoot), $true)
            }
        }
    }
}
catch {
    Show-OwnerError $_.Exception.Message
    if ($PreflightOnly) {
        [ordered]@{
            status = "BLOCKED"
            reason = $_.Exception.Message
            launch_performed = $false
            app_build_1_started = $true
        } | ConvertTo-Json -Compress
    }
    exit 1
}
