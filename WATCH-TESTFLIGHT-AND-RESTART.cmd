@echo off
title Czedr - watch TestFlight and restart API
cd /d "%~dp0scripts"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\watch-testflight-and-restart.ps1"
