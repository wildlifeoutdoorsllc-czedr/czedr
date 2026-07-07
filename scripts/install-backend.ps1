# Apply Czedr backend schema to local MySQL (Saturn / ledger-only).
. (Join-Path $PSScriptRoot 'Czedr-RepoRoot.ps1')
$root = Get-CzedrRepoRoot
$mysql = "mysql"
if (Get-Command mysql -ErrorAction SilentlyContinue) { $mysql = "mysql" }
else { $mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" }

Write-Host "Creating database..."
Get-Content (Join-Path $root 'scripts\local-mysql-init.sql') | & $mysql -u root

Write-Host "Applying saturn schema..."
Get-Content (Join-Path $root 'database\schemas\saturn.sql') | & $mysql -u root

Write-Host "Running SQL migrations (tracked in schema_migrations)..."
if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    throw "PHP is required on PATH to run scripts\run-migrations.php (applies database/migrations)."
}
Push-Location -LiteralPath $root
try {
    php (Join-Path $root 'scripts\run-migrations.php')
    if ($LASTEXITCODE -ne 0) { throw "run-migrations.php exited with code $LASTEXITCODE" }
} finally {
    Pop-Location
}

Write-Host "Done. Copy .env.example to .env (no encryption key required for ledger-only)."
