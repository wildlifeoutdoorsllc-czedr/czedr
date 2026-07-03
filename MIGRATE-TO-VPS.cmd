@echo off
title Czedr - Migrate PC data to VPS
cd /d "%~dp0"
echo.
echo  This copies your local Czedr database and files to the VPS.
echo  The API will keep running at https://api.czedr.com
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\migrate-local-to-vps.ps1"
pause
