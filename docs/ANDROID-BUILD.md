# Android build tracker

| Field | Value |
|-------|--------|
| **Aligned with iOS** | TestFlight **build 110** |
| **Android versionName** | **110** (`android/app/build.gradle.kts`) |
| **Package** | `com.czedr.app` |

## Run

1. `scripts\start-php-server.ps1` on the PC  
2. Android Studio → Open `android/` → Run on emulator or device  
3. Sign-in screen shows **Android · Build 110**

## vs iOS 110

Same API flows for LAN testing: discovery, register, login, balance, PIN, transfer, success screen, history, menu logout.

Not yet ported: secure auth (`login-secure`), bank link UI, funding screens, invoice send (placeholder only).
