# Czedr / OneVPS — Support handoff document

**Purpose:** Share this with OneVPS support, a contractor, or anyone helping deploy the Czedr API.  
**Owner:** Michael (non-technical user — prefers step-by-step guidance, not jargon).  
**Last updated:** June 2026

---

## 1. Summary

We are deploying **Czedr** (payment / fintech mobile app with PHP API backend) to a **OneVPS** virtual server. DNS for the API subdomain is configured. **SSH login has been problematic** — likely wrong port (22 vs 22122) and/or password issues. **The application is not deployed yet** on the server (no web server listening on 80/443).

---

## 2. Server details

| Item | Value |
|------|--------|
| Provider | OneVPS (onevps.cloud) |
| Hostname | `VM5413717769735819.onevps.cloud` |
| IPv4 | `91.220.203.91` |
| OS | Ubuntu 24.04 LTS |
| RAM | 2 GB |
| SSH port | **22122** (not default 22) |
| SSH user | `root` |
| Root password | Set by OneVPS at provisioning — **only in client panel / welcome email** (not stored in this repo) |

### Verified connectivity (external checks)

| Port | Status | Notes |
|------|--------|--------|
| **22122** | Open | SSH service responds |
| **22** | Closed | Using `ssh root@IP` without `-p 22122` causes **Connection refused** |
| **80** | Closed | Expected until Caddy/nginx is installed |
| **443** | Closed | Expected until TLS is configured |

---

## 3. DNS (GoDaddy)

Nameservers: `ns03.domaincontrol.com`, `ns04.domaincontrol.com` (GoDaddy DNS — not Cloudflare).

| Host | Intended purpose | Status (last check) |
|------|------------------|---------------------|
| `api.czedr.com` | Czedr API (production) | **A → 91.220.203.91** — correct |
| `czedr.com` (@) | Marketing / main site | May need **A → 91.220.203.91** if website on same VPS |
| `www.czedr.com` | Marketing | CNAME to `@` — depends on apex A record |

**Production API URL (target):** `https://api.czedr.com`

---

## 4. SSH login — known issues and fixes

### OneVPS instructions (from support email)

> Login: `ssh -p 22122 root@IP`  
> Type `yes` on first connect.  
> Password is not visible when typing — copy from panel into Notepad and paste carefully.  
> PuTTY: https://blog.onevps.com/how-to-connect-to-linux-from-windows-using-putty/  
> Port: **22122**

### Error guide

| Error | Likely cause | Fix |
|-------|--------------|-----|
| **Connection refused** | Connecting to port **22** instead of **22122** | Use `ssh -p 22122 root@91.220.203.91` or PuTTY port **22122** |
| **Permission denied** | Wrong or expired root password | Reset root password in OneVPS panel; wait 1–2 min; retry |
| **Connection timed out** | VPS stopped or network/firewall | Reboot VPS in panel; confirm IP |

### Windows helper (in repo)

- Script: `scripts/ssh-onevps.cmd`
- Guide: `docs/ONEVPS-SSH-LOGIN.md`

---

## 5. Automated deploy (from Michael’s PC)

Double-click **`MAKE-VPS-WORK.cmd`** in the repo root (or run `scripts\deploy-onevps.ps1`).

1. First run prompts for the **root password once** (port **22122**) to install an SSH key.
2. Script uploads the API and runs `scripts/deploy-on-server.sh` on the VPS.
3. Success: `https://api.czedr.com/v1/health` returns JSON with `"Status":"true"`.

Server secrets are stored at `/root/.czedr-deploy-secrets` on the VPS — back up securely.

---

## 6. Operation timeouts (do not run stuck jobs for 24 hours)

Automated SSH and deploy scripts now **stop on their own** if something hangs.

| Kind of task | Max wait | Where |
|--------------|----------|--------|
| Quick check (echo, audit SQL) | **2 minutes** | `scripts/Czedr-SshDefaults.ps1` profile **Quick** |
| Deploy / migrate / email setup | **30 minutes** | profile **Deploy** |
| Full VPS backup download | **2 hours** | profile **Long** |

**Full guide:** `docs/OPS-TIMEOUTS.md`  
**Shared library:** `scripts/Czedr-SshDefaults.ps1` (used by deploy, backup, migrate, Gmail setup)

### Windows helpers

| Tool | Purpose |
|------|---------|
| `CONNECT-TO-VPS.cmd` | Interactive SSH (with connect + keepalive options) |
| `QUERY-VPS-AUDIT.cmd` | Ask for an email → show last 50 audit lines from VPS (**2 min** cap) |

