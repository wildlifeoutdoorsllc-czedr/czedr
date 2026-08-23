@echo off
REM Start Jibber Talk locally (progress board for AIs + Michael)
cd /d "%~dp0jibber-talk"
if not exist .env (
  copy /Y .env.example .env >nul
)
python -m pip install -q -r requirements.txt
start "" http://127.0.0.1:8791/
python -m uvicorn jibber.main:app --host 127.0.0.1 --port 8791
pause
