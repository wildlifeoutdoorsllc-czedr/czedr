# Check emulator hypervisor + GPU before starting Czedr_API30.
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$emu = Join-Path $sdk "emulator\emulator.exe"
$aehdDir = Join-Path $sdk "extras\google\Android_Emulator_Hypervisor_Driver"
$ok = $true

Write-Host "=== Emulator preflight ===" -ForegroundColor Cyan

if (-not (Test-Path $emu)) {
    Write-Host "FAIL: emulator.exe not found. Install Android SDK / open android/ in Studio." -ForegroundColor Red
    exit 1
}

$aehd = Get-Service -Name "aehd" -ErrorAction SilentlyContinue
if ($aehd -and $aehd.Status -eq "Running") {
    Write-Host "OK:   AEHD service is running (preferred on this PC)." -ForegroundColor Green
} elseif ($aehd) {
    Write-Host "WARN: AEHD installed but STOPPED. WHPX often crashes here (VP exit code 4)." -ForegroundColor Yellow
    Write-Host "      Fix: run install-aehd-admin.ps1 as Administrator, reboot, then start emulator." -ForegroundColor Yellow
    $ok = $false
} else {
    Write-Host "WARN: AEHD service not found." -ForegroundColor Yellow
    $ok = $false
}

Write-Host ""
Write-Host "Accel check:" -ForegroundColor Cyan
& $emu -accel-check 2>&1 | ForEach-Object { Write-Host "  $_" }

if (-not $ok) {
    Write-Host ""
    Write-Host "Start blocked until AEHD is running. See install-aehd-admin.ps1" -ForegroundColor Red
    exit 2
}

Write-Host ""
Write-Host "Preflight passed. Run: .\start-android-emulator.ps1" -ForegroundColor Green
exit 0
