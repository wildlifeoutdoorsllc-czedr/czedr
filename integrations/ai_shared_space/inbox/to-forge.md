# Inbox → Forge

**Status:** ready for next session  
**From:** Michael + overnight Czedr Cloud Agent  
**Date:** 2026-09-08

## Build or fix request

SocialXads CGI → modern platform. Full notes: **`docs/SOCIALXADS-D-DRIVE-REVIEW.md`**.

Open **`D:\SocialXads`** (not this Czedr folder) and continue:

1. Read `legacy/paypal_ipn.pl` (redact secrets).
2. Read `.env.example` only — do not commit `.env.local`.
3. Map Prisma schema to `ads/` + `ads_settings.pl` (banner exchange, ratio 2, admin approval).
4. Do not enable live PayPal; settings copy is **sandbox**.

## Done when (how I'll know it worked)

- Private GitHub (or equivalent) has SocialXads so agents can work without `D:\`, **or**
- Written gap list: which `MIGRATION_PLAN.md` phases are actually implemented in `src` / `prisma`.

## Do NOT change (optional)

- Czedr iOS/TestFlight unless Michael asks.
- Live PayPal / production DNS without Michael.
