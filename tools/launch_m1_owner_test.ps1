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

# Compatibility entry point for older notes. The desktop shortcut uses the
# current launcher directly, so there is still only one owner-test path.
& (Join-Path $PSScriptRoot "launch_desktop_owner_test.ps1") @PSBoundParameters
exit $LASTEXITCODE
