# iOS TestFlight build tracker

Update this file when a build is **uploaded to TestFlight** or when planning the next ship.

| Field | Value |
|-------|--------|
| **Last shipped (TestFlight)** | **94** — Send Invoice, centered home, manual CI (`49ae848`) |
| **Next ship build number** | **96** (after 95 completes) |
| **In progress** | **95** — keyboard ✕ toolbar + tap to dismiss (`34c15f4`) |

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
| 95 | Keyboard dismiss (✕ bar, tap outside) |
| 94 | Send Invoice, centered home balance, manual TestFlight |
| 93 | SwiftUI signup, referrer, demo fund script |
| 92 | Larger hero logo |
| 91 | Single toolbar + logo per screen |
| 90 | SwiftUI compile fixes |
