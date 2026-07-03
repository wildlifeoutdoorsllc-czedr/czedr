# If the emulator shows "Loading" stuck at ~42% but adb works, dismiss the boot splash.
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$adb = Join-Path $sdk "platform-tools\adb.exe"

$line = (& $adb devices 2>&1 | Select-String "emulator-\d+\s+device").Line
if (-not $line) {
    Write-Host "No emulator online. Start one first." -ForegroundColor Red
    exit 1
}

$id = ($line -split "\s+")[0]
$boot = (& $adb -s $id shell getprop sys.boot_completed 2>&1).ToString().Trim()
if ($boot -ne "1") {
    Write-Host "Android still booting (sys.boot_completed=$boot). Wait a few minutes." -ForegroundColor Yellow
    exit 1
}

& $adb -s $id root 2>$null | Out-Null
Start-Sleep -Seconds 2
& $adb -s $id shell setprop service.bootanim.exit 1 2>$null | Out-Null
& $adb -s $id shell stop bootanim 2>$null | Out-Null
Write-Host "Boot animation stopped on $id. If the window still shows 42%, close and run start-android-emulator.ps1 (not Studio Run)." -ForegroundColor Green
