# iOS TestFlight build tracker

Update this file when a build is **uploaded to TestFlight** or when planning the next ship.

| Field | Value |
|-------|--------|
| **Last shipped (TestFlight)** | **135** — Forgot password Option B: check email → reset link in Safari ([CI run](https://github.com/wildlifeoutdoorsllc-czedr/czedr/actions/runs/27101770902)) |
| **Next ship build number** | **136** |
| **In progress** | **136** — sign-in autofill hint after Invalid credentials; trim passwords on login |

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
| 135 | Forgot password: check-email screen → reset link in Mail/Safari (Option B); manual code fallback |
| 134 | support@czedr.com on forgot-password; backend reset email Reply-To |
| 132 | Sign up: referrer ID (not a question); QR scan + paste on optional referrer field |
| 131 | Payment QR on Referral Earnings; Profile without QR; full-width line above Logout |
| 130 | (upload may be processing) same as 131 — Apple duplicate if re-uploaded |
| 129 | History: green credits, red debits; Menu → Referral Earnings |
| 128 | Pending Invoices: Waiting on them / You owe (API lists) |
| 127 | Send Invoice success screen; whole-dollar amounts; PIN gate; QR on Send Invoice (includes 125–126) |
| 126 | Send Invoice: QR scan + paste debtor ID (same as Make Payment) |
| 125 | Clear stale home errors; funding errors only on + My Bank |
| 124 | Profile text size — Standard, Large, Extra large (saved on device) |
| 123 | `/v1/me` payment QR; Change PIN; Profile support help |
| 122 | Profile: pinned Back + scroll; QR false-color raster; compact hero — **verified on device** |
| 121 | Profile QR renders correctly (black on white) |
| 120 | Profile payment QR; scan/paste recipient on Make Payment; tagline trim |
| 119 | Forgot password on sign-in; PIN set UX fixes |
| 110 | Auto-find API on Wi‑Fi; fix registration; LAN IP in CI |
| 109 | Remove floating ✕ bubble on PIN number pad |
| 108 | Logout inside menu List (always scrollable, not clipped) |
| 107 | UIKit menu button on home; Set PIN screen before payments |
| 106 | Menu Logout at bottom; fix home hamburger menu |
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
