# iOS TestFlight build tracker

Update this file when a build is **uploaded to TestFlight** or when planning the next ship.

| Field | Value |
|-------|--------|
| **Last shipped (TestFlight)** | **96** — charcoal placeholders (superseded by 97) |
| **Next ship build number** | **98** (after 97 completes) |
| **In progress** | **97** — white field text + placeholders (legacy CzedrTheme match) |

## Ship pipeline (user preference)

After iOS changes are **committed**, **push and ship the next build** without waiting for a separate “ship” message. Use `scripts/ship-testflight.ps1 -BuildNumber N -WaitForPrevious` so a new build starts only after the prior TestFlight workflow finishes.

## Ship checklist

- [ ] Commits on `czedrmaster`
- [ ] `docs/IOS-BUILD.md` — **Next** = build you will upload
- [ ] `.\scripts\ship-testflight.ps1 -BuildNumber <N> -WaitForPrevious`
- [ ] Install from TestFlight → confirm build **N** on sign-in screen
- [ ] Update **Last shipped** above

## History (recent)

| Build | Notes |
|-------|--------|
| 97 | White text and placeholders on orange fields (legacy match) |
| 96 | Charcoal placeholder text on orange fields |
| 95 | Keyboard dismiss (✕ bar, tap outside) |
| 94 | Send Invoice, centered home balance, manual TestFlight |
| 93 | SwiftUI signup, referrer, demo fund script |
