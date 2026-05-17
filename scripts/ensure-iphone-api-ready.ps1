# Ensures Windows allows iPhones on the LAN to reach the Czedr API on port 8080.
$ErrorActionPreference = 'SilentlyContinue'
$ruleName = 'Czedr API 8080'

function Test-FirewallReady {
    $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue |
        Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' }
    if (-not $rule) { return $false }
    $profiles = $rule | Select-Object -ExpandProperty Profile
    return ($profiles -contains 'Any' -or ($profiles -contains 'Public' -and $profiles -contains 'Private'))
}

function Install-FirewallRule {
    $existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existing) {
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    }
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort 8080 `
        -Profile Any | Out-Null
}

if (-not (Test-FirewallReady)) {
    try {
        Install-FirewallRule
        Write-Host "Firewall: opened port 8080 for all network types." -ForegroundColor Green
    } catch {
        Write-Host "Firewall: elevation required — approving the Windows prompt fixes iPhone login." -ForegroundColor Yellow
        $scriptPath = Join-Path $PSScriptRoot 'allow-lan-api-firewall.ps1'
        Start-Process powershell -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath
        ) | Out-Null
    }
} else {
    Write-Host "Firewall: port 8080 already allowed." -ForegroundColor DarkGray
}

$wifi = Get-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wifi -and $wifi.NetworkCategory -eq 'Public') {
    try {
        Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Private -ErrorAction Stop
        Write-Host "Wi-Fi: set to Private (easier for phone access)." -ForegroundColor Green
    } catch {
        Write-Host "Wi-Fi: still Public — firewall rule above must include Public (it does)." -ForegroundColor DarkYellow
    }
}
