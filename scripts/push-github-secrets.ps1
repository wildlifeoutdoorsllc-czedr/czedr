# Push TestFlight secrets to GitHub (requires gh auth with repo scope).
# Usage: .\push-github-secrets.ps1 [-IssuerId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx']

param(
    [string]$IssuerId,
    [string]$Repo = "wildlifeoutdoorsllc-czedr/czedr",
    [string]$P8Path = "$env:USERPROFILE\Downloads\AuthKey_579ABG6V64.p8",
    [string]$P12Path,
    [string]$P12PasswordPath
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Czedr-RepoRoot.ps1')
$repoRoot = Get-CzedrRepoRoot
if (-not $P12Path) { $P12Path = Join-Path $repoRoot 'secrets\czedr-dist.p12' }
if (-not $P12PasswordPath) { $P12PasswordPath = Join-Path $repoRoot 'secrets\p12-export-password.txt' }

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Install GitHub CLI: winget install GitHub.cli" -ForegroundColor Red
    exit 1
}
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Run: gh auth login   (token needs repo scope for secrets)" -ForegroundColor Red
    exit 1
}

foreach ($p in @($P8Path, $P12Path, $P12PasswordPath)) {
    if (-not (Test-Path $p)) { throw "Missing file: $p" }
}

if (-not $IssuerId) {
    $IssuerId = Read-Host "APPSTORE_ISSUER_ID (UUID from App Store Connect API page)"
}
if ([string]::IsNullOrWhiteSpace($IssuerId)) { throw "Issuer ID required" }

$keyId = ([IO.Path]::GetFileNameWithoutExtension($P8Path) -replace '^AuthKey_', '')
$p8Pem = Get-Content -Path $P8Path -Raw
$p12B64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $P12Path)))
$p12Pass = (Get-Content $P12PasswordPath -Raw).Trim()
$keychainPass = -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

Write-Host "Setting secrets on $Repo ..." -ForegroundColor Cyan
"RTBD3X8LWC" | gh secret set APPLE_TEAM_ID --repo $Repo
$IssuerId.Trim() | gh secret set APPSTORE_ISSUER_ID --repo $Repo
$keyId | gh secret set APPSTORE_KEY_ID --repo $Repo
$p8Pem | gh secret set APPSTORE_PRIVATE_KEY --repo $Repo
$p12B64 | gh secret set BUILD_CERTIFICATE_BASE64 --repo $Repo
$p12Pass | gh secret set P12_PASSWORD --repo $Repo
$keychainPass | gh secret set KEYCHAIN_PASSWORD --repo $Repo

Write-Host ""
Write-Host "Secrets set. Verify:" -ForegroundColor Green
gh secret list --repo $Repo
Write-Host ""
Write-Host "Next: GitHub Actions -> iOS TestFlight -> Run workflow" -ForegroundColor Cyan
