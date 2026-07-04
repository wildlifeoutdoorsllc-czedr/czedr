<#
.SYNOPSIS
    Add a TestFlight beta tester to CZEDR via the App Store Connect API.

.DESCRIPTION
    Creates (or finds) a beta tester by email and adds them to a TestFlight
    beta group -- no browser required. Uses JWT (ES256) authentication against
    the App Store Connect REST API.

    On first run you will be prompted for your APPSTORE_ISSUER_ID; it is saved
    to secrets\testflight-config.json so subsequent runs are one-liner.

.EXAMPLE
    .\add-testflight-tester.ps1 -Email "jlacy4203@icloud.com"

.EXAMPLE
    .\add-testflight-tester.ps1 -Email "jlacy4203@icloud.com" -FirstName "John" -LastName "Lacy"

.EXAMPLE
    .\add-testflight-tester.ps1 -Email "someone@example.com" -GroupName "External Testers"

.NOTES
    Requires Windows PowerShell 5.1+ (.NET Framework CNG) or PowerShell 7+.
    The .p8 key must be accessible locally (not just in GitHub secrets).
#>

param(
    [Parameter(Mandatory)]
    [string]$Email,

    [string]$FirstName,
    [string]$LastName,
    [string]$GroupName,

    [string]$P8Path,
    [string]$KeyId,
    [string]$IssuerId,

    [switch]$ListGroups
)

$ErrorActionPreference = 'Stop'
$root        = Split-Path $PSScriptRoot -Parent
$configPath  = Join-Path $root 'secrets\testflight-config.json'
$bundleId    = 'com.czedr.app'
$baseUrl     = 'https://api.appstoreconnect.apple.com'

# -- Config persistence -----------------------------------------------

