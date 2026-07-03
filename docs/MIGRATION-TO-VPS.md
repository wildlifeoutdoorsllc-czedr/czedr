# Czedr — migrated to OneVPS (production)

**API (production):** `https://api.czedr.com`  
**Server:** `91.220.203.91` (SSH port `22122`)

Your PC is no longer required for the API to run. The VPS runs MariaDB, PHP API, and HTTPS (Caddy) 24/7.

---

## What lives where now

| Piece | Location |
|-------|----------|
| API + database | OneVPS `/var/www/czedr` |
| DNS | GoDaddy — `api.czedr.com` → VPS |
| Code updates from PC | `MAKE-VPS-WORK.cmd` or `scripts\deploy-onevps.ps1` |
| Full DB copy PC → VPS | `scripts\migrate-local-to-vps.ps1` |

---

## On your PC (optional)

| Task | Command |
|------|---------|
| Deploy code only | `MAKE-VPS-WORK.cmd` |
| Copy local MySQL to VPS again | `scripts\migrate-local-to-vps.ps1` |
| Test API without starting PHP | Open `https://api.czedr.com/v1/health` |
| Old local API (dev only) | `START-IPHONE-TESTING.cmd` — not needed for production apps |

---

## iPhone (TestFlight)

Production URL must be **baked into the app** at build time.

1. GitHub repo variable: **`CZEDR_API_BASE`** = `https://api.czedr.com` *(set May 2026)*
2. Ship build **111+**: `scripts\ship-testflight.ps1 -BuildNumber 111 -WaitForPrevious`
3. Install from TestFlight; sign-in should hit `api.czedr.com` (not your PC IP).

Until you install that build, older TestFlight builds still point at your home Wi‑Fi IP.

### Waiting on Apple?

Build **111** was **uploaded successfully** from GitHub CI (May 31, 2026). CI finishes when the `.ipa` reaches Apple — **not** when TestFlight is ready to install.

| Stage | Who | Typical time |
|-------|-----|----------------|
| GitHub Actions build + upload | Done | ~2 min |
| Apple **Processing** | Apple | **5–30 min** (sometimes up to ~1 hour) |
| Appears in **TestFlight** app | You install build **111** | After processing |

**Where to look:** iPhone → **TestFlight** app → Czedr → build **111**.  
If missing after an hour, check [App Store Connect](https://appstoreconnect.apple.com) → TestFlight → processing errors.

---

## Environment fixes applied (production)

These were blocking sign-in or bank features after migration:

| Issue | Fix |
|-------|-----|
| Production blocked plain login (`/v1/auth/login`) | `CZEDR_ALLOW_PLAIN_AUTH=1` on VPS until apps use `*-secure` auth (HTTPS still required) |
| Broken `.env` (duplicate / placeholder crypto pepper) | Repaired via `scripts/repair-production-env.sh` |
| Daily DB backup | `/etc/cron.daily/czedr-mysql-backup` on VPS (14-day retention) |

Re-run env repair after a bad deploy: `bash /var/www/czedr/scripts/repair-production-env.sh` on the server.

---

## Android

- **Release APK** defaults to `https://api.czedr.com`
- **Debug** still uses `http://10.0.2.2:8080` for emulator
- On a physical phone: use release build or set API URL to `https://api.czedr.com`

---

## Security reminders

- Rotate VPS root password after SafePass / chat exposure
- Back up `/root/.czedr-deploy-secrets` on the server (DB password + crypto pepper)
- Do not commit `.env` or `config/database.local.php`

---

## Support

- `docs/SUPPORT-HANDOFF-ONEVPS.md`
- `docs/DEPLOY-ONEVPS-CZEDR.md`
