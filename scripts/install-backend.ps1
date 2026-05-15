# Apply Czedr secure backend schemas to local MySQL
$root = Split-Path $PSScriptRoot -Parent
$mysql = "mysql"
if (Get-Command mysql -ErrorAction SilentlyContinue) { $mysql = "mysql" }
else { $mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" }

$files = @(
    "$root\scripts\local-mysql-init.sql",
    "$root\database\schemas\saturn.sql"
)
$planets = @("mercury", "venus", "earth", "mars", "jupiter")
foreach ($p in $planets) {
    $files += "$root\database\schemas\planet_vault.sql"
}

Write-Host "Creating databases..."
& $mysql -u root -e "SOURCE $($root -replace '\\','/')/scripts/local-mysql-init.sql" 2>&1 | Out-Null
Get-Content "$root\scripts\local-mysql-init.sql" | & $mysql -u root

Write-Host "Applying saturn schema..."
Get-Content "$root\database\schemas\saturn.sql" | & $mysql -u root

foreach ($p in $planets) {
    Write-Host "Applying vault schema on $p..."
    @("USE $p;", (Get-Content "$root\database\schemas\planet_vault.sql" -Raw)) | & $mysql -u root
}

Write-Host "Creating planet users..."
Get-Content "$root\scripts\setup-planet-users.sql" | & $mysql -u root

Write-Host "Applying payooze_id -> czedr_id migration..."
Get-Content "$root\database\migrations\003_rename_payooze_id_to_czedr_id.sql" | & $mysql -u root

Write-Host "Applying signup_challenges table..."
Get-Content "$root\database\migrations\004_signup_challenges.sql" | & $mysql -u root

Write-Host "Done. Copy .env.example to .env and run: php scripts/generate-env-key.php"
