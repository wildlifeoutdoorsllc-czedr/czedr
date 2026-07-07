# Czedr — Security & Technical Brief (for counsel review)

**Prepared:** May 2026  
**Repository:** `C:\Michaels Apps\czedr` / `https://github.com/wildlifeoutdoorsllc-czedr/czedr`  
**Branch:** `czedrmaster`  
**Product:** Czedr mobile wallet (iOS TestFlight; Android in development) with PHP/MySQL API  

---

## Important notice (not legal advice)

This document is a **technical summary** of engineering work and security discussions between the product owner and development assistance (AI-assisted coding in Cursor). It is intended to help your attorney understand **what the system does**, **what controls exist**, and **what risks remain**.

It is **not** legal advice, a compliance certification, or a penetration-test report. Counsel should use this together with your privacy policy, terms of use, money-transmitter / fintech licensing strategy, and any formal security audit you commission.

---

## 1. Executive summary

Czedr is a **ledger-first** payment application: users hold balances on an internal ledger; bank linking is optional (micro-deposit verification). The API runs on a **self-hosted PHP backend**; the iPhone app is distributed via **Apple TestFlight**.

Security work in this engagement focused on:

1. **Reliability** — account creation and API connectivity on local Wi‑Fi (TestFlight build **110**).
2. **Defensive architecture** — threat modeling for internet-facing deployment.
3. **Production hardening** — route guards, headers, documentation, and edge-protection guidance.
4. **Clarifying misconceptions** — custom “AI chatter” protocols and obscurity do **not** replace TLS, authentication, or server-side authorization.

**Current posture:** Strong **password hashing** (Argon2id) and **session token hashing** on the server; **rate limits** on auth; **HTTPS gate** ready for production; **plain-text auth and legacy routes disabled** when `APP_ENV=production` (unless explicit override flags). **Gaps:** 4-digit PIN entropy, iOS client still uses plain JSON login on local dev paths, production email for password reset not fully wired, formal third-party pentest not yet performed.

---

## 2. Chronology (conversation arc)

| Phase | Topic | Outcome |
|-------|--------|---------|
| A | iOS fixes (builds 103–109) | PIN entry, payment success screen, menu/logout, Set PIN flow |
| B | Account creation failures | Stale LAN API IP; PHP registration bug fixed; Wi‑Fi API auto-discovery; TestFlight **110** |
| C | External threat model | Documented attack paths: TLS, stolen tokens, misconfiguration, not “unreadable protocols” |
| D | Production checklist | `docs/PRODUCTION-SECURITY-CHECKLIST.md`, `.env.production.example` |
| E | Obscurity / “AI norm code” gateway | Advised **not practical** as primary security; TLS + auth remain essential |
| F | DDoS / dictionary attacks | `docs/EDGE-WAF-DDOS.md` — CDN/WAF/nginx before PHP |
| G | Hardening + this brief | `ProductionRouteGuard`, static page blocks, attorney brief |

---

## 3. System architecture (high level)

```
[iPhone app — SwiftUI]
        │  HTTPS (production) or HTTP (local dev only)
        ▼
[Reverse proxy / CDN — recommended in production]
        ▼
[PHP API — backend/public/index.php → backend/src/App.php]
        ▼
[MySQL database "saturn" — users, sessions, ledger, invoices, bank vault blobs]
```

**Authentication model**

- User registers / logs in with **email + password** (minimum 10 characters).
- Server returns a **Bearer token** (`auth_token` / `auth_code`); stored on device (Keychain on iOS in recent builds).
- **4-digit PIN** required for transfers and invoices (verified server-side; Argon2id hash).
- Platform reserved IDs (`REVENUE`, `SYSTEM`, `CORPORATE`) cannot be registered by the public.

**Money movement**

- Internal ledger credits/debits; transfer fee and referral rewards configurable via environment variables.
- Self-service “load money” endpoint exists for **local development only** unless explicitly enabled — must remain off in production.

---

## 4. Security controls implemented (in codebase)

### 4.1 Storage and cryptography

| Control | Implementation |
|---------|----------------|
| Passwords | Argon2id (`AuthService.php`) |
| Session tokens | Random 32 bytes; SHA-256 hash stored (`auth_sessions` table) |
| PIN | Argon2id; lockout after 5 failures / 30 minutes |
| Signup/login “secure” payloads | AES-256-GCM (v2) or legacy ECB (v1) derived from signup challenge image + optional `CZEDR_CRYPTO_PEPPER` |
| Bank account numbers at rest | AES-256-GCM vault (`BankVaultCryptor.php`) |

