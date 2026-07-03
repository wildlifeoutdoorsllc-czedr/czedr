# Try emulator boot strategies; exits 0 if adb reports device online within timeout.
param(
    [string]$Avd = "Czedr_API34",
    [ValidateSet("off", "aehd", "whpx", "auto")]
    [string]$Accel = "aehd",
    [ValidateSet("off", "swiftshader", "guest")]
    [string]$Gpu = "off",
    [int]$TimeoutSec = 300
)

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$emu = Join-Path $sdk "emulator\emulator.exe"
$adb = Join-Path $sdk "platform-tools\adb.exe"

if (-not (Test-Path $emu)) { Write-Error "emulator.exe not found"; exit 2 }

Get-Process -Name "qemu-system*","emulator" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
Start-Sleep -Seconds 2
& $adb kill-server 2>$null | Out-Null
& $adb start-server 2>$null | Out-Null

$args = @(
    "-avd", $Avd,
    "-no-snapshot-load",
    "-no-snapshot-save",
    "-no-snapstorage",
    "-no-boot-anim",
    "-no-audio",
    "-cores", "1",
    "-memory", "1024",
    "-gpu", $Gpu
)
switch ($Accel) {
    "off"  { $args += "-no-accel" }
    "whpx" { $args += @("-accel", "whpx") }
    default { $args += @("-accel", "auto") }
}

$log = Join-Path $env:TEMP "czedr-emu-test-$Avd-$Accel-$Gpu.log"
Write-Host "Boot: $Avd accel=$Accel gpu=$Gpu (log: $log)" -ForegroundColor Cyan

$proc = Start-Process -FilePath $emu -ArgumentList $args -RedirectStandardOutput $log -RedirectStandardError $log -PassThru -WindowStyle Hidden

$deadline = (Get-Date).AddSeconds($TimeoutSec)
$online = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    if ($proc.HasExited) {
        Write-Host "Emulator exited early (code $($proc.ExitCode))" -ForegroundColor Red
        Get-Content $log -Tail 15 -EA SilentlyContinue
        exit 1
    }
    $out = & $adb devices 2>&1 | Out-String
    if ($out -match "emulator-\d+\s+device") {
        $online = $true
        break
    }
    $boot = & $adb shell getprop sys.boot_completed 2>&1
    if ($boot -match "1") { $online = $true; break }
}

if ($online) {
    Write-Host "SUCCESS: $Avd online (accel=$Accel gpu=$Gpu)" -ForegroundColor Green
    & $adb shell getprop ro.build.version.release 2>&1
    exit 0
}

Write-Host "TIMEOUT: device not online after ${TimeoutSec}s" -ForegroundColor Red
Get-Content $log -Tail 20 -EA SilentlyContinue
Stop-Process -Id $proc.Id -Force -EA SilentlyContinue
exit 1
