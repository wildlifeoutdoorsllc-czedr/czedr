@echo off
:: Install Android Emulator Hypervisor Driver (AEHD). Must run as Administrator.
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "AEHD=%LOCALAPPDATA%\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"
if not exist "%AEHD%\silent_install_safe.bat" (
    echo AEHD not found. Install "Android Emulator Hypervisor Driver" in SDK Manager.
    pause
    exit /b 1
)

echo Installing AEHD from:
echo   %AEHD%
cd /d "%AEHD%"
call silent_install_safe.bat

echo.
echo Starting aehd service...
sc.exe start aehd
sc.exe query aehd

echo.
echo If you see error 4294967201, AEHD conflicts with Hyper-V/WHPX.
echo Run repair-aehd-4294967201.cmd as Administrator instead, then reboot.
echo.
echo If STATE is RUNNING, reboot once then run preflight-emulator.cmd
pause
