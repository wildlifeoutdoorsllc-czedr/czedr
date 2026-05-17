# Allow inbound TCP 8080 so iPhones/Android on the same Wi-Fi can reach the Czedr API.
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$ruleName = 'Czedr API 8080'

$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Remove-NetFirewallRule -DisplayName $ruleName
}

New-NetFirewallRule `
    -DisplayName $ruleName `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 8080 `
    -Profile Any

Write-Host ""
Write-Host "Firewall rule added: $ruleName (TCP 8080, all network profiles)" -ForegroundColor Green
Write-Host "Restart the API if it is already running: scripts\start-php-server.ps1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "On iPhone Safari, open: http://YOUR_PC_LAN_IP:8080/v1/health" -ForegroundColor Yellow
Write-Host "(Use the LAN IP printed by start-php-server.ps1)" -ForegroundColor DarkGray
Write-Host ""
