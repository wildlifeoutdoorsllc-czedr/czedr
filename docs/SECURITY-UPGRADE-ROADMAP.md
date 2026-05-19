# Czedr security upgrade roadmap

Phased plan to raise protection **without changing how the app feels** to users (same screens, same sign-in flow, same TestFlight builds). Work can be done in order; each phase stands alone.

**Current snapshot (after security pass, May 2026)**

| Layer | Today | Grade |
|-------|--------|-------|
| Passwords in DB | Argon2id | Strong |
| Session tokens | Hashed server-side | Good |
| Image challenge | AES-256-ECB + `image_b64` sync (build 74) | Obfuscation only |
| Local iPhone testing | HTTP on Wi‑Fi (`http://192.168.x.x:8080`) | No wire encryption (OK for `APP_ENV=local`) |
| Login / PIN brute force | **Rate limits** (see below) | Improved |
| Production HTTPS | **Enforced** when `APP_ENV` ≠ `local` | Ready when you deploy TLS |
| Reserved IDs | **REVENUE / SYSTEM** blocked at register | Fixed |
| Reset token logs | Plain token **local only**; hash in production | Fixed |

### Implemented in code (restart `START-IPHONE-TESTING.cmd` to apply)

| Control | Limit |
|---------|--------|
| Login failures | 10 / 15 min per IP and per email |
| Registration | 5 / hour per IP |
| Signup challenge | 30 / hour per IP |
| PIN verify failures | 5 / 15 min per user |
| Forgot password | 3 / hour per IP and per email |
| Production HTTP | Blocked unless `CZEDR_ALLOW_HTTP=1` |
| Disable limits (debug) | `CZEDR_RATE_LIMIT=0` in `.env` |

---

## Design principle

> **HTTPS protects the wire. Argon2id protects stored passwords. Image challenge adds a one-time envelope for legacy compatibility — it is not a substitute for TLS.**

Users should not see new steps, new screens, or “security mode.” Engineers change infrastructure and algorithms behind the same APIs where possible.

---

## Phase 1 — HTTPS everywhere (highest impact) — **gate ready, deploy when you have a domain**

**Goal:** Encrypt all traffic between phone and API so Wi‑Fi sniffing cannot read passwords or tokens.

**Code status:** `HttpsGate` blocks HTTP when `APP_ENV` is not `local`. See **`docs/DEPLOY-HTTPS.md`**.

**User impact:** None if API URL stays the same host (only `http` → `https`).

### 1A — Staging / production API

| Task | Notes |
|------|--------|
| Host API behind TLS | Nginx, Caddy, or cloud load balancer terminating TLS 1.2+ |
| Certificate | Let’s Encrypt (free) or cloud-managed cert |
| Force HTTPS | Redirect `http` → `https`; HSTS header after stable |
| Set `APP_ENV=production` | Disables welcome balance mint, reset tokens in JSON, ledger load |
| Set `CZEDR_API_BASE` in CI | `https://api.yourdomain.com` in GitHub Actions variable for TestFlight builds |

### 1B — Local dev (optional, for paranoid LAN testing)

| Option | Effort | Notes |
|--------|--------|--------|
| **mkcert** + reverse proxy | Medium | `https://192.168.x.x` with trusted cert on your PC; install mkcert root on iPhone once |
| Keep HTTP on LAN only | Low | Acceptable for home TestFlight; **not** for coffee-shop Wi‑Fi demos |

### 1C — iOS app

| Task | Notes |
|------|--------|
| Compile `CZEDR_API_BASE` as `https://...` | Already supported via workflow / `CzedrConfig.h` |
| ATS (App Transport Security) | Default blocks plain HTTP in production builds — HTTPS required for App Store |
| LAN finder | `CzedrLanAPIFinder` can probe `https://` first, then `http://` only in debug builds if needed |

### 1D — Verification

```bash
curl -sS https://api.yourdomain.com/v1/health
# Expect Status: true
```

Sign in on device; confirm Charles/mitmproxy shows TLS, not cleartext JSON passwords.

**Done when:** TestFlight build points at `https://` API; no production traffic over HTTP.

---

## Phase 2 — Rate limits and abuse controls ✅ **Done**

Implemented in `backend/src/Security/RateLimiter.php`, migration `010_rate_limits.sql`, wired in `App.php`.

**Test:** `php scripts/test-rate-limits.php` (API must be running).

**User impact:** After repeated wrong passwords, users see: *“Too many attempts. Please try again later.”*

### Hardening (build 76) ✅

