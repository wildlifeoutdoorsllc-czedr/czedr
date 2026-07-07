# Returns the Czedr repository root (parent of scripts/).
# Dot-source: . (Join-Path $PSScriptRoot 'Czedr-RepoRoot.ps1')
# Optional override: set env CZEDR_REPO_ROOT to a fixed path (e.g. after moving the repo).

function Get-CzedrRepoRoot {
    if ($env:CZEDR_REPO_ROOT -and (Test-Path $env:CZEDR_REPO_ROOT)) {
        return (Resolve-Path $env:CZEDR_REPO_ROOT).Path
    }
    $scriptsDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    return (Resolve-Path (Join-Path $scriptsDir '..')).Path
}
