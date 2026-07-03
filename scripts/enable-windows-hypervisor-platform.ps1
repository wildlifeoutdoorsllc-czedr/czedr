# Enable Windows Hypervisor Platform (helps Android emulator WHPX on Windows 10/11).
# Run once as Administrator, then reboot.
#Requires -RunAsAdministrator

$feature = "HypervisorPlatform"
$state = (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue).State
if ($state -eq "Enabled") {
    Write-Host "Windows Hypervisor Platform is already enabled."
    exit 0
}

Write-Host "Enabling Windows Hypervisor Platform..."
Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All
Write-Host "Done. Reboot required for WHPX."