| Item | Status |
|------|--------|
| Legacy `/updatepin` without old PIN | **Blocked** — requires `old_pin` + `new_pin` |
| Legacy `/userpin` overwrite | **Blocked** if PIN already set |
| Profile photos public | **Auth required** (Bearer or `auth_code` query on own files only) |
| PIN brute force | **Account lockout** — 5 failures → 30 min lock |
| Email user after lockout | Not yet |
| CAPTCHA on register | Only if bots appear |

---

## Phase 3 — Modernize payload crypto ✅ **Done (build 75)**

**User impact:** None — same screens; stronger invisible encryption.

| Component | Implementation |
|-----------|----------------|
| Cipher | **AES-256-GCM** (12-byte random IV, 16-byte auth tag per request) |
| Key derivation | **HKDF-SHA256** from full image bytes + `challenge_id` |
| Wire format | `0x02` + IV + tag + ciphertext (base64), `crypto_version: 2` |
| Server optional pepper | `CZEDR_CRYPTO_PEPPER` in `.env` |
| Legacy v1 | Server still decrypts old ECB clients; new app sends v2 only |
| iOS plain-register fallback | **Removed** (secure path only) |

**Test:** `php scripts/test-crypto-v2-roundtrip.php`

**Note:** This is the **strongest practical design** for an image-bound envelope. True classified/military systems add HSMs, key escrow, and accredited modules — not achievable in a consumer app alone.

---

## Phase 4 — Production hygiene (parallel / ongoing)

**Goal:** Close known gaps from the security audit without UX change.

| Priority | Item | Action |
|----------|------|--------|
| Critical | `POST /v1/ledger/load` | Keep disabled unless `APP_ENV=local` or explicit staging flag (already gated) |
| Critical | `REVENUE` / `SYSTEM` czedr_id squatting | Reject reserved IDs at register |
| High | Legacy PIN routes without old PIN | Route iOS to `/pin/update-secure` only; deprecate legacy |
| High | Reset tokens in log file | Log hash only, or disable file log in production |
| Medium | Profile images public | Require auth or signed URLs for `/v1/media/profile/` |
| Medium | Invoice list emails | Scope to authenticated user only (verify queries) |
| Low | API request logging | Redact `enc_data`, passwords, Bearer tokens |

---

## Suggested timeline

| Phase | Effort (dev) | When |
|-------|----------------|------|
| **1 — HTTPS** | 1–3 days (hosting + DNS + TestFlight URL) | Before public beta / App Store |
| **2 — Rate limits** | 2–4 days | Same release train as HTTPS |
| **3 — Crypto v2** | 1–2 weeks | After HTTPS live; can ship in app build + server together |
| **4 — Hygiene** | Ongoing | Sprinkle into PRs |

Phases 1 + 2 give the largest real-world gain for users. Phase 3 is “audit polish” and long-term maintainability.

---

## What users will **not** see

- No extra registration steps
- No “verify image puzzle” UI (image stays invisible)
- No change to menu, home, payments, or PIN screens
- Same TestFlight install flow; only the compiled API URL may change to `https://`

---

## What engineers should track per release

- [ ] `APP_ENV=production` on public server
- [ ] `CZEDR_API_BASE` uses `https://`
- [ ] TLS certificate auto-renewal
- [ ] Rate limit 429 tested on login
- [ ] `scripts/test-signup-secure.php` passes against staging
- [ ] No passwords in application logs
- [ ] Build number bumped; TestFlight smoke: register, login, pay, PIN

---

## Quick reference — encryption levels

| Question | Answer |
|----------|--------|
| Are passwords encrypted in the database? | **Hashed** with Argon2id (one-way; industry standard) |
| Is sign-in encrypted over the air on your PC Wi‑Fi test? | **Only if HTTPS** — current `http://192.168.x.x:8080` is **not** |
| What does the LoC image do? | Derives a one-time key so the JSON body is not plain text in logs |
| Is that “bank level”? | **No** — bank apps rely on TLS + regulated infra; image layer is supplemental |
| After this roadmap? | **Bank-like wire security** via HTTPS + **strong storage** via Argon2id + **abuse resistance** via rate limits; image layer optional/modernized |

---

## Related docs

- `docs/AGENT-HANDOFF.md` — audit findings
- `docs/TESTFLIGHT_SETUP.md` — `CZEDR_API_BASE` and CI
- `docs/PROJECT-CONVERSATION-NOTES.md` — image challenge summary
- `backend/src/Security/ImageDerivedCryptor.php` — current v1 crypto
- `scripts/test-signup-secure.php` — regression test after crypto changes
