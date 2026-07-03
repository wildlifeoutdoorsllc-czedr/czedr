@echo off
REM Credit a user on the VPS by email. Example:
REM   FUND-USER.cmd wildlifeoutdoorsllc@gmail.com 1000
setlocal
cd /d "%~dp0"
if "%~2"=="" (
  echo Usage: FUND-USER.cmd email dollars
  echo Example: FUND-USER.cmd wildlifeoutdoorsllc@gmail.com 1000
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fund-user-vps.ps1" -Email "%~1" -Dollars "%~2"
exit /b %ERRORLEVEL%
