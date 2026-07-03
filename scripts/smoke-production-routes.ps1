# Quick production route smoke (no credentials).
# Usage: powershell -File scripts\smoke-production-routes.ps1
# Expect: health 200; /v1/me and /v1/funding/status return 401 (auth), NOT 404.

$ErrorActionPreference = "Stop"
$Base = if ($env:CZEDR_SMOKE_BASE) { $env:CZEDR_SMOKE_BASE.TrimEnd("/") } else { "https://api.czedr.com" }

function Get-RouteStatus {
    param([string]$Path)
    try {
        $r = Invoke-WebRequest -Uri "$Base$Path" -Method GET -UseBasicParsing -TimeoutSec 20
        return [int]$r.StatusCode
    } catch {
        if ($_.Exception.Response) {
            return [int]$_.Exception.Response.StatusCode.value__
        }
        throw
    }
}

Write-Host "Czedr production route smoke" -ForegroundColor Cyan
Write-Host "Base: $Base"
Write-Host ""

$health = Get-RouteStatus "/v1/health"
if ($health -ne 200) {
    Write-Host "[FAIL] GET /v1/health -> HTTP $health (expected 200)" -ForegroundColor Red
    exit 1
}
Write-Host "[OK]   GET /v1/health -> 200" -ForegroundColor Green

$authRoutes = @(
    "/v1/me",
    "/v1/funding/status",
    "/v1/ledger/balance"
)

$failed = $false
foreach ($path in $authRoutes) {
    $code = Get-RouteStatus $path
    if ($code -eq 404) {
        Write-Host "[FAIL] GET $path -> 404 Not found (deploy repo is ahead of server)" -ForegroundColor Red
        $failed = $true
    } elseif ($code -eq 401) {
        Write-Host "[OK]   GET $path -> 401 (route registered; auth required)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] GET $path -> HTTP $code (expected 401 without token)" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($failed) {
    Write-Host "Fix: run MAKE-VPS-WORK.cmd (or scripts\deploy-onevps.ps1) then re-run this script." -ForegroundColor Yellow
    exit 1
}

Write-Host "All route checks passed." -ForegroundColor Green
