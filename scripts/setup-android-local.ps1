# Writes android/local.properties with sdk.dir (Android Studio SDK).
$root = Split-Path $PSScriptRoot -Parent
$android = Join-Path $root "android"
$localProps = Join-Path $android "local.properties"

$sdk = $env:ANDROID_HOME
if (-not $sdk -or -not (Test-Path $sdk)) {
    $sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
if (-not (Test-Path $sdk)) {
    Write-Host "Android SDK not found. Install Android Studio and SDK first." -ForegroundColor Red
    exit 1
}

$sdkEscaped = ($sdk -replace '\\', '/')
"sdk.dir=$sdkEscaped" | Set-Content -Path $localProps -Encoding ASCII
Write-Host "Wrote $localProps"
Write-Host "  sdk.dir=$sdkEscaped"
