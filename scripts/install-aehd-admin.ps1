# Reinstall/start Android Emulator Hypervisor Driver (AEHD). Run as Administrator.
#Requires -RunAsAdministrator

$aehdDir = "$env:LOCALAPPDATA\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"
$installer = Join-Path $aehdDir "silent_install_safe.bat"
if (-not (Test-Path $installer)) {
    $installer = Join-Path $aehdDir "silent_install.bat"
}

if (-not (Test-Path $installer)) {
    Write-Host "AEHD not found. Install via SDK Manager: Android Emulator Hypervisor Driver (AEHD)." -ForegroundColor Red
    exit 1
}

Write-Host "Installing AEHD from: $aehdDir" -ForegroundColor Cyan
Push-Location $aehdDir
& cmd /c (Split-Path -Leaf $installer)
Pop-Location

Start-Sleep -Seconds 2
$s = Get-Service -Name "aehd" -ErrorAction SilentlyContinue
if ($s) {
    if ($s.Status -ne "Running") { Start-Service aehd -ErrorAction SilentlyContinue }
    Write-Host "AEHD service: $((Get-Service aehd).Status)" -ForegroundColor $(if ((Get-Service aehd).Status -eq "Running") { "Green" } else { "Yellow" })
}

Write-Host ""
Write-Host "Reboot Windows, then:" -ForegroundColor Green
Write-Host "  cd D:\CZEDR\scripts" -ForegroundColor DarkGray
Write-Host "  .\preflight-emulator.ps1" -ForegroundColor DarkGray
Write-Host "  .\start-android-emulator.ps1" -ForegroundColor DarkGray
