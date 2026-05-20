# Credit $10,000 to Alice and Bob; show balances and REVENUE fee ledger.
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

try {
    $null = Invoke-RestMethod -Uri "http://127.0.0.1:8080/v1/health" -TimeoutSec 3
} catch {
    Write-Host "Start the API first: START-IPHONE-TESTING.cmd" -ForegroundColor Yellow
    exit 1
}

php "$PSScriptRoot\fund-test-accounts.php"
