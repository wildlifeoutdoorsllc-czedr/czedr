# Edge protection: dictionary attacks, DDoS, and honeypots

How to shield the Czedr API **before** traffic reaches PHP. Complements in-app `RateLimiter` and `ProductionRouteGuard`.

See also: `docs/PRODUCTION-SECURITY-CHECKLIST.md`, `docs/DEPLOY-HTTPS.md`.

---

## Layered model

| Layer | Stops | Tool examples |
|-------|--------|----------------|
| 1 — CDN / WAF | Volume DDoS, obvious bots | Cloudflare, AWS WAF, Azure Front Door |
| 2 — Reverse proxy | Per-IP rate limits, TLS | nginx, Caddy |
| 3 — PHP API | Per-email login limits, PIN lockout | `RateLimiter.php`, `AuthService.php` |
| 4 — App (iOS) | Stolen device risk | Keychain, HTTPS, PIN |

Under a volumetric DDoS, layers 3–4 may never run. **Always use layer 1–2 in production.**

---

## Dictionary / credential stuffing

**Signals:** many `POST` to auth paths, high failure rate, one IP / many emails.

### Cloudflare (example)

- **Rate limiting rule:** `http.request.uri.path` contains `/v1/auth/login` → 10 requests / minute / IP → Block or Managed Challenge
- Same for `/v1/auth/register`, `/v1/auth/forgot-password`
- **Bot Fight Mode** on staging/production zone

### nginx (on origin)

```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;

location ~ ^/v1/auth/(login|register|forgot-password) {
    limit_req zone=auth burst=5 nodelay;
    proxy_pass http://127.0.0.1:8080;
}
```

### Application (already in repo)

| Path | Limit | File |
|------|-------|------|
| `/v1/auth/login` | 10 / 15 min / IP + email | `App.php` `handleLogin()` |
| `/v1/auth/register` | 5 / hour / IP | `guardRegisterAttempt()` |
| PIN failures | 5 → 30 min lockout | `AuthService.php` |

**Production:** plain `/v1/auth/login` and `/register` return **404** unless `CZEDR_ALLOW_PLAIN_AUTH=1`. Prefer `/v1/auth/*-secure` from clients.

---

## DDoS (volume)

A separate “sandbox server” does **not** absorb a flood if the attacker knows your **origin IP**. Use:

1. **Hide origin** — DNS only to CDN; firewall allows only CDN IP ranges to port 443.
2. **Anycast CDN** — absorbs L3/L4 and much L7.
3. **Do not expose** `php -S 0.0.0.0:8080` on the public internet.

### Optional “sink” / honeypot

| Pattern | Use |
|---------|-----|
| WAF routes high bot score to `sink.yourdomain.com` | Static 429 page or slow honeypot |
| Fake `POST /login` on honeypot | Log attacker IPs (research) |
| Fail2ban on nginx `access.log` | Ban IPs after N 401/429 |

Not a substitute for CDN DDoS protection.

---

## Path reference (strict limits)

| Path | Suggested edge limit |
|------|----------------------|
| `POST /v1/auth/login*` | 10/min/IP |
| `POST /v1/auth/register*` | 5/min/IP |
| `POST /v1/auth/forgot-password` | 3/hour/IP |
| `GET /v1/health` | 60/min/IP (or CDN cache) |
| `POST /v1/transfers` | 30/min/IP (authenticated) |

---

## Verify

```bash
# Health via CDN
curl -sS https://api.yourdomain.com/v1/health

# Plain auth blocked in production (expect 404)
curl -sS -X POST https://api.yourdomain.com/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"a@b.com","password":"test"}'

# Sandbox HTML blocked (expect 404 JSON)
curl -sS -o /dev/null -w "%{http_code}" https://api.yourdomain.com/sandbox
```

```powershell
php scripts/test-rate-limits.php
php scripts/test-production-guards.php
```

---

## iOS / TestFlight note

Current SwiftUI client (`CzedrAPIClient.swift`) uses **plain** `/v1/auth/login` and `/register` for home Wi‑Fi testing. Against a **production** API:

- Set `CZEDR_ALLOW_PLAIN_AUTH=1` only during migration, **or**
- Ship an app build that uses `login-secure` / `register-secure` (see `SharedServiceController.m` and `scripts/test-auth-secure.php`).

Local dev (`APP_ENV=local`) keeps plain auth enabled.
