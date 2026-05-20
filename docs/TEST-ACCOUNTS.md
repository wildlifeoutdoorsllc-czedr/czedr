# Czedr test accounts (Alice & Bob)

Keep this file for later. Use two accounts to send money to each other in the **iPhone Safari sandbox** or via the API.

**Database:** First-time setup runs `scripts\install-backend.ps1` once — it creates only the **`saturn`** schema (no planet vault databases), then runs **`php scripts/run-migrations.php`** so all **`database/migrations/*.sql`** files are applied exactly once (recorded in **`schema_migrations`**). On existing servers, run **`php scripts/run-migrations.php`** after deploy when you add new migration files. Optionally set **`CZEDR_AUTO_MIGRATE=1`** in `.env` so the web entrypoint applies pending migrations before handling requests (first hit after deploy runs DDL; ensure the DB user may **ALTER** tables).

**Production safety:** Set **`APP_ENV=production`** on real deployments (or omit `APP_ENV` — it defaults to production). That disables the **`$100` welcome credit**, hides **`reset_token` in forgot-password JSON**, returns **404** for **`GET /v1/dev/setup`**, and blocks **`POST /v1/ledger/load`** unless you explicitly set **`CZEDR_ALLOW_LEDGER_LOAD=1`**. Run **`php scripts/test-env-security.php`** for quick checks.

**Staff vs member (directory privacy):** New rows default to **`role=member`**. Only **`staff`** users see another person’s **email** when validating a Czedr ID (`GET /v1/users/validate` and legacy **`valid_recipient`**). Other users get a **masked** label (e.g. last few ID characters), not an email. Promote only trusted accounts, directly in MySQL:  
`UPDATE users SET role = 'staff' WHERE email = 'trusted-ops@yourorg.com' LIMIT 1;`  
Apply migration **`database/migrations/008_user_role.sql`** (included in **`install-backend.ps1`**) before relying on this. Platform revenue totals stay **`CZEDR_ADMIN_REPORT_TOKEN`** + **`GET /v1/admin/revenue-ledger`** — that bearer secret is separate from app accounts.

**Referrals (single-level):** At signup, pass optional **`referrer_czedr_id`** (or **`referred_by_czedr_id`**) with an existing member’s Czedr ID. When that new member **sends** a P2P payment, their referrer receives **`CZEDR_REFERRAL_REWARD_CENTS`** (default **17** = $0.17) minted from the system ledger—not taken from the payment or fee. Only **one** hop (no pyramids). Referral rewards are **normal ledger credits** (same balance as everything else). See totals with **`GET /v1/referrals/earnings`** (auth), the sandbox **Referral earnings** button, or in the native app use the **Referral earnings** bar at the bottom of the home screen (or tap the **balance** line when signed in).

**Platform fees (ops):** Transfers can credit internal user **`REVENUE`**. To read that ledger balance, set **`CZEDR_ADMIN_REPORT_TOKEN`** in `.env` and call **`GET /v1/admin/revenue-ledger`** with header **`Authorization: Bearer <token>`** or **`X-Czedr-Admin-Token`**. If the token env var is unset, that URL returns 404.

---

## Start the server (Windows PC only)

```powershell
cd D:\CZEDR\scripts
.\start-php-server.ps1
```

Leave that window open. The script prints **health** and **sandbox** URLs for this PC and your **LAN IP**, for example:

`http://192.168.x.x:8080/sandbox`

(Phone and PC must be on the **same Wi‑Fi** for LAN URLs. **`start-iphone-sandbox.ps1`** runs the same server.)

---

## Add $10,000 to Alice and Bob (PC)

```powershell
cd D:\CZEDR\scripts
.\fund-test-accounts.ps1
```

Credits **$10,000** to each test account via the ledger API and prints balances. After Alice sends money to Bob, run again (or check REVENUE with `CZEDR_ADMIN_REPORT_TOKEN` in `.env`) to confirm the **$1.29** platform fee landed in the **REVENUE** account.

## Create or refresh test accounts (PC)

```powershell
cd D:\CZEDR\scripts
.\create-test-accounts.ps1
```

That prints the **current** Czedr IDs and balances. IDs stay the same if the accounts already exist; new installs get new IDs.

### Default logins

| Role | Email | Password |
|------|--------|----------|
| Alice (payer) | `alice@test.czedr` | `TestPass1234!` |
| Bob (receiver) | `bob@test.czedr` | `TestPass1234!` |

Local dev (`APP_ENV=local` in `.env`) gives each account **$100** welcome balance on first signup.

**Last seeded IDs (your machine — re-run script if unsure):**

| | Czedr ID |
|---|----------|
| Alice | `CZAB79D695` |
| Bob | `CZ93EE0AF0` |

---

## On iPhone (Safari only — no PowerShell on the phone)

1. Open the sandbox URL from the PC script (e.g. `http://192.168.68.51:8080/sandbox`).
2. Tap **Use this page’s host** → **Health check** (should say online).
3. **Auth** → **Sign in** as Alice or Bob (table above).

### Send Alice → Bob

1. Signed in as **Alice**.
2. **Money** tab → **Pay Czedr ID** → Bob’s ID (from script output, e.g. `CZ93EE0AF0`).
3. Amount e.g. `25` → **Send payment** → **Refresh balance**. The **sender** pays the platform fee (default **$1.29** per transfer via `CZEDR_TRANSFER_FEE_CENTS`); the **recipient receives the full amount** you entered. Set the fee to `0` in `.env` for local dev if you like.

### Send Bob → Alice

1. **Auth** → **Sign out**.
2. Sign in as **Bob**.
3. **Money** → pay Alice’s ID (e.g. `CZAB79D695`).

### Optional PIN (sandbox)

**PIN** tab → set `1234` after login. Not required for transfers in the web sandbox.

### Forgot password

**Sandbox:** Auth → **Forgot password** → enter email → **Send reset code** → use code shown (local dev) → new password → **Set new password**.

**App:** Login screen → **Forgot password?** → same flow. Local dev shows the reset code on screen; check `storage/logs/password-reset.log` on the PC.

---

## Create your own account (instead of Alice/Bob)

Sandbox → **Auth** → **Create account**

- Email: anything valid (e.g. `you@test.czedr`)
- Password: **10+ characters** (e.g. `TestPass1234!`)

---

## Two-user transfer demo (PC terminal)

```powershell
php D:\CZEDR\scripts\test-transfer-demo.php
```

Creates random Alice/Bob emails and prints IDs for API testing.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| iPhone can’t open sandbox URL | Same Wi‑Fi; allow Windows Firewall port **8080**; use IP printed by `start-php-server.ps1` |
| Sign-in failed / Invalid credentials | API not running; or password changed by `test-forgot-password.php` — run `php scripts/reset-test-passwords.php` or `create-test-accounts.ps1` again |
| Invalid Czedr ID | Copy ID from latest `create-test-accounts.ps1` output |
| $0 balance | Check `.env` has `APP_ENV=local`; register a **new** email |

---

## TestFlight (real app later)

See `docs/TESTFLIGHT_SETUP.md`. Same backend; app install via TestFlight, not Safari.
