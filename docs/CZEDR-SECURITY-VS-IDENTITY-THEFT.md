# Czedr vs real-world identity theft & attacks

**For:** Michael (product owner)  
**Purpose:** Plain-language comparison of how identity theft and online fraud usually happen, versus what Czedr does today.  
**Not:** Legal advice, compliance certification, or a penetration test.

Sources: your repo docs (`ATTORNEY-SECURITY-BRIEF.md`, `PRODUCTION-SECURITY-CHECKLIST.md`, `EDGE-WAF-DDOS.md`, `ATLAS-CONTINUITY.md`, `SUPPORT-HANDOFF-ONEVPS.md`) plus public fraud trends (FTC/ITRC-style reports, 2024–2026).

---

## 1. What you are trying to do (from your documents)

| Goal | Status |
|------|--------|
| Ship **Czedr** — mobile wallet, internal ledger, P2P, optional bank link | App in TestFlight; API **not live** on production server yet |
| Host API at **`https://api.czedr.com`** on OneVPS (`91.220.203.91`) | DNS for `api` is set; server not fully deployed |
| Protect users (passwords, money, bank data) | Strong **server-side** design; **deployment and mobile client** still have gaps |
| Legal/compliance readiness | Attorney brief exists; licensing/KYC not decided in code |
| Avoid “security theater” (fake AI protocols, obscurity) | Correctly rejected in your security discussions |

**Current blocker:** SSH/deploy to OneVPS — not a “missing feature” in the app, but operations.

---

## 2. How most online identity theft & fraud actually happens

These are the **common real-world paths** (not every case, but the majority reported to FTC/ITRC and industry summaries):

| # | Attack | What criminals do | What they get |
|---|--------|-------------------|---------------|
| 1 | **Phishing / smishing** | Fake email, text, or site that looks like your bank or app | Password, sometimes OTP |
| 2 | **Credential stuffing** | Use passwords stolen from *other* breaches; try same email/password on your app | Account login |
| 3 | **Account takeover (ATO)** | Use stolen session token or password; change email/phone; drain money | Full account control |
| 4 | **Device theft** | Steal unlocked phone; use app if no PIN/biometrics | Transfers if app is open |
| 5 | **Malware / infostealers** | Malware on PC/phone steals saved passwords or cookies | Credentials, tokens |
| 6 | **Social engineering** | Call victim pretending to be support; trick them to reveal codes | PIN, password, reset links |
| 7 | **Synthetic identity** | Mix real SSN + fake name/address; open new accounts | New fraudulent accounts |
| 8 | **Server / cloud breach** | Hack poorly secured API or database | All users’ data at once |
| 9 | **Man-in-the-middle** | Intercept traffic on **unencrypted Wi‑Fi** or no TLS | Passwords, tokens in transit |
| 10 | **Insider / misconfiguration** | Leave dev mode on, public database, admin URL exposed | Mass data or free money |
| 11 | **SIM swap** | Take over phone number; intercept SMS OTP | 2FA bypass (if you rely on SMS) |
| 12 | **Supply chain** | Compromise vendor (email, hosting, GitHub secrets) | Keys, deploy access |

**2024–2026 trend:** More **credential stuffing** and **ATO** using **old breach data** (ITRC “previously compromised data”), and **AI-written phishing** that looks legitimate. Obscure custom protocols do **not** stop these.

---

## 3. Comparison: each threat vs Czedr

Legend: **Strong** = well addressed in design | **Partial** = some control, gaps remain | **Weak** = high residual risk | **N/A** = not primary for this product yet | **Ops** = depends on you deploying correctly

| Threat | vs Czedr | Why |
|--------|----------|-----|
| Phishing | **Partial** | User can still type password on a fake site; app can’t fix that alone. Secure signup/login paths help only if the **real app** uses them. |
| Credential stuffing | **Partial** | Rate limits on login/register; Argon2id passwords. Reused passwords from other sites still work **once** until detected. |
| Account takeover | **Partial** | Bearer token in Keychain (iOS) helps; **4-digit PIN** is weak if attacker has token. Lockout after 5 PIN failures helps online guessing. |
| Device theft | **Partial** | PIN required for pay; needs user to lock phone + short session timeout (product choice). |
| Malware on user device | **Weak** | Any app can be attacked if the device is compromised; no substitute for OS security. |
| Social engineering | **Ops / education** | No code stops “support called and asked for your PIN.” |
| Synthetic identity | **Partial** | Email signup; no strong government-ID KYC in repo — fraudster can register fake users if you allow open signup. |
| Server/database breach | **Partial → Strong if deployed right** | Passwords hashed; tokens hashed; bank numbers encrypted vault. **Risk if** `.env` leaked, MySQL exposed to internet, weak VPS. |
| Man-in-the-middle | **Strong in production** | `HttpsGate` blocks HTTP when `APP_ENV=production`. **Weak on LAN dev** (HTTP for testing). |
| Misconfiguration | **Ops** | Flags like `CZEDR_ALLOW_LEDGER_LOAD`, `APP_ENV=local`, weak admin token = catastrophic. Checklist exists. |
| SIM swap | **N/A** | Czedr does not rely on SMS OTP in core design reviewed. |
| DDoS / outage | **Ops** | Needs Cloudflare/WAF; PHP limits alone insufficient (`EDGE-WAF-DDOS.md`). |
| Webhook forgery (Moov) | **Partial** | Only if ACH enabled; needs `MOOV_WEBHOOK_SECRET`. |
| **Custom “AI norm code” obscurity** | **Not a defense** | Your docs correctly say TLS + auth matter; obscurity does not replace them. |