### On the server (safest for audit / SQL)

After `CONNECT-TO-VPS.cmd`:

```bash
bash /var/www/czedr/scripts/vps-audit-user.sh rita@test.czedr
```

Deploy once so that script exists on the VPS (`MAKE-VPS-WORK.cmd`).

### For Cursor agents

Rule file: `.cursor/rules/czedr-ops-timeouts.mdc` — agents must not leave SSH running overnight; use `vps-audit-user.sh` instead of nested quoted MySQL from PowerShell.

---

## 7. Requisites for Cursor / deploy

What **Cursor AI** (or any remote assistant) needs versus what **Michael** must do on his PC.

### Blockers — not available to Cursor

| Requisite | Status | Why it matters |
|-----------|--------|----------------|
| **SSH login** (`root@91.220.203.91`, port **22122**) | Not established | Without SSH, nothing can be installed or configured on the VPS. |
| **Root password or SSH key on Michael’s PC** | Not shared with AI | Password lives only in the OneVPS panel / welcome email. **Never paste the root password into Cursor chat.** |
| **OneVPS panel access** | Owner only | AI cannot reset password, reboot VM, or open VNC/console. |
| **Interactive SSH password entry** | Owner only | `MAKE-VPS-WORK.cmd` and `scripts/ssh-onevps.cmd` prompt on Michael’s machine; the agent cannot type there. |

### Already in place — no extra action for these

| Item | Value / location |
|------|------------------|
| Server IP | `91.220.203.91` |
| SSH port | **22122** (verified open externally) |
| API DNS | `api.czedr.com` → `91.220.203.91` |
| Deploy automation | `MAKE-VPS-WORK.cmd`, `scripts/deploy-onevps.ps1`, `scripts/deploy-on-server.sh` |
| Application source | `C:\Michaels Apps\czedr` on Michael’s PC |

### What Michael provides so Cursor can help next

After **one** of the following, tell Cursor the outcome (paste error text if it failed — **not** the password):

1. **SSH works** — `scripts/ssh-onevps.cmd` opens a `root@...#` shell, or  
2. **Deploy finished** — `MAKE-VPS-WORK.cmd` completed; report what `https://api.czedr.com/v1/health` shows, or  
3. **Exact error** — e.g. `Permission denied`, `Connection refused`, or last ~20 lines from the deploy window.

### Generated on the server (do not commit to git)

The deploy script creates these on first successful run:

| Secret / file | Path on VPS |
|---------------|-------------|
| DB password, crypto pepper | `/root/.czedr-deploy-secrets` |
| Production `.env` | `/var/www/czedr/.env` |
| Database config | `/var/www/czedr/config/database.local.php` |

Back up `/root/.czedr-deploy-secrets` securely after deploy. Cursor does not need these values unless troubleshooting a manual `.env` edit.

### Optional later (not required for first API online)

| Requisite | Purpose |
|-----------|---------|
| GoDaddy DNS still pointing `api` → `91.220.203.91` | Let’s Encrypt / HTTPS if cert step fails |
| OneVPS VNC/console | If password reset still yields `Permission denied` |
| GitHub deploy token | Only if using `git clone` on server (repo is private; raw GitHub URLs return 404) |
| Cloudflare on `czedr.com` | WAF / DDoS (`docs/EDGE-WAF-DDOS.md`) |
| GitHub `CZEDR_API_BASE=https://api.czedr.com` | iOS TestFlight / Android CI |
| Moov / SMTP credentials | Only when ACH or email is enabled |

### One-line summary

**Cursor can write and run deploy scripts in the repo, but cannot log into OneVPS until Michael completes SSH once (password on port 22122, or by running `MAKE-VPS-WORK.cmd`).**

---

## 8. What we need from OneVPS support

Please confirm or assist with:

1. **Root password reset** for `91.220.203.91` if login fails with Permission denied.
2. Confirm **SSH is enabled on port 22122** for this VM.
3. Confirm VPS is **running** (not suspended / stopped).
4. If SSH still fails: enable **VNC / HTML5 console** access so we can run `passwd` and set a new root password.
5. (Optional) Confirm no provider-level firewall blocking ports **80** and **443** after we deploy the web stack.

---

## 9. Deployment work still required (after SSH works)

Full guide: **`docs/DEPLOY-ONEVPS-CZEDR.md`**

High-level checklist:

