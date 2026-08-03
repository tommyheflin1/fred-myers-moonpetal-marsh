[CmdletBinding()]
param(
    [ValidatePattern("^[0-9a-fA-F]{40}$")]
    [string]$ExpectedCommit = ""
)

# Compatibility entry point for older notes. The installer updates/renames the
# one existing shortcut; it never creates a second Fred owner-test link.
& (Join-Path $PSScriptRoot "install_desktop_owner_shortcut.ps1") @PSBoundParameters
exit $LASTEXITCODE
