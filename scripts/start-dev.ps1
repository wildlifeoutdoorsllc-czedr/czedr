# One-shot local dev after reboot: preflight, MySQL (if used), API, Czedr_API30 emulator.
# Run:  .\start-dev.ps1
# Or:   powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Michaels Apps\czedr\scripts\start-dev.ps1"
param(
    [switch]$SkipEmulator,
    [switch]$SkipApi
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ps = 'powershell.exe'
$psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass')

Write-Host ""
Write-Host "=== Czedr dev stack ===" -ForegroundColor Cyan
Write-Host ""

if (-not $SkipEmulator) {
    & "$PSScriptRoot\preflight-emulator.ps1"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $SkipApi) {
    if (-not (Test-Path "$root\.env")) {
        Copy-Item "$root\.env.example" "$root\.env"
        if (Get-Command php -ErrorAction SilentlyContinue) {
            php "$root\scripts\generate-env-key.php"
        }
    }

    $mysqlScript = Join-Path $PSScriptRoot 'start-mysql.ps1'
    if (Test-Path $mysqlScript) {
        Write-Host 'Starting MySQL...' -ForegroundColor DarkGray
        & $mysqlScript
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'WARNING: MySQL failed to start. Login will not work until MySQL is running.' -ForegroundColor Yellow
            Write-Host '  Fix: run .\start-mysql.ps1 or start mysqld --console in an Admin window.' -ForegroundColor Yellow
        }
    }

    $on8080 = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
    if ($on8080) {
        Write-Host "API already listening on :8080" -ForegroundColor Green
    } else {
        Write-Host "Starting API in a new window (keep it open)..." -ForegroundColor Green
        Start-Process $ps -ArgumentList ($psArgs + @('-File', (Join-Path $PSScriptRoot 'start-php-server.ps1')))
        Start-Sleep -Seconds 2
        try {
            $null = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/v1/health' -UseBasicParsing -TimeoutSec 15
            Write-Host "API health: OK" -ForegroundColor Green
        } catch {
            Write-Host "API not ready yet - check the PHP window." -ForegroundColor Yellow
        }
    }
}

if (-not $SkipEmulator) {
    $emuRunning = Get-Process -Name 'qemu-system*', 'emulator' -ErrorAction SilentlyContinue
    if ($emuRunning) {
        Write-Host "Emulator already running." -ForegroundColor Green
    } else {
        Write-Host "Starting Czedr_API30 in a new window (boot may take 3-10 min)..." -ForegroundColor Green
        Start-Process $ps -ArgumentList ($psArgs + @('-File', (Join-Path $PSScriptRoot 'start-android-emulator.ps1')))
    }
}

Write-Host ""
Write-Host "After reboot you only need this script - hypervisor settings persist." -ForegroundColor DarkGray
Write-Host "Android API base: http://10.0.2.2:8080" -ForegroundColor DarkGray
Write-Host "iPhone TestFlight API: http://192.168.68.51:8080 (same Wi-Fi as this PC)" -ForegroundColor DarkGray
Write-Host "If System UI hangs: tap Wait, or run .\dismiss-emulator-bootanim.ps1" -ForegroundColor DarkGray
Write-Host ""
