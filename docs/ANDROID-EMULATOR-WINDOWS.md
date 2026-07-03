# Android emulator on Windows (troubleshooting)

## Your PC profile

| Item | Value |
|------|--------|
| CPU | Intel Celeron **N5095** (no **AVX**) |
| RAM | ~16 GB |
| Fix that worked | **API 30** AVD + **GPU off** + QEMU CPU `max,avx=off,...` |

The default API 34 image + AEHD often hit **QEMU2 CPU thread hanging** on this chip because the guest CPU profile expects AVX.

---

## Working setup (use this)

1. **Memory integrity** — Off (Core isolation), then reboot once.
2. **AEHD** — Installed (`Android_Emulator_Hypervisor_Driver` in SDK extras).  
   Optional later: `scripts\fix-emulator-hypervisor.ps1` (admin) switches to **WHPX**; requires another reboot.
3. **AVD** — **Czedr_API30** (Android 11 / API 30), not Pixel_8 or API 37.
4. **Start**:

```powershell
cd D:\CZEDR\scripts
.\start-php-server.ps1          # separate window — keep open
.\start-android-emulator.ps1    # default: Czedr_API30
```

5. **App API base** — `http://10.0.2.2:8080`

First boot can take **3–8 minutes** on a Celeron.

---

## AVDs on this machine

| AVD | Use |
|-----|-----|
| **Czedr_API30** | **Preferred** — stable on N5095 |
| Czedr_API34 | May hang (AVX / API 34) |
| Pixel_7_API_34 | Same risk as Czedr_API34 |
| Pixel_8 | **Do not use** (Android 37, 16 KB pages) |

---

## If the emulator still fails

1. **Device Manager** → AVD → **Graphics: Software - GLES 2.0** → **Cold Boot Now**
2. Close **Docker** / other VMs; reboot
3. Reinstall AEHD (admin):  
   `%LOCALAPPDATA%\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver\silent_install_safe.bat`
4. **Physical phone** (USB debugging) — most reliable fallback  
   API base: `http://YOUR_PC_LAN_IP:8080` from `start-php-server.ps1`

---

## Scripts

| Script | Purpose |
|--------|---------|
| `start-android-emulator.ps1` | Starts **Czedr_API30** with safe flags |
| `fix-emulator-hypervisor.ps1` | Admin: enable WHPX, uninstall AEHD (reboot after) |
| `enable-windows-hypervisor-platform.ps1` | Admin: enable Hypervisor Platform only |

---

## Technical notes

- **Root cause**: Celeron N5095 lacks AVX; AEHD does not expose AVX to the guest ([AEHD issue #61](https://github.com/google/android-emulator-hypervisor-driver/issues/61)).
- **Mitigation**: `-gpu off` and `-qemu -cpu max,avx=off,avx2=off,f16c=off,xsave=off`
- **advancedFeatures.ini** in `%USERPROFILE%\.android\` disables Vulkan/Wi‑Fi/Bluetooth to reduce load.
