# Start MySQL + Czedr PHP API (+ optional Moov ACH)
$root = Split-Path $PSScriptRoot -Parent
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
    & "$PSScriptRoot\start-mysql.ps1"
}

if (-not (Test-Path "$root\.env")) {
    Copy-Item "$root\.env.example" "$root\.env"
    php "$root\scripts\generate-env-key.php"
}

Write-Host "Starting Czedr API on http://127.0.0.1:8080 ..."
Start-Process powershell -ArgumentList @(
    '-NoProfile', '-Command',
    "php -S 127.0.0.1:8080 -t `"$root\backend\public`" `"$root\backend\public\index.php`""
) -WindowStyle Minimized

Start-Sleep -Seconds 2
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/v1/health' -UseBasicParsing -TimeoutSec 5
    Write-Host "API health: $($r.Content)"
} catch {
    Write-Host "API not responding yet — check PHP process."
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Starting Moov ACH (optional) on http://127.0.0.1:8081 ..."
    Push-Location $root
    docker compose up -d moov-ach 2>$null
    Pop-Location
} else {
    Write-Host "Docker not found — skip Moov ACH (ACH export uses placeholder files)."
}

Write-Host "`nRun demo: php scripts\test-transfer-demo.php"
Write-Host "Run tests: php scripts\test-api.php"
