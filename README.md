# Czedr

Secure P2P payments by **Czedr ID** — iOS client and PHP API with an **internal ledger only**. There is **no card processing, no ACH, and no bank linking**; money exists only as Czedr balances. Optional per-transfer **sender-paid** platform fees accrue to a `REVENUE` ledger account. **Single-level referrals:** new signups can record a referrer’s Czedr ID; when they **send** money, the referrer earns a small configurable reward (`CZEDR_REFERRAL_REWARD_CENTS`, default 17¢) minted from the system ledger.

## Using local for now (recommended)

Everything runs on your **Windows PC + same Wi‑Fi iPhone**. No hosted API required yet.

1. DB: run `scripts\install-backend.ps1` (creates **saturn** only) + `.env` — see `docs/TEST-ACCOUNTS.md`
2. Start API: `scripts\start-iphone-sandbox.ps1`
3. On iPhone **Safari**: URL shown by the script, e.g. `http://192.168.x.x:8080/sandbox`
4. Same URL pattern for the **TestFlight** app once built: use workflow input **`api_base_url`** = `http://YOUR_PC_LAN_IP:8080` (physical devices cannot use `127.0.0.1`)

Simulator on PC can use `http://127.0.0.1:8080`; see `CzedrConfig.h`.

## Local dev (Windows)

1. MySQL + PHP — see `scripts/` and `docs/TEST-ACCOUNTS.md`
2. Start API: `scripts\start-iphone-sandbox.ps1`
3. iPhone Safari: `http://YOUR_PC_IP:8080/sandbox`

## TestFlight

See `docs/TESTFLIGHT_SETUP.md` and GitHub Actions workflow **iOS TestFlight**.

## Test accounts

`alice@test.czedr` / `bob@test.czedr` — password `TestPass1234!` (reset: `php scripts/reset-test-passwords.php`).
