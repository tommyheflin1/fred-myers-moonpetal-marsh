[CmdletBinding()]
param(
    [ValidateSet("Preflight", "InstallLaunch", "CaptureDiagnostics")]
    [string]$Mode = "Preflight",
    [string]$Serial = "",
    [switch]$AcknowledgeOwnerDevice,
    [switch]$AcknowledgeSaveRisk,
    [switch]$AcknowledgeDiagnosticCapture,
    [string]$ApkPath = "",
    [string]$AdbPath = "",
    [switch]$TestMode,
    [string]$DeviceListFixturePath = "",
    [string]$DeviceFactsFixturePath = "",
    [string]$ApkMetadataFixturePath = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$CandidateSourceSha = "3f00fff76c568d35ec72913e03bce2714819faae"
$ExpectedApkSha256 = "760971B1F10BBC8672030C5397CE1E477B9CE6F0B04FA596749BD46A98E3EF4F"
$ExpectedApkBytes = 84845973
$ExpectedPackage = "com.flinsappvault.fredmyers.dev"
$ExpectedVersionCode = 20104
$MinimumDeviceApi = 24
$SupportedAbis = @("arm64-v8a", "x86_64")
$MinimumFreeStorageKb = 524288

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppVaultRoot = Split-Path -Parent $RepoRoot
if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $ApkPath = Join-Path $RepoRoot "builds\android\fred-myers-app-build-1-debug.apk"
}
if ([string]::IsNullOrWhiteSpace($AdbPath)) {
    $AdbPath = Join-Path $AppVaultRoot "work\toolchain\android-sdk\platform-tools\adb.exe"
}
$BuildToolsRoot = Join-Path $AppVaultRoot "work\toolchain\android-sdk\build-tools\36.0.0"
$AaptPath = Join-Path $BuildToolsRoot "aapt2.exe"
$ApkSignerPath = Join-Path $BuildToolsRoot "apksigner.bat"
$ZipAlignPath = Join-Path $BuildToolsRoot "zipalign.exe"

function Write-ResultAndExit {
    param(
        [string]$Result,
        [string]$DeviceClassification,
        [string]$OwnerAction,
        [int]$ExitCode,
        [bool]$MutationPerformed = $false,
        [hashtable]$Additional = @{}
    )
    $payload = [ordered]@{
        schema_version = 1
        status = "UNVERIFIED"
        result = $Result
        candidate_source_sha = $CandidateSourceSha
        apk_sha256 = $script:ActualApkSha256
        apk_size_bytes = $script:ActualApkBytes
        expected_package = $ExpectedPackage
        device_classification = $DeviceClassification
        selected_device = -not [string]::IsNullOrWhiteSpace($Serial)
        mutation_performed = $MutationPerformed
        owner_action = $OwnerAction
    }
    foreach ($key in $Additional.Keys) {
        $payload[$key] = $Additional[$key]
    }
    Write-Output ($payload | ConvertTo-Json -Compress -Depth 5)
    exit $ExitCode
}

function Get-Sha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Find-Python {
    $bundled = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if (Test-Path -LiteralPath $bundled) {
        return $bundled
    }
    $python = Get-Command "python.exe" -ErrorAction SilentlyContinue
    if ($null -ne $python) {
        $probe = Invoke-NativeCapture $python.Source @("--version")
        if ($probe.exit_code -eq 0) {
            return $python.Source
        }
    }
    return ""
}

function Invoke-NativeCapture {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @()
    )
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    return [pscustomobject]@{
        output = $output
        exit_code = $exitCode
    }
}

