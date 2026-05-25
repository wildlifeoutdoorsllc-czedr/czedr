# Czedr Android

Native **Kotlin + Jetpack Compose** client aligned with **iOS TestFlight build 110** (same JSON API on `/v1/...`).

## Parity with iOS build 110

| Feature | Android |
|---------|---------|
| Wi‑Fi API auto-discovery | Yes (`LanApiFinder`) |
| Sign in / Sign up | Yes |
| API base URL field + status | Yes |
| Home balance + tiles | Yes |
| Make Payment + PIN | Yes |
| Payment success screen | Yes |
| History | Yes |
| Menu drawer + Logout | Yes |
| Set PIN | Yes |
| Build label | **Android · Build 110** |
| Send Invoice / Pending | Placeholder |

## Requirements

- Android Studio Koala+ (JDK 17, Android SDK 34)
- API running: `scripts\start-php-server.ps1` from repo root

## Run

1. Double-click **`START-ANDROID-DEV.cmd`** at repo root (API + `local.properties`).
2. Android Studio → open **`android/`** → **Sync Project with Gradle Files** → **Run** ▶.
3. Guide: **`docs/ANDROID-STUDIO-QUICKSTART.md`**
4. **Emulator:** `http://10.0.2.2:8080` · **Phone:** same Wi‑Fi, use discovery or LAN URL from API window.

Cleartext HTTP is enabled for local dev only (`usesCleartextTraffic`).

## Auth

Uses **`POST /v1/auth/login`** and **`POST /v1/auth/register`** (plain JSON), same as the SwiftUI iOS client on LAN. Production servers may require `*-secure` endpoints — see `docs/PRODUCTION-SECURITY-CHECKLIST.md`.

## Layout

- `data/api/CzedrApi.kt` — HTTP client
- `data/network/LanApiFinder.kt` — subnet health scan
- `data/session/SessionStore.kt` — DataStore session
- `ui/CzedrScreens.kt` — Compose UI + navigation
- `ui/MainViewModel.kt` — state

## Emulator (Windows)

See **`docs/ANDROID-EMULATOR-WINDOWS.md`**. Prefer **Czedr_API30** on Intel Celeron-class PCs.

```powershell
cd D:\CZEDR\scripts
.\start-php-server.ps1
.\start-android-emulator.ps1
```
