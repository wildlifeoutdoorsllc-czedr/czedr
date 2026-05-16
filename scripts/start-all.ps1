# Start MySQL + Czedr PHP API
$root = Split-Path $PSScriptRoot -Parent
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
    & "$PSScriptRoot\start-mysql.ps1"
}

if (-not (Test-Path "$root\.env")) {
    Copy-Item "$root\.env.example" "$root\.env"
    php "$root\scripts\generate-env-key.php"
}

Write-Host "Starting Czedr API on http://0.0.0.0:8080 (localhost + LAN) ..."
Start-Process powershell -ArgumentList @(
    '-NoProfile', '-Command',
    "Set-Location `"$root\backend\public`"; php -S 0.0.0.0:8080 -t `"$root\backend\public`" `"$root\backend\public\index.php`""
) -WindowStyle Minimized

Start-Sleep -Seconds 2
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/v1/health' -UseBasicParsing -TimeoutSec 5
    Write-Host "API health: $($r.Content)"
} catch {
    Write-Host "API not responding yet — check PHP process."
}

Write-Host "`nRun demo: php scripts\test-transfer-demo.php"
Write-Host "Run tests: php scripts\test-api.php"
