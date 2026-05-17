@echo off
cd /d "%~dp0scripts"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\restart-iphone-testing.ps1"
