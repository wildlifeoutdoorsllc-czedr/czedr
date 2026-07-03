@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dismiss-emulator-bootanim.ps1"
pause
