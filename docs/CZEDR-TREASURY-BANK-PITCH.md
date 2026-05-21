# Czedr — treasury & ACH partnership brief

**For:** Commercial treasury, business banking, and ACH origination teams  
**Primary relationship:** **Frost Bank** (existing client banking) — also suitable for Texas credit unions and regional banks  
**Company:** Czedr — mobile P2P payments  
**Confidential — May 2026**

---

## One-page summary

Czedr is a **Texas-oriented** payments app where members pay each other using an **in-app balance** (Czedr ID to Czedr ID). **No bank account is required** to send or receive inside the network. Members who want to move **cash in or out** can optionally link a bank using **micro-deposit verification only**—we **never** ask for online banking passwords and **do not** use Plaid, Yodlee, or similar aggregators.

We are seeking a **settlement account** and **ACH origination** partnership (NACHA **file** exchange preferred) for:

1. **Micro-deposit credits** (account verification)  
2. **ACH debits** (add money to in-app balance)  
3. **ACH credits** (withdraw to verified bank)

Our ledger is the **system of record for member balances**; the bank is the **system of record for settlement cash**. We use standard **open-source NACHA tooling** (moov-io/ach) and can upload files via your SFTP or treasury portal.

**Why Frost:** We already bank with Frost and value a long-term Texas relationship with straightforward treasury support.

---

## How Czedr works (for treasury)

```text
┌─────────────────────────────────────────────────────────────┐
│  Inside Czedr (no bank needed)                              │
│  Member A balance  ──P2P──►  Member B balance               │
│  Optional platform fee ($1.29) → CORPORATE settlement pool  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Optional cash in/out (ACH, verified bank only)             │
│  Bank ──ACH debit──► Settlement account ──► credit ledger   │
│  Ledger ──ACH credit──► Settlement account ──► member bank  │
└─────────────────────────────────────────────────────────────┘
```

| Flow | ACH type | When we move money on ledger |
|------|----------|------------------------------|
| **Add money** | ACH debit (member → settlement) | **After** ACH settles (not before) |
| **Withdraw** | ACH credit (settlement → member) | Debit member on request; finalize on settle; reverse on return |
| **Verify bank** | Two small ACH credits | N/A (verification only) |
| **P2P payment** | None | Immediate between member balances |

---

## What we are NOT asking for

- ❌ Plaid / Yodlee / credential-based bank login  
- ❌ Card acquiring or card settlement through this request  
- ❌ Commingled consumer accounts without clear reconciliation  
- ❌ The bank maintaining per-member balances (we maintain the ledger)

---

## What we ARE asking for

| # | Request | Notes |
|---|---------|--------|
| 1 | **Commercial settlement account** (Texas entity) | For ACH settlement and reconciliation |
| 2 | **ACH origination** via **NACHA file** (SFTP, portal, or API you support) | Open to your standard SEC codes (WEB/PPD/etc. per your compliance) |
| 3 | **Micro-deposit program** | Two credits (e.g. $0.01–$0.99) for verification |
| 4 | **Return / NOC files** | Daily (or per your cycle) for reconciliation |
| 5 | **Same-day ACH** | Optional; standard next-day acceptable for pilot |
| 6 | **Written program approval** | Pilot → production with volume tiers |

---

## Volume and growth (honest range)

We are **early stage** (TestFlight / controlled rollout). User count may start very small and could grow substantially if the product succeeds. We want a structure that works at **pilot volume** without renegotiating at every milestone.

**Suggested pilot limits (configurable in our app):**

| Control | Example starting point |
|---------|-------------------------|
| Per-member daily ACH in | $500 – $2,500 |
| Per-member daily ACH out | $500 – $2,500 |
| Micro-deposit size | $0.01 – $0.99 |
| Cooling period after new bank link | 3–7 days before withdraw |

We will provide **monthly volume forecasts** before production and increase limits with your approval.

---

## Reconciliation & controls (post-industry lessons)

We align with strong **FBO / settlement** governance:

- **Daily reconcile:** bank settlement balance vs. ledger aggregate + pending ACH  
- **Idempotent** ACH requests (no duplicate credits on retry)  
- **Audit log** for link, deposit, withdraw, return  
- **Admin read-only** corporate settlement reporting (fees minus referrals)  
- **No** member-facing claim that balances are FDIC-insured unless your program provides that with approved copy  

