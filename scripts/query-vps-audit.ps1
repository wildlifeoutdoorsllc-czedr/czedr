# Fetch recent audit_events for a user email from the VPS (2-minute timeout).
# Usage: powershell -File scripts\query-vps-audit.ps1 -Email alice@test.czedr

param(
    [Parameter(Mandatory = $true)]
    [string]$Email
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Czedr-SshDefaults.ps1')

if (-not (Test-Path $script:CzedrSshKey)) {
    throw 'SSH key missing. Run MAKE-VPS-WORK.cmd or CONNECT-TO-VPS.cmd setup first.'
}

$safe = $Email.Trim()
$quoted = "'" + ($safe -replace "'", "'\''") + "'"
$remote = "bash /var/www/czedr/scripts/vps-audit-user.sh $quoted"

Write-Host "Querying VPS audit log for $safe (max 2 minutes)..." -ForegroundColor Cyan
Invoke-CzedrSsh -RemoteCommand $remote -BatchMode -Profile Quick | ForEach-Object { Write-Host $_ }
