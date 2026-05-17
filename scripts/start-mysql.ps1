# Start MySQL Server 8.4 without Windows service (dev use)
$mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.4\bin"
$myIni = "C:\ProgramData\MySQL\MySQL Server 8.4\my.ini"

if (Get-Process mysqld -ErrorAction SilentlyContinue) {
    Write-Host "MySQL is already running."
    exit 0
}

Start-Process -FilePath "$mysqlBin\mysqld.exe" -ArgumentList "--defaults-file=$myIni" -WindowStyle Hidden

$ready = $false
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    try {
        & "$mysqlBin\mysql.exe" -u root -e "SELECT 1" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    } catch { }
}
if (-not $ready) {
    Write-Error "MySQL did not become ready on port 3306. Check C:\ProgramData\MySQL\MySQL Server 8.4\Data\*.err"
    exit 1
}

& "$mysqlBin\mysql.exe" -u root -e "SELECT 'MySQL is ready' AS status, VERSION() AS version;"
