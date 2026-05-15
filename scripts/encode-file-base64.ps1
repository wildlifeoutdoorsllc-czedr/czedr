# Encode a file to base64 for GitHub Actions secrets (certificates, API keys).
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$bytes = [IO.File]::ReadAllBytes((Resolve-Path $Path))
$b64 = [Convert]::ToBase64String($bytes)
Write-Host "File: $Path"
Write-Host "Length: $($b64.Length) characters"
Write-Host ""
Write-Host "Copy into GitHub secret:"
Write-Host $b64
