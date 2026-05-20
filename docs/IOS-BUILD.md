# iOS TestFlight build tracker

Update this file when a build is **uploaded to TestFlight** or when planning the next ship.

| Field | Value |
|-------|--------|
| **Last shipped (TestFlight)** | **93** — signup + referrer (`763c06d`) |
| **Next ship build number** | **94** |
| **Pending local (not pushed)** | `beecb11` — Send Invoice + Pending Invoices |

## Ship checklist

- [ ] Feature batch tested locally (API + logic) where possible
- [ ] Commits on `czedrmaster`
- [ ] `docs/IOS-BUILD.md` — set **Next** to the build you will upload
- [ ] `.\scripts\ship-testflight.ps1 -BuildNumber <N>`
- [ ] Wait for Actions green → install from TestFlight → confirm build **N** on sign-in screen
- [ ] Update **Last shipped** and clear **Pending local** above

## History (recent)

| Build | Notes |
|-------|--------|
| 93 | SwiftUI signup, referrer, demo fund script |
| 92 | Larger hero logo |
| 91 | Single toolbar + logo per screen |
| 90 | SwiftUI compile fixes |
