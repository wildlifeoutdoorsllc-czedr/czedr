# Czedr — agent handoff (May 2026)

**Read this first** when continuing work on the Czedr iOS app, TestFlight uploads, or Windows iPhone testing setup.

**Workflow (2026):** `docs/DEVELOPMENT-WORKFLOW.md` — manual TestFlight only; `docs/IOS-BUILD.md` — build numbers; agent rule `.cursor/rules/czedr-workflow.mdc`.

Related docs: `docs/TEST-ACCOUNTS.md`, `docs/TESTFLIGHT_SETUP.md`, `docs/IOS-SWIFTUI.md`, `IPHONE-LOGIN-HELP.txt`, `docs/PROJECT-CONVERSATION-NOTES.md`.

---

## Executive summary (where we left off)

| Area | Status |
|------|--------|
| **Windows dev API** | Working — PHP on `0.0.0.0:8080`, MySQL `saturn`, `APP_ENV=local` |
| **TestFlight on device** | User is on **build 54** — **login still crashes** after sign-in |
| **Fix in git** | **Builds 55–56** on branch `czedrmaster` — **not on TestFlight** |
| **Blocker** | Apple **daily upload limit** (error **90382**) — builds 55+ **built in CI** but **upload failed** |
| **User symptom (build 54)** | Crash **right after Sign in**; user noted it took a **fraction of a second longer** before crash → login API likely succeeds, crash is **post-login UI transition** |
| **Security review** | Done in chat — see [Security review](#security-review-summary) below; no code fixes shipped yet |

**Immediate next action for an agent:** When Apple’s upload limit resets (~24h after failed upload on **2026-05-17**), re-run GitHub Actions **iOS TestFlight** (or confirm build **56** CI finished and upload succeeded). User should install **build 56**, not 54. Keep `START-IPHONE-TESTING.cmd` running on the PC.

---

## Repository

| Item | Value |
|------|--------|
| Path | `C:\Michaels Apps\czedr` |
| Branch | `czedrmaster` |
| Remote | `https://github.com/wildlifeoutdoorsllc-czedr/czedr.git` |
| iOS workflow | `.github/workflows/ios-testflight.yml` |
| Fastlane | `fastlane/Fastfile` → `bundle exec fastlane ios beta` |
| Repo variable | `CZEDR_API_BASE` — e.g. `http://192.168.68.51:8080` (baked into TestFlight builds at CI time) |

**Commit policy:** Commits only when user asks. **Push / TestFlight:** only when user asks to push or ship. TestFlight is **workflow_dispatch** only (not on every push). See `docs/DEVELOPMENT-WORKFLOW.md`.

---

## Windows environment (completed this session)

### Stack
- **PHP 8.3** built-in server → `backend/public` on port **8080**
- **MySQL 8.4** database **`saturn`**
- **`.env`**: `APP_ENV=local` (welcome balance, ledger load allowed locally)

### Entry points
| File | Purpose |
|------|---------|
| `START-IPHONE-TESTING.cmd` (repo root) | Calls `scripts/START-IPHONE-TESTING.cmd` |
| `scripts/START-IPHONE-TESTING.cmd` | Firewall + `start-php-server.ps1` |
| `scripts/start-php-server.ps1` | Migrations, LAN IP display, `php -S 0.0.0.0:8080` |
| `RESTART-IPHONE-TESTING.cmd` | Kill port 8080, open fresh testing window |
| `WATCH-TESTFLIGHT-AND-RESTART.cmd` | Poll `gh` for successful TestFlight runs → auto-restart API |

### Fixes applied locally
- **`scripts/start-php-server.ps1`** — rewritten with ASCII only (smart quotes had broken PowerShell parsing).
- **Firewall** — port 8080 allowed for LAN (user may need `scripts/allow-lan-api-firewall.cmd` as admin on Public Wi‑Fi).

### LAN URLs (example from session)
- PC LAN IP used: **`192.168.68.51`**
- Health: `http://192.168.68.51:8080/v1/health`
- Sandbox: `http://192.168.68.51:8080/sandbox`
- Written to `scripts/iphone-api-url.txt` when server starts

### Test logins
| User | Email | Password | Notes |
|------|-------|----------|--------|
| Alice | `alice@test.czedr` | `TestPass1234!` | Payer; `czedr_id` **CZAB79D695**; `user_pin` **1** in API |
| Bob | `bob@test.czedr` | `TestPass1234!` | Payee |

Reset passwords: `php scripts/reset-test-passwords.php`  
Seed accounts: `scripts/seed-test-accounts.php` or `scripts/create-test-accounts.ps1`

---

## iOS login crash — timeline (builds 51–56)

### Build 51 — force-quit session clear
**Problem:** After swipe-up force-quit, app reopened still “logged in” (`auth_codeSaved` in `NSUserDefaults`).

**Fix:**
- `Czedr/AppDelegate.m` — on cold launch, if logged in → `[CzedrAppChrome clearLocalSession]` before `mainViewSwitch`.
- `classes/CzedrAppChrome.h` — declared `+isLoggedIn`, `+clearLocalSession` (build 51 CI failed once without header; fixed in `1a104cc`).
- Android parity: `CzedrApplication.kt` clears session on new process.

**Commits:** `2b4211d`, `1a104cc`

---

### Builds 52–54 — login crash on Sign in (Alice)
**User report:** Crash immediately (then “fraction of a second longer”) after tapping **Sign in** on TestFlight.

**Diagnosis:** Login API succeeds; crash during **post-login navigation** / HUD / home load.

| Build | Changes | TestFlight upload |
|-------|---------|-------------------|
| **52** | Main-thread API callbacks (`CzedrDispatchMain`); safer `saveLoginPayload` / `auth_token`; `completeLoginWithPayload`; nil-safe Core Data on home | Success |
| **53** | HUD on **window** (`hudHostView`); defer home `setViewControllers`; balance-only on login (no Core Data sync); `viewDidAppear` for home data | Success |
| **54** | **`presentHomeAfterLogin`** replaces **entire** `window.rootViewController`; no full LAN scan on submit (only `testBaseURL`); removed empty `UIMainStoryboardFile` from `Info.plist` | **Success — user still crashes** |

**Commits:** `17e66f1` (52), `b1a775e` (53), `d500b1c` (54)

**Build 49 (context):** Bob crash — `GeneratePinViewController` incorrectly subclassed `ViewController`; fixed to `UIViewController` (`7b2b2a7`).

---

### Builds 55–56 — fix not on device yet
| Build | Changes | TestFlight upload |
|-------|---------|-------------------|
| **55** | **Reuse existing `MMDrawerController`** — `setCenterViewController` instead of replacing window root; defer navigation 1 frame; `hideAllHUDsForView` on window; `presentPinSetupAfterLogin` | **FAILED** — Apple 90382 upload limit |
| **56** | 55 + **suspend session chrome** 1.5s during transition; **close drawer** before center swap; **double defer** login finish; delay home `call_loadCardsService` 0.4s; skip `refreshSessionBar` in `viewDidLayoutSubviews` while suspended | CI **in progress / may fail upload** at handoff (`cc960e4`) |

**Commits:** `170d681` (55), `cc960e4` (56)

### Key files (login flow)
| File | Role |
|------|------|
| `Czedr/ViewController.m` | Sign-in UI, `call_LoginService`, `performLoginRequest`, `completeLoginWithPayload` |
| `Czedr/AppDelegate.m` | `mainViewSwitch`, `presentHomeAfterLogin`, `presentPinSetupAfterLogin` |
| `SharedServiceController.m` | `loginSecureWithEmail`, `saveLoginPayload`, `legacyUserPayloadFromV1`, v1 JSON client |
| `leftSwipeViewController.m` | Home; `call_loadCardsService` (balance); deferred in build 56 |
| `classes/CzedrAppChrome.m` | Session bar; `suspendSessionBarRefreshForSeconds` (build 56) |
| `classes/GeneratePinViewController.m` | PIN setup; `navigateToHomeAfterLogin` |
| `classes/CzedrLanAPIFinder.m` | LAN discovery; `testBaseURL` on submit |
| `CzedrConfig.h` | `CZEDR_USE_V1_API 1`, `CZEDR_API_BASE` (overridden at CI from `CZEDR_API_BASE` var) |

### Session storage (iOS)
- Token: `NSUserDefaults` key **`auth_codeSaved`**
- User payload: **`userDataArray`**
- **Not Keychain** — security note for production
- Cleared on cold launch in `AppDelegate` (build 51)

### Login flow (v1)
1. User enters API URL (auto-discovered on screen open via `CzedrLanAPIFinder.resolve`).
2. Sign in → `testBaseURL` → `POST /v1/auth/login` (plain JSON, not image-secure).
3. `saveLoginPayload` → `completeLoginWithPayload`.
4. If `user_pin == "0"` → PIN screen; else → home.

---

## TestFlight / CI state

### Last known workflow results (2026-05-17)
| Run | Commit / build | Build | Upload |
|-----|----------------|-------|--------|
| Success | build 54 login fix | 54 | Yes — **user on this build** |
| Failure | build 55 Alice fix | 55 | No — **90382 upload limit** |
| Failure | auto-restart scripts | — | No — same limit |
| In progress / TBD | build 56 hardening | 56 | TBD |

**Upload error message:**
```text
Upload limit reached. The upload limit for your application has been reached.
Please wait 1 day and try again. (90382)
```

**To upload when limit resets:**
1. GitHub → **Actions** → **iOS TestFlight** → **Run workflow** (branch `czedrmaster`, build number **56**).
2. Or push a commit touching `Czedr/**` (workflow auto-triggers).
3. User installs from TestFlight; verify build number **56** in app or TestFlight UI.

### Automation added (local PC)
- `scripts/restart-iphone-testing.ps1` — stop :8080, launch `START-IPHONE-TESTING.cmd` in new window.
- `scripts/watch-testflight-and-restart.ps1` — polls `gh run list --workflow ios-testflight.yml`; on new **success**, runs restart script. State: `scripts/.testflight-watch-state.txt` (gitignored).
- User asked agent to **restart testing server after each build upload** — watcher was started in background during session.

**Requires:** `gh auth login` on dev PC.

---

## Security review summary

Static review of `backend/src/` — no exploitation attempted.

### Critical / high (production-relevant)
1. **`POST /v1/ledger/load`** — self-service minting if `APP_ENV=local` or `CZEDR_ALLOW_LEDGER_LOAD=1`.
2. **`REVENUE` / `SYSTEM` czedr_id squatting** at register — can capture platform fees (referrer blocked but not own ID).
3. **Legacy `/updatepin`, `/userpin`** — overwrite PIN without old PIN (iOS still uses these in some flows).
4. **Password reset tokens** logged plaintext to `storage/logs/password-reset.log` in all envs.
5. **Image-derived AES-ECB** “secure” auth — weak; not a substitute for TLS.

### Medium
- 4-digit PIN brute force (no rate limit)
- No API rate limiting
- Profile images public without auth
- Invoice lists expose emails

### Solid
- Prepared statements; Argon2id passwords; hashed session tokens; admin route uses `hash_equals`.

**No security fixes were committed** in this session — only documented.

---

## Android (brief)

- `android/` — Kotlin, `SessionStore` (DataStore), `CzedrApplication.onCreate` clears token on new process (parity with iOS build 51).
- Emulator docs: `docs/ANDROID-EMULATOR-WINDOWS.md`
- Many `scripts/*emulator*` files exist (untracked or local tooling from git status at session start).

---

## Uncommitted / local-only (check `git status`)

At session start, many files were untracked: emulator scripts, `docs/ANDROID-EMULATOR-WINDOWS.md`, `backend/storage/profiles/*.jpg`, etc. Agent should run `git status` before assuming clean tree.

---

## Agent playbook — next session

### 1. Confirm TestFlight build 56
```powershell
gh run list --workflow=ios-testflight.yml --limit 3
gh run view <run-id> --log-failed   # if failed
```

### 2. If upload still blocked
- Wait 24h from last 90382 failure (~2026-05-17 18:24 UTC).
- Do **not** spam CI; one manual workflow run is enough.

### 3. When build 56 is on device
- Run `START-IPHONE-TESTING.cmd` on PC (or `RESTART-IPHONE-TESTING.cmd`).
- TestFlight → install **build 56**.
- Sign in: `alice@test.czedr` / `TestPass1234!`
- **Success criteria:** Home screen with balance; no crash.
- If still crashes: get crash log (Xcode Organizer / Settings → Privacy → Analytics) or note spinner vs instant crash.

### 4. If build 56 still crashes
Consider:
- Symbolicated crash from TestFlight
- Temporarily **disable session bar** entirely after login
- Test on Simulator with Xcode if Mac available
- Verify `CZEDR_API_BASE` in installed IPA matches PC LAN IP

### 5. After successful upload
- Run `RESTART-IPHONE-TESTING.cmd` on user PC (or ensure `WATCH-TESTFLIGHT-AND-RESTART.cmd` is running).

### 6. Security (if user wants)
Prioritize: block reserved `czedr_id`, fix legacy PIN routes, stop logging reset tokens.

---

## Chat transcript reference

Full agent transcript (tool calls stripped in export):  
`C:\Users\pc\.cursor\projects\c-Michaels-Apps-czedr\agent-transcripts\cc9fcfe4-9941-4a37-9103-ba3f058f4e3a\cc9fcfe4-9941-4a37-9103-ba3f058f4e3a.jsonl`

---

## Commit log (this session — newest first)

```
cc960e4 Harden post-login transition for TestFlight build 56.
0658069 Add auto-restart of iPhone testing server after TestFlight uploads.
170d681 Fix Alice login crash: reuse drawer after sign-in (build 55).
d500b1c Fix login crash: replace root UI after sign-in, skip LAN scan on submit (build 54).
b1a775e Fix login crash: HUD on window, defer home navigation (build 53).
17e66f1 Fix login crash: main-thread UI, safe session save, Core Data (build 52).
1a104cc Expose session helpers in CzedrAppChrome header for AppDelegate.
2b4211d Require sign-in again after force-quit (build 51).
```

---

*Handoff written: 2026-05-17. Update this file when build 56 uploads or login is verified.*
