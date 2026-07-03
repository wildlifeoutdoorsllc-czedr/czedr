@echo off
title Czedr - VPS user audit log
cd /d "%~dp0"
set /p CZEDR_EMAIL=Account email (e.g. rita@test.czedr): 
if "%CZEDR_EMAIL%"=="" (
  echo No email entered.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\query-vps-audit.ps1" -Email "%CZEDR_EMAIL%"
echo.
pause
