# Czedr test accounts (Alice & Bob)

Keep this file for later. Use two accounts to send money to each other in the **iPhone Safari sandbox** or via the API.

---

## Start the server (Windows PC only)

```powershell
cd D:\CZEDR\scripts
.\start-iphone-sandbox.ps1
```

Leave that window open. Note the line:

`iPhone Safari: http://192.168.x.x:8080/sandbox`

(iPhone and PC must be on the **same Wi‑Fi**.)

---

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
3. Amount e.g. `25` → **Send payment** → **Refresh balance**.

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
| iPhone can’t open sandbox URL | Same Wi‑Fi; allow Windows Firewall port **8080**; use IP from `start-iphone-sandbox.ps1` |
| Sign-in failed / Invalid credentials | API not running; or password changed by `test-forgot-password.php` — run `php scripts/reset-test-passwords.php` or `create-test-accounts.ps1` again |
| Invalid Czedr ID | Copy ID from latest `create-test-accounts.ps1` output |
| $0 balance | Check `.env` has `APP_ENV=local`; register a **new** email |

---

## TestFlight (real app later)

See `docs/TESTFLIGHT_SETUP.md`. Same backend; app install via TestFlight, not Safari.
