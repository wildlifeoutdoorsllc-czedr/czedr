# iOS — common support issues vs app coverage

**Purpose:** Map the problems members most often contact support about to what the SwiftUI app already handles in-app (so fewer tickets and faster self-service).

**Last reviewed:** June 2026 (build **123**)

---

## Top support themes (payments / wallet apps)

| # | Why people contact support | In-app coverage (iOS) | Build / notes |
|---|---------------------------|------------------------|---------------|
| 1 | **Can’t sign in** / wrong password | **Forgot password?** on sign-in → email reset flow | 119+ |
| 2 | **Forgot payment PIN** | Sign out → **Forgot password?** → sign in → menu **Change PIN** (needs current PIN once) + Profile help text | 123 |
| 3 | **Want to change PIN** | Menu / Profile → **Change PIN** (`POST /v1/auth/pin/update`) | 123 (was broken: only “set” worked) |
| 4 | **PIN locked** after wrong tries | Server message shown on payment / PIN screens | API lockout 30 min |
| 5 | **Can’t send a payment** | Home banner if no PIN; Make Payment hints; **VALIDATE** recipient | 107+ |
| 6 | **Wrong recipient / ID** | **VALIDATE**, QR scan, paste from clipboard | 120+ |
| 7 | **How do I get paid?** | Profile → **My payment QR** + Czedr ID text | 122+; payload from **`/v1/me`** | 123 |
| 8 | **Balance looks wrong** | Home balance refresh; **History** list | 90+ |
| 9 | **Stuck on a screen / no back** | Profile **Back** + **Back to Home**, scroll | 122 |
| 10 | **App won’t connect** | Sign-in API field; Wi‑Fi discovery on LAN builds | TestFlight uses `https://api.czedr.com` |
| 11 | **How to contact support** | Profile → **Email support** (`support@czedr.com`) | 123 |
| 12 | **Invoices** | Menu **Send Invoice**; Pending still placeholder | Send shipped earlier |
| 13 | **Change password while logged in** | Use **Sign out** → **Forgot password?** (no in-app “change password” yet) | Documented in Profile help |
| 14 | **Add bank / deposit** | **+ My Bank** stub; ACH gated on server | Moov later |

---

## Still human-support (not fully self-serve)

- Account closure, fraud disputes, legal requests  
- Production email delivery failures for password reset (check `docs/EMAIL-SETUP.md`)  
- ACH / Moov onboarding when enabled  
- Reserved Czedr ID disputes  

---

## QA smoke (after each TestFlight build)

1. Sign in → Home shows balance  
2. **Forgot password?** (staging) or test account  
3. Set or **Change PIN** → Make Payment with **VALIDATE** + PIN  
4. Profile: QR visible, **Back** works, **Email support** opens Mail  
5. Force-quit → must sign in again (session policy)

---

## Related docs

- `docs/TEST-ACCOUNTS.md` — Alice / Bob  
- `docs/QR-PAYMENTS.md` — QR + `payment_qr_payload`  
- `docs/IOS-BUILD.md` — TestFlight numbers  
- `docs/IOS-SWIFTUI.md` — screen map  
