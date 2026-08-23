# Route a message through the AI Interpreter with a persona system prompt.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('atlas', 'nova', 'forge')]
    [string]$Persona,
    [string]$Message,
    [switch]$NewSession
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$personaFile = Join-Path $root "integrations\ai_shared_space\personas\$Persona.md"
if (-not (Test-Path $personaFile)) {
    throw "Missing persona file: $personaFile"
}

$system = Get-Content $personaFile -Raw
$sessionFile = Join-Path $root ".cursor\interpreter-session-$Persona.txt"

& (Join-Path $PSScriptRoot 'start-ai-interpreter.ps1')
Start-Sleep -Seconds 2

$cli = Join-Path $root 'ai-interpreter\cli.py'
if (-not (Test-Path $cli)) { throw "Missing $cli" }

function Invoke-Cli([string[]]$Args) {
    $out = & python $cli @Args 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($out | Out-String) }
    return ($out | Out-String).Trim()
}

$sid = $null
if (-not $NewSession -and (Test-Path $sessionFile)) {
    $sid = (Get-Content $sessionFile -Raw).Trim()
}
if (-not $sid) {
    $title = "Czedr $Persona"
    $sid = Invoke-Cli @('new', '--title', $title, '--system', $system)
    $dir = Split-Path $sessionFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Set-Content -Path $sessionFile -Value $sid -NoNewline
}

if (-not $Message) {
    $Message = Read-Host "Message for $Persona"
}
if (-not $Message.Trim()) { throw 'Empty message' }

Write-Host "Persona: $Persona | Session: $sid" -ForegroundColor Cyan
Invoke-Cli @('ask', $Message, '--session', $sid) | ForEach-Object { $_ }
