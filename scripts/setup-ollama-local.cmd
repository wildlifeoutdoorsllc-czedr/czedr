@echo off
title Setup Ollama Local
echo.
echo ==============================
echo  Install / start Ollama local
echo ==============================
echo.

where winget >nul 2>nul
if errorlevel 1 (
  echo winget not found. Install Ollama manually from:
  echo https://ollama.com/download/windows
  goto :end
)

echo Installing Ollama (if not already installed)...
winget install -e --id Ollama.Ollama --accept-package-agreements --accept-source-agreements

echo.
echo Starting Ollama app...
start "" "C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\Ollama.exe"

echo.
echo Pulling default model: llama3.2
ollama pull llama3.2

echo.
echo Done. Test with:
echo   ollama run llama3.2 "hello"
echo.

:end
pause
