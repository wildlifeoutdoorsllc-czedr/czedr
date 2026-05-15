# Local PHP dev server for Czedr API (secure backend)
$root = Split-Path $PSScriptRoot -Parent
$docRoot = Join-Path $root "backend\public"
Set-Location $docRoot
Write-Host "Czedr API: http://127.0.0.1:8080/v1/health"
Write-Host "Document root: $docRoot"
php -S 127.0.0.1:8080 -t $docRoot "$docRoot\index.php"
