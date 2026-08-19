[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ToolPath = Join-Path (Split-Path -Parent $PSScriptRoot) "validate_physical_android_device.ps1"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ApkPath = Join-Path $RepoRoot "builds\android\fred-myers-app-build-1-debug.apk"
$ExpectedHash = "916CECBEE7243768A786979A2D6A48B110AF59453BA9E8CBB46F6901EA4F6224"
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("fred-physical-preflight-" + [guid]::NewGuid().ToString("N"))
$Passed = 0
$Failed = 0

function Assert-Equal {
    param($Actual, $Expected, [string]$Label)
    if ($Actual -eq $Expected) {
        $script:Passed++
        Write-Output "PASS $Label"
    } else {
        $script:Failed++
        Write-Output "FAIL $Label expected=$Expected actual=$Actual"
    }
}

function Write-Fixture {
    param([string]$Name, [string]$Content)
    $path = Join-Path $TempRoot $Name
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
    return $path
}

function Invoke-Case {
    param(
        [string]$Name,
        [string]$Devices,
        [string]$ExpectedResult,
        [int]$ExpectedExit,
        [string]$Facts = "",
        [string]$Metadata = "",
        [string]$Serial = "",
        [string]$CaseApkPath = "",
        [string]$ExpectedReportedHash = ""
    )
    $devicesPath = Write-Fixture ($Name + "-devices.txt") $Devices
    $args = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ToolPath,
        "-TestMode", "-DeviceListFixturePath", $devicesPath
    )
    if (-not [string]::IsNullOrWhiteSpace($Facts)) {
        $factsPath = Write-Fixture ($Name + "-facts.json") $Facts
        $args += @("-DeviceFactsFixturePath", $factsPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($Metadata)) {
        $metadataPath = Write-Fixture ($Name + "-metadata.json") $Metadata
        $args += @("-ApkMetadataFixturePath", $metadataPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($Serial)) {
        $args += @("-Serial", $Serial)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseApkPath)) {
        $args += @("-ApkPath", $CaseApkPath)
    }
    if ([string]::IsNullOrWhiteSpace($ExpectedReportedHash)) {
        $ExpectedReportedHash = $ExpectedHash
    }
    $output = @(& powershell.exe @args 2>&1)
    $exitCode = $LASTEXITCODE
    $jsonLine = $output | Where-Object { $_ -match "^\{" } | Select-Object -Last 1
    if ($null -eq $jsonLine) {
        $script:Failed++
        Write-Output "FAIL $Name did not return JSON"
        return
    }
    $result = $jsonLine | ConvertFrom-Json
    Assert-Equal $result.result $ExpectedResult "$Name result"
    Assert-Equal $exitCode $ExpectedExit "$Name exit code"
    Assert-Equal $result.status "UNVERIFIED" "$Name remains unverified"
    Assert-Equal $result.mutation_performed $false "$Name performs no mutation"
    Assert-Equal $result.apk_sha256 $ExpectedReportedHash "$Name reports the observed APK hash"
}

New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
try {
    $normalMetadata = '{"package":"com.flinsappvault.fredmyers.dev","version_code":20105,"version_name":"0.2.1-app-build-1-r5","min_sdk":24,"target_sdk":36,"abis":["arm64-v8a","x86_64"],"permission_count":0}'
    $normalFacts = '{"api":35,"abis":["arm64-v8a"],"free_storage_kb":1048576,"installed":false,"installed_version_code":0}'
    $header = "List of devices attached`r`n"

    Invoke-Case "no-device" $header "DEVICE_NOT_CONNECTED" 0 "" $normalMetadata
    Invoke-Case "unauthorized" ($header + "PHONE-TEST unauthorized transport_id:1`r`n") "DEVICE_UNAUTHORIZED" 50 "" $normalMetadata
    Invoke-Case "offline" ($header + "PHONE-TEST offline transport_id:1`r`n") "DEVICE_OFFLINE" 51 "" $normalMetadata
    Invoke-Case "emulator-only" ($header + "emulator-5554 device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64`r`n") "EMULATOR_ONLY" 53 "" $normalMetadata
    Invoke-Case "multiple-ambiguous" ($header + "PHONE-A device model:PhoneA`r`nPHONE-B device model:PhoneB`r`n") "MULTIPLE_DEVICES_AMBIGUOUS" 52 "" $normalMetadata

    $wrongHashApk = Write-Fixture "wrong-hash.apk" "fictional invalid apk"
    $wrongHash = (Get-FileHash -LiteralPath $wrongHashApk -Algorithm SHA256).Hash
    Invoke-Case "wrong-hash" $header "APK_HASH_MISMATCH" 42 "" $normalMetadata "" $wrongHashApk $wrongHash

    $wrongPackage = '{"package":"com.example.wrong","version_code":20105,"version_name":"0.2.1-app-build-1-r5","min_sdk":24,"target_sdk":36,"abis":["arm64-v8a","x86_64"],"permission_count":0}'
    Invoke-Case "wrong-package" $header "APK_PACKAGE_MISMATCH" 43 "" $wrongPackage

    $oldApi = '{"api":23,"abis":["arm64-v8a"],"free_storage_kb":1048576,"installed":false,"installed_version_code":0}'
    Invoke-Case "unsupported-api" ($header + "PHONE-TEST device model:Phone`r`n") "DEVICE_API_UNSUPPORTED" 56 $oldApi $normalMetadata "PHONE-TEST"

    $wrongAbi = '{"api":35,"abis":["armeabi-v7a"],"free_storage_kb":1048576,"installed":false,"installed_version_code":0}'
    Invoke-Case "unsupported-abi" ($header + "PHONE-TEST device model:Phone`r`n") "DEVICE_ABI_UNSUPPORTED" 57 $wrongAbi $normalMetadata "PHONE-TEST"

    $unknownInstalledVersion = '{"api":35,"abis":["arm64-v8a"],"free_storage_kb":1048576,"installed":true,"installed_version_code":0}'
    Invoke-Case "unknown-installed-version" ($header + "PHONE-TEST device model:Phone`r`n") "INSTALLED_VERSION_UNKNOWN" 59 $unknownInstalledVersion $normalMetadata "PHONE-TEST"

    $newerInstalledVersion = '{"api":35,"abis":["arm64-v8a"],"free_storage_kb":1048576,"installed":true,"installed_version_code":30000}'
    Invoke-Case "downgrade-blocked" ($header + "PHONE-TEST device model:Phone`r`n") "DOWNGRADE_BLOCKED" 60 $newerInstalledVersion $normalMetadata "PHONE-TEST"

    Invoke-Case "explicit-serial" ($header + "PHONE-TEST device model:Phone`r`nemulator-5554 device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64`r`n") "DEVICE_PREFLIGHT_READY" 0 $normalFacts $normalMetadata "PHONE-TEST"

    Write-Output "RESULT physical_android_preflight_passed=$Passed physical_android_preflight_failed=$Failed"
    if ($Failed -ne 0) {
        exit 1
    }
} finally {
    if (Test-Path -LiteralPath $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
