# Poll GitHub Actions for a new successful iOS TestFlight upload, then restart the local API server.
# Leave this running in a terminal while you wait for TestFlight builds.
param(
    [int]$PollSeconds = 90
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path $PSScriptRoot -Parent
$restartScript = Join-Path $PSScriptRoot 'restart-iphone-testing.ps1'
$stateFile = Join-Path $PSScriptRoot '.testflight-watch-state.txt'
$workflow = 'ios-testflight.yml'

function Get-LatestRun {
    $json = gh run list --workflow $workflow --limit 1 `
        --json databaseId,status,conclusion,headBranch,displayTitle,createdAt 2>$null
    if (-not $json) {
        return $null
    }
    $runs = $json | ConvertFrom-Json
    if ($runs -is [array] -and $runs.Count -gt 0) {
        return $runs[0]
    }
    return $null
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error 'GitHub CLI (gh) is required. Install from https://cli.github.com/ and run gh auth login.'
    exit 1
}

Set-Location $repoRoot
$lastSeenId = $null
if (Test-Path $stateFile) {
    $lastSeenId = (Get-Content $stateFile -Raw).Trim()
}

$latest = Get-LatestRun
if ($latest -and -not $lastSeenId) {
    $lastSeenId = [string]$latest.databaseId
    $lastSeenId | Set-Content -Path $stateFile -Encoding ASCII -NoNewline
    Write-Host "Watching for new TestFlight uploads (baseline run $lastSeenId)."
} elseif ($latest) {
    Write-Host "Watching for new TestFlight uploads (last handled run $lastSeenId)."
} else {
    Write-Host "Watching for TestFlight workflow runs..."
}

while ($true) {
    try {
        $run = Get-LatestRun
        if ($run -and $run.status -eq 'completed' -and $run.conclusion -eq 'success') {
            $runId = [string]$run.databaseId
            if ($runId -ne $lastSeenId) {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host " TestFlight upload finished: $($run.displayTitle)" -ForegroundColor Cyan
                Write-Host " Run $runId @ $($run.createdAt)" -ForegroundColor Cyan
                Write-Host " Restarting START-IPHONE-TESTING..." -ForegroundColor Cyan
                Write-Host "========================================" -ForegroundColor Cyan
                & powershell -NoProfile -ExecutionPolicy Bypass -File $restartScript
                $lastSeenId = $runId
                $lastSeenId | Set-Content -Path $stateFile -Encoding ASCII -NoNewline
            }
        }
    } catch {
        Write-Host "Watch error: $_" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds $PollSeconds
}
