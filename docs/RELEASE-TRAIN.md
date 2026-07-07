# Czedr release train (where we are now)

**Last updated:** June 2026  
**Audience:** Michael + agents — single checklist for **API (OneVPS)** + **iOS TestFlight** + **Android**.

---

## Current stage

| Layer | State | Notes |
|-------|--------|--------|
| **Production API** | `https://api.czedr.com` live | Health OK; **code on server is behind git** |
| **DNS** | `api.czedr.com` → `91.220.203.91` | See `docs/DEPLOY-ONEVPS-CZEDR.md` |
| **iOS TestFlight** | Build **124** shipped | SwiftUI; points at `https://api.czedr.com` via GitHub `CZEDR_API_BASE` |
| **Bank linking** | Micro-deposit only | `MOOV_ENABLED=0` on VPS — P2P uses **ledger balance** only |
| **ACH / Moov** | Off until bank + legal | By design (`docs/VALIDIFI-PARTNER-INQUIRY.md`) |

### Production gap (verified June 2026)

Smoke from your PC (`scripts/smoke-production-routes.ps1`):

| Route | Expected without token | Production today |
|-------|------------------------|------------------|
| `GET /v1/health` | 200 | OK |
| `GET /v1/me` | **401** | **404 Not found** — server missing route (iOS build 123+) |
| `GET /v1/funding/status` | **401** | **401** — route exists |
| `GET /v1/ledger/balance` | **401** | **401** |

**Symptom on device:** red **“Not found”** on home was often **`GET /v1/me`** (Profile refresh) or a stale global error after **+ My Bank**. iOS build **125+** scopes funding errors to My Bank and clears home errors when balance loads.

---

## Release pairing rule

Always ship **API before or with** the iOS build that calls new routes.

| iOS build needs | Server must have |
|-----------------|------------------|
| 123+ Profile QR, Change PIN | `GET /v1/me`, migrations through QR/PIN |
| 124 Profile text size | No new API |
| 125+ Home error UX fix | Same as 123+; deploy latest `backend/` |
| 103+ + My Bank | `GET /v1/funding/status`, migration `014_bank_link_microdeposits.sql`, `CZEDR_CRYPTO_PEPPER` |

---

## Step 1 — Deploy API (OneVPS)

**From Windows** (after one-time SSH key in `MAKE-VPS-WORK.cmd`):

```text
MAKE-VPS-WORK.cmd
```

Or:

```powershell
powershell -File C:\Michaels Apps\czedr\scripts\deploy-onevps.ps1
```

This uploads `backend/`, `database/`, `config/`, runs `scripts/deploy-on-server.sh` (migrations, restart `czedr-api`).

**Verify:**

```powershell
powershell -File C:\Michaels Apps\czedr\scripts\smoke-production-routes.ps1
```

All three auth routes must show **401**, not **404**.

**On server** (optional deeper test with a real token):

```bash
php /var/www/czedr/scripts/test-api.php   # if CZEDR_TEST_BASE=https://api.czedr.com — use staging account only
```

---

## Step 2 — Ship iOS (TestFlight)

1. Commit iOS + docs on `czedrmaster`.
2. Set **Next ship** in `docs/IOS-BUILD.md` (e.g. **125**).
3. Confirm GitHub variable **`CZEDR_API_BASE`** = `https://api.czedr.com`.
4. Run:

```powershell
.\scripts\ship-testflight.ps1 -BuildNumber 125 -WaitForPrevious
```

5. Install from TestFlight → sign-in screen shows **SwiftUI · Build 125**.
6. **Device checks:**
   - Home: balance loads, **no** red “Not found” under My Bank.
   - Profile → payment QR loads (uses `/v1/me`).
   - **+ My Bank**: status text loads; errors stay on that screen only.

---

## Step 3 — Android (when ready)

Release build should use `https://api.czedr.com` (`docs/MIGRATION-TO-VPS.md`). Same API deploy as Step 1.

---

## Environment defaults (production best practice)

On VPS `.env` (see `scripts/deploy-on-server.sh` and `.env.production.example`):

| Variable | Production value |
|----------|------------------|
| `APP_ENV` | `production` |
| `APP_DEBUG` | `false` |
| `CZEDR_CRYPTO_PEPPER` | set (required for bank vault) |
| `CZEDR_AUTO_MIGRATE` | `0` (migrations in deploy script) |
| `MOOV_ENABLED` | `0` until ACH partner live |
| `CZEDR_BANK_LINK_METHOD` | `microdeposit` |
| `CZEDR_ALLOW_PLAIN_AUTH` | `1` until all clients use `*-secure` |

Do **not** set `CZEDR_ALLOW_LEDGER_LOAD` in production.

---

## When something breaks

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| **Not found** on home (old build) | `/v1/me` 404 or stale `errorMessage` | Deploy API; ship iOS 125+ |
| **Not found** on + My Bank only | Migration 014 not applied or pepper missing | Re-run deploy; check `php scripts/run-migrations.php` on VPS |
| Balance works, Profile broken | `/v1/me` missing on server | Deploy latest backend |
| **authcode expired** | Token expired | Sign out and sign in again |
| Can't deploy from PC | SSH key not installed | `MAKE-VPS-WORK.cmd` once with OneVPS password |

---

## Related docs

- `docs/PRODUCTION-SECURITY-CHECKLIST.md` — security gates
- `docs/DEPLOY-ONEVPS-CZEDR.md` — VPS setup
- `docs/IOS-BUILD.md` — TestFlight build numbers
- `docs/OPS-TIMEOUTS.md` — SSH/deploy timeouts

---

## Changelog

| Date | Notes |
|------|--------|
| 2026-06-03 | Initial release train; production `/v1/me` 404 documented; smoke script added |
