# Switch Android emulator from AEHD to WHPX.
# WARNING: On this project, Czedr_API30 was stable with AEHD + swiftshader, NOT WHPX.
# Running this while AEHD is needed causes error 4294967201 or WHPX VP exit code 4.
# Prefer repair-aehd-4294967201.cmd unless you require WSL2/Docker hypervisor.
# Run as Administrator, then REBOOT.
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$aehdDir = "$env:LOCALAPPDATA\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"
$uninstall = Join-Path $aehdDir "silent_install.bat"

Write-Host "1. Enabling Windows Hypervisor Platform..." -ForegroundColor Cyan
$feature = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
if ($feature.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart -All | Out-Null
    Write-Host "   Enabled (reboot required)."
} else {
    Write-Host "   Already enabled."
}

if (Test-Path $uninstall) {
    Write-Host "2. Uninstalling AEHD driver (use WHPX instead)..." -ForegroundColor Cyan
    Push-Location $aehdDir
    & cmd /c "silent_install.bat -u"
    Pop-Location
    Write-Host "   AEHD uninstall attempted."
} else {
    Write-Host "2. AEHD installer not found; skip uninstall." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "REBOOT Windows, then run: .\scripts\start-android-emulator.ps1" -ForegroundColor Green
Write-Host "Verify with: emulator -accel-check  (should prefer WHPX)" -ForegroundColor DarkGray