function Read-ApkMetadata {
    if ($TestMode -and -not [string]::IsNullOrWhiteSpace($ApkMetadataFixturePath)) {
        if (-not (Test-Path -LiteralPath $ApkMetadataFixturePath -PathType Leaf)) {
            Write-ResultAndExit "TEST_FIXTURE_INVALID" "NOT_CHECKED" "Repair the fictional APK metadata fixture." 21
        }
        return Get-Content -LiteralPath $ApkMetadataFixturePath -Raw | ConvertFrom-Json
    }

    foreach ($tool in @($AaptPath, $ApkSignerPath, $ZipAlignPath)) {
        if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
            Write-ResultAndExit "ANDROID_TOOLCHAIN_UNAVAILABLE" "NOT_CHECKED" "Restore the verified local Android build-tools 36.0.0 installation." 22
        }
    }
    $python = Find-Python
    if ([string]::IsNullOrWhiteSpace($python)) {
        Write-ResultAndExit "PYTHON_UNAVAILABLE" "NOT_CHECKED" "Restore Python before running the APK content inspection." 23
    }

    $inspectScript = Join-Path $PSScriptRoot "inspect_android_apk.py"
    $exportValidator = Join-Path $PSScriptRoot "validate_android_export.py"
    $inspection = Invoke-NativeCapture $python @($inspectScript, $ApkPath)
    if ($inspection.exit_code -ne 0) {
        Write-ResultAndExit "APK_CONTENT_INVALID" "NOT_CHECKED" "Rebuild and reinspect the exact Fred debug APK." 24
    }
    $exportContract = Invoke-NativeCapture $python @($exportValidator)
    if ($exportContract.exit_code -ne 0) {
        Write-ResultAndExit "APK_PROJECT_CONTRACT_INVALID" "NOT_CHECKED" "Repair the development-only Android export contract." 25
    }
    $badgingResult = Invoke-NativeCapture $AaptPath @("dump", "badging", $ApkPath)
    if ($badgingResult.exit_code -ne 0) {
        Write-ResultAndExit "APK_BADGING_UNREADABLE" "NOT_CHECKED" "Rebuild the APK before physical-device testing." 26
    }
    $badging = @($badgingResult.output)
    $badgingText = $badging -join "`n"
    $packageMatch = [regex]::Match($badgingText, "package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'")
    $minMatch = [regex]::Match($badgingText, "minSdkVersion:'(\d+)'")
    $targetMatch = [regex]::Match($badgingText, "targetSdkVersion:'(\d+)'")
    $abiMatch = [regex]::Match($badgingText, "native-code:(.+)")
    if (-not $packageMatch.Success -or -not $minMatch.Success -or -not $targetMatch.Success -or -not $abiMatch.Success) {
        Write-ResultAndExit "APK_METADATA_INCOMPLETE" "NOT_CHECKED" "Rebuild the APK before physical-device testing." 27
    }
    $abis = @([regex]::Matches($abiMatch.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
    $permissionCount = ([regex]::Matches($badgingText, "(?m)^uses-permission:")).Count

    $signatureResult = Invoke-NativeCapture $ApkSignerPath @("verify", "--verbose", "--print-certs", $ApkPath)
    $signatureOutput = @($signatureResult.output)
    if ($signatureResult.exit_code -ne 0 -or -not (($signatureOutput -join "`n") -match "Verified using v2 scheme .*: true")) {
        Write-ResultAndExit "APK_SIGNATURE_INVALID" "NOT_CHECKED" "Rebuild the Godot debug-signed APK." 28
    }
    $alignmentResult = Invoke-NativeCapture $ZipAlignPath @("-c", "-P", "16", "4", $ApkPath)
    if ($alignmentResult.exit_code -ne 0) {
        Write-ResultAndExit "APK_ALIGNMENT_INVALID" "NOT_CHECKED" "Rebuild the aligned Godot debug APK." 29
    }
    return [pscustomobject]@{
        package = $packageMatch.Groups[1].Value
        version_code = [int]$packageMatch.Groups[2].Value
        version_name = $packageMatch.Groups[3].Value
        min_sdk = [int]$minMatch.Groups[1].Value
        target_sdk = [int]$targetMatch.Groups[1].Value
        abis = $abis
        permission_count = $permissionCount
    }
}

function Read-DeviceRows {
    if ($TestMode -and -not [string]::IsNullOrWhiteSpace($DeviceListFixturePath)) {
        if (-not (Test-Path -LiteralPath $DeviceListFixturePath -PathType Leaf)) {
            Write-ResultAndExit "TEST_FIXTURE_INVALID" "NOT_CHECKED" "Repair the fictional device-list fixture." 30
        }
        return @(Get-Content -LiteralPath $DeviceListFixturePath)
    }
    if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
        Write-ResultAndExit "ADB_UNAVAILABLE" "NOT_CHECKED" "Restore the verified Android SDK platform tools." 31
    }
    $discovery = Invoke-NativeCapture $AdbPath @("devices", "-l")
    if ($discovery.exit_code -ne 0) {
        Write-ResultAndExit "ADB_DISCOVERY_FAILED" "NOT_CHECKED" "Repair ADB discovery without changing device settings." 32
    }
    return @($discovery.output)
}

