@echo off
:: Fix AEHD StartService error 4294967201 (hypervisor conflict).
:: AEHD cannot run while Windows Hypervisor Platform / Hyper-V owns the CPU.
:: Run as Administrator, then REBOOT.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo === Repair AEHD error 4294967201 ===
echo.
echo Your PC has VBS/Hyper-V active. AEHD needs exclusive virtualization.
echo This script disables WHPX features and reinstalls AEHD.
echo (If you use WSL2 or Docker, you may prefer WHPX instead - see repair-whpx-only.cmd)
echo.
pause

set "AEHD=%LOCALAPPDATA%\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"

echo [1/4] Stopping AEHD...
sc.exe stop aehd 2>nul

echo [2/4] Disabling Windows Hypervisor Platform (conflicts with AEHD)...
dism.exe /online /disable-feature /featurename:HypervisorPlatform /norestart
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart

echo [3/4] Reinstalling AEHD driver...
if not exist "%AEHD%\silent_install.bat" (
    echo ERROR: AEHD not in SDK. Install via SDK Manager first.
    pause
    exit /b 1
)
cd /d "%AEHD%"
call silent_install.bat -u
call silent_install_safe.bat

echo [4/4] Starting AEHD service...
sc.exe start aehd
sc.exe query aehd

echo.
echo === Manual step (required) ===
echo Turn OFF Memory integrity:
echo   Windows Security - Device security - Core isolation - Memory integrity OFF
echo Then REBOOT.
echo.
echo After reboot run: preflight-emulator.cmd
echo.
pause
