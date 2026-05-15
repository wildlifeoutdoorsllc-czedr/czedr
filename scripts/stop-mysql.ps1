# Stop local mysqld process (dev use)
& "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqladmin.exe" -u root shutdown 2>$null
Start-Sleep -Seconds 2
if (Get-Process mysqld -ErrorAction SilentlyContinue) {
    Stop-Process -Name mysqld -Force
}
Write-Host "MySQL stopped."
