# Czedr

Secure P2P payments by **Czedr ID** — iOS client, PHP API, and planet-split MySQL vault.

## Local dev (Windows)

1. MySQL + PHP — see `scripts/` and `docs/TEST-ACCOUNTS.md`
2. Start API: `scripts\start-iphone-sandbox.ps1`
3. iPhone Safari: `http://YOUR_PC_IP:8080/sandbox`

## TestFlight

See `docs/TESTFLIGHT_SETUP.md` and GitHub Actions workflow **iOS TestFlight**.

## Test accounts

`alice@test.czedr` / `bob@test.czedr` — password `TestPass1234!` (reset: `php scripts/reset-test-passwords.php`).
