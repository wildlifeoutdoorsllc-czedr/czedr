# Android Studio — quick start

Do this once, then **Run** ▶ whenever you test.

## One-click (Windows)

Double-click **`START-ANDROID-DEV.cmd`** at the repo root. It:

1. Starts the PHP API (`scripts/start-php-server.ps1`) in a separate window — **keep it open**
2. Writes `android/local.properties` (SDK path for Gradle)

## In Android Studio

1. **File → Open** → `C:\Michaels Apps\czedr\android` (the `android` folder only)
2. **File → Sync Project with Gradle Files** (wait until finished)
3. **Run target:** prefer a **physical phone** (USB debugging) — see **`docs/ANDROID-PHYSICAL-DEVICE.md`**
4. **Avoid the emulator** on this PC if it froze or crashed Windows (Celeron + 16 GB RAM is often too tight).
5. If you still use an emulator: **Czedr_API30** only, nothing else running, long boot wait.
6. Select the **app** run configuration → **Run** ▶

Sign-in screen should show **Android · Build 110**.

## API URL

| Device | API base |
|--------|----------|
| Emulator | `http://10.0.2.2:8080` (default) |
| Physical phone (same Wi‑Fi) | `http://YOUR_PC_IP:8080` (from API window) |

## Test account

| Email | Password |
|-------|----------|
| `alice@test.czedr` | `TestPass1234!` |

Set a **4-digit PIN** from the menu before **Make Payment**.

## Build from terminal (optional)

```powershell
cd C:\Michaels Apps\czedr\android
.\gradlew.bat assembleDebug
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Gradle sync fails | Run `scripts\setup-android-local.ps1`; install SDK API 34 in SDK Manager |
| Red errors in `CzedrApi.kt` | **File → Sync** then **Build → Rebuild** (fixes are on `czedrmaster`) |
| Cannot reach server | API window must stay open; emulator uses `10.0.2.2` not your LAN IP |
| Emulator slow / crash | Use **Czedr_API30** — see `docs/ANDROID-EMULATOR-WINDOWS.md` |
