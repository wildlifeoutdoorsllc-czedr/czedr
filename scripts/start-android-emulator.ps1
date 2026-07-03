# Start API 30 emulator tuned for Intel Celeron (no AVX) + AEHD/WHPX.
# After fix-emulator-hypervisor.ps1: reboot once, then WHPX may work without AEHD.
param(
    [ValidateSet("Pixel_7_API_34", "Czedr_API34", "Czedr_API30")]
    [string]$Avd = "Czedr_API30",
    [int]$BootTimeoutSec = 720,
    [switch]$Force
)

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$emu = Join-Path $sdk "emulator\emulator.exe"
$adb = Join-Path $sdk "platform-tools\adb.exe"

if (-not (Test-Path $emu)) {
    Write-Host "Emulator not found. Open android/ in Android Studio first." -ForegroundColor Red
    exit 1
}

$aehd = Get-Service -Name "aehd" -ErrorAction SilentlyContinue
if ($aehd -and $aehd.Status -eq "Running") {
    $Accel = "on"
} elseif ($Force) {
    Write-Host "WARN: AEHD not running; trying auto accel (-Force)." -ForegroundColor Yellow
    $Accel = "auto"
} else {
    Write-Host "AEHD hypervisor is not running. WHPX will likely crash (VP exit code 4)." -ForegroundColor Red
    Write-Host "Fix: right-click install-aehd-admin.cmd -> Run as administrator, reboot, then preflight-emulator.cmd" -ForegroundColor Yellow
    Write-Host "Or retry with: start-android-emulator.cmd -Force  (may still fail)" -ForegroundColor DarkGray
    exit 2
}

Get-Process -Name "qemu-system*", "emulator" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Starting $Avd (accel=$Accel, swiftshader GPU, cold boot, non-AVX CPU)..." -ForegroundColor Cyan
Write-Host "API base in app: http://10.0.2.2:8080" -ForegroundColor DarkGray
Write-Host "Boot can take 3-10 min on a Celeron. If stuck at 42%, wait or run dismiss-emulator-bootanim.ps1" -ForegroundColor DarkGray
Write-Host ""

$bootJob = Start-Job -ScriptBlock {
    param($Adb, $TimeoutSec)
    & $Adb kill-server 2>$null | Out-Null
    & $Adb start-server 2>$null | Out-Null
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $line = (& $Adb devices 2>&1 | Select-String "emulator-\d+\s+device").Line
        if ($line) {
            $id = ($line -split "\s+")[0]
            $boot = (& $Adb -s $id shell getprop sys.boot_completed 2>&1).ToString().Trim()
            if ($boot -eq "1") {
                & $Adb -s $id root 2>$null | Out-Null
                Start-Sleep -Seconds 2
                & $Adb -s $id shell setprop service.bootanim.exit 1 2>$null | Out-Null
                & $Adb -s $id shell stop bootanim 2>$null | Out-Null
                return "ready:$id"
            }
        }
        Start-Sleep -Seconds 5
    }
    return "timeout"
} -ArgumentList $adb, $BootTimeoutSec

& $emu -avd $Avd `
    -accel $Accel `
    -gpu swiftshader `
    -no-snapshot-load `
    -no-snapshot-save `
    -no-snapstorage `
    -no-boot-anim `
    -no-audio `
    -cores 1 `
    -memory 1024 `
    -qemu "-cpu" "max,avx=off,avx2=off,f16c=off,xsave=off"

$bootResult = Receive-Job $bootJob -ErrorAction SilentlyContinue
Remove-Job $bootJob -Force -ErrorAction SilentlyContinue
if ($bootResult -match "^ready:") {
    Write-Host "Boot helper finished for $($bootResult.Substring(6))." -ForegroundColor DarkGray
}
