@echo off
title AI Interpreter
cd /d "%~dp0"

if not exist .env (
  echo Copy .env.example to .env and add OPENAI_API_KEY
  copy .env.example .env
)

python -m pip install -q -r requirements.txt 2>nul
python -m uvicorn interpreter.main:app --host 127.0.0.1 --port 8790
pause