function ConvertTo-DeviceRecords {
    param([string[]]$Rows)
    $records = @()
    foreach ($row in $Rows) {
        if ($row -notmatch "^(\S+)\s+(device|unauthorized|offline)\b(.*)$") {
            continue
        }
        $deviceSerial = $Matches[1]
        $state = $Matches[2]
        $details = $Matches[3]
        $isEmulator = (
            $deviceSerial -match "^emulator-" -or
            $details -match "\bmodel:sdk_" -or
            $details -match "\bproduct:sdk_" -or
            $details -match "\bmodel:Android_SDK"
        )
        $records += [pscustomobject]@{
            serial = $deviceSerial
            state = $state
            is_emulator = $isEmulator
        }
    }
    return $records
}

function Read-DeviceFacts {
    if ($TestMode -and -not [string]::IsNullOrWhiteSpace($DeviceFactsFixturePath)) {
        if (-not (Test-Path -LiteralPath $DeviceFactsFixturePath -PathType Leaf)) {
            Write-ResultAndExit "TEST_FIXTURE_INVALID" "SELECTED_PHYSICAL" "Repair the fictional device-facts fixture." 33
        }
        return Get-Content -LiteralPath $DeviceFactsFixturePath -Raw | ConvertFrom-Json
    }
    $apiResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "getprop", "ro.build.version.sdk")
    $abiResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "getprop", "ro.product.cpu.abilist")
    $apiText = ($apiResult.output | Out-String).Trim()
    $abiText = ($abiResult.output | Out-String).Trim()
    if ($apiText -notmatch "^\d+$" -or [string]::IsNullOrWhiteSpace($abiText)) {
        Write-ResultAndExit "DEVICE_FACTS_UNAVAILABLE" "SELECTED_PHYSICAL" "Reconnect the authorized phone and rerun preflight." 34
    }
    $installedPathResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "pm", "path", $ExpectedPackage)
    $installedPath = ($installedPathResult.output | Out-String).Trim()
    $installed = $installedPath -match "^package:"
    $installedVersion = 0
    if ($installed) {
        $packageDumpResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "dumpsys", "package", $ExpectedPackage)
        $packageDump = $packageDumpResult.output | Out-String
        $versionMatch = [regex]::Match($packageDump, "(?m)^\s*versionCode=(\d+)")
        if ($versionMatch.Success) {
            $installedVersion = [int]$versionMatch.Groups[1].Value
        }
    }
    $storageResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "df", "-k", "/data")
    $storageOutput = $storageResult.output | Out-String
    $storageLines = @($storageOutput -split "`r?`n" | Where-Object { $_ -match "^\S+\s+\d+\s+\d+\s+\d+" })
    $freeStorageKb = 0
    if ($storageLines.Count -gt 0) {
        $columns = @($storageLines[-1] -split "\s+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($columns.Count -ge 4 -and $columns[3] -match "^\d+$") {
            $freeStorageKb = [int64]$columns[3]
        }
    }
    return [pscustomobject]@{
        api = [int]$apiText
        abis = @($abiText -split "," | ForEach-Object { $_.Trim() })
        free_storage_kb = $freeStorageKb
        installed = $installed
        installed_version_code = $installedVersion
    }
}

