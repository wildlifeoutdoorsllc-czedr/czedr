@echo off
:: Use WHPX instead of AEHD (when you need WSL2/Docker or AEHD gives 4294967201).
:: Run as Administrator, then REBOOT.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo === Switch emulator to WHPX only ===
echo.

set "AEHD=%LOCALAPPDATA%\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"

sc.exe stop aehd 2>nul
if exist "%AEHD%\silent_install.bat" (
    cd /d "%AEHD%"
    call silent_install.bat -u
)

echo Enabling Windows Hypervisor Platform...
dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart

sc.exe query aehd
echo.
echo Turn OFF Memory integrity if WHPX still crashes (VP exit code 4).
echo Reboot, then run: start-android-emulator-force.cmd
echo.
pause
