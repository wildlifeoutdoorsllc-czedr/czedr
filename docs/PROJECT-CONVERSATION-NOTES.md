# Czedr — project notes from development sessions

This file summarizes work and decisions from Cursor chat sessions (May 2026).  
Use it as a handoff if you return later or share the repo with someone else.

> **Latest full handoff (login crash, TestFlight builds 51–56, Windows setup, security review):**  
> **`docs/AGENT-HANDOFF.md`** — start there for the next agent.

---

## Product direction

- **Czedr** replaces legacy Payooze / 3ds3cur3 / S3cur3e branding.
- Users pay by **Czedr ID** on an **internal ledger** only: **no** card, **no** ACH, **no** bank account storage in the shipped API.
- **Single MySQL database (`saturn`)** holds users, sessions, ledger, invoices, and audit. (Planet-split vault code was removed from the runtime product to reduce scope and risk.)

---

## What was built

### Backend (`backend/`, `database/`)

- PHP 8.3 REST API at `/v1/*`
- Ledger, auth, invoices, audit (`saturn` schema only)
- **Secure auth**: image-derived AES (Library of Congress challenge) for signup, login, PIN
- **Forgot password**: `POST /v1/auth/forgot-password`, `POST /v1/auth/reset-password`
- **Legacy bridge**: old iOS paths (`/login`, `/invoicerecev`, etc.) map to v1
- Local dev: `APP_ENV=local` gives **$100 welcome balance** on register

### iOS app (`payooxe/`, `classes/`, `CzedrConfig.h`)

- Wired to `http://127.0.0.1:8080` (or PC LAN IP on device)
- `SharedServiceController` — v1 client + secure login/signup/PIN
- Bundle ID `com.czedr.app`, display name **Czedr**

### iPhone testing without a Mac

- **Safari sandbox**: `scripts/start-php-server.ps1` → open `http://<PC-IP>:8080/sandbox` (`start-iphone-sandbox.ps1` is the same)
- Cannot email a config file to change the native app; URLs are baked in at build time
- **TestFlight**: GitHub Actions — see `docs/TESTFLIGHT_SETUP.md`

### Test accounts

- See **`docs/TEST-ACCOUNTS.md`**
- Script: `scripts/create-test-accounts.ps1` → Alice & Bob (`alice@test.czedr` / `bob@test.czedr`, password `TestPass1234!` unless reset)

### Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `start-php-server.ps1` | API on `0.0.0.0:8080` (emulator + LAN). `start-iphone-sandbox.ps1` calls this script. |
| `create-test-accounts.ps1` | Seed Alice/Bob |
| `test-api.php` | API smoke test |
| `test-transfer-demo.php` | Two-user transfer |
| `test-signup-secure.php` / `test-auth-secure.php` | Secure crypto flows |
| `test-forgot-password.php` | Forgot-password flow |

---

## Architecture (short)

| Piece | Role |
|-------|------|
| `czedr_id` | Public ID (e.g. `CZAB79D695`) |
| Saturn DB | Users, sessions, ledger, invoices, audit, reset tokens |
| Image challenge | Random LoC image; key = base64(image)[0:16] + md5(challenge_id)[0:16]; AES-256-ECB |

---

## Git save (code)

- Commit **`2882e3c`**: full platform snapshot (415 files).
- **Not in git** (on purpose): `.env`, `DB details for Czedr.txt`, `*.pptx`.

---

## Common issues & fixes

| Symptom | Fix |
|---------|-----|
| `{"result":"Not found"}` | Legacy path or server not running; use `/v1/...` or legacy bridge; restart PHP |
| iPhone can’t reach API | Same Wi‑Fi; run `start-php-server.ps1`; allow firewall port 8080 |
| Undo All in Cursor | Try Redo (`Ctrl+Y`); files on disk were mostly fine; commit protects going forward |
| Alice login fails after tests | Password may have been reset by `test-forgot-password.php`; use forgot-password or re-seed |

---

## Zelle

- No public Zelle API for apps; bank/partner programs only. Czedr settles value on the **internal ledger** only.

---

## Where Cursor stores chat history

- Cursor keeps transcripts under your user profile, e.g.  
  `C:\Users\pc\.cursor\projects\d-CZEDR\agent-transcripts\`  
- This markdown file is the **project-facing** summary; it is safe to commit and share (no secrets).

---

## Next steps (when you continue)

See **`docs/AGENT-HANDOFF.md`** for current priorities. Short version:

1. Upload **build 56** to TestFlight when Apple daily limit (90382) resets.
2. User tests login on **build 56** (not 54) with `START-IPHONE-TESTING.cmd` running.
3. Optional: security fixes (reserved `czedr_id`, legacy PIN routes, reset-token logging).
4. Optional: real email for password reset (SMTP not wired; local uses `storage/logs/password-reset.log`).

---

*Last updated: 2026-05-17*