### 4.2 Network and transport

| Control | Implementation |
|---------|----------------|
| HTTPS enforcement | `HttpsGate.php` — blocks HTTP when not `APP_ENV=local` |
| Security headers | `JsonResponse.php` — `nosniff`, `DENY` frame, `Referrer-Policy`, HSTS when HTTPS |
| Production route guard | `ProductionRouteGuard.php` — see §4.4 |

### 4.3 Abuse resistance

| Control | Limit (approx.) | File |
|---------|-----------------|------|
| Login failures | 10 / 15 min per IP and email | `App.php`, `RateLimiter.php` |
| Registration | 5 / hour per IP | `App.php` |
| Signup challenge | 30 / hour per IP | `App.php` |
| Forgot password | 3 / hour per IP and email | `App.php` |
| PIN verify | 5 / 15 min per user + account lockout | `AuthService.php`, `LegacyCompat.php` |

Disable limits only via `CZEDR_RATE_LIMIT=0` (must not be set in production).

### 4.4 Production hardening (May 2026)

When `APP_ENV=production` (default if unset):

| Item | Behavior |
|------|----------|
| Plain `POST /v1/auth/login` | **404** unless `CZEDR_ALLOW_PLAIN_AUTH=1` |
| Plain `POST /v1/auth/register` | **404** unless `CZEDR_ALLOW_PLAIN_AUTH=1` |
| Legacy routes (`/login`, `/signup`, …) | **Not registered** unless `CZEDR_ALLOW_LEGACY_API=1` |
| `/sandbox`, `/corporate-portal` HTML | **404** (not served) |
| Profile images | `auth_code` query parameter **not accepted** (Bearer header only) |
| `POST /v1/ledger/load` | **403** unless `CZEDR_ALLOW_LEDGER_LOAD=1` |
| Welcome balance on register | **Disabled** (local only) |
| Password reset token in API JSON | **Disabled** (local only) |
| Reset token in log file | **Hash only** in production |

**Local development** (`APP_ENV=local`): plain auth, legacy routes, sandbox pages, and welcome balance remain available for TestFlight-on-LAN testing.

### 4.5 iOS / TestFlight (recent)

| Build | Security-relevant change |
|-------|-------------------------|
| 110 | Wi‑Fi API discovery; fixes account creation against correct LAN server |
| 107–109 | Set PIN; menu/session UX |
| Earlier | Secure register path in **legacy** Objective-C (`SharedServiceController.m`); **SwiftUI** client still uses plain `/v1/auth/login` and `/register` for dev |

**Counsel note:** Production API with plain auth blocked means the **next TestFlight build** should adopt `*-secure` auth endpoints **or** operators must temporarily set `CZEDR_ALLOW_PLAIN_AUTH=1` during migration (increased exposure).

---

## 5. Threat model summary (external attacker)

**Primary risks on a real server**

1. **Missing or misconfigured TLS** — passwords and tokens exposed on the network.
2. **Stolen Bearer token + PIN guessing** — 4-digit PIN is weak but rate-limited.
3. **Environment misconfiguration** — e.g. `APP_ENV=local`, `CZEDR_ALLOW_LEDGER_LOAD=1`, weak admin token.
4. **Credential stuffing** — breached passwords from other sites.
5. **DDoS** — must be mitigated at CDN/nginx; PHP rate limits alone are insufficient.
6. **Webhook forgery** — if Moov ACH enabled without `MOOV_WEBHOOK_SECRET`.

**Ineffective as primary defense**

- Custom encoded “norm code” or LLM translation layers (**security through obscurity**).
- A duplicate “sandbox server” for DDoS without hiding origin IP and using a CDN.

---

## 6. Recommendations (engineering; for product counsel awareness)

### Before public launch (P0)

- [ ] Deploy API behind **TLS 1.2+** with `APP_ENV=production`
- [ ] Use `.env.production.example`; set **`CZEDR_CRYPTO_PEPPER`** and strong secrets
- [ ] **Never** enable `CZEDR_ALLOW_LEDGER_LOAD` or `CZEDR_ALLOW_HTTP` in production
- [ ] Point TestFlight builds to **`https://`** API (`CZEDR_API_BASE` in GitHub Actions)
- [ ] Place **Cloudflare or equivalent WAF** in front (see `EDGE-WAF-DDOS.md`)
- [ ] Ship iOS **secure auth** or controlled migration with `CZEDR_ALLOW_PLAIN_AUTH`

