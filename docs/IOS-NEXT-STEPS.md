# Czedr iOS — honest assessment and path to “done”

**Date:** May 2026  
**Context:** Builds 82–87 attempted toolbar + logo on logged-in screens. Make Payment on Build 87 still showed forms only (no logo, no chrome bar). Backend security work is in better shape than the legacy iOS UI layer.

---

## What is actually wrong (not just “one more tweak”)

| Layer | Status |
|--------|--------|
| **PHP API + ledger** | Working for local/TestFlight; Argon2, rate limits, HTTPS gate documented |
| **iOS business logic** | Spread across 2015-era Objective-C, XIBs, MMDrawerController, Core Data, v1 API |
| **iOS chrome (logo / menu / back)** | Bolted on in `CzedrAppChrome`; fights XIB fixed frames, drawer parent chain, nav transitions |
| **Why Build 87 failed visually** | Chrome install depended on `mm_drawerController` (often nil for pushed screens) and layout order before `viewWillAppear`; scroll views use autoresizing that resets frames |

You are not wasting time because the product is hopeless — you are hitting **architecture debt** on the iOS shell, not the payment API.

---

## Three realistic options (fastest → most maintainable)

### Option A — Finish legacy iOS (2–4 weeks focused)

**Keep:** Objective-C app, PHP backend, TestFlight pipeline.

**Do:**

1. One **`CzedrLoggedInShell`** component (single UIView) added in code to every logged-in screen: toolbar + compact logo + `contentTopY`. No drawer-level overlay.
2. Retire `CzedrAppChrome` overlay logic; hide all green legacy header XIB blocks.
3. Smoke-test matrix: Home, Make Payment, Send Invoice, Pending, History, Profile, Link Card.
4. Moov ACH when ready (already scaffolded).

**Pros:** Fastest to App Store with current repo.  
**Cons:** Still hard to change UI later; Swift/UIKit mix awkward.

**Build 88** in git starts this: drawer resolved via window root, layout refreshes chrome before measuring scroll, autoresizing disabled on scroll.

---

### Option B — New iOS shell in SwiftUI (6–10 weeks, recommended)

**Keep:** PHP `v1` API, MySQL, TestFlight CI, Windows dev scripts.

**Replace:** Only the iPhone app with a **small SwiftUI** project:

- `LoggedInShell` — one toolbar + logo (same asset as sign-in).
- Screens: Login, Home, Make Payment, History, Profile, Link Card (MVP).
- `URLSession` + Keychain for token; no Core Data unless you need offline cache.
- Same `CZEDR_API_BASE` / TestFlight workflow.

**Pros:** Logo and navigation are trivial; security (Keychain, ATS) is standard; you can ship MVP in phases.  
**Cons:** Up-front rewrite of UI; must re-test all flows.

This is the best balance if you need the app **complete soon** and **maintainable** without burning time on XIB archaeology.

---

### Option C — Cross-platform (Flutter / React Native) (3–6 months)

Only if you need Android and iOS from one codebase long term. **Not** the fastest path for “iPhone done soon.”

---

## Security (already improved; production checklist)

Documented in `docs/SECURITY-UPGRADE-ROADMAP.md` and `docs/DEPLOY-HTTPS.md`:

- Passwords: Argon2id  
- Rate limits on login / PIN / register  
- Production: HTTPS required (`APP_ENV=production`)  
- Card link: AES-GCM (Build 77+)  
- Moov ACH: behind `MOOV_ENABLED` until live  

**Do before public launch:** TLS on API, rotate secrets, no `CZEDR_ALLOW_HTTP` in prod, TestFlight `CZEDR_API_BASE` → `https://...`

---

## Recommended decision

| If you need… | Choose |
|--------------|--------|
| TestFlight usable in **days** | **Option A** + Build 88+ shell hardening |
| App you can change without pain in **weeks** | **Option B** SwiftUI shell |
| One codebase for Android + iOS later | Option C (after MVP) |

**Recommendation:** Commit to **Option B** for UI, keep **Option A** only long enough to ship one stable TestFlight (Build 88–90) if you cannot pause feature work for a SwiftUI sprint.

---

## Immediate next engineering steps (Option A path)

1. Install **Build 88** when CI finishes — fixes drawer discovery + scroll layout.
2. If Make Payment still has no logo → implement `CzedrLoggedInShell` UIView (single file, ~200 lines) used from every `viewWillAppear`.
3. Update `docs/AGENT-HANDOFF.md` with “shell refactor” as the only UI pattern going forward.
4. Stop adding chrome logic to `MMDrawerController` / `drawer.view`.

---

## What you should not do

- More than 2–3 “build 88/89/90” tweaks without the shell refactor — diminishing returns.
- Full rewrite in another language before PHP API is frozen for MVP.
- Re-enable storing auth in `NSUserDefaults` without Keychain (legacy; plan Keychain in SwiftUI or small Obj-C patch).

---

## Files to read for continuity

| Doc | Purpose |
|-----|---------|
| `docs/AGENT-HANDOFF.md` | Login crash history, TestFlight |
| `docs/SECURITY-UPGRADE-ROADMAP.md` | Security phases |
| `docs/MOOV-ACH-FUNDING.md` | Deposits |
| `docs/TEST-ACCOUNTS.md` | Alice/Bob |
| `docs/TESTFLIGHT_SETUP.md` | CI secrets |

---

## Summary for stakeholders

Czedr’s **money and auth logic** are on track. The **iPhone UI** is legacy and fighting every change. Fastest reliable completion: **one in-app shell component** (Option A) then optionally **SwiftUI** (Option B) for long-term velocity. Build 88 addresses the immediate “no logo on Make Payment” bug; the strategy doc above is how to stop the churn.
