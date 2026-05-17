@echo off
title Czedr - iPhone testing setup
cd /d "%~dp0"

echo.
echo  ============================================
echo   Czedr - set up your PC for iPhone login
echo  ============================================
echo.
echo  Step 1: Allowing your iPhone to reach this PC (port 8080).
echo          If Windows asks, click YES.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure-iphone-api-ready.ps1"

echo.
echo  Step 2: Starting the Czedr server (keep this window open).
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-php-server.ps1"
