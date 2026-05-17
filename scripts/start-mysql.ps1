# Start MySQL Server 8.4 without Windows service (dev use)
$mysqlBin = 'C:\Program Files\MySQL\MySQL Server 8.4\bin'
$myIni = 'C:\ProgramData\MySQL\MySQL Server 8.4\my.ini'
$mysqld = Join-Path $mysqlBin 'mysqld.exe'
$mysql = Join-Path $mysqlBin 'mysql.exe'

if (-not (Test-Path $mysqld)) {
    Write-Host "MySQL not found at $mysqld" -ForegroundColor Red
    exit 1
}

function Test-MySqlListening {
    $conn = Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue
    return $null -ne $conn
}

function Test-MySqlLogin {
    $out = & $mysql -u root --protocol=TCP -h 127.0.0.1 -e 'SELECT 1' 2>&1
    return $LASTEXITCODE -eq 0
}

if (Test-MySqlListening) {
    if (Test-MySqlLogin) {
        Write-Host 'MySQL is already running on port 3306.' -ForegroundColor Green
        exit 0
    }
}

$existing = Get-Process mysqld -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host 'Stopping stale mysqld process...' -ForegroundColor Yellow
    Stop-Process -Name mysqld -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

$errLog = Join-Path $env:TEMP 'czedr-mysqld.err'
if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }

Write-Host 'Starting mysqld...' -ForegroundColor DarkGray
$defaultsArg = '--defaults-file="' + $myIni + '"'
$proc = Start-Process -FilePath $mysqld -ArgumentList $defaultsArg `
    -WindowStyle Hidden -PassThru -RedirectStandardError $errLog

$ready = $false
for ($i = 0; $i -lt 25; $i++) {
    Start-Sleep -Seconds 2
    if ($proc.HasExited) {
        Write-Host "mysqld exited (code $($proc.ExitCode)). Recent log:" -ForegroundColor Red
        if (Test-Path $errLog) { Get-Content $errLog -Tail 15 }
        $dataErr = Get-ChildItem 'C:\ProgramData\MySQL\MySQL Server 8.4\Data\*.err' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($dataErr) {
            Write-Host "--- $($dataErr.FullName) ---" -ForegroundColor DarkGray
            Get-Content $dataErr.FullName -Tail 10
        }
        exit 1
    }
    if (Test-MySqlListening -and (Test-MySqlLogin)) {
        $ready = $true
        break
    }
}

if (-not $ready) {
    Write-Host 'MySQL did not become ready on port 3306 within 50 seconds.' -ForegroundColor Red
    Write-Host 'Try manually: & "' -NoNewline
    Write-Host $mysqld -NoNewline -ForegroundColor Yellow
    Write-Host '" --defaults-file="' -NoNewline
    Write-Host $myIni -NoNewline -ForegroundColor Yellow
    Write-Host '" --console' -ForegroundColor Yellow
    exit 1
}

& $mysql -u root -e "SELECT 'MySQL is ready' AS status, VERSION() AS version;"
Write-Host 'MySQL is ready.' -ForegroundColor Green
exit 0
