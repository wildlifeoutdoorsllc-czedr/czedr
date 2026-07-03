@echo off
title Czedr - Gmail App Password
cd /d "%~dp0"
echo.
echo  This saves your Google App Password on the server for you.
echo  You do NOT need to use nano or SSH yourself.
echo.
echo  You will need the 16-character password from:
echo  https://myaccount.google.com/apppasswords
echo  (sign in as czedrapp@gmail.com)
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\set-gmail-app-password.ps1"
echo.
pause
