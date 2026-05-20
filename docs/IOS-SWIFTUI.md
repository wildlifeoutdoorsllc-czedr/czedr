# Czedr iOS — SwiftUI shell (Option B)

## Toggle

| `CzedrConfig.h` | Behavior |
|-----------------|----------|
| `CZEDR_USE_SWIFTUI 1` | SwiftUI app (default) |
| `CZEDR_USE_SWIFTUI 0` | Legacy Objective-C + MMDrawer |

## Layout

```
ios/CzedrSwift/
  CzedrAPIClient.swift      # v1 API (login, balance, transfer, history)
  KeychainStore.swift       # auth token + session fields
  AppSession.swift          # ObservableObject for UI
  CzedrSwiftRootView.swift  # Login, shell, home, payment, history, profile
  CzedrSwiftBootstrap.swift # UIHostingController entry
  CzedrSwiftLauncher.m      # Called from AppDelegate
```

## TestFlight

- Manual ship only: `docs/DEVELOPMENT-WORKFLOW.md`, `scripts/ship-testflight.ps1`, build tracker `docs/IOS-BUILD.md`
- Workflow: `.github/workflows/ios-testflight.yml` (not triggered by push)
- API base still baked via `CzedrConfig.h` (`CZEDR_API_BASE`)
- On device, sign-in screen shows **SwiftUI · Build N** under the logo
- Test account: `docs/TEST-ACCOUNTS.md` (Alice, PIN `1` for transfers)

## Session policy

- **Force-quit and reopen** → sign-in required (Keychain + legacy UserDefaults cleared on cold launch).
- **Sign out** on Profile → same clear + server logout when possible.

## MVP screens (build 90+)

| Screen | Status |
|--------|--------|
| Login | Done |
| Home (balance + tiles) | Done |
| Make Payment | Done |
| History | Done |
| Profile / Sign out | Done |
| Send Invoice | Request payment from debtor (`POST /v1/invoices`) |
| Pending Invoices | Placeholder |
| Link Card | Placeholder |

## Adding a screen

1. Add view in `CzedrSwiftRootView.swift` or a new file under `ios/CzedrSwift/`
2. Register file in `payooxe.xcodeproj` (Sources build phase)
3. Wrap with `LoggedInShell` for logo + menu + back
4. Add API methods to `CzedrAPIClient.swift` if needed
