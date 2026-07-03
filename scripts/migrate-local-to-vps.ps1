# Migrate Czedr from this PC to OneVPS (DB + files + production config).
# Requires SSH key from MAKE-VPS-WORK.cmd (~/.ssh/id_ed25519_czedr_onevps).
# Usage: powershell -File scripts\migrate-local-to-vps.ps1

param(
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Czedr-SshDefaults.ps1")

$RepoRoot = Split-Path $PSScriptRoot -Parent
$SshKey = $script:CzedrSshKey
$HostIP = $script:CzedrVpsHost
$Port = $script:CzedrVpsPort
$User = $script:CzedrVpsUser

if (-not (Test-Path $SshKey)) {
    throw "SSH key missing. Run MAKE-VPS-WORK.cmd once first."
}

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

Write-Step "Deploy latest code to VPS"
if (-not $SkipDeploy) {
    & "$RepoRoot\scripts\deploy-onevps.ps1"
} else {
    Write-Host "Skipped (SkipDeploy)" -ForegroundColor DarkGray
}

Write-Step "Export local saturn database"
$dump = Join-Path $env:TEMP "czedr-saturn-migrate.sql"
if (Test-Path $dump) { Remove-Item $dump -Force }
$mysqldump = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqldump.exe"
if (-not (Test-Path $mysqldump)) {
    $found = (where.exe mysqldump 2>$null | Select-Object -First 1)
    if ($found) { $mysqldump = $found }
}
if (-not (Test-Path $mysqldump)) { throw "mysqldump not found" }
& $mysqldump -u root --single-transaction --routines --triggers saturn | Set-Content -Path $dump -Encoding utf8
$size = (Get-Item $dump).Length
Write-Host "Dump size: $([math]::Round($size / 1MB, 2)) MB"

Write-Step "Upload database dump"
Invoke-CzedrScp -ScpArgs @($dump, "${User}@${HostIP}:/tmp/czedr-saturn-migrate.sql") -Profile Deploy | Out-Null

Write-Step "Upload profile storage (if any)"
$storage = Join-Path $RepoRoot "backend\storage"
if (Test-Path $storage) {
    Invoke-CzedrScp -ScpArgs @("-r", $storage, "${User}@${HostIP}:/var/www/czedr/backend/") -Profile Deploy | Out-Null
}

Write-Step "Import database on VPS"
Invoke-CzedrScp -ScpArgs @(
    (Join-Path $RepoRoot "scripts\import-db-on-vps.sh"),
    "${User}@${HostIP}:/tmp/czedr-import.sh"
) -Profile Deploy | Out-Null
Invoke-CzedrSsh -RemoteCommand "bash /tmp/czedr-import.sh /tmp/czedr-saturn-migrate.sql" -BatchMode -Profile Deploy | Out-Null

Write-Step "Apply production Caddy (api + marketing placeholder)"
$caddy = @'
api.czedr.com {
    reverse_proxy 127.0.0.1:8080
}

czedr.com, www.czedr.com {
    respond "Czedr — coming soon. API: https://api.czedr.com/v1/health" 200
}
'@
$caddyPath = Join-Path $env:TEMP "Caddyfile"
Set-Content -Path $caddyPath -Value $caddy -Encoding utf8
Invoke-CzedrScp -ScpArgs @($caddyPath, "${User}@${HostIP}:/etc/caddy/Caddyfile") -Profile Quick | Out-Null
Invoke-CzedrSsh -RemoteCommand 'systemctl reload caddy' -BatchMode -Profile Quick | Out-Null

Write-Host ""
Write-Host "Migration complete." -ForegroundColor Green
Write-Host "  API:  https://api.czedr.com/v1/health"
Write-Host "  Site: https://czedr.com"
Write-Host "  Next: install TestFlight build 111 when ready (production API)"
