# Czedr — management takeover package

**Purpose:** One place for **new management / contractors / counsel** to see what exists, what is already backed up in git, and what must be transferred **privately** (never committed).  
**Owner today:** Michael (Wildlife Outdoors LLC / Czedr).  
**Last updated:** 2026-08-23  
**Audience:** Non-technical executives + incoming technical operators.

> **Secrets never belong in this repo.** Passwords, SSH keys, Apple `.p8`, DB credentials, and `.env` files stay off git. This document only lists *where* they live and *how* to back them up.

---

## 1. Snapshot (as of this doc)

| Area | State | Where to verify |
|------|--------|-----------------|
| **Source code** | GitHub: `wildlifeoutdoorsllc-czedr/czedr` | Branches `main` and `czedrmaster` |
| **Production API** | `https://api.czedr.com` | `docs/RELEASE-TRAIN.md`, smoke script below |
| **VPS** | OneVPS `91.220.203.91`, SSH port **22122** | `docs/SUPPORT-HANDOFF-ONEVPS.md` |
| **iOS TestFlight** | Last shipped **137**; next **139**; **138** in progress (Forgot PIN) | `docs/IOS-BUILD.md` |
| **Bank / ACH** | Micro-deposit linking only; Moov/ACH **off** | `docs/BANK-LINK-MICRODEPOSITS.md` |
| **Daily DB backup on VPS** | Cron: `/etc/cron.daily/czedr-mysql-backup` (14-day retention) | `docs/MIGRATION-TO-VPS.md` |

---

## 2. What “backed up” means here

| Layer | Backed up how | New management action |
|-------|----------------|------------------------|
| **Application source** | GitHub remotes (`main`, `czedrmaster`) | Confirm org admin access; clone both branches |
| **Docs / runbooks** | This `docs/` tree in git | Start with **this file**, then the map in §4 |
| **Production MySQL (`saturn`)** | Daily cron on VPS + emergency scripts | Run emergency backup before cutover (§5) |
| **Secrets / `.env` / deploy pepper** | Local PC + `/root/.czedr-deploy-secrets` on VPS — **not in git** | Copy via USB / encrypted vault; rotate after handoff |
| **Apple Developer / TestFlight** | App Store Connect (account ownership) | Transfer Apple team + CI secrets (GitHub Actions) |
| **DNS (GoDaddy)** | Registrar account | Transfer or share GoDaddy login out-of-band |
| **Domain / email** | `czedr.com`, `api.czedr.com`, support mailbox | Confirm MX and who owns `support@czedr.com` |

**Git does not replace a secrets backup.** Pushing code is not enough for takeover.

---

## 3. Private transfer checklist (do this offline)

Hand these to new management on **USB or an encrypted vault** — never paste into chat or commit:

- [ ] OneVPS panel login (root password reset capability)
- [ ] SSH private key used for deploy (`id_ed25519_czedr_onevps` on Michael’s PC, if present)
- [ ] Production `.env` and `/root/.czedr-deploy-secrets` (DB password, `CZEDR_CRYPTO_PEPPER`, mail settings)
- [ ] Local Windows copies: `D:\CZEDR\.env`, `config\database.local.php`, `DB details for Czedr.txt` (if used)
- [ ] GitHub org `wildlifeoutdoorsllc-czedr` — owner/admin role
- [ ] Apple Developer / App Store Connect — app `com.czedr.app`, TestFlight, signing certs / `.p8` for CI
- [ ] GitHub Actions secrets/variables used by `.github/workflows/ios-testflight.yml` (including `CZEDR_API_BASE`)
- [ ] GoDaddy (DNS for `czedr.com` / `api.czedr.com`)
- [ ] Any bank / counsel / ValidiFI / Frost relationship contacts (`docs/CZEDR-ATTORNEY-BRIEF.md`, `docs/VALIDIFI-PARTNER-INQUIRY.md`)
- [ ] Latest folder from `scripts\backup-everything.ps1` → `D:\CZEDR\backups\emergency-*`

---

## 4. Document map (read in this order)