function Redact-DiagnosticText {
    param([string]$Text)
    $redacted = $Text -replace [regex]::Escape($Serial), "<DEVICE>"
    $redacted = $redacted -replace "(?i)[A-Z]:\\Users\\[^\\\r\n]+", "<WINDOWS_USER_PATH>"
    $redacted = $redacted -replace "(?i)/Users/[^/\r\n]+", "/Users/<USER>"
    $redacted = $redacted -replace "(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", "<EMAIL>"
    return $redacted
}

$script:ActualApkSha256 = ""
$script:ActualApkBytes = 0

if ($TestMode -and $Mode -ne "Preflight") {
    Write-ResultAndExit "TEST_MODE_MUTATION_BLOCKED" "NOT_CHECKED" "Use TestMode only for fictional, read-only preflight fixtures." 40
}
if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) {
    Write-ResultAndExit "APK_NOT_FOUND" "NOT_CHECKED" "Restore the exact Fred development APK." 41
}
Write-Verbose "Verifying the local APK hash and byte count."
$apkItem = Get-Item -LiteralPath $ApkPath
$script:ActualApkBytes = $apkItem.Length
$script:ActualApkSha256 = Get-Sha256 $ApkPath
if ($script:ActualApkSha256 -ne $ExpectedApkSha256 -or $script:ActualApkBytes -ne $ExpectedApkBytes) {
    Write-ResultAndExit "APK_HASH_MISMATCH" "NOT_CHECKED" "Use only the hash-guarded Fred APK named in the owner handoff." 42
}

Write-Verbose "Inspecting the local APK identity, SDK, ABI, permission, signature, and alignment contracts."
$metadata = Read-ApkMetadata
if ([string]$metadata.package -ne $ExpectedPackage) {
    Write-ResultAndExit "APK_PACKAGE_MISMATCH" "NOT_CHECKED" "Use only the expected Fred development package." 43
}
if ([int]$metadata.version_code -ne $ExpectedVersionCode) {
    Write-ResultAndExit "APK_VERSION_MISMATCH" "NOT_CHECKED" "Use only the expected Fred development version." 44
}
if ([int]$metadata.min_sdk -ne 24 -or [int]$metadata.target_sdk -ne 36) {
    Write-ResultAndExit "APK_SDK_CONTRACT_MISMATCH" "NOT_CHECKED" "Rebuild the exact SDK 24/36 Fred candidate." 45
}
$apkAbis = @($metadata.abis)
foreach ($expectedAbi in $SupportedAbis) {
    if ($expectedAbi -notin $apkAbis) {
        Write-ResultAndExit "APK_ABI_CONTRACT_MISMATCH" "NOT_CHECKED" "Rebuild the arm64-v8a plus x86_64 Fred candidate." 46
    }
}
if ([int]$metadata.permission_count -ne 0) {
    Write-ResultAndExit "APK_PERMISSION_CONTRACT_MISMATCH" "NOT_CHECKED" "Do not install an APK that requests Android permissions." 47
}

Write-Verbose "Discovering ADB targets without selecting or mutating a device."
$records = @(ConvertTo-DeviceRecords (Read-DeviceRows))
Write-Verbose ("ADB discovery returned {0} classified target(s)." -f $records.Count)
if ($records.Count -eq 0) {
    Write-ResultAndExit "DEVICE_NOT_CONNECTED" "ZERO_DEVICES" "Connect one owner-authorized physical Android phone with USB debugging, then rerun Preflight with -Serial; do not install yet." 0
}
$unauthorized = @($records | Where-Object { $_.state -eq "unauthorized" })
$offline = @($records | Where-Object { $_.state -eq "offline" })
if ($unauthorized.Count -gt 0) {
    Write-ResultAndExit "DEVICE_UNAUTHORIZED" "UNAUTHORIZED_OR_MIXED" "Authorize the intended phone on its own screen, disconnect every other target, then rerun read-only Preflight." 50
}
if ($offline.Count -gt 0) {
    Write-ResultAndExit "DEVICE_OFFLINE" "OFFLINE_OR_MIXED" "Reconnect the intended phone without changing developer settings, then rerun read-only Preflight." 51
}

