@echo off
title Czedr - AI Team (Atlas, Nova, Forge)
cd /d "%~dp0"
echo.
echo  Starting AI Interpreter...
start "AI Interpreter" cmd /k "cd /d \"%~dp0ai-interpreter\" && call START-INTERPRETER.cmd"
timeout /t 4 /nobreak >nul
start http://127.0.0.1:8790/
echo.
echo  ========================================
echo   AI Team
echo  ========================================
echo.
echo  Atlas  - You are IN Cursor now. Say: Read docs/AI-TEAM.md
echo  Nova   - Double-click scripts\ai-nova.cmd
echo  Forge  - Cursor Agent mode, or scripts\ai-forge.cmd
echo  Jibber - Double-click START-JIBBER.cmd  (progress board :8791)
echo.
echo  Guide: docs\AI-TEAM.md
echo  Jibber: docs\JIBBER-TALK.md
echo  Inbox: integrations\ai_shared_space\inbox\
echo.
pause
