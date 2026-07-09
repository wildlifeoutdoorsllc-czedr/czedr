# Start AI Interpreter if not already running; used by START-AI-TEAM.cmd
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$aiDir = Join-Path $root 'ai-interpreter'
$health = 'http://127.0.0.1:8790/v1/health'

try {
    $r = Invoke-WebRequest -Uri $health -UseBasicParsing -TimeoutSec 2
    if ($r.StatusCode -eq 200) { exit 0 }
} catch {}

Start-Process cmd.exe -ArgumentList '/k', "cd /d `"$aiDir`" && START-INTERPRETER.cmd"