if ([string]::IsNullOrWhiteSpace($Serial)) {
    if ($records.Count -gt 1) {
        Write-ResultAndExit "MULTIPLE_DEVICES_AMBIGUOUS" "MULTIPLE_AUTHORIZED" "Disconnect unrelated targets or rerun with the exact owner-approved physical serial." 52
    }
    if ([bool]$records[0].is_emulator) {
        Write-ResultAndExit "EMULATOR_ONLY" "ONE_EMULATOR" "Connect one owner-authorized physical Android phone; emulator evidence is not physical acceptance." 53
    }
    Write-ResultAndExit "PHYSICAL_DEVICE_OWNER_AUTH_REQUIRED" "ONE_PHYSICAL_UNSELECTED" "Confirm this is the owner phone, then rerun read-only Preflight with its explicit serial." 0
}

$selected = @($records | Where-Object { $_.serial -eq $Serial })
if ($selected.Count -ne 1) {
    Write-ResultAndExit "EXPLICIT_SERIAL_NOT_FOUND" "SELECTION_FAILED" "Use the exact serial of one connected owner-authorized physical phone." 54
}
if ([bool]$selected[0].is_emulator) {
    Write-ResultAndExit "EXPLICIT_SERIAL_IS_EMULATOR" "SELECTED_EMULATOR" "Select a physical Android phone; emulator evidence is not physical acceptance." 55
}

$facts = Read-DeviceFacts
if ([int]$facts.api -lt $MinimumDeviceApi) {
    Write-ResultAndExit "DEVICE_API_UNSUPPORTED" "SELECTED_PHYSICAL" "Use an owner-authorized physical phone running Android API 24 or newer." 56
}
$deviceAbis = @($facts.abis)
$compatibleAbis = @($deviceAbis | Where-Object { $_ -in $SupportedAbis })
if ($compatibleAbis.Count -eq 0) {
    Write-ResultAndExit "DEVICE_ABI_UNSUPPORTED" "SELECTED_PHYSICAL" "Use an arm64-v8a compatible owner phone." 57
}
if ([int64]$facts.free_storage_kb -lt $MinimumFreeStorageKb) {
    Write-ResultAndExit "DEVICE_STORAGE_INSUFFICIENT" "SELECTED_PHYSICAL" "Free at least 512 MB on the owner phone without deleting app data." 58
}

$installState = "FIRST_INSTALL"
if ([bool]$facts.installed) {
    $installState = "SAFE_UPDATE"
    if ([int]$facts.installed_version_code -le 0) {
        Write-ResultAndExit "INSTALLED_VERSION_UNKNOWN" "SELECTED_PHYSICAL" "Stop; do not update, uninstall, or clear data until the installed Fred version is known." 59
    }
    if ([int]$facts.installed_version_code -gt $ExpectedVersionCode) {
        Write-ResultAndExit "DOWNGRADE_BLOCKED" "SELECTED_PHYSICAL" "Do not downgrade or uninstall; prepare a newer Fred debug build." 60
    }
}

if ($Mode -eq "Preflight") {
    Write-ResultAndExit "DEVICE_PREFLIGHT_READY" "SELECTED_PHYSICAL" "Review the owner matrix, then explicitly authorize InstallLaunch with both acknowledgement flags." 0 $false @{
        install_state = $installState
        device_api = [int]$facts.api
        compatible_abi = [string]$compatibleAbis[0]
    }
}

if (-not $AcknowledgeOwnerDevice -or -not $AcknowledgeSaveRisk) {
    Write-ResultAndExit "MUTATION_ACKNOWLEDGEMENT_REQUIRED" "SELECTED_PHYSICAL" "Provide -AcknowledgeOwnerDevice and -AcknowledgeSaveRisk only after owner approval and save-risk review." 61
}

