# Upload admin-fund-user.php and credit a member on production VPS.
param(
    [Parameter(Mandatory = $true)]
    [string]$Email,
    [Parameter(Mandatory = $true)]
    [double]$Dollars,
    [string]$Memo = 'Admin test fund'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Czedr-SshDefaults.ps1')

if (-not (Test-Path $script:CzedrSshKey)) {
    throw 'SSH key missing. Run MAKE-VPS-WORK.cmd or CONNECT-TO-VPS.cmd first.'
}

$localScript = Join-Path $PSScriptRoot 'admin-fund-user.php'
if (-not (Test-Path $localScript)) {
    throw "Missing $localScript"
}

$remote = '/var/www/czedr/scripts/admin-fund-user.php'
Write-Host "Uploading fund script to VPS..." -ForegroundColor Cyan
Invoke-CzedrScp -ScpArgs @($localScript, "${script:CzedrVpsUser}@${script:CzedrVpsHost}:${remote}") -Profile Quick | Out-Null

$safeEmail = $Email.Trim() -replace "'", "'\''"
$memoEsc = $Memo -replace "'", "'\''"
$cmd = "php $remote '$safeEmail' $Dollars '$memoEsc'"
Write-Host "Crediting `$$Dollars to $Email on production..." -ForegroundColor Cyan
Invoke-CzedrSsh -RemoteCommand $cmd -BatchMode -Profile Quick | ForEach-Object { Write-Host $_ }
