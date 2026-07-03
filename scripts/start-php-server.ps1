# Czedr API - PHP built-in server for local dev (Android emulator, devices on Wi-Fi, browser).
$root = Split-Path $PSScriptRoot -Parent
$docRoot = Join-Path $root "backend\public"

function Get-LanIPv4 {
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*' -and
            $_.PrefixOrigin -ne 'WellKnown'
        } |
        Select-Object -ExpandProperty IPAddress -First 1
}

$lanIp = Get-LanIPv4
if (-not $lanIp) { $lanIp = 'YOUR_PC_LAN_IP' }

$existing = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    $owningPid = ($existing | Select-Object -First 1).OwningProcess
    Write-Host "Stopping existing listener on 8080 (PID $owningPid)..."
    Stop-Process -Id $owningPid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Czedr API (local development)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This PC:     http://127.0.0.1:8080/v1/health" -ForegroundColor Green
Write-Host "PC LAN:      http://${lanIp}:8080/v1/health" -ForegroundColor Green
Write-Host "Sandbox:     http://${lanIp}:8080/sandbox" -ForegroundColor Yellow
Write-Host ""
Write-Host "Android emulator use API base:  http://10.0.2.2:8080" -ForegroundColor DarkGray
Write-Host "Phone on same Wi-Fi use API base: http://${lanIp}:8080" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Keep this window open while testing." -ForegroundColor DarkGray
Write-Host ""

& (Join-Path $PSScriptRoot 'ensure-iphone-api-ready.ps1')

Write-Host "Database: applying pending migrations..." -ForegroundColor DarkGray
$migrateScript = Join-Path $PSScriptRoot 'run-migrations.php'
if (Test-Path $migrateScript) {
    & php $migrateScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Database migrations failed - fix MySQL/.env, then restart." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

$apiUrlFile = Join-Path $root 'scripts\iphone-api-url.txt'
"http://${lanIp}:8080" | Set-Content -Path $apiUrlFile -Encoding UTF8

Set-Location $docRoot
Write-Host "Document root: $docRoot" -ForegroundColor DarkGray
$router = Join-Path $docRoot 'index.php'
php -S '0.0.0.0:8080' -t $docRoot $router