---

## 4. Highest failure points for Czedr **right now**

Ordered by impact if you go live without fixing:

| Priority | Failure point | What goes wrong |
|----------|---------------|-----------------|
| **P0** | API **not deployed** with TLS on production | Users can’t use prod safely; or you test on HTTP forever |
| **P0** | `APP_ENV=local` or dev flags on public server | Free money load, plain auth, sandbox pages, welcome balance |
| **P0** | No **Cloudflare/WAF** in front of origin | DDoS, password-guessing at scale overwhelms 2 GB VPS |
| **P0** | MySQL or `.env` exposed to internet | Full database + secrets stolen — worst-case breach |
| **P1** | iOS/Android still use **plain** `/v1/auth/login` in production build | Password visible on network if plain auth allowed server-side |
| **P1** | **4-digit PIN** + stolen Bearer token | Attacker can try PIN (mitigated by lockout, not eliminated) |
| **P1** | Password reset **email not fully wired** | Weak recovery or support burden; users pick bad flows |
| **P1** | **Origin IP published** without CDN-only firewall | Attackers bypass Cloudflare and hit VPS directly |
| **P2** | No formal **penetration test** | Unknown holes in PHP/routes |
| **P2** | Open registration without KYC | Fake accounts, referral abuse, laundering risk (legal + fraud) |
| **P2** | `auth_code` in URL for profile images | Token leakage via logs/referrer (checklist says remove in prod) |
| **P3** | Weak VPS provider ops (SSH password, no updates) | Server takeover — not app code |

---

## 5. What Czedr does **well** (you should not undervalue this)

- Passwords: **Argon2id** (industry standard).
- Sessions: random token, **hashed** in database.
- PIN: **Argon2id** + lockout.
- Production guards: block plain auth, legacy routes, dev HTML, self-ledger load (when `APP_ENV=production`).
- HTTPS enforcement in production.
- Rate limits on auth endpoints.
- Bank account storage: encrypted vault (when used).
- Documentation: attorney brief, production checklist, edge/WAF guide.

This is **better than many small fintech MVPs** at the code level. The gap is **deployment, mobile client alignment, and operations** — not “no security thought.”

---

## 6. What does **not** protect users (common misconceptions)

| Idea | Reality |
|------|---------|
| Custom AI / “norm code” gateway | Does not stop phishing or stolen passwords |
| Duplicate “sandbox server” for DDoS | Useless if real IP is known; use CDN |
| Hiding API path names | Minor; attackers find routes |
| Only using TestFlight | Security = production server + app build + user behavior |

---

## 7. Recommended order of work (non-technical owner view)

1. **Get on the server** — SSH port 22122, deploy API (`DEPLOY-ONEVPS-CZEDR.md`).
2. **Turn on HTTPS** — `https://api.czedr.com` only.
3. **Cloudflare** in front — hide origin, rate-limit login paths.
4. **Production `.env`** — checklist P0 items; never enable dev flags.
5. **Ship app build** that uses **secure auth** endpoints for production API URL.
6. **Attorney + licensing** — money transmission / stored value (outside engineering).
7. **Paid penetration test** before marketing to strangers.

---

## 8. How this relates to paying for Cursor

Cursor helps **write and review** code and docs; it does **not**:

- Host your API
- Reset OneVPS passwords
- Replace a security auditor or lawyer
- Guarantee one assistant personality across projects

Your **$60/month** is for the **tool**; **Atlas-style** help means clear, step-by-step guidance in the right project (SocialXads vs Czedr) — not a separate product tier.

---

## 9. Document index (your “notes” consolidated)

| File | Contents |
|------|----------|
| This file | Identity theft vs Czedr |
| `ATTORNEY-SECURITY-BRIEF.md` | Counsel overview |
| `PRODUCTION-SECURITY-CHECKLIST.md` | P0–P3 technical fixes |
| `EDGE-WAF-DDOS.md` | Cloudflare/nginx |
| `SUPPORT-HANDOFF-ONEVPS.md` | VPS + DNS + support ticket |
| `ATLAS-CONTINUITY.md` | How you prefer to work with assistants |
| `AGENT-HANDOFF.md` | Latest app/build status |

---

*End of document.*
