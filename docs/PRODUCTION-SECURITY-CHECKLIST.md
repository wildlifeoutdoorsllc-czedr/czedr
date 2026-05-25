# Production security remediation checklist

Defensive checklist for shipping Czedr on a **real internet-facing server**. Maps each item to **environment variables**, **source files**, and **verification steps**.

Related: `docs/SECURITY-UPGRADE-ROADMAP.md`, `docs/DEPLOY-HTTPS.md`, `.env.example`, `.env.production.example`.

---

## How to use this doc

| Priority | Meaning |
|----------|---------|
| **P0** | Block public launch until done |
| **P1** | Do in the same release train as HTTPS |
| **P2** | Hardening / reduce attack surface |
| **P3** | Ongoing hygiene and monitoring |

Check boxes as you complete items. After deploy, run the [Smoke verification](#smoke-verification-production) section.

---

## Production `.env` template

Copy `.env.production.example` to `.env` on the server (never commit `.env`). Generate secrets with:

```powershell
# 32+ byte pepper (hex)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
# Admin token (64 hex chars)
-join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object { [char]$_ })
```

| Variable | Production value | Read in code |
|----------|------------------|--------------|
| `APP_ENV` | `production` | `backend/src/Support/Env.php` → `isLocal()` |
| `APP_DEBUG` | `false` | `backend/public/index.php`, `bootstrap.php` |
| `CZEDR_RATE_LIMIT` | `1` (or unset) | `backend/src/Security/RateLimiter.php` |
| `CZEDR_ALLOW_HTTP` | **unset** | `backend/src/Security/HttpsGate.php` |
| `CZEDR_ALLOW_LEDGER_LOAD` | **unset** or `0` | `Env::allowSelfServiceLedgerLoad()` |
| `CZEDR_CRYPTO_PEPPER` | **required** (32+ random bytes) | `SecurePayloadCryptor.php`, `BankVaultCryptor.php` |
| `CZEDR_ADMIN_REPORT_TOKEN` | long random (or unset = admin routes 404) | `App.php` admin routes |
| `APP_PUBLIC_URL` | `https://api.yourdomain.com` | `PasswordResetService.php` (email links when SMTP added) |
| `CZEDR_AUTO_MIGRATE` | `0` (run migrations in deploy script) | `backend/public/index.php` |
| `MOOV_WEBHOOK_SECRET` | set if `MOOV_ENABLED=1` | `MoovWebhookVerifier.php` |

Full annotated template: **`.env.production.example`** at repo root.

---

## Route map (`backend/src/App.php`)

All routes are registered in `App::registerRoutes()` unless noted as legacy.

### Public (no Bearer)

| Method | Path | Handler area | Risk if misconfigured |
|--------|------|--------------|------------------------|
| GET | `/v1/health` | L84–93 | Info disclosure (low) |
| GET | `/v1/dev/setup` | L129–149 | **404 unless `APP_ENV=local`** |
| GET | `/v1/auth/signup-challenge` | L151–163 | Abuse / cost (rate limited) |
| POST | `/v1/auth/register` | L165–177 | Bot signups; plain JSON |
| POST | `/v1/auth/register-secure` | L179–203 | Preferred register path |
| POST | `/v1/auth/login` | L205–211 | Credential stuffing |
| POST | `/v1/auth/login-secure` | L213–220 | Preferred login path |
| POST | `/v1/auth/forgot-password` | L275–295 | Enumeration / abuse |
| POST | `/v1/auth/reset-password` | L297–305 | Token brute force |
| POST | `/v1/webhooks/moov` | L607–631 | Forged ledger events |

### Admin (shared secret)

| Method | Path | Env | File lines |
|--------|------|-----|------------|
| GET | `/v1/admin/revenue-ledger` | `CZEDR_ADMIN_REPORT_TOKEN` | L95–110 |
| GET | `/v1/admin/corporate-ledger` | same | L112–127 |

### Authenticated (`withAuth` — L681–697)

| Method | Path | Extra gate | File lines |
|--------|------|------------|------------|
| POST | `/v1/auth/logout` | — | L267–273 |
| POST | `/v1/auth/pin/set` | no overwrite if set | L248–255 |
| POST | `/v1/auth/pin/set-secure` | encrypted body | L257–265 |
| POST | `/v1/auth/pin/verify-secure` | rate limit | L222–235 |
| POST | `/v1/auth/pin/update-secure` | old PIN required | L237–246 |
| GET | `/v1/ledger/balance` | — | L307–314 |
| POST | `/v1/ledger/load` | **`allowSelfServiceLedgerLoad()`** | L323–337 |
| POST | `/v1/transfers` | **PIN** | L344–357 |
| POST | `/v1/invoices` | **PIN** | L363–376 |
| GET | `/v1/invoices/received`, `/sent` | scoped to `$uid` | L378–390 |
| GET | `/v1/users/validate` | recipient lookup | L339–342 |
| POST | `/v1/funding/bank-link/*` | vault + micro-deposit | `registerFundingRoutes()` L534–557 |
| POST | `/v1/profile/avatar` | — | L446–459 |
| GET | `/v1/media/profile/{file}` | Bearer or `auth_code` query | L461–491 |

### Legacy (`LegacyCompat::register` — `backend/src/Legacy/LegacyCompat.php`)

Still mounted from `App.php` L501–509. Same auth wrapper, but **duplicate paths** (`/login`, `/signup`, `/userpin`, …).

### Static HTML (`backend/public/index.php`)

| URL | File | P2 action |
|-----|------|-----------|
| `/sandbox` | `sandbox.html` | Block at reverse proxy in prod |
| `/corporate`, `/corporate-portal` | `corporate-portal.html` | Block or auth at edge |

---

## P0 — Before any public beta

### P0.1 TLS and HTTPS gate

| Task | Files | Env |
|------|-------|-----|
| Terminate TLS at Caddy/nginx/ALB | `docs/DEPLOY-HTTPS.md` | `APP_ENV=production` |
| Confirm plain HTTP returns 403 | `backend/src/Security/HttpsGate.php` | Do **not** set `CZEDR_ALLOW_HTTP` |
| Point TestFlight at `https://` API | `.github/workflows/ios-testflight.yml`, GitHub var `CZEDR_API_BASE` | `https://api.yourdomain.com` |

**Verify:**

```bash
curl -sS https://api.yourdomain.com/v1/health
curl -sS http://api.yourdomain.com/v1/health   # expect 403 "HTTPS is required"
```

### P0.2 Disable “free money” and dev behavior

| Task | Files | Env |
|------|-------|-----|
| Never use `APP_ENV=local` on public host | `AuthService.php` L91–100 (welcome balance) | `APP_ENV=production` |
| Block self-service ledger mint | `App.php` L323–327, `Env.php` L59–66 | **unset** `CZEDR_ALLOW_LEDGER_LOAD` |
| Hide dev setup endpoint | `App.php` L129–133 | `APP_ENV=production` → 404 |

**Verify:** Authenticated `POST /v1/ledger/load` returns **403** with body mentioning disabled.

### P0.3 Secrets and crypto pepper

| Task | Files | Env |
|------|-------|-----|
| Set strong `CZEDR_CRYPTO_PEPPER` | `BankVaultCryptor.php` L51–59, `SecurePayloadCryptor.php` | Required in prod (throws if missing for bank vault) |
| Generate unique `CZEDR_ADMIN_REPORT_TOKEN` or leave unset | `App.php` L95–127 | 32+ byte random; store in secrets manager |
| Lock MySQL credentials | `config/database.local.php`, `ConnectionFactory.php` | `VAULT_*` least-privilege user |

**Verify:** Server starts; bank-link start does not throw pepper error.

### P0.4 Debug and errors off

| Task | Files | Env |
|------|-------|-----|
| No stack traces to clients | `index.php` L48–50 | `APP_DEBUG=false` |
| No migration on random HTTP hit | `index.php` L21–34 | `CZEDR_AUTO_MIGRATE=0` |

---

## P1 — Same release as HTTPS

### P1.1 Rate limits stay on

| Endpoint | Limit | Code |
|----------|-------|------|
| Login | 10 / 15 min per IP + email | `App.php` `handleLogin()` L741–757 |
| Register | 5 / hour per IP | `guardRegisterAttempt()` L729–734 |
| Signup challenge | 30 / hour per IP | L151–161 |
| PIN (legacy `/checkpin`) | 5 / 15 min per user | `LegacyCompat.php` L69–77 |
| PIN verify-secure | 5 / 15 min per user | `App.php` L222–231 |
| Forgot password | 3 / hour per IP + email | L275–288 |
| PIN lockout | 5 failures → 30 min | `AuthService.php` L229–247 |

| Task | Env |
|------|-----|
| Never set `CZEDR_RATE_LIMIT=0` in production | |

**Verify:** `php scripts/test-rate-limits.php` against staging.

### P1.2 Session and password hygiene

| Task | Files | Notes |
|------|-------|-------|
| Passwords Argon2id | `AuthService.php` L69, L104 | Already implemented |
| Tokens hashed SHA-256 | `AuthService.php` L167–180 | Bearer in header only |
| Reset: no token in JSON | `PasswordResetService.php` L70–74 | Only when `isLocal()` |
| Reset: log hash only | `PasswordResetService.php` L145–151 | Production log line |
| Revoke sessions on password reset | `PasswordResetService.php` L112–114 | Done |

**Gap (P1 follow-up):** Wire SMTP for `deliverResetToken()` — today production reset is audit/log only (`PasswordResetService.php` L155–158).

### P1.3 PIN and payments

| Task | Files | Notes |
|------|-------|-------|
| Transfers require PIN | `App.php` L345 | `requirePinForPayment()` |
| Invoices require PIN | `App.php` L364 | same |
| Legacy PIN overwrite blocked | `LegacyCompat.php` L82–101 | Requires `old_pin` on `/updatepin` |
| iOS uses `/v1/auth/pin/*` not legacy | `ios/CzedrSwift/` | Confirm in release QA |

**Residual risk:** 4-digit PIN = 10k space. Rate limits + lockout mitigate online guessing; stolen Bearer token remains the main threat.

**Optional hardening (code change):** step-up for large transfers, longer PIN, device binding.

### P1.4 Reserved platform IDs

| Task | Files |
|------|-------|
| Block REVENUE / SYSTEM / CORPORATE at register | `ReservedCzedrIds.php`, `AuthService.php` L62 |

**Verify:** `POST /v1/auth/register` with `czedr_id=REVENUE` → 400.

---

## P2 — Reduce attack surface

### P2.1 Remove or gate plain auth routes ✅ **Done (May 2026)**

| Route | File | Production behavior |
|-------|------|---------------------|
| `POST /v1/auth/register` | `App.php` | **404** unless `CZEDR_ALLOW_PLAIN_AUTH=1` |
| `POST /v1/auth/login` | `App.php` | **404** unless `CZEDR_ALLOW_PLAIN_AUTH=1` |

Guard: `backend/src/Security/ProductionRouteGuard.php`. iOS SwiftUI still calls plain paths — use local `APP_ENV=local`, secure client, or temporary override flag.

### P2.2 Legacy route deprecation ✅ **Done (May 2026)**

Legacy routes are **not registered** when `APP_ENV=production` unless `CZEDR_ALLOW_LEGACY_API=1`. See `App.php` (LegacyCompat registration guarded).

### P2.3 Bearer token never in URLs

| Task | Files |
|------|-------|
| Profile media: header only | `App.php` L461–467 accepts `auth_code` query — **remove for prod** or short-lived signed URLs |
| iOS Keychain storage | `ios/CzedrSwift/KeychainStore.swift` | Do not log tokens |

### P2.4 Static and corporate pages ✅ **Done (May 2026)**

`/sandbox` and `/corporate*` return **404** when not `APP_ENV=local` (`backend/public/index.php`).

### P2.5 Moov webhooks

| Task | Files | Env |
|------|-------|-----|
| Require webhook secret | `MoovWebhookVerifier.php` | `MOOV_WEBHOOK_SECRET` |
| Disable Moov if unused | `MoovConfig.php` | `MOOV_ENABLED=0` |

**Verify:** POST fake body to `/v1/webhooks/moov` without signature → **401**.

### P2.6 Bank vault and micro-deposits

| Task | Files | Env |
|------|-------|-----|
| Unique pepper per environment | `BankVaultCryptor.php` | `CZEDR_CRYPTO_PEPPER` |
| Confirm micro-deposit amounts not guessable in prod | `MicroDepositBankLinkService.php` L222+ | Unset `CZEDR_MICRO_DEPOSIT_CENTS_*` in prod |
| `CZEDR_MICRO_DEPOSIT_SKIP_WAIT` only local | L114–118 | `APP_ENV=local` only |

### P2.7 Ingress / edge

| Task | Notes |
|------|-------|
| Firewall: 443 only public | MySQL not on `0.0.0.0` |
| WAF or fail2ban on 429 spikes | Optional |
| HSTS header | Caddy/nginx after TLS stable |
| Redact `Authorization` in access logs | Proxy config |

---

## P3 — Ongoing

| Task | Files / location |
|------|------------------|
| Rotate `CZEDR_ADMIN_REPORT_TOKEN`, DB passwords, Moov keys | Secrets manager |
| Monitor `storage/logs/password-reset.log` permissions (600) | `PasswordResetService.php` L134 |
| Audit `audit` table for `auth.login_failed`, `auth.pin_locked` | `AuditService.php` |
| Redact `enc_data`, passwords in app logs | Logging policy |
| Penetration test (dynamic) | Third party |
| Dependabot / PHP updates | Composer if added |
| Referral / sybil policy | `LedgerService.php` referral mint |

---

## File index (security-relevant)

| File | Responsibility |
|------|----------------|
| `backend/src/App.php` | All `/v1/*` routes, `withAuth`, rate limit hooks |
| `backend/src/Legacy/LegacyCompat.php` | Legacy `/login`, `/signup`, PIN, invoices |
| `backend/public/index.php` | Static HTML, bootstrap, `APP_DEBUG` errors |
| `backend/src/Security/HttpsGate.php` | HTTP blocked in production |
| `backend/src/Security/RateLimiter.php` | Global on/off via `CZEDR_RATE_LIMIT` |
| `backend/src/Auth/AuthService.php` | Register, login, PIN, sessions |
| `backend/src/Auth/PasswordResetService.php` | Reset tokens, logging |
| `backend/src/Auth/SignupChallengeService.php` | Challenge images for crypto |
| `backend/src/Security/PayloadCryptor.php` | v1/v2 decrypt for secure routes |
| `backend/src/Security/SecurePayloadCryptor.php` | AES-GCM v2 |
| `backend/src/Security/ReservedCzedrIds.php` | Platform ID squatting |
| `backend/src/Ledger/LedgerService.php` | Transfers, fees, referrals |
| `backend/src/Funding/BankVaultCryptor.php` | Bank account encryption at rest |
| `backend/src/Funding/MicroDepositBankLinkService.php` | Bank link + confirm |
| `backend/src/Moov/MoovWebhookVerifier.php` | Webhook authenticity |
| `backend/src/Media/ProfileMediaService.php` | Avatar storage + ACL |
| `backend/src/Support/Env.php` | `isLocal()`, ledger load flag |
| `backend/src/Security/ProductionRouteGuard.php` | Plain auth, legacy API, dev pages |
| `docs/EDGE-WAF-DDOS.md` | CDN/WAF dictionary + DDoS |
| `docs/ATTORNEY-SECURITY-BRIEF.md` | Counsel overview of security posture |
| `.env` / `.env.production.example` | Runtime secrets |
| `docs/DEPLOY-HTTPS.md` | TLS rollout |
| `docs/SECURITY-UPGRADE-ROADMAP.md` | Phased plan (already partially done) |

---

## Smoke verification (production)

Run after deploy (replace host):

```bash
# 1. HTTPS only
curl -sS -o /dev/null -w "%{http_code}" https://api.yourdomain.com/v1/health   # 200
curl -sS http://api.yourdomain.com/v1/health                                      # 403

# 2. Dev routes closed
curl -sS -o /dev/null -w "%{http_code}" https://api.yourdomain.com/v1/dev/setup   # 404

# 3. Rate limit (optional, staging)
php scripts/test-rate-limits.php

# 4. Secure signup roundtrip
php scripts/test-signup-secure.php

# 5. Register reserved ID rejected
# POST /v1/auth/register {"email":"x@y.com","password":"LongPassword1!","czedr_id":"REVENUE"} → error
```

**iOS / TestFlight**

- [ ] Sign-in screen shows expected build number
- [ ] `CZEDR_API_BASE` is `https://` in GitHub Actions variables
- [ ] Register → Set PIN → transfer with PIN on staging
- [ ] Settings → Local Network not required for prod HTTPS host

---

## Suggested implementation order (PR-sized)

1. **Ops only:** `.env.production.example` + server TLS + `APP_ENV=production` (no code).
2. **Proxy:** block `/sandbox`, `/corporate`, legacy paths if no old clients.
3. **Code:** production guard on `POST /v1/auth/register` and `POST /v1/auth/login` (404 unless `APP_ENV=local`).
4. **Code:** drop `auth_code` query support on profile media GET.
5. **Code:** SMTP password reset + remove dependency on log file for prod.
6. **Product:** PIN policy / step-up limits (larger change).

---

## Changelog

| Date | Notes |
|------|-------|
| 2026-05-25 | Initial checklist from external threat model review |
