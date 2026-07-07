# Android testing on a **physical phone** (no emulator)

Use this if the Android emulator **freezes or crashes your PC** (common on Intel Celeron N5095 with 16 GB RAM).

The Czedr app works the same; only the API URL differs from the emulator.

---

## Before you start

1. **Close Android Studio’s emulator** if it is open (Device Manager → stop any running AVD).
2. Run only: **API server** + **Android Studio** + **browser** — not emulator + heavy apps together.
3. Phone and PC on the **same Wi‑Fi**.

---

## 1. Start the API on your PC

Double-click **`START-ANDROID-DEV.cmd`** or:

```powershell
cd C:\Michaels Apps\czedr\scripts
.\start-php-server.ps1
```

Keep that window open. Note the **LAN** line, e.g. `http://192.168.68.56:8080`.

---

## 2. Enable USB debugging on your phone

| Step | Action |
|------|--------|
| 1 | **Settings → About phone** → tap **Build number** 7 times (Developer mode on) |
| 2 | **Settings → Developer options** → turn on **USB debugging** |
| 3 | Plug phone into PC with a data-capable USB cable |
| 4 | On phone, tap **Allow** when asked to trust this computer |

**Samsung / some brands:** install [USB driver](https://developer.android.com/studio/run/oem-usb) for your OEM if the PC does not see the device.

---

## 3. Confirm the PC sees the phone

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

You want:

```text
XXXXXXXX    device
```

If it says `unauthorized`, unlock the phone and accept the USB debugging prompt.

If the list is empty, try another USB port, another cable, or **Developer options → Default USB configuration → File transfer / MTP**.

---

## 4. Run from Android Studio

1. **File → Open** → `C:\Michaels Apps\czedr\android`
2. **File → Sync Project with Gradle Files** (once)
3. Top toolbar: device dropdown → select your **phone** (not Pixel_7 / Czedr_API30)
4. **Run** ▶

---

## 5. Sign in on the phone

- Wait for **“Server found: http://192.168.x.x:8080”** on the sign-in screen, **or**
- Paste the LAN URL from the API window into **API base URL** (not `10.0.2.2` — that is emulator-only).

Test account:

| Email | Password |
|-------|----------|
| `alice@test.czedr` | `TestPass1234!` |

Then: menu → **Set PIN** → **Make Payment**.

---

## Wireless debugging (optional, no USB after pairing)

Android 11+:

1. **Developer options → Wireless debugging** → On  
2. **Pair device with pairing code**  
3. In Android Studio: **Pair devices using Wi‑Fi** (Device Manager toolbar)

Phone and PC must stay on the same Wi‑Fi.

---

## Do **not** use on this PC (unless you accept another crash risk)

| Avoid | Why |
|-------|-----|
| Pixel_8 / API 37 AVD | Too heavy |
| Czedr_API34 / Pixel_7 API 34 | Often hangs on N5095 |
| Multiple emulators | RAM exhaustion |
| Emulator + many Chrome tabs + IDE | Same |

If you must try an emulator again later: **Czedr_API30** only, close other apps, and use `scripts\start-android-emulator.cmd` in a dedicated window — expect **5–10+ minutes** boot and still risky on 16 GB RAM.

---

## Quick checklist

- [ ] API window open (`/v1/health` works in PC browser)
- [ ] `adb devices` shows `device`
- [ ] Studio run target = **physical phone**
- [ ] API URL = PC **LAN** IP, not `10.0.2.2`
- [ ] Windows Firewall allowed port **8080** if connection fails
