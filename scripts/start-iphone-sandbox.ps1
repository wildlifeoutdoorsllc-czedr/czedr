# Start Czedr API so your iPhone on the same Wi-Fi can reach it + open setup info.
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
if (-not $lanIp) { $lanIp = 'YOUR_PC_IP' }

$existing = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    $pid = $existing.OwningProcess | Select-Object -First 1
    Write-Host "Stopping existing listener on 8080 (PID $pid)..."
    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Czedr iPhone sandbox" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PC LAN IP:     $lanIp" -ForegroundColor Green
Write-Host "iPhone Safari: http://${lanIp}:8080/sandbox" -ForegroundColor Yellow
Write-Host "Setup JSON:    http://${lanIp}:8080/v1/dev/setup" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. iPhone and PC must be on the SAME Wi-Fi."
Write-Host "2. Allow Windows Firewall for PHP (port 8080) if prompted."
Write-Host "3. Keep this window open while testing."
Write-Host ""

try {
    $ruleName = 'Czedr API 8080'
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Added firewall rule: $ruleName" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "Could not add firewall rule (run as Administrator if iPhone cannot connect)." -ForegroundColor DarkYellow
}

Set-Location $docRoot
php -S "0.0.0.0:8080" -t $docRoot "$docRoot\index.php"
