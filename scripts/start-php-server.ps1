# Czedr API — PHP built-in server for local dev (Android emulator, devices on Wi‑Fi, browser).
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
Write-Host "Phone on same Wi‑Fi use API base: http://${lanIp}:8080" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Keep this window open while testing." -ForegroundColor DarkGray
Write-Host ""

$ruleName = 'Czedr API 8080'
$fwRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq 'True' }
if (-not $fwRule) {
    Write-Host ""
    Write-Host "WARNING: Windows Firewall is not open for port 8080." -ForegroundColor Red
    Write-Host "  iPhone login will fail until you run (as Administrator):" -ForegroundColor Yellow
    Write-Host "    scripts\allow-lan-api-firewall.cmd" -ForegroundColor Yellow
    Write-Host ""
    try {
        if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 -Profile Private,Domain -ErrorAction Stop | Out-Null
            Write-Host "Added firewall rule: $ruleName" -ForegroundColor Green
        }
    } catch {
        Write-Host "  (Could not auto-add rule — elevation required.)" -ForegroundColor DarkYellow
    }
}

Set-Location $docRoot
Write-Host "Document root: $docRoot" -ForegroundColor DarkGray
php -S "0.0.0.0:8080" -t $docRoot "$docRoot\index.php"
