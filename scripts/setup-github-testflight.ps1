# Interactive helper: push GitHub Actions secrets for iOS TestFlight.
# Requires: GitHub CLI (gh) logged in, Apple Developer Program, App Store Connect API .p8,
#           and a distribution .p12 (usually created on a Mac).
#
# Usage:
#   gh auth login
#   cd D:\CZEDR\scripts
#   .\setup-github-testflight.ps1
#
# Docs: docs\TESTFLIGHT_SETUP.md

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

function Require-Gh {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "Install GitHub CLI: winget install GitHub.cli" -ForegroundColor Red
        Write-Host "Then run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
    $auth = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not logged in to GitHub. Run: gh auth login" -ForegroundColor Red
        exit 1
    }
    Write-Host "GitHub CLI: OK" -ForegroundColor Green
}

function Read-SecretPlain([string]$Prompt) {
    $v = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($v)) { throw "Value required for: $Prompt" }
    return $v.Trim()
}

function Read-SecretHidden([string]$Prompt) {
    $sec = Read-Host $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr).Trim() }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Set-GhSecret([string]$Name, [string]$Value) {
    $Value | gh secret set $Name --repo (gh repo view --json nameWithOwner -q .nameWithOwner)
    if ($LASTEXITCODE -ne 0) { throw "Failed to set secret: $Name" }
    Write-Host "  Set secret: $Name" -ForegroundColor Green
}

function Encode-FileBase64([string]$Path) {
    if (-not (Test-Path $Path)) { throw "File not found: $Path" }
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $Path)))
}

Write-Host ""
Write-Host "=== Czedr: GitHub + Apple TestFlight setup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "You must complete these in Apple portals first (this script cannot):" -ForegroundColor Yellow
Write-Host "  1. developer.apple.com — register bundle ID com.czedr.app" -ForegroundColor DarkGray
Write-Host "  2. appstoreconnect.apple.com — New App (iOS, Czedr, com.czedr.app)" -ForegroundColor DarkGray
Write-Host "  3. App Store Connect → Users and Access → API → download AuthKey_*.p8" -ForegroundColor DarkGray
Write-Host "  4. On a Mac: Apple Distribution cert → export as .p12 (see docs\TESTFLIGHT_SETUP.md)" -ForegroundColor DarkGray
Write-Host ""

Require-Gh

$repo = gh repo view --json nameWithOwner -q .nameWithOwner
Write-Host "Repository: $repo" -ForegroundColor Cyan
Write-Host ""

$teamId = Read-SecretPlain "APPLE_TEAM_ID (10 chars, Developer → Membership)"
$issuerId = Read-SecretPlain "APPSTORE_ISSUER_ID (App Store Connect → Users and Access → Integrations)"
$keyId = Read-SecretPlain "APPSTORE_KEY_ID (from the .p8 filename, e.g. AuthKey_ABC123.p8 → ABC123)"

$p8Path = Read-SecretPlain "Full path to AuthKey_*.p8"
$p8Pem = Get-Content -Path $p8Path -Raw

$hasP12 = Read-Host "Do you have a distribution .p12 file? (y/n)"
if ($hasP12 -match '^[Yy]') {
    $p12Path = Read-SecretPlain "Full path to distribution.p12"
    $p12B64 = Encode-FileBase64 $p12Path
    $p12Password = Read-SecretHidden "P12_PASSWORD (export password)"
} else {
    Write-Host ""
    Write-Host "Without a .p12, the workflow will fail at code signing." -ForegroundColor Yellow
    Write-Host "Options: borrow a Mac, MacinCloud trial, or Apple Developer support docs." -ForegroundColor Yellow
    Write-Host "Re-run this script after you have the .p12." -ForegroundColor Yellow
    exit 2
}

$keychainPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
Write-Host "Generated KEYCHAIN_PASSWORD (random, for CI only)." -ForegroundColor DarkGray

Write-Host ""
Write-Host "Setting GitHub Actions secrets..." -ForegroundColor Cyan
Set-GhSecret 'APPLE_TEAM_ID' $teamId
Set-GhSecret 'APPSTORE_ISSUER_ID' $issuerId
Set-GhSecret 'APPSTORE_KEY_ID' $keyId
Set-GhSecret 'APPSTORE_PRIVATE_KEY' $p8Pem
Set-GhSecret 'BUILD_CERTIFICATE_BASE64' $p12B64
Set-GhSecret 'P12_PASSWORD' $p12Password
Set-GhSecret 'KEYCHAIN_PASSWORD' $keychainPassword

$setApi = Read-Host "Set optional variable CZEDR_API_BASE? (y/n)"
if ($setApi -match '^[Yy]') {
    $apiBase = Read-SecretPlain "API URL (e.g. http://192.168.1.10:8080 for PC on Wi-Fi)"
    gh variable set CZEDR_API_BASE --body $apiBase --repo $repo
    if ($LASTEXITCODE -ne 0) { throw 'Failed to set CZEDR_API_BASE variable' }
    Write-Host "  Set variable: CZEDR_API_BASE" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Next steps:" -ForegroundColor Green
Write-Host "  1. Push code: git push origin czedrmaster   (or your default branch)" -ForegroundColor DarkGray
Write-Host "  2. GitHub → Actions → iOS TestFlight → Run workflow" -ForegroundColor DarkGray
Write-Host "  3. For PC API on iPhone, use workflow input api_base_url = http://YOUR_LAN_IP:8080" -ForegroundColor DarkGray
Write-Host "  4. App Store Connect → TestFlight → add Internal Tester" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Verify secrets: gh secret list --repo $repo" -ForegroundColor DarkGray
Write-Host ""
