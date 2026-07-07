# Czedr development workflow

How we work on this repo to stay fast locally and avoid wasted TestFlight / CI time.

## Principles

| Rule | Why |
|------|-----|
| **Code locally, ship deliberately** | Every TestFlight build costs ~3 min CI + Apple processing + your install time. |
| **Ship after each iOS batch** | User preference: commit → push → next TestFlight build (fluid installs). |
| **Push ≠ build** | Pushing to `czedrmaster` does **not** auto-trigger CI (run `ship-testflight.ps1`). |
| **Agent commits when you ask** | Keeps git history aligned with your intent. |
| **Agent ships iOS after commit** | Push + `ship-testflight.ps1 -WaitForPrevious` unless user says to hold builds. |

## Daily loop (Windows + iPhone)

1. **API** (keep window open):
   ```powershell
   cd C:\Michaels Apps\czedr\scripts
   .\start-php-server.ps1
   ```
2. **Test on device** with the **latest TestFlight** build (see `docs/IOS-BUILD.md` for number).
3. **Implement** in `ios/CzedrSwift/` (SwiftUI default in `CzedrConfig.h`).
4. **Commit** when you say so — often after a feature batch is done.
5. **Ship** the next build from `docs/IOS-BUILD.md` after iOS commits (see pipeline below).

## Git

| Action | Who | When |
|--------|-----|------|
| Commit | Agent (on request) or you | Feature done, message describes *why* |
| Push | You or agent **only when asked** | Before ship, or to back up work |
| TestFlight build | **Manual** | `scripts/ship-testflight.ps1` or GitHub Actions UI |

Branch: **`czedrmaster`**.

## TestFlight (manual only)

CI workflow: `.github/workflows/ios-testflight.yml` — **`workflow_dispatch` only** (no push trigger).

### Ship one build

```powershell
cd C:\Michaels Apps\czedr\scripts
.\ship-testflight.ps1 -BuildNumber 96 -WaitForPrevious
```

This will:

1. Confirm you are on `czedrmaster` and working tree is clean (or warn).
2. **Wait** until the previous TestFlight workflow finishes (avoids overlapping Mac CI jobs).
3. `git push` (unless `-SkipPush`).
4. Run GitHub Actions **iOS TestFlight** with that build number.
5. Remind you to run `RESTART-IPHONE-TESTING.cmd` after upload succeeds.

**Agent default:** after iOS commits, push and ship the next build with `-WaitForPrevious`.

**GitHub UI alternative:** Actions → **iOS TestFlight** → Run workflow → set **build_number** (e.g. `94`).

### Build numbers

Track in **`docs/IOS-BUILD.md`**:

- **Shipped** — last build on TestFlight users should install.
- **Next** — number to pass when shipping the current batch.

Bump **Next** only when starting a new ship (not on every code edit).

## SwiftUI backlog (priority)

Update this list as items ship. **Current** (May 2026):

| Priority | Item | Status |
|----------|------|--------|
| P0 | Login, Home, Make Payment, History, Profile | Shipped (build 90+) |
| P0 | Signup + referrer Czedr ID | Shipped (build 93) |
| P1 | Send Invoice + Pending lists | **Local commit `beecb11` — not shipped** |
| P2 | Pay / reject / cancel invoice | Not started |
| P2 | Link Card | Placeholder |
| P3 | Change PIN, forgot password | Not started |
| P3 | Moov deposit | Backend gated |

**Rule:** Prefer completing a **P1 row** before shipping; avoid shipping for one-line tweaks unless blocking you.

## What the agent does by default

- Implements and documents in `docs/IOS-SWIFTUI.md` when screens change.
- Updates `docs/IOS-BUILD.md` **Next** only when you agree to ship.
- Commits **only when you ask**.
- Does **not** push or run TestFlight unless you ask to **ship** / **push**.
- At end of a session, states: branch, unpushed commits, last TestFlight build, suggested next step.

## Test accounts

`docs/TEST-ACCOUNTS.md` — Alice / Bob, fund via `php scripts/fund-test-accounts.php` with API on `:8080`.

## Related docs

- `docs/IOS-SWIFTUI.md` — SwiftUI map
- `docs/IOS-BUILD.md` — build numbers
- `docs/TESTFLIGHT_SETUP.md` — secrets and Apple setup
- `docs/AGENT-HANDOFF.md` — deep history (legacy crashes, security)
