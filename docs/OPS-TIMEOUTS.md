# Czedr — operation timeouts (SSH, deploy, Cursor)

**For:** Michael, contractors, and Cursor agents working on OneVPS.

**Why:** A stuck SSH or SQL command should **fail in minutes**, not run for **24 hours**. Hung jobs look “busy” but produce no useful output.

**Policy:** These are the **repo defaults**. You do not need to pick different numbers unless counsel, your bank, or a vendor contract requires something stricter. If a job legitimately needs longer, use profile **Long** (2 hr) — not “unlimited.”

---

## Why these values (standards we follow)

| Principle | How Czedr applies it |
|-----------|----------------------|
| **Fail fast on probes** | Health checks and `echo OK` use **15s connect** + **~2 min** total — standard for automation that should answer immediately. |
| **OpenSSH keepalives** | `ServerAliveInterval` + `ServerAliveCountMax` detect dead TCP sessions without waiting for the OS default (often hours). |
| **Batch jobs get a budget** | Deploy/migrate **30 min** matches typical CI/deploy expectations; if deploy routinely exceeds that, fix the server — don’t raise the cap to 24h. |
| **Hard ceiling on “unknown”** | **2 hours** for large backup/SCP is a common ops max for scripted work; anything still running after that is treated as **stuck**, not “slow.” |
| **Human sessions differ** | `CONNECT-TO-VPS.cmd` stays interactive — no PowerShell job cap while **you** are at the keyboard. |

This matches common practice for small VPS + SSH automation (not banking batch windows, which can be longer under contract).

---

## Time limits (defaults)

| Profile | Max wall time | Typical use |
|---------|----------------|-------------|
| **Quick** | **2 minutes** | `echo OK`, health check, one-line SQL via `vps-audit-user.sh` |
| **Deploy** | **30 minutes** | `deploy-onevps.ps1`, migrate, Gmail setup, medium SCP |
| **Long** | **2 hours** | Full `backup-everything.ps1` VPS download |

These are enforced in **`scripts/Czedr-SshDefaults.ps1`** (PowerShell job timeout **and** OpenSSH `ConnectTimeout` / `ServerAlive*`).

---

## SSH options (all automated scripts)

Every `ssh` / `scp` from repo scripts should use:

| Option | Quick | Deploy / Long |
|--------|-------|----------------|
| `ConnectTimeout` | 15s | 30s |
| `ServerAliveInterval` | 30s | 60s |
| `ServerAliveCountMax` | 4 (~2 min dead) | 30 (~30 min) or 120 (~2 hr) |
| Port | **22122** | **22122** |
| Key | `%USERPROFILE%\.ssh\id_ed25519_czedr_onevps` | same |

**Interactive login** (`CONNECT-TO-VPS.cmd`): same connect + keepalive options; you can still type as long as you need.

---

## Scripts that use shared timeouts

| Script | Profile |
|--------|---------|
| `scripts/deploy-onevps.ps1` | Deploy |
| `scripts/migrate-local-to-vps.ps1` | Deploy |
| `scripts/backup-everything.ps1` | Long (VPS part) |
| `scripts/set-gmail-app-password.ps1` | Quick / Deploy |
| `scripts/Czedr-SshDefaults.ps1` | (library) |

---

## Safe VPS queries (avoid hung agents)

**Do not** run nested PowerShell → SSH → bash → MySQL with heavy quoting from Cursor.

**Do:**

1. SSH in: `CONNECT-TO-VPS.cmd`
2. Run on server:

```bash
bash /var/www/czedr/scripts/vps-audit-user.sh alice@test.czedr
```

Or from PC (Quick profile, 2 min cap):

```powershell
. .\scripts\Czedr-SshDefaults.ps1
Invoke-CzedrSsh -RemoteCommand 'bash /var/www/czedr/scripts/vps-audit-user.sh rita@test.czedr' -BatchMode -Profile Quick
```

---

## Cursor / AI agents

When an agent runs SSH or long shell work:

| Task type | Stop after |
|-----------|------------|
| Single check | **2 minutes** |
| Deploy / backup | **30 minutes** (use **Long** / 2 hr only if copying large backups) |
| Unknown / stuck | **2 hours absolute max** — then report failure and simplify the command |

**Never** leave a background shell waiting overnight without a timeout.

See also: `.cursor/rules/czedr-ops-timeouts.mdc`

---

## If something times out

1. Read the error — “timed out after 120s” vs “Connection refused”.
2. Test SSH: `CONNECT-TO-VPS.cmd` or Quick `Invoke-CzedrSsh … 'echo OK'`.
3. For SQL/audit: use **`vps-audit-user.sh`** on the server.
4. For deploy: re-run `MAKE-VPS-WORK.cmd`; check `https://api.czedr.com/v1/health`.

---

## Related docs

- `docs/SUPPORT-HANDOFF-ONEVPS.md` — server access, deploy
- `docs/ONEVPS-SSH-LOGIN.md` — login help
- `CONNECT-TO-VPS.cmd` — interactive SSH
