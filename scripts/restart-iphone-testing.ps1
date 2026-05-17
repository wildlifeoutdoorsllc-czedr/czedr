# Stop anything on 8080 and open START-IPHONE-TESTING in a new console window.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$launcher = Join-Path $root 'START-IPHONE-TESTING.cmd'

$existing = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    $pid8080 = ($existing | Select-Object -First 1).OwningProcess
    Write-Host "Stopping existing listener on 8080 (PID $pid8080)..."
    Stop-Process -Id $pid8080 -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

if (-not (Test-Path $launcher)) {
    Write-Error "Not found: $launcher"
    exit 1
}

Write-Host "Starting $launcher in a new window..."
Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', "`"$launcher`"" -WorkingDirectory $root
Write-Host "Done. Keep that window open while testing on your iPhone."
