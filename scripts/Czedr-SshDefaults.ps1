# Shared SSH/SCP defaults for Czedr OneVPS automation.
# Dot-source from other scripts: . "$PSScriptRoot\Czedr-SshDefaults.ps1"

$script:CzedrVpsHost = '91.220.203.91'
$script:CzedrVpsPort = 22122
$script:CzedrVpsUser = 'root'
$script:CzedrSshKey = Join-Path $env:USERPROFILE '.ssh\id_ed25519_czedr_onevps'

# Max wall-clock time before we stop a stuck SSH/SCP (seconds).
$script:CzedrSshMaxSeconds = @{
    Quick  = 120    # health check, echo, one SQL line
    Deploy = 1800   # deploy, migrate, backup (30 min)
    Long   = 7200   # large copy / full backup (2 hours)
}

function Get-CzedrSshBaseArgs {
  param(
    [switch]$BatchMode,
    [ValidateSet('Quick', 'Deploy', 'Long')]
    [string]$Profile = 'Quick'
  )

  $opts = switch ($Profile) {
    'Quick' {
      @(
        '-o', 'ConnectTimeout=15',
        '-o', 'ServerAliveInterval=30',
        '-o', 'ServerAliveCountMax=4'
      )
    }
    'Deploy' {
      @(
        '-o', 'ConnectTimeout=30',
        '-o', 'ServerAliveInterval=60',
        '-o', 'ServerAliveCountMax=30'
      )
    }
    'Long' {
      @(
        '-o', 'ConnectTimeout=30',
        '-o', 'ServerAliveInterval=60',
        '-o', 'ServerAliveCountMax=120'
      )
    }
  }

  $args = @(
    '-p', $script:CzedrVpsPort,
    '-i', $script:CzedrSshKey
  ) + $opts + @('-o', 'StrictHostKeyChecking=accept-new')

  if ($BatchMode) { $args += '-o', 'BatchMode=yes' }
  return $args
}

function Get-CzedrScpBaseArgs {
  param(
    [ValidateSet('Quick', 'Deploy', 'Long')]
    [string]$Profile = 'Deploy'
  )

  $connect = if ($Profile -eq 'Quick') { 15 } else { 30 }
  $aliveMax = switch ($Profile) {
    'Quick' { 4 }
    'Deploy' { 30 }
    'Long' { 120 }
  }

  return @(
    '-P', $script:CzedrVpsPort,
    '-i', $script:CzedrSshKey,
    '-o', "ConnectTimeout=$connect",
    '-o', 'ServerAliveInterval=60',
    '-o', "ServerAliveCountMax=$aliveMax",
    '-o', 'StrictHostKeyChecking=accept-new'
  )
}

function Invoke-CzedrSsh {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RemoteCommand,
    [switch]$BatchMode,
    [ValidateSet('Quick', 'Deploy', 'Long')]
    [string]$Profile = 'Quick',
    [int]$MaxSeconds = 0,
    [switch]$AllowFailure
  )

  if ($MaxSeconds -le 0) { $MaxSeconds = $script:CzedrSshMaxSeconds[$Profile] }

  $sshArgs = Get-CzedrSshBaseArgs -BatchMode:$BatchMode -Profile $Profile
  $sshArgs += "${script:CzedrVpsUser}@${script:CzedrVpsHost}", $RemoteCommand

  $job = Start-Job -ScriptBlock {
    param($Args)
    $lines = & ssh @Args 2>&1 | ForEach-Object { $_.ToString() }
    [pscustomobject]@{ Lines = @($lines); Code = $LASTEXITCODE }
  } -ArgumentList (,$sshArgs)

  $done = Wait-Job $job -Timeout $MaxSeconds
  if (-not $done) {
    Stop-Job $job -Force -ErrorAction SilentlyContinue
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    throw "SSH timed out after ${MaxSeconds}s (profile $Profile). Command: $RemoteCommand"
  }

  $result = Receive-Job $job
  Remove-Job $job -Force

  if (-not $AllowFailure -and $result.Code -ne 0) {
    $text = ($result.Lines | Out-String).Trim()
    throw "SSH failed (exit $($result.Code)): $text"
  }

  return $result.Lines
}

function Invoke-CzedrScp {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$ScpArgs,
    [ValidateSet('Quick', 'Deploy', 'Long')]
    [string]$Profile = 'Deploy',
    [int]$MaxSeconds = 0,
    [switch]$AllowFailure
  )

  if ($MaxSeconds -le 0) { $MaxSeconds = $script:CzedrSshMaxSeconds[$Profile] }

  $base = Get-CzedrScpBaseArgs -Profile $Profile
  $all = $base + $ScpArgs

  $job = Start-Job -ScriptBlock {
    param($Args)
    $lines = & scp @Args 2>&1 | ForEach-Object { $_.ToString() }
    [pscustomobject]@{ Lines = @($lines); Code = $LASTEXITCODE }
  } -ArgumentList (,$all)

  $done = Wait-Job $job -Timeout $MaxSeconds
  if (-not $done) {
    Stop-Job $job -Force -ErrorAction SilentlyContinue
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    throw "SCP timed out after ${MaxSeconds}s (profile $Profile)."
  }

  $result = Receive-Job $job
  Remove-Job $job -Force
  if (-not $AllowFailure -and $result.Code -ne 0) {
    throw "SCP failed: $(($result.Lines | Out-String).Trim())"
  }
  return $result.Lines
}

function Test-CzedrSshKeyAuth {
  try {
    $null = Invoke-CzedrSsh -RemoteCommand 'echo OK' -BatchMode -Profile Quick -MaxSeconds 30
    return $true
  } catch {
    return $false
  }
}
