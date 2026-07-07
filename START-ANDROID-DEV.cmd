@echo off
REM Czedr Android dev: API server + hints for Android Studio.
cd /d "%~dp0"
title Czedr Android dev

echo.
echo [1/2] Starting API on port 8080...
start "Czedr API" cmd /k "powershell -NoProfile -ExecutionPolicy Bypass -File \"%~dp0scripts\start-php-server.ps1\""

echo.
echo [2/2] Android Studio setup...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-android-local.ps1"

echo.
echo ========================================
echo  Next in Android Studio
echo ========================================
echo  1. Open folder:  %~dp0android
echo  2. File - Sync Project with Gradle Files
echo  3. Plug in phone USB debugging OR slow emulator Czedr_API30
echo     Phone API: http://LAN_IP:8080  (see API window)
echo     Emulator only: http://10.0.2.2:8080
echo     If emulator crashed PC: docs\ANDROID-PHYSICAL-DEVICE.md
echo.
echo  Test login: alice@test.czedr / TestPass1234!
echo ========================================
echo.
pause
