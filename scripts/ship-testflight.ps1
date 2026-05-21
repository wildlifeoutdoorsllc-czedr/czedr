# Ship Czedr iOS to TestFlight: push (optional) + manual workflow run.
# Usage:
#   .\ship-testflight.ps1 -BuildNumber 96
#   .\ship-testflight.ps1 -BuildNumber 96 -WaitForPrevious   # wait for last CI run to finish first
#   .\ship-testflight.ps1 -BuildNumber 96 -SkipPush
#   .\ship-testflight.ps1 -BuildNumber 96 -PushOnly

param(
    [Parameter(Mandatory = $true)]
    [int]$BuildNumber,
    [switch]$SkipPush,
    [switch]$PushOnly,
    [switch]$WaitForPrevious
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'czedrmaster') {
    Write-Host "Warning: branch is '$branch', not czedrmaster." -ForegroundColor Yellow
}

$dirty = git status --porcelain
if ($dirty) {
    Write-Host "Uncommitted changes:" -ForegroundColor Yellow
    git status -sb
    $ok = Read-Host "Continue anyway? (y/N)"
    if ($ok -notmatch '^[yY]') { exit 1 }
}

$ahead = (git rev-list --count "origin/czedrmaster..HEAD" 2>$null)
if (-not $SkipPush -and -not $PushOnly) {
    if ($ahead -gt 0) {
        Write-Host "Pushing $ahead commit(s) to origin/czedrmaster..." -ForegroundColor Cyan
        git push origin czedrmaster
    } else {
        Write-Host "Already up to date with origin/czedrmaster (no push needed)." -ForegroundColor DarkGray
    }
} elseif ($SkipPush) {
    Write-Host "SkipPush: not pushing." -ForegroundColor DarkGray
}

if ($PushOnly) {
    Write-Host "PushOnly: done." -ForegroundColor Green
    exit 0
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "gh CLI not found. Run workflow manually:" -ForegroundColor Yellow
    Write-Host "  GitHub -> Actions -> iOS TestFlight -> Run workflow" -ForegroundColor Yellow
    Write-Host "  build_number = $BuildNumber" -ForegroundColor Yellow
    exit 0
}

if ($WaitForPrevious) {
    Write-Host "Waiting for any in-progress iOS TestFlight workflow to finish..." -ForegroundColor Cyan
    while ($true) {
        $status = (gh run list --workflow=ios-testflight.yml --limit 1 --json status --jq '.[0].status' 2>$null)
        if ($status -ne 'in_progress' -and $status -ne 'queued' -and $status -ne 'pending' -and $status -ne 'waiting') {
            if ($status -eq 'completed') {
                $conclusion = (gh run list --workflow=ios-testflight.yml --limit 1 --json conclusion --jq '.[0].conclusion' 2>$null)
                Write-Host "Previous run: $conclusion" -ForegroundColor DarkGray
            }
            break
        }
        Write-Host "  Still running ($status) - checking again in 30s..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 30
    }
}

Write-Host "Starting iOS TestFlight workflow (build $BuildNumber)..." -ForegroundColor Cyan
gh workflow run ios-testflight.yml --ref czedrmaster -f "build_number=$BuildNumber"
Start-Sleep -Seconds 2
gh run list --workflow=ios-testflight.yml --limit 1

Write-Host ""
Write-Host "After upload succeeds: install build $BuildNumber from TestFlight." -ForegroundColor Green
Write-Host "Update docs/IOS-BUILD.md (Last shipped = $BuildNumber)." -ForegroundColor Green
Write-Host "Optional: RESTART-IPHONE-TESTING.cmd or WATCH-TESTFLIGHT-AND-RESTART.cmd" -ForegroundColor DarkGray
