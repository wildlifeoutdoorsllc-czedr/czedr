@echo off
title Czedr - Deploy to OneVPS
cd /d "%~dp0"
echo.
echo  This will deploy Czedr to your VPS at api.czedr.com
echo.
echo  FIRST TIME ONLY: you will paste your OneVPS root password once.
echo  After that, deploys run without asking again.
echo.
echo  Need the password? OneVPS panel -^> your VPS -^> root password reset
echo  SSH port is 22122 (not 22)
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy-onevps.ps1"
echo.
if errorlevel 1 (
  echo.
  echo  Deploy failed. Try: scripts\ssh-onevps.cmd to test login manually.
  echo  Help: docs\ONEVPS-SSH-LOGIN.md and docs\SUPPORT-HANDOFF-ONEVPS.md
)
pause
