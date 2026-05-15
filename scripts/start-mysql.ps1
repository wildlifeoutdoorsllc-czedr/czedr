# Start MySQL Server 8.4 without Windows service (dev use)
$mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.4\bin"
$myIni = "C:\ProgramData\MySQL\MySQL Server 8.4\my.ini"

if (Get-Process mysqld -ErrorAction SilentlyContinue) {
    Write-Host "MySQL is already running."
    exit 0
}

Start-Process -FilePath "$mysqlBin\mysqld.exe" -ArgumentList "--defaults-file=$myIni" -WindowStyle Hidden
Start-Sleep -Seconds 4

& "$mysqlBin\mysql.exe" -u root -e "SELECT 'MySQL is ready' AS status, VERSION() AS version;"
