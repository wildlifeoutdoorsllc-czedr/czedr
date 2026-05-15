# Verify PHP is compatible with local MySQL 8.4
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
    Write-Host "Starting MySQL..."
    & "$PSScriptRoot\start-mysql.ps1"
}

Write-Host ""
php "$PSScriptRoot\test-mysql.php"
exit $LASTEXITCODE