### Near term (P1)

- [ ] Wire **SMTP** for password reset (today: audit log / file in local only)
- [ ] Formal **penetration test** and remediation tracking
- [ ] Privacy policy / terms aligned with ledger, referrals, optional bank link
- [ ] Legal review of **money transmission**, KYC/AML, and state licensing (outside engineering scope)

### Ongoing (P2–P3)

- [ ] Monitor audit logs for `auth.login_failed`, `auth.pin_locked`
- [ ] Rotate `CZEDR_ADMIN_REPORT_TOKEN`, DB credentials, Moov keys
- [ ] Consider stronger step-up authentication for large transfers

---

## 7. Regulatory and business topics (flag for attorney)

Engineering does **not** determine licensing. Counsel may wish to explore:

| Topic | Technical hook |
|-------|----------------|
| Stored value / money transmission | Internal ledger, user balances, P2P transfers |
| Bank linking | Micro-deposit verification; encrypted ABA/account storage |
| Referral payments | Configurable cents per qualifying transfer (`CZEDR_REFERRAL_REWARD_CENTS`) |
| Consumer disclosures | Fees shown in API health (`transfer_fee_cents`) |
| Data protection | Email, profile images, bank vault, audit logs |
| Incident response | No formal IR playbook in repo — recommend client policy |

---

## 8. Repository documents (index)

| Document | Purpose |
|----------|---------|
| `docs/ATTORNEY-SECURITY-BRIEF.md` | **This file** — counsel overview |
| `docs/PRODUCTION-SECURITY-CHECKLIST.md` | Prioritized remediation mapped to code and `.env` |
| `docs/SECURITY-UPGRADE-ROADMAP.md` | Phased security plan (partially completed) |
| `docs/EDGE-WAF-DDOS.md` | CDN/WAF/nginx for dictionary + DDoS |
| `docs/DEPLOY-HTTPS.md` | TLS deployment |
| `.env.production.example` | Production environment template |
| `docs/LEDGER-FIRST-BANK-OPTIONAL.md` | Product model (ledger vs ACH) |
| `docs/IOS-BUILD.md` | TestFlight build tracker (e.g. build 110) |

**Key source files**

| File | Role |
|------|------|
| `backend/src/App.php` | Route registration, auth, transfers |
| `backend/src/Security/ProductionRouteGuard.php` | Production blocks |
| `backend/src/Security/HttpsGate.php` | HTTP blocked in production |
| `backend/src/Security/RateLimiter.php` | Abuse limits |
| `backend/src/Auth/AuthService.php` | Users, PIN, sessions |
| `ios/CzedrSwift/CzedrAPIClient.swift` | Current iOS API client |
| `scripts/test-production-guards.php` | Smoke test for production guards |

---

## 9. Testing performed (engineering)

| Test | Script / method |
|------|-----------------|
| Rate limits | `scripts/test-rate-limits.php` |
| Secure signup | `scripts/test-signup-secure.php` |
| Secure auth / PIN | `scripts/test-auth-secure.php` |
| Production guards | `scripts/test-production-guards.php` |
| TestFlight CI | GitHub Actions `ios-testflight.yml` (build 110 uploaded) |

No independent third-party security audit was conducted as part of this engagement.

---

## 10. Open issues and limitations

1. **4-digit PIN** — industry-weak; mitigated by rate limits, not eliminated.  
2. **iOS plain JSON auth** — suitable for LAN dev; production should use `*-secure` endpoints.  
3. **Password reset email** — production delivery not fully implemented in code reviewed.  
4. **Obscurity / AI protocol** — discussed and **not adopted** as a security control.  
5. **DDoS** — requires edge provider; documented, not automatically provisioned.  
6. **Legal/compliance** — attorney must assess; engineering brief does not certify compliance with PCI-DSS, SOC 2, state MTL, etc.

---

## 11. Contact and maintenance

- Update this brief when major security architecture changes ship.  
- Suggested version line in git commit messages: `docs: security brief` or `security: production guards`.  
- For technical questions, refer to `docs/PRODUCTION-SECURITY-CHECKLIST.md` and the codebase paths in §8.

---

*End of brief.*