- [ ] SSH login successful on port **22122**
- [ ] Install: MariaDB, PHP 8.x, Caddy (or nginx), firewall (ufw)
- [ ] Add 2 GB swap (recommended on 2 GB RAM)
- [ ] Deploy application code to `/var/www/czedr` (from GitHub or upload)
- [ ] Configure `.env` from `.env.production.example` (secrets not in git)
- [ ] Configure `config/database.local.php` from `config/database.local.php.example`
- [ ] Create MySQL database `saturn` and user `app_saturn`
- [ ] Run `php scripts/run-migrations.php`
- [ ] Run PHP API on `127.0.0.1:8080` (systemd service)
- [ ] Caddy reverse proxy + Let's Encrypt for `api.czedr.com`
- [ ] Verify: `curl https://api.czedr.com/v1/health` returns success
- [ ] Set GitHub Actions variable `CZEDR_API_BASE=https://api.czedr.com` for iOS TestFlight / Android builds

Security references in repo:

- `docs/PRODUCTION-SECURITY-CHECKLIST.md`
- `docs/DEPLOY-HTTPS.md`
- `docs/EDGE-WAF-DDOS.md` (Cloudflare recommended in front of API)

---

## 10. Application context (for contractors)

| Item | Detail |
|------|--------|
| Product | Czedr — mobile wallet / payments (iOS TestFlight, Android) |
| Backend | PHP 8, MySQL (`saturn` database), REST API under `/v1/` |
| Repo | `C:\Michaels Apps\czedr` locally; GitHub: `wildlifeoutdoorsllc-czedr/czedr` |
| Local dev | Windows PC, PHP on port 8080, LAN testing |
| Production env | `APP_ENV=production`, HTTPS required, no dev routes |

---

## 11. AI / support strategy (owner is not a developer)

The owner is **not a programming expert**. Preferred approach:

1. **OneVPS human support** — password reset, SSH port, console access.
2. **Step-by-step guides** in this repo — one task at a time.
3. **Cursor AI** — project-aware help with copy-paste commands.
4. **Optional freelancer** — deploy using `DEPLOY-ONEVPS-CZEDR.md` if SSH + deploy remains blocked.

AI cannot log into OneVPS or enter passwords on the owner's behalf.

---

## 12. Related repo documents

| Document | Purpose |
|----------|---------|
| `docs/DEPLOY-ONEVPS-CZEDR.md` | Full Ubuntu 24 deploy on OneVPS |
| `docs/ONEVPS-SSH-LOGIN.md` | SSH troubleshooting |
| `docs/OPS-TIMEOUTS.md` | Max wait times for SSH/deploy (2 min / 30 min / 2 hr) |
| `QUERY-VPS-AUDIT.cmd` | User audit log from VPS (timeout-safe) |
| `docs/DEPLOY-HTTPS.md` | TLS and production API URL |
| `docs/PRODUCTION-SECURITY-CHECKLIST.md` | Production hardening |
| `docs/CURSOR-INTERPRETER.md` | Local AI interpreter (separate from hosting) |
| `scripts/ssh-onevps.cmd` | Windows SSH launcher (port 22122) |
| `MAKE-VPS-WORK.cmd` | One-click deploy from Windows (repo root) |
| `scripts/ONEVPS-ONE-PAGE-STEPS.txt` | Short owner checklist |

---

## 13. Copy-paste ticket for OneVPS support

```
Subject: SSH login help — VM5413717769735819 / 91.220.203.91

Hello,

I need help logging into my VPS via SSH.

- IP: 91.220.203.91
- Hostname: VM5413717769735819.onevps.cloud
- OS: Ubuntu 24.04
- I am using: ssh -p 22122 root@91.220.203.91 (or PuTTY port 22122)

Problem:
- [ ] Connection refused (when using port 22)
- [ ] Permission denied (when using port 22122)
- [ ] Other: _______________

Please:
1. Reset the root password and send/confirm the new password.
2. Confirm SSH is active on port 22122.
3. If needed, provide VNC/console access instructions.

I plan to host api.czedr.com on this server after login works.

Thank you.
```

---

## 14. Status log (update as you go)

| Date | Event |
|------|--------|
| May 2026 | VPS provisioned at OneVPS; IP 91.220.203.91 |
| May 2026 | DNS: api.czedr.com → 91.220.203.91 configured |
| May 2026 | SSH port 22122 verified open externally; port 22 closed |
| May 2026 | SSH login not completed by owner — password/port confusion |
| May 2026 | **Migration complete:** 48 users imported; API live at https://api.czedr.com |
| May 2026 | GitHub `CZEDR_API_BASE` → `https://api.czedr.com`; TestFlight build **111** queued |
| May 2026 | `czedr.com` placeholder on VPS; PC no longer required for API uptime |

---

*End of support handoff document.*