function Load-Config {
    if (Test-Path $configPath) {
        return Get-Content $configPath -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-Config([hashtable]$cfg) {
    $dir = Split-Path $configPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $cfg | ConvertTo-Json | Set-Content $configPath -Encoding utf8
    Write-Host "  Config saved -> $configPath" -ForegroundColor DarkGray
}

# -- Resolve auth parameters -------------------------------------------

$config = Load-Config

# P8 path
if (-not $P8Path) {
    if ($config -and $config.P8Path -and (Test-Path $config.P8Path)) {
        $P8Path = $config.P8Path
    } else {
        $default = Join-Path $env:USERPROFILE 'Downloads\AuthKey_579ABG6V64.p8'
        if (Test-Path $default) {
            $P8Path = $default
        } else {
            $P8Path = Read-Host 'Path to your AuthKey_*.p8 file'
        }
    }
}
if (-not (Test-Path $P8Path)) {
    throw "P8 key not found: $P8Path`nDownload from App Store Connect > Users & Access > Integrations > App Store Connect API."
}

# Key ID (derived from filename if not supplied)
if (-not $KeyId) {
    if ($config -and $config.KeyId) {
        $KeyId = $config.KeyId
    } else {
        $KeyId = [IO.Path]::GetFileNameWithoutExtension($P8Path) -replace '^AuthKey_', ''
    }
}
if ([string]::IsNullOrWhiteSpace($KeyId)) { throw 'Could not determine Key ID from filename. Pass -KeyId explicitly.' }

# Issuer ID
if (-not $IssuerId) {
    if ($config -and $config.IssuerId) {
        $IssuerId = $config.IssuerId
    } else {
        Write-Host ''
        Write-Host 'Find your Issuer ID at:' -ForegroundColor Yellow
        Write-Host '  App Store Connect > Users and Access > Integrations > App Store Connect API' -ForegroundColor DarkGray
        Write-Host '  (UUID shown at the top of the page)' -ForegroundColor DarkGray
        Write-Host ''
        $IssuerId = Read-Host 'APPSTORE_ISSUER_ID'
    }
}
if ([string]::IsNullOrWhiteSpace($IssuerId)) { throw 'Issuer ID is required.' }

Save-Config @{ P8Path = $P8Path; KeyId = $KeyId; IssuerId = $IssuerId }

# -- JWT generation (ES256 via CNG) ------------------------------------

function ConvertTo-Base64Url([byte[]]$Bytes) {
    [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-AscJwt {
    $pem = Get-Content $P8Path -Raw
    $pem = $pem -replace '-----BEGIN PRIVATE KEY-----', '' `
                -replace '-----END PRIVATE KEY-----', '' `
                -replace '\s', ''
    $keyBytes = [Convert]::FromBase64String($pem)

    $cngKey = [Security.Cryptography.CngKey]::Import(
        $keyBytes,
        [Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob
    )
    $ecdsa = New-Object Security.Cryptography.ECDsaCng($cngKey)

    $header  = "{`"alg`":`"ES256`",`"kid`":`"$KeyId`",`"typ`":`"JWT`"}"
    $now     = [long]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    $exp     = $now + 1200
    $payload = "{`"iss`":`"$IssuerId`",`"iat`":$now,`"exp`":$exp,`"aud`":`"appstoreconnect-v1`"}"

    $hdrB64  = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($header))
    $plB64   = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($payload))

    $toSign  = [Text.Encoding]::UTF8.GetBytes("$hdrB64.$plB64")
    $sig     = $ecdsa.SignData($toSign, [Security.Cryptography.HashAlgorithmName]::SHA256)
    $sigB64  = ConvertTo-Base64Url $sig

    $ecdsa.Dispose()
    $cngKey.Dispose()

    return "$hdrB64.$plB64.$sigB64"
}

# -- API helper --------------------------------------------------------

function Invoke-Asc {
    param(
        [string]$Method = 'GET',
        [string]$Path,
        [string]$Body,
        [string]$Token
    )
    $headers = @{
        Authorization  = "Bearer $Token"
        'Content-Type' = 'application/json'
    }
    $params = @{
        Method          = $Method
        Uri             = "$baseUrl$Path"
        Headers         = $headers
        UseBasicParsing = $true
    }
    if ($Body) {
        $params.Body = [Text.Encoding]::UTF8.GetBytes($Body)
    }
    try {
        return Invoke-RestMethod @params
    }
    catch {
        $status = $null
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
            $reader = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errBody = $reader.ReadToEnd()
            $reader.Close()
        }
        if ($status -eq 409) {
            return @{ _conflict = $true; _body = $errBody }
        }
        Write-Host "  API error ($status): $errBody" -ForegroundColor Red
        throw $_
    }
}

# -- Main --------------------------------------------------------------

Write-Host ''
Write-Host '=== Czedr: Add TestFlight Tester ===' -ForegroundColor Cyan
Write-Host "  Email:  $Email" -ForegroundColor White
if ($FirstName -or $LastName) {
    Write-Host "  Name:   $FirstName $LastName" -ForegroundColor White
}
Write-Host "  Key ID: $KeyId" -ForegroundColor DarkGray
Write-Host ''

# 1. JWT
Write-Host 'Generating JWT...' -ForegroundColor DarkGray
$jwt = New-AscJwt
Write-Host '  JWT OK' -ForegroundColor Green

# 2. Find app
Write-Host "Finding app ($bundleId)..." -ForegroundColor DarkGray
$apps = Invoke-Asc -Path "/v1/apps?filter[bundleId]=$bundleId" -Token $jwt
if (-not $apps.data -or $apps.data.Count -eq 0) {
    throw "App $bundleId not found in App Store Connect."
}
$appId   = $apps.data[0].id
$appName = $apps.data[0].attributes.name
Write-Host "  App: $appName ($appId)" -ForegroundColor Green

# 3. Find beta group
Write-Host 'Finding beta groups...' -ForegroundColor DarkGray
$groups = Invoke-Asc -Path "/v1/apps/$appId/betaGroups" -Token $jwt
if (-not $groups.data -or $groups.data.Count -eq 0) {
    throw 'No beta groups found. Create one in App Store Connect > TestFlight first.'
}

if ($ListGroups) {
    Write-Host ''
    Write-Host 'Available beta groups:' -ForegroundColor Yellow
    foreach ($g in $groups.data) {
        $kind = if ($g.attributes.isInternalGroup) { 'internal' } else { 'external' }
        Write-Host "  - $($g.attributes.name) ($kind) [$($g.id)]" -ForegroundColor White
    }
    Write-Host ''
    Write-Host 'Re-run with -GroupName "Name" to target a specific group.' -ForegroundColor DarkGray
    return
}

$targetGroup = $null
if ($GroupName) {
    $targetGroup = $groups.data | Where-Object { $_.attributes.name -eq $GroupName } | Select-Object -First 1
    if (-not $targetGroup) {
        Write-Host "Group '$GroupName' not found. Available:" -ForegroundColor Red
        foreach ($g in $groups.data) {
            Write-Host "  - $($g.attributes.name)" -ForegroundColor Yellow
        }
        throw "Beta group '$GroupName' not found."
    }
} else {
    $external = $groups.data | Where-Object { -not $_.attributes.isInternalGroup }
    if ($external) {
        $targetGroup = $external | Select-Object -First 1
    } else {
        $targetGroup = $groups.data | Select-Object -First 1
    }
}

$groupId    = $targetGroup.id
$groupLabel = $targetGroup.attributes.name
$isInternal = $targetGroup.attributes.isInternalGroup

if ($isInternal) {
    Write-Host "  Warning: '$groupLabel' is an internal group. The tester must also be" -ForegroundColor Yellow
    Write-Host '           an App Store Connect user with a Developer role.' -ForegroundColor Yellow
}
Write-Host "  Group: $groupLabel ($(if ($isInternal) {'internal'} else {'external'}))" -ForegroundColor Green

# 4. Check if tester already exists
Write-Host 'Checking for existing tester...' -ForegroundColor DarkGray
$encodedEmail = [Uri]::EscapeDataString($Email)
$existing = Invoke-Asc -Path "/v1/betaTesters?filter[email]=$encodedEmail" -Token $jwt
$testerId = $null

if ($existing.data -and $existing.data.Count -gt 0) {
    $testerId = $existing.data[0].id
    Write-Host "  Tester exists ($testerId)" -ForegroundColor Yellow

    Write-Host "Adding to group '$groupLabel'..." -ForegroundColor DarkGray
    $addBody = @{
        data = @(
            @{ type = 'betaTesters'; id = $testerId }
        )
    } | ConvertTo-Json -Depth 3 -Compress
    $addResult = Invoke-Asc -Method POST `
        -Path "/v1/betaGroups/$groupId/relationships/betaTesters" `
        -Body $addBody -Token $jwt
    if ($addResult._conflict) {
        Write-Host '  Already in this group' -ForegroundColor Yellow
    } else {
        Write-Host '  Added to group' -ForegroundColor Green
    }
} else {
    Write-Host 'Creating tester and adding to group...' -ForegroundColor DarkGray
    $attrs = @{ email = $Email }
    if ($FirstName) { $attrs.firstName = $FirstName }
    if ($LastName)  { $attrs.lastName  = $LastName }

    $createPayload = @{
        data = @{
            type       = 'betaTesters'
            attributes = $attrs
            relationships = @{
                betaGroups = @{
                    data = @(
                        @{ type = 'betaGroups'; id = $groupId }
                    )
                }
            }
        }
    } | ConvertTo-Json -Depth 5

    $result = Invoke-Asc -Method POST -Path '/v1/betaTesters' -Body $createPayload -Token $jwt
    if ($result._conflict) {
        Write-Host '  Tester may already exist (409). Retrying lookup...' -ForegroundColor Yellow
        $jwt2 = New-AscJwt
        $retry = Invoke-Asc -Path "/v1/betaTesters?filter[email]=$encodedEmail" -Token $jwt2
        if ($retry.data -and $retry.data.Count -gt 0) {
            $testerId = $retry.data[0].id
            $addBody = @{ data = @(@{ type = 'betaTesters'; id = $testerId }) } | ConvertTo-Json -Depth 3 -Compress
            Invoke-Asc -Method POST `
                -Path "/v1/betaGroups/$groupId/relationships/betaTesters" `
                -Body $addBody -Token $jwt2 | Out-Null
            Write-Host "  Found and added existing tester ($testerId)" -ForegroundColor Green
        } else {
            throw 'Tester creation returned 409 but lookup found nothing. Check App Store Connect manually.'
        }
    } else {
        $testerId = $result.data.id
        Write-Host "  Tester created ($testerId)" -ForegroundColor Green
    }
}

Write-Host ''
Write-Host "Done! Apple will email $Email with TestFlight instructions." -ForegroundColor Green
Write-Host 'They install the TestFlight app, accept the invite, and install Czedr.' -ForegroundColor DarkGray
Write-Host ''