if ($Mode -eq "InstallLaunch") {
    $installArguments = @("-s", $Serial, "install", "--no-streaming")
    if ($installState -eq "SAFE_UPDATE") {
        $installArguments += "-r"
    }
    $installArguments += $ApkPath
    $installResult = Invoke-NativeCapture $AdbPath $installArguments
    $installOutput = @($installResult.output)
    if ($installResult.exit_code -ne 0 -or -not (($installOutput -join "`n") -match "(?m)^Success$")) {
        Write-ResultAndExit "INSTALL_FAILED" "SELECTED_PHYSICAL" "Stop; preserve device data and review the app-scoped install error." 62
    }
    $activityResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "cmd", "package", "resolve-activity", "--brief", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.LAUNCHER", $ExpectedPackage)
    $activity = ($activityResult.output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($activity) -or $activity -notmatch [regex]::Escape($ExpectedPackage)) {
        Write-ResultAndExit "LAUNCH_ACTIVITY_NOT_FOUND" "SELECTED_PHYSICAL" "Stop without uninstalling or clearing data; inspect the Fred package manifest." 63 $true
    }
    $launchResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "am", "start", "-n", $activity)
    $launchOutput = @($launchResult.output)
    if ($launchResult.exit_code -ne 0 -or (($launchOutput -join "`n") -match "(?i)\bError\b")) {
        Write-ResultAndExit "LAUNCH_FAILED" "SELECTED_PHYSICAL" "Stop without uninstalling or clearing data; inspect only Fred app diagnostics." 64 $true
    }
    Write-ResultAndExit "INSTALL_LAUNCH_COMPLETE_UNVERIFIED" "SELECTED_PHYSICAL" "Complete both owner test runs before recording physical-device acceptance." 0 $true @{
        install_state = $installState
    }
}

if (-not $AcknowledgeDiagnosticCapture) {
    Write-ResultAndExit "DIAGNOSTIC_ACKNOWLEDGEMENT_REQUIRED" "SELECTED_PHYSICAL" "Provide -AcknowledgeDiagnosticCapture only for a bounded Fred app-scoped capture." 65
}
if (-not [bool]$facts.installed) {
    Write-ResultAndExit "APP_NOT_INSTALLED" "SELECTED_PHYSICAL" "Run the separately authorized InstallLaunch flow first." 66
}
$pidResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "pidof", $ExpectedPackage)
$pidText = ($pidResult.output | Out-String).Trim()
if ($pidText -notmatch "^\d+$") {
    Write-ResultAndExit "APP_NOT_RUNNING" "SELECTED_PHYSICAL" "Launch Fred normally, then rerun the bounded capture." 67
}
$meminfoResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "dumpsys", "meminfo", $ExpectedPackage)
$gfxinfoResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "shell", "dumpsys", "gfxinfo", $ExpectedPackage, "framestats")
$logcatResult = Invoke-NativeCapture $AdbPath @("-s", $Serial, "logcat", "--pid", $pidText, "-d", "-t", "400")
if ($meminfoResult.exit_code -ne 0 -or $gfxinfoResult.exit_code -ne 0 -or $logcatResult.exit_code -ne 0) {
    Write-ResultAndExit "DIAGNOSTIC_CAPTURE_FAILED" "SELECTED_PHYSICAL" "Stop without broadening capture scope; preserve the app and review the Fred-only command failure." 68
}
$captureRoot = Join-Path $RepoRoot ("builds\physical-android\capture-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ"))
New-Item -ItemType Directory -Path $captureRoot -Force | Out-Null
$captures = [ordered]@{
    meminfo = @($meminfoResult.output)
    gfxinfo = @($gfxinfoResult.output)
    logcat = @($logcatResult.output)
}
foreach ($name in $captures.Keys) {
    $safeText = Redact-DiagnosticText (($captures[$name]) -join "`n")
    Set-Content -LiteralPath (Join-Path $captureRoot ($name + ".txt")) -Value $safeText -Encoding UTF8
}
Write-ResultAndExit "DIAGNOSTIC_CAPTURE_COMPLETE_UNVERIFIED" "SELECTED_PHYSICAL" "Review the redacted, Fred-only files and complete human acceptance separately." 0 $true @{
    capture_path = "builds/physical-android/" + (Split-Path -Leaf $captureRoot)
}
