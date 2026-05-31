# Deploy Czedr to OneVPS from Windows (after one-time SSH key setup).
# Usage: powershell -File scripts\deploy-onevps.ps1
# Or double-click: MAKE-VPS-WORK.cmd

$ErrorActionPreference = "Stop"

$HostIP = "91.220.203.91"
$Port = 22122
$User = "root"
$SshKey = Join-Path $env:USERPROFILE ".ssh\id_ed25519_czedr_onevps"
$RepoRoot = Split-Path $PSScriptRoot -Parent

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Ensure-SshKey {
    $sshDir = Split-Path $SshKey -Parent
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }
    if (-not (Test-Path $SshKey)) {
        Write-Step "Creating SSH key (no passphrase) for OneVPS"
        ssh-keygen -t ed25519 -f $SshKey -N '""' -C "czedr-onevps-deploy"
    }
}

function Test-SshKeyAuth {
    $out = & ssh -p $Port -i $SshKey -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new `
        "${User}@${HostIP}" "echo OK" 2>&1
    return ($LASTEXITCODE -eq 0)
}

function Install-SshKeyOnServer {
    Write-Host ""
    Write-Host 'ONE-TIME SETUP - enter your OneVPS root password when asked.' -ForegroundColor Yellow
    Write-Host 'Copy password from OneVPS panel into Notepad, then right-click to paste.' -ForegroundColor Yellow
    Write-Host ""
    & scp -P $Port -o StrictHostKeyChecking=accept-new "${SshKey}.pub" "${User}@${HostIP}:/tmp/czedr_install_key.pub"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not upload SSH key. Reset password in OneVPS panel; use port $Port."
    }
    $cmd = "umask 077; mkdir -p .ssh; touch .ssh/authorized_keys; grep -qF 'czedr-onevps-deploy' .ssh/authorized_keys || cat /tmp/czedr_install_key.pub >> .ssh/authorized_keys; chmod 700 .ssh; chmod 600 .ssh/authorized_keys; rm -f /tmp/czedr_install_key.pub"
    & ssh -p $Port -o StrictHostKeyChecking=accept-new "${User}@${HostIP}" $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "SSH key install failed. Reset password in OneVPS panel and use port $Port."
    }
}

function Build-DeployArchive {
    $staging = Join-Path $env:TEMP "czedr-deploy-staging"
    $tar = Join-Path $env:TEMP "czedr-deploy.tgz"
    if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
    New-Item -ItemType Directory -Path $staging | Out-Null

    foreach ($name in @("backend", "config", "database", "scripts", "marketing")) {
        $src = Join-Path $RepoRoot $name
        if (-not (Test-Path $src)) { throw "Missing $src" }
        if ($name -eq "config") {
            $destConfig = Join-Path $staging "config"
            New-Item -ItemType Directory -Path $destConfig -Force | Out-Null
            Get-ChildItem $src -File | Where-Object { $_.Name -ne "database.local.php" } | Copy-Item -Destination $destConfig -Force
        } else {
            Copy-Item -Path $src -Destination (Join-Path $staging $name) -Recurse -Force
        }
    }
    Copy-Item (Join-Path $RepoRoot ".env.production.example") (Join-Path $staging ".env.production.example") -Force
    $localDb = Join-Path $staging "config\database.local.php"
    if (Test-Path $localDb) { Remove-Item $localDb -Force }

    if (Test-Path $tar) { Remove-Item $tar -Force }
    Push-Location $staging
    & tar -czf $tar .
    Pop-Location
    if (-not (Test-Path $tar)) { throw "Failed to create $tar" }
    return $tar
}

Write-Host "Czedr OneVPS deploy" -ForegroundColor Green
Write-Host "Repo: $RepoRoot"
Write-Host "Server: ${User}@${HostIP}:${Port}"

Ensure-SshKey

if (-not (Test-SshKeyAuth)) {
    Install-SshKeyOnServer
    if (-not (Test-SshKeyAuth)) {
        throw "SSH key auth still failing after install."
    }
    Write-Host 'SSH key installed - future deploys will not ask for a password.' -ForegroundColor Green
}

Write-Step 'Packaging API (backend, config, database, scripts)'
$archive = Build-DeployArchive
$remoteTar = "/tmp/czedr-deploy.tgz"

Write-Step "Uploading to server"
& scp -P $Port -i $SshKey -o StrictHostKeyChecking=accept-new $archive "${User}@${HostIP}:${remoteTar}"

Write-Step "Extracting and running deploy-on-server.sh"
$remote = 'set -e; mkdir -p /var/www/czedr; cd /var/www/czedr; tar xzf /tmp/czedr-deploy.tgz; chmod +x scripts/deploy-on-server.sh scripts/onevps-bootstrap.sh; bash scripts/deploy-on-server.sh'
& ssh -p $Port -i $SshKey -o StrictHostKeyChecking=accept-new "${User}@${HostIP}" $remote

Write-Host ""
Write-Host "Done. Open in browser: https://api.czedr.com/v1/health" -ForegroundColor Green