---

## Technology (no vendor lock-in on ACH files)

| Component | Role |
|-----------|------|
| **moov-io/ach** (open source) | Build and validate NACHA files |
| **achgateway** (optional) | Automated SFTP / return processing at scale |
| **Czedr API** | Ledger, micro-deposit link, deposit/withdraw when enabled |

We are **not** requesting Moov.io, Stripe ACH, or Plaid for core origination. We want a direct **bank–originator** relationship with transparent per-entry economics.

---

## Economics (discussion starters)

We prefer **transparent** pricing, for example:

- Per **ACH entry** (debit/credit)  
- Per **return** / chargeback handling  
- **Monthly** treasury or cash management (if applicable)  
- **No** per-active-user middleware fees from a third-party aggregator  

We are open to **minimums** that match pilot volume and step down with scale.

---

## Frost Bank — why we want to start here

- **Existing relationship:** We already bank with Frost and trust your team.  
- **Texas focus:** Czedr is built with Texas members and Texas banking relationships in mind.  
- **Straightforward ask:** Standard corporate ACH origination + settlement, not exotic crypto or cross-border.  
- **Conservative linking:** Micro-deposits only; reduces fraud and compliance surface vs. credential aggregation.

**Ideal next step with Frost:** 30-minute call with commercial treasury / ACH origination to review this brief, NACHA file format, and pilot timeline.

---

## Also open to (if Frost is not a fit for ACH)

Texas **credit unions** and **regional banks** with strong business ACH desks—for example institutions that already publish **ACH origination** for business members. We will use the **same** brief and reconciliation standards everywhere.

---

## Pilot timeline (proposed)

| Week | Milestone |
|------|-----------|
| 1–2 | NDA + compliance questionnaire + legal entity docs |
| 2–4 | Settlement account + origination agreement + NACHA file spec |
| 4–6 | Test files (zero-dollar / micro / small live pilot) |
| 6–8 | Member micro-deposit linking in app |
| 8+ | Controlled ACH deposit; withdraw after deposit stability |

Ledger-only P2P can operate **before** ACH is live; ACH is an **optional** member feature.

---

## Appendix A — FAQ for treasury officers

**Q: Is this crypto?**  
A: No. USD ACH and internal ledger only.

**Q: Who holds consumer funds?**  
A: Settlement cash at the bank; per-member balances on Czedr ledger per your approved structure (counsel-coordinated FBO/agent terms).

**Q: How do members link a bank?**  
A: They enter routing/account; we send two micro-deposits; they confirm amounts in the app. No bank website password.

**Q: What if ACH returns?**  
A: Deposits: no ledger credit until settled; if returned after credit, reversal per NACHA rules. Withdrawals: ledger hold, return credits balance back.

**Q: NACHA SEC codes?**  
A: We will follow your compliance team’s direction (WEB for consumer debits, etc.).

---

## Appendix B — contact sheet (fill before sending)

| | |
|--|--|
| **Company legal name** | _[fill in]_ |
| **DBA / app name** | Czedr |
| **Texas address** | _[fill in]_ |
| **EIN** | _[fill in]_ |
| **Primary contact** | _[name, title, phone, email]_ |
| **Technical contact** | _[name, email]_ |
| **Frost relationship manager (if known)** | _[fill in]_ |
| **Requested meeting** | Commercial treasury / ACH origination, 30–45 min |

---

## Appendix C — one paragraph email intro (copy/paste)

> Subject: Czedr — ACH origination & settlement pilot (existing Frost client)  
>  
> Hello,  
>  
> I’m building **Czedr**, a Texas-focused mobile app for P2P payments between members using an in-app balance (no bank required for payments inside the network). We’re planning optional ACH cash-in/out using **micro-deposit bank verification only**—no Plaid or bank passwords—and NACHA file origination with reconciliation against our internal ledger.  
>  
> We already bank with **Frost** and would like to explore a **settlement account and ACH origination** program with your treasury team. I’ve attached a short brief outlining flows, controls, and pilot volume. Could we schedule 30 minutes to discuss file formats, micro-deposits, and next steps?  
>  
> Thank you,  
> _[Name]_  

---

*Attach this document or link to the repository docs folder. Technical supplements: `docs/LEDGER-FIRST-BANK-OPTIONAL.md`, `docs/BANK-LINK-MICRODEPOSITS.md`.*
