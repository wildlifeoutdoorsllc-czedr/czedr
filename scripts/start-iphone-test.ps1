# PC prep for TestFlight on a real iPhone (same Wi-Fi). No emulator.
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent

function Get-LanIP {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object -ExpandProperty IPAddress -First 1
    if ($ip) { return $ip }
    return 'YOUR_PC_LAN_IP'
}

Write-Host ''
Write-Host '=== Czedr iPhone TestFlight prep ===' -ForegroundColor Cyan
Write-Host ''

& (Join-Path $PSScriptRoot 'start-mysql.ps1')
if ($LASTEXITCODE -ne 0) {
    Write-Host 'MySQL must be running for login. Fix start-mysql.ps1 errors above.' -ForegroundColor Red
    exit 1
}

$on8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if (-not $on8080) {
    Write-Host 'Starting API...' -ForegroundColor Green
    Start-Process powershell -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $PSScriptRoot 'start-php-server.ps1')
    )
    Start-Sleep -Seconds 3
}

$lan = Get-LanIP
try {
    $h = Invoke-WebRequest -Uri "http://${lan}:8080/v1/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "API health on LAN: OK ($($h.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "API not reachable at http://${lan}:8080 - check firewall / PHP window." -ForegroundColor Red
    exit 1
}

Set-Location $root
php (Join-Path $PSScriptRoot 'seed-test-accounts.php')

Write-Host ''
Write-Host 'TestFlight on iPhone (you do this):' -ForegroundColor Yellow
Write-Host '  1. Install newest Czedr build in TestFlight'
Write-Host '  2. Settings > Privacy > Local Network > Czedr > ON'
Write-Host "  3. Safari test: http://${lan}:8080/v1/health"
Write-Host '  4. Sign in: bob@test.czedr / TestPass1234!'
Write-Host ''
Write-Host "If TestFlight still points at old API, wait for CI build with CZEDR_API_BASE=http://${lan}:8080" -ForegroundColor DarkGray
Write-Host 'Keep this PC awake and the API window open while testing.' -ForegroundColor DarkGray
Write-Host ''
