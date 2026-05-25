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

1. Start the API on your PC (`START-IPHONE-TESTING.cmd` or `scripts\start-php-server.ps1`).
2. Open the **`android/`** folder in Android Studio → Sync Gradle → Run.
3. **Emulator:** default API base `http://10.0.2.2:8080` (host machine).
4. **Physical device:** same Wi‑Fi as PC; discovery should find `http://192.168.x.x:8080`, or enter the URL from the script output.

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
