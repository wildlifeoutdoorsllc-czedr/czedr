@echo off
title Czedr - iPhone testing setup
cd /d "%~dp0"

echo.
echo  ============================================
echo   Czedr - set up your PC for iPhone login
echo  ============================================
echo.
echo  Step 1: Windows will ask to allow port 8080.
echo          Click YES on the security prompt.
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"%~dp0allow-lan-api-firewall.ps1\"\"' -Wait"

echo.
echo  Step 2: Starting the Czedr server (keep this window open).
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-php-server.ps1"
