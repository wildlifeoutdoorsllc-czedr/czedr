# Create demo accounts for sandbox testing (run on your Windows PC).
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$health = $null
try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:8080/v1/health" -TimeoutSec 3
} catch {
    Write-Host "Starting API is required. Run in another window:" -ForegroundColor Yellow
    Write-Host "  cd $root\scripts" -ForegroundColor Cyan
    Write-Host "  .\start-php-server.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

php "$PSScriptRoot\seed-test-accounts.php"