| Order | Doc | Why |
|-------|-----|-----|
| 1 | **`docs/MANAGEMENT-TAKEOVER.md`** (this file) | Ownership cutover |
| 2 | `docs/RELEASE-TRAIN.md` | Live API + iOS pairing rules |
| 3 | `docs/IOS-BUILD.md` | Current TestFlight build numbers |
| 4 | `docs/DEVELOPMENT-WORKFLOW.md` | How code is committed and shipped |
| 5 | `docs/DEPLOY-ONEVPS-CZEDR.md` | How production is deployed |
| 6 | `docs/SUPPORT-HANDOFF-ONEVPS.md` | Server, DNS, SSH port **22122** |
| 7 | `docs/ONEVPS-SSH-LOGIN.md` | SSH troubleshooting |
| 8 | `docs/OPS-TIMEOUTS.md` | How long ops jobs may run |
| 9 | `docs/PRODUCTION-SECURITY-CHECKLIST.md` | Security before go-live changes |
| 10 | `docs/ATTORNEY-SECURITY-BRIEF.md` / `docs/CZEDR-ATTORNEY-BRIEF.md` | Legal / MSB context |
| 11 | `docs/TEST-ACCOUNTS.md` | Dev test logins only (not production users) |
| 12 | `docs/ATLAS-CONTINUITY.md` | How Michael prefers to work with assistants |
| 13 | `docs/AGENT-HANDOFF.md` | Older iOS/TestFlight agent notes (may be dated — prefer IOS-BUILD + RELEASE-TRAIN for numbers) |

---

## 5. Run the emergency backup (Michael’s Windows PC)

This cloud agent **cannot** reach OneVPS or Michael’s local MySQL. New management (or Michael) must run:

```powershell
cd D:\CZEDR
powershell -File scripts\backup-everything.ps1
```

**Produces:** `D:\CZEDR\backups\emergency-YYYYMMDD-HHMMSS\` containing:

- Local `saturn` SQL dump (if mysqldump is installed)
- Local `.env` / DB config copies (if present)
- Git commit/branch snapshot
- VPS dump: `saturn.sql.gz`, app tarball, Caddyfile, deploy secrets (via SSH)

**Then:** copy that folder to USB or encrypted cloud. Folder is **gitignored** (`backups/`).

**On-server only** (if already logged into the VPS):

```bash
bash /var/www/czedr/scripts/backup-vps-on-server.sh
# prints OK:/var/backups/czedr/emergency-...
```

**Verify production after cutover:**

```powershell
powershell -File D:\CZEDR\scripts\smoke-production-routes.ps1
```

Expect `GET /v1/health` → 200; authenticated routes without a token → **401** (not 404).

---

## 6. Systems inventory

| System | Detail |
|--------|--------|
| **Repo** | `https://github.com/wildlifeoutdoorsllc-czedr/czedr.git` |
| **Primary product branch** | `czedrmaster` (iOS shipping); `main` also used |
| **API** | PHP under `backend/`; public root `backend/public` |
| **DB** | MySQL database name **`saturn`** |
| **iOS** | SwiftUI: `ios/CzedrSwift/`; flag `CZEDR_USE_SWIFTUI` in `CzedrConfig.h` |
| **Android** | `android/` — see `docs/ANDROID-BUILD.md` |
| **TestFlight CI** | Manual `workflow_dispatch` only — `scripts/ship-testflight.ps1` |
| **VPS path** | `/var/www/czedr` |
| **SSH** | `ssh -p 22122 root@91.220.203.91` |

---

## 7. After takeover (first 48 hours)

1. Confirm GitHub org + Apple + GoDaddy + OneVPS access.  
2. Run `backup-everything.ps1` and store the emergency folder offline.  
3. Rotate VPS root password and deploy secrets; update GitHub Actions secrets.  
4. Smoke-test `https://api.czedr.com` and install latest TestFlight build.  
5. Do **not** enable Moov/ACH until bank + counsel say so.  
6. Keep working style for operators: step-by-step, exact error text — see `docs/ATLAS-CONTINUITY.md`.

---

## 8. Honest limits

| This package includes | This package does **not** include |
|----------------------|-----------------------------------|
| Runbooks and code pointers in git | Live passwords or private keys |
| How to generate an emergency backup | A backup folder already sitting in this cloud VM |
| Current build/API status pointers | Automatic transfer of Apple/GoDaddy accounts |

If a contractor only has GitHub access and nothing from §3, they can read code but **cannot** operate production safely.

---

*Michael: after new management has the private checklist (§3) and one successful `backup-everything.ps1` run, the operational handoff is complete.*
