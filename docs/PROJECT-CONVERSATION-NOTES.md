# Czedr — project notes from development sessions

This file summarizes work and decisions from Cursor chat sessions (May 2026).  
Use it as a handoff if you return later or share the repo with someone else.

---

## Product direction

- **Czedr** replaces legacy Payooze / 3ds3cur3 / S3cur3e branding.
- Users pay by **Czedr ID** on an **internal ledger** (no card required for P2P).
- Sensitive bank/card data, when linked, is split across **planet** MySQL databases (mercury–jupiter); users/sessions/ledger on **saturn**.
- **No single admin** should see full card numbers; field-level encryption + vault split.

---

## What was built

### Backend (`backend/`, `database/`)

- PHP 8.3 REST API at `/v1/*`
- Planet vault, ledger, auth, invoices, bank accounts, audit
- **Secure auth**: image-derived AES (Library of Congress challenge) for signup, login, PIN
- **Forgot password**: `POST /v1/auth/forgot-password`, `POST /v1/auth/reset-password`
- **Legacy bridge**: old iOS paths (`/login`, `/invoicerecev`, etc.) map to v1
- Local dev: `APP_ENV=local` gives **$100 welcome balance** on register

### iOS app (`payooxe/`, `classes/`, `CzedrConfig.h`)

- Wired to `http://127.0.0.1:8080` (or PC LAN IP on device)
- `SharedServiceController` — v1 client + secure login/signup/PIN
- Bundle ID `com.czedr.app`, display name **Czedr**

### iPhone testing without a Mac

- **Safari sandbox**: `scripts/start-iphone-sandbox.ps1` → open `http://<PC-IP>:8080/sandbox`
- Cannot email a config file to change the native app; URLs are baked in at build time
- **TestFlight**: GitHub Actions — see `docs/TESTFLIGHT_SETUP.md`

### Test accounts

- See **`docs/TEST-ACCOUNTS.md`**
- Script: `scripts/create-test-accounts.ps1` → Alice & Bob (`alice@test.czedr` / `bob@test.czedr`, password `TestPass1234!` unless reset)

### Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `start-iphone-sandbox.ps1` | API on `0.0.0.0:8080` for iPhone on Wi‑Fi |
| `start-php-server.ps1` | API on `127.0.0.1` only |
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
| Saturn DB | Users, sessions, ledger, invoices, reset tokens |
| Mercury–Jupiter | Encrypted bank field shards |
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
| iPhone can’t reach API | Same Wi‑Fi; run `start-iphone-sandbox.ps1`; allow firewall port 8080 |
| Undo All in Cursor | Try Redo (`Ctrl+Y`); files on disk were mostly fine; commit protects going forward |
| Alice login fails after tests | Password may have been reset by `test-forgot-password.php`; use forgot-password or re-seed |

---

## Zelle

- No public Zelle API for apps; bank/partner programs only. Czedr uses internal ledger + optional ACH export stub.

---

## Where Cursor stores chat history

- Cursor keeps transcripts under your user profile, e.g.  
  `C:\Users\pc\.cursor\projects\d-CZEDR\agent-transcripts\`  
- This markdown file is the **project-facing** summary; it is safe to commit and share (no secrets).

---

## Next steps (when you continue)

1. Push git to GitHub: `git push origin master`
2. Add Apple/GitHub secrets → run **iOS TestFlight** workflow
3. Point production API via `CZEDR_API_BASE` or workflow `api_base_url` input
4. Optional: real email for password reset (SMTP env vars — not wired yet; local uses `storage/logs/password-reset.log`)

---

*Last updated: May 2026*
