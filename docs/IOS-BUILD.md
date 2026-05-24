# iOS TestFlight build tracker

Update this file when a build is **uploaded to TestFlight** or when planning the next ship.

| Field | Value |
|-------|--------|
| **Last shipped (TestFlight)** | **105** — Make Payment Success screen |
| **Next ship build number** | **106** |
| **In progress** | — |

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
| 105 | Make Payment Success screen after submit |
| 104 | Fix PIN tap/focus (UIKit capture field) |
| 103 | + My Bank optional link; micro-deposit; no bank password |
| 102 | PIN entry: four vertical red slots + masked dots |
| 101 | Signup: referrer optional helper text |
| 100 | US comma money formatting |
| 99 | Make Payment Description field |
| 98 | Visible placeholders + dark text on orange fields |
| 97 | White field text attempt |
| 96 | Charcoal placeholder text |
| 95 | Keyboard dismiss (✕ bar, tap outside) |
| 94 | Send Invoice, centered home balance, manual TestFlight |
| 93 | SwiftUI signup, referrer, demo fund script |
