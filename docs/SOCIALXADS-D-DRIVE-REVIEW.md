# SocialXads — D: drive review (handoff)

**Date:** 2026-09-08  
**Who:** Michael (product owner) + Cloud Agent on the Czedr repo  
**Why this file exists:** Michael asked to keep moving while he slept. The agent **cannot** open `D:\`. This is everything learned from photos and file snippets so the next chat (Atlas or Forge) does not start over.

**Do not** paste `.env.local`, PayPal live keys, or full `ads_settings.pl` with secrets into git or chat.

---

## Honest limits

| Can | Cannot |
|---|---|
| Read what Michael pastes or photographs | See `D:\SocialXads` from Cursor Cloud |
| Check the public website | Push code into SocialXads (it is **not** on GitHub under `wildlifeoutdoorsllc-czedr`) |
| Write this handoff | Finish the CGI → Next.js cutover overnight without that folder as a git repo |

**Atlas vs Forge:** Atlas is step-by-step ops (this review). Forge is the builder. Forge needs Cursor opened on `D:\SocialXads` (or a GitHub copy). Asking Atlas in a *different* Czedr chat does not magically mount `D:\`.

---

## Where the files live

- **PC:** `D:\SocialXads` (also pinned on D: among other products)
- **Launcher settings path:** `d:/SocialXads/ads_settings.pl` (project root)
- **Copy we read:** `D:\SocialXads\legacy\ads_settings.pl` (131 lines) — treat as possibly a second copy of the root file
- **Perl:** Windows shebang `C:\Strawberry\perl\bin\perl.exe`
- **Mail in settings:** Linux `/usr/sbin/sendmail` — PC edit vs Linux host mismatch

---

## What the old product is

Classic **Perl CGI banner exchange**, public path intended as:

`https://socialxads.com/banner_exchange/`

| Piece | Role |
|---|---|
| `legacy/ads.pl` | Thin launcher; `require`s settings; zone empty |
| `ads_settings.pl` | All config (display, admin, PayPal, mail) |
| `ads_display.pl` | Pick/show banners (`$ADVdisplay_path`) |
| `D:\SocialXads\ads\` | Banner files (`$ADVadverts_dir`); default banner name **`gameleases`** |
| `ads_admin.pl` | Admin |
| `paypal_ipn.pl` | PayPal IPN (migration plan “webhook”) |
| `_vti_cnf` | Old FrontPage leftover |
| Exchange name | **SocialXads Advertisers** |
| Display ratio | **2** (show others to earn your own views) |
| Member edit | Off; **admin approval required** |
| Uploads | Off in this copy |
| Tracking | Cookies on; **IP logging on**; 7-day master IP log |
| Social bots | Allowlist added (Facebook, X, LinkedIn, Slack, Discord, WhatsApp, Telegram, Pinterest, Reddit) |

**PayPal in this settings copy (not live secrets):**

- Mode: **`sandbox`**
- Business email: placeholder `your-paypal-business@example.com`
- Currency: USD
- Return / cancel / IPN URLs all under `https://socialxads.com/banner_exchange/`
- Admin contact in file: wildlifeoutdoorsllc Gmail (do not commit the address elsewhere)

---

## What the new product looks like (folder photo)

On `D:\SocialXads` (July 2026 timestamps): Next.js (`.next`, `src`, `public`), Prisma, `android` / `ios` / `fastlane`, `.github`, `integrations`, `legacy`, `node_modules`, `.env.example`, `.env.local`.

`MIGRATION_PLAN.md` is a **parallel-run CGI → secure platform** plan (auth/MFA, PostgreSQL, audit, PayPal idempotency, feature parity, data migrate, shadow traffic, blue/green, decommission). It has **no dates, owners, or done/not-done**.

**Plan vs disk:** Foundation (Next/Prisma/mobile) and a `legacy` tree are already there. Live CGI cutover is **not** done (see website check below).

---

## Public website check (2026-09-08)

| URL | Result |
|---|---|
| `https://socialxads.com/` | GoDaddy Website Builder **“Launching Soon”** + contact form — **not** the Perl exchange |
| `https://socialxads.com/banner_exchange/ads.pl` | **404** |

So DNS/domain is a placeholder. The Perl URLs in settings are **not** what the public site serves today.

GitHub org `wildlifeoutdoorsllc-czedr` has **only** the Czedr repo. No SocialXads remote found.

---

## Suggested next work (when Michael is back)

Do **not** treat this Czedr PR as a SocialXads code change.

1. **Forge (build):** File → Open Folder → `D:\SocialXads`. First job: read `paypal_ipn.pl` (star secrets), then `.env.example` only (not `.env.local`), then map Prisma models to `ads/` files.  
2. **Atlas (ops):** Decide if `socialxads.com` should stay “Launching Soon” or point at the Next.js app — that is DNS/GoDaddy, not this Czedr repo.  
3. **Backup:** Copy `D:\SocialXads` to git (private GitHub) so Cloud Agents can work without `D:\`. Until that exists, overnight agents cannot write SocialXads code.  
4. **Do not** turn on live PayPal from this sandbox copy.

---

## D: folder map (from Explorer photo, not opened)

**Current-ish:** CZEDR, CZEDRWEB, SocialXads, CQ Athletes, Cloodog, FoxholeFamily, ServiceSurvivors, HitMe App Files, Network Enc, AI chat.

**Slypal cluster (same date):** Slypal 10142020, SLYPAL FINAL, SLYPAL TEST, Slypal Windows Server.

**Tazool cluster:** Raj's Tazool, TAZ2, Tazool 100per working.

**Other:** Spyderfy Working, Pubcos, temp-cert, temp-cloodog-cert.

Only **SocialXads** was opened in this session.
