@echo off
title Czedr - Emergency backup
cd /d "%~dp0"
echo.
echo  Backs up VPS + local database + secrets to:
echo  D:\CZEDR\backups\emergency-YYYYMMDD-HHMMSS\
echo.
echo  Keep the backup folder PRIVATE. Do not upload to public cloud unencrypted.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\backup-everything.ps1"
echo.
pause
