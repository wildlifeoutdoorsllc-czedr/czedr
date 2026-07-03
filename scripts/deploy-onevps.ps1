# Deploy Czedr to OneVPS from Windows (after one-time SSH key setup).
# Usage: powershell -File scripts\deploy-onevps.ps1
# Or double-click: MAKE-VPS-WORK.cmd

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Czedr-SshDefaults.ps1")

$HostIP = $script:CzedrVpsHost
$Port = $script:CzedrVpsPort
$User = $script:CzedrVpsUser
$SshKey = $script:CzedrSshKey
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
    return (Test-CzedrSshKeyAuth)
}

function Install-SshKeyOnServer {
    Write-Host ""
    Write-Host 'ONE-TIME SETUP - enter your OneVPS root password when asked.' -ForegroundColor Yellow
    Write-Host 'Copy password from OneVPS panel into Notepad, then right-click to paste.' -ForegroundColor Yellow
    Write-Host ""
    $scpArgs = Get-CzedrScpBaseArgs -Profile Quick
    $scpArgs += "${SshKey}.pub", "${User}@${HostIP}:/tmp/czedr_install_key.pub"
    & scp @scpArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Could not upload SSH key. Reset password in OneVPS panel; use port $Port."
    }
    $cmd = "umask 077; mkdir -p .ssh; touch .ssh/authorized_keys; grep -qF 'czedr-onevps-deploy' .ssh/authorized_keys || cat /tmp/czedr_install_key.pub >> .ssh/authorized_keys; chmod 700 .ssh; chmod 600 .ssh/authorized_keys; rm -f /tmp/czedr_install_key.pub"
    $sshArgs = Get-CzedrSshBaseArgs -Profile Quick
    $sshArgs += "${User}@${HostIP}", $cmd
    & ssh @sshArgs
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
Invoke-CzedrScp -ScpArgs @($archive, "${User}@${HostIP}:${remoteTar}") -Profile Deploy | Out-Null

Write-Step "Extracting and running deploy-on-server.sh"
$remote = 'set -e; mkdir -p /var/www/czedr; cd /var/www/czedr; tar xzf /tmp/czedr-deploy.tgz; chmod +x scripts/deploy-on-server.sh scripts/onevps-bootstrap.sh scripts/vps-audit-user.sh; bash scripts/deploy-on-server.sh'
Invoke-CzedrSsh -RemoteCommand $remote -Profile Deploy | Out-Null

Write-Host ""
Write-Host "Done. Open in browser: https://api.czedr.com/v1/health" -ForegroundColor Green
