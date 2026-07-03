# Paste Google App Password once - writes MAIL_PASS on the VPS (no nano).
# Usage: double-click SET-GMAIL-APP-PASSWORD.cmd

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Czedr-SshDefaults.ps1")

$HostIP = $script:CzedrVpsHost
$User = $script:CzedrVpsUser
$SshKey = $script:CzedrSshKey
$RepoRoot = Split-Path $PSScriptRoot -Parent
$RemoteScript = "/var/www/czedr/scripts/update-mail-pass.sh"

if (-not (Test-Path $SshKey)) {
    Write-Host ""
    Write-Host "SSH key not found. Run MAKE-VPS-WORK.cmd once first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  Czedr - Gmail App Password setup" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. We can open Google App Passwords in your browser."
Write-Host "  2. Sign in as czedrapp@gmail.com and create a password named Czedr VPS."
Write-Host "  3. Paste the 16-character password here (spaces are OK)."
Write-Host ""

$open = Read-Host "Open https://myaccount.google.com/apppasswords now? (Y/n)"
if ($open -eq "" -or $open -match '^[Yy]') {
    Start-Process "https://myaccount.google.com/apppasswords"
    Write-Host ""
    Write-Host "  Create the app password in the browser, then return here." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "  Paste your Google App Password and press Enter." -ForegroundColor Yellow
Write-Host "  (You will see what you paste - that is normal in this window.)" -ForegroundColor DarkGray
$pass = (Read-Host "  App password").Trim()
$pass = $pass -replace '\s', ''

if ($pass.Length -lt 16) {
    Write-Host ""
    Write-Host "  That looks too short ($($pass.Length) characters). Google gives 16 letters." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  Uploading helper and saving password on the server..." -ForegroundColor Cyan

Invoke-CzedrScp -ScpArgs @(
    (Join-Path $PSScriptRoot "update-mail-pass.sh"),
    "${User}@${HostIP}:/var/www/czedr/scripts/update-mail-pass.sh"
) -Profile Quick | Out-Null

Invoke-CzedrSsh -RemoteCommand "chmod +x $RemoteScript" -Profile Quick | Out-Null

$stdinArgs = Get-CzedrSshBaseArgs -Profile Quick
$stdinArgs += "${User}@${HostIP}", "bash $RemoteScript"
$pass | & ssh @stdinArgs
if ($LASTEXITCODE -ne 0) { throw "Could not save MAIL_PASS on server." }

Write-Host ""
Write-Host "  Applying email settings and sending a test message..." -ForegroundColor Cyan

Invoke-CzedrSsh -RemoteCommand 'bash /var/www/czedr/scripts/setup-vps-email.sh' -BatchMode -Profile Deploy | Out-Null
Invoke-CzedrSsh -RemoteCommand 'cd /var/www/czedr && php scripts/test-mail.php czedrapp@gmail.com' -BatchMode -Profile Quick | Out-Null

Write-Host ""
Write-Host "  Done. Check czedrapp@gmail.com inbox (and Spam) for CZEDR test email." -ForegroundColor Green
Write-Host ""
