param(
    [string]$Message,
    [string]$Backend,
    [string]$Persona,
    [switch]$Broadcast,
    [switch]$NewSession,
    [string]$Title = "Cursor Session"
)

$ErrorActionPreference = "Stop"

if ($Persona) {
    $personaArgs = @('-Persona', $Persona)
    if ($Message) { $personaArgs += @('-Message', $Message) }
    if ($NewSession) { $personaArgs += '-NewSession' }
    & (Join-Path $PSScriptRoot 'start-ai-persona.ps1') @personaArgs
    exit $LASTEXITCODE
}

$root = Split-Path $PSScriptRoot -Parent
$aiDir = Join-Path $root "ai-interpreter"
$cli = Join-Path $aiDir "cli.py"
$sessionFile = Join-Path $root ".cursor\interpreter-session.txt"

if (-not (Test-Path $cli)) {
    Write-Error "Missing $cli. Run setup first."
}

if (-not $Message -and $args.Count -gt 0) {
    $Message = ($args -join " ")
}

$message = $Message.Trim()
if (-not $message) {
    Write-Error "Provide a message. Example: .\scripts\cursor-interpreter.ps1 -Message \"Hello world\""
}

function Invoke-CliRaw([string[]]$CliArgs) {
    $output = & python $cli @CliArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        $joined = ($output | Out-String).Trim()
        throw "Interpreter CLI failed: $joined"
    }
    return $output
}

function Get-OrCreateSessionId {
    if (-not $NewSession -and (Test-Path $sessionFile)) {
        $sid = (Get-Content $sessionFile -Raw).Trim()
        if ($sid) { return $sid }
    }
    $sid = ((Invoke-CliRaw @("new", "--title", $Title)) | Out-String).Trim()
    $sessionDir = Split-Path $sessionFile -Parent
    if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir | Out-Null }
    Set-Content -Path $sessionFile -Value $sid -NoNewline
    return $sid
}

$sessionId = Get-OrCreateSessionId

$cliArgs = @("ask", $message, "--session", $sessionId)
if ($Backend) {
    $cliArgs += @("--backend", $Backend)
}
if ($Broadcast) {
    $cliArgs += "--broadcast"
}

Write-Host "Session: $sessionId" -ForegroundColor Cyan
Invoke-CliRaw $cliArgs | ForEach-Object { $_ }
