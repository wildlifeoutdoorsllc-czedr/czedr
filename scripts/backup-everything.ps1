# Emergency backup: VPS + local PC + repo metadata.
# Usage: powershell -File scripts\backup-everything.ps1
# Output: D:\CZEDR\backups\emergency-YYYYMMDD-HHMMSS\

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Czedr-SshDefaults.ps1")

$RepoRoot = Split-Path $PSScriptRoot -Parent
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutRoot = Join-Path $RepoRoot "backups\emergency-$Stamp"
$SshKey = $script:CzedrSshKey
$HostIP = $script:CzedrVpsHost
$Port = $script:CzedrVpsPort

New-Item -ItemType Directory -Path $OutRoot -Force | Out-Null
Write-Host "Emergency backup -> $OutRoot" -ForegroundColor Green

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

# --- Local MySQL ---
Write-Step "Local MySQL (saturn)"
$localSql = Join-Path $OutRoot "local-saturn.sql"
$mysqldump = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqldump.exe"
if (-not (Test-Path $mysqldump)) {
    $found = (where.exe mysqldump 2>$null | Select-Object -First 1)
    if ($found) { $mysqldump = $found }
}
if (Test-Path $mysqldump) {
    & $mysqldump -u root --single-transaction --routines --triggers saturn |
        Out-File -FilePath $localSql -Encoding utf8
    Write-Host "Local DB exported: local-saturn.sql"
} else {
    Write-Host "mysqldump not found - skipped local DB." -ForegroundColor Yellow
}

# --- Local secrets / config ---
Write-Step "Local config and secrets"
foreach ($rel in @(".env", "config\database.local.php", "config\database.vault.local.php")) {
    $src = Join-Path $RepoRoot $rel
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $OutRoot (Split-Path $rel -Leaf)) -Force
    }
}
if (Test-Path "$env:USERPROFILE\.ssh\id_ed25519_czedr_onevps") {
    New-Item -ItemType Directory -Path (Join-Path $OutRoot "ssh-key-backup") -Force | Out-Null
    Copy-Item "$env:USERPROFILE\.ssh\id_ed25519_czedr_onevps*" (Join-Path $OutRoot "ssh-key-backup") -Force
    Write-Host "SSH deploy key copied (keep this folder private)."
}

# --- Git snapshot ---
Write-Step "Git branch and recent commits"
Push-Location $RepoRoot
git rev-parse HEAD | Out-File (Join-Path $OutRoot "git-commit.txt")
git branch -vv | Out-File (Join-Path $OutRoot "git-branch.txt")
git log -5 --oneline | Out-File (Join-Path $OutRoot "git-log.txt")
git status -sb | Out-File (Join-Path $OutRoot "git-status.txt")
Pop-Location

# --- VPS backup ---
if (-not (Test-Path $SshKey)) {
    Write-Host "SSH key missing - skipped VPS backup." -ForegroundColor Yellow
} else {
    Write-Step "VPS full backup (database + secrets + app)"
    Invoke-CzedrScp -ScpArgs @(
        (Join-Path $RepoRoot "scripts\backup-vps-on-server.sh"),
        "root@${HostIP}:/tmp/czedr-backup.sh"
    ) -Profile Deploy | Out-Null
    $remotePath = (Invoke-CzedrSsh -RemoteCommand 'bash /tmp/czedr-backup.sh' -BatchMode -Profile Long | Out-String).Trim()
    Write-Host $remotePath
    if ($remotePath -match 'OK:(/var/backups/czedr/emergency-[0-9-]+)') {
        $vpsDir = $Matches[1]
        $vpsLocal = Join-Path $OutRoot "vps"
        New-Item -ItemType Directory -Path $vpsLocal -Force | Out-Null
        Invoke-CzedrScp -ScpArgs @("-r", "root@${HostIP}:${vpsDir}/*", "${vpsLocal}/") -Profile Long | Out-Null
        Write-Host "VPS backup downloaded."
    } else {
        Write-Host "VPS backup may have failed - check SSH." -ForegroundColor Yellow
    }
}

# --- Manifest ---
Write-Step "Writing manifest"
$manifest = @(
    "Czedr emergency backup",
    "Created: $Stamp",
    "PC folder: $OutRoot",
    "",
    "RESTORE HINTS",
    "VPS DB: gunzip -c saturn.sql.gz | mysql -u root saturn",
    'Local DB: mysql -u root saturn < local-saturn.sql',
    "VPS app: tar xzf czedr-app.tgz -C /var/www",
    "Secrets: czedr-deploy-secrets file in vps folder",
    "",
    "DO NOT commit this folder to git. Copy to USB or encrypted cloud."
)
$manifest | Set-Content (Join-Path $OutRoot "RESTORE.txt") -Encoding UTF8

Write-Host ""
Write-Host "Backup complete." -ForegroundColor Green
Write-Host "  $OutRoot"
Write-Host ""
Write-Host "Copy this folder to a USB drive or encrypted cloud when you can." -ForegroundColor Yellow
