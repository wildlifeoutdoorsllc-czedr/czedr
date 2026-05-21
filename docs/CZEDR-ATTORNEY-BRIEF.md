# Czedr — confidential attorney brief (Texas)

**Purpose:** Background for counsel reviewing product structure, Texas money-services regulation, and bank-partner vs license paths.  
**Not legal advice.** Prepared for discussion only.  
**Date:** May 2026  
**Principal state of operations:** Texas  

---

## 1. Executive summary

**Czedr** is a mobile payments application that lets registered members hold an **in-app USD balance** (internal ledger) and send money to other members by **Czedr ID** (peer-to-peer). The platform charges a **per-transfer service fee** (default **$1.29**) credited to an internal **CORPORATE** platform account, and may pay **referral rewards** (default **$0.17** per qualifying side, up to two per transfer) from that fee pool.

The product is designed **ledger-first**: members can use P2P features **without** linking a bank account. **Optional** bank linking uses **micro-deposit verification only** (two small ACH credits; member confirms amounts). The company **does not** use Plaid, Yodlee, MX, Finicity, or any flow that collects **online banking usernames or passwords**.

**Future / optional:** ACH **deposit** (bank → in-app balance) and ACH **withdrawal** (balance → bank) via a **settlement account** at a depository institution and **NACHA file** origination (open-source tooling + bank SFTP/portal). This rail is **feature-flagged off** until a bank relationship and compliance program exist.

**Ask of counsel:** (1) Texas MSB / stored-value / money-transmission analysis; (2) recommended structure with a **Texas bank or credit union** (client has existing relationship with **Frost Bank**); (3) disclosures and marketing language; (4) FBO / custody documentation; (5) NACHA and BSA/AML program scope.

---

## 2. Product mechanics (technical facts)

| Topic | Current / planned behavior |
|--------|----------------------------|
| **System of record for member balances** | Application database (MySQL ledger), not the bank |
| **P2P transfer** | Debit sender balance, credit recipient balance; optional platform fee debited from sender |
| **Bank required for P2P?** | **No** |
| **Bank link method** | Micro-deposit only; routing + account + name; encrypted at rest server-side |
| **When is bank balance credited?** | Only after ACH deposit **settles** (webhook / return file), not on request alone |
| **Withdrawal (planned)** | Debit member ledger on request (hold); ACH credit out on settlement; reverse on return |
| **Reserved platform IDs** | `CORPORATE`, `SYSTEM`, `REVENUE` — not registrable by members |
| **Card processing** | Not in scope for external card settlement; “link card” legacy areas are not live card acquiring |

**Referral program:** Single-level; optional referrer at signup; rewards on qualifying P2P activity, not multi-level.

---

## 3. Regulatory questions (Texas-focused)

### 3.1 Texas Finance Code Chapter 152 (money services)

Please advise whether any of the following trigger **money transmission** or **stored value** licensing in Texas (NMLS / Texas Department of Banking):

1. **Ledger-only P2P** between members with no ACH cash-in/out (balances funded by other members, promotions, or controlled admin credits in testing).
2. **Ledger + ACH deposit** (ACH debit from member bank → settlement account → credit member ledger on settle).
3. **Ledger + ACH withdraw** (debit member ledger → ACH credit to verified linked bank).
4. **Platform fees and referral payouts** settled on internal ledger and/or from a corporate settlement pool.

**Specific Texas resources we understand may be relevant:**

- Texas Finance Code **Chapter 152** (money services businesses).  
- Texas Department of Banking **Money Services Businesses** guidance and NMLS filing (including **$10,000** application fee reference on TDB site — please confirm current amount).  
- Any **payment processor** or **agent-of-payee** interpretive positions applicable to ACH-only wallet loads (we do not rely on this without your analysis).

### 3.2 Federal / other

- **FinCEN** MSB registration and AML program when ACH or certain ledger activity is live.  
- **NACHA** Operating Rules (WEB/PPD/CCD choices, micro-deposits, returns, unauthorized return liability).  
- **UDAAP** / clear consumer disclosures (not FDIC-insured balance unless bank program provides pass-through insurance with correct marketing).  
- **State money transmission** beyond Texas if members nationwide (product may be national via app stores).

### 3.3 Exemptions / partner-bank models

Please evaluate whether a structure such as:

- **Partner bank** as ODFI and settlement account holder, with Czedr as technology/operations agent under written agreement, or  
- **Licensed MSB** with bank as settlement only, or  
- **Narrow exemption** (if any) for closed-loop or limited activity phases,

is appropriate for **Phase 1** (ledger-only or limited pilot) vs **Phase 2** (ACH in/out).

---

## 4. Consumer disclosures (draft themes for counsel)

We intend to make clear (exact language TBD by counsel):

- In-app balance is **not a bank account** unless a future bank program states otherwise.  
- Funds are **not FDIC/NCUA insured** as a bank deposit unless a specific pass-through arrangement exists and is disclosed.  
- **No** online banking password is ever requested.  
- Bank linking uses **micro-deposits** and may take **1–3 business days** (or same-day if bank supports).  
- ACH deposits/withdrawals subject to review, limits, returns, and fraud holds.  
- P2P transfers are **not reversible** by the platform except as stated in terms.

---

## 5. Bank / FBO structure (for coordination with treasury counsel)

**Desired arrangement with a Texas depository institution (Frost Bank is preferred existing relationship):**

| Element | Requested understanding |
|---------|-------------------------|
| **Settlement account** | Commercial account in company name (or counsel-approved FBO structure) |
| **ACH origination** | NACHA-compliant **file** exchange (SFTP or secure upload), not only third-party API aggregators |
| **Micro-deposits** | Two small **ACH credits** for account verification |
| **Member debits** | ACH debits for “add money” from verified accounts |
| **Member credits** | ACH credits for “withdraw” to verified accounts |
| **Reconciliation** | Daily: bank settlement balance ↔ aggregate of member ledger + pending ACH |
| **System of record** | Czedr ledger authoritative for **per-member** balances; bank authoritative for **settlement** cash |

Please review **post-Synapse** expectations: independent bank visibility, penny-perfect reconciliation, and clarity on ledger of record.

---

## 6. Compliance program scope (when ACH is enabled)

We anticipate counsel will recommend or oversee:

- BSA/AML policy, CIP/KYC, OFAC screening, SAR/CTR processes  
- NACHA audit trail, return handling, unauthorized return policy  
- Information security (encryption of bank account data at rest, no credential aggregation)  
- Consumer complaint and error resolution (Reg E if applicable)  
- Record retention and vendor due diligence (hosting, ACH file tools — **open-source** moov-io/ach, achgateway; no Plaid)

---

## 7. Phased rollout (for legal planning)

| Phase | Activity | ACH / bank |
|-------|----------|------------|
| **0 (current)** | P2P, invoices, referrals on internal ledger; optional referrer at signup | ACH rail **disabled**; bank link API can exist without cash movement |
| **1** | Public beta / TestFlight; Texas-forward user base possible | Micro-deposit **verification** only with bank approval |
| **2** | ACH deposit live | Settlement account + origination agreement |
| **3** | ACH withdraw live | Holds, returns, velocity limits |
| **4** | Scale | Automated returns processing, enhanced fraud, possible RTP/FedNow (separate analysis) |

---

## 8. Documents and code references (for diligence)

| Item | Location |
|------|----------|
| Ledger-first / bank optional policy | `docs/LEDGER-FIRST-BANK-OPTIONAL.md` |
| Micro-deposit linking (no aggregators) | `docs/BANK-LINK-MICRODEPOSITS.md` |
| ACH settlement design (ledger credit on settle) | `docs/MOOV-ACH-FUNDING.md` |
| Corporate fee / referral pool | `docs/CORPORATE-LEDGER.md` |
| Schema (bank links, deposits, withdrawals) | `database/migrations/013_moov_ach.sql`, `014_bank_link_microdeposits.sql` |

---

## 9. Questions for counsel (checklist)

1. Is **Phase 0 ledger-only P2P** (no ACH) viable in Texas with stated disclosures, and for how long?  
2. What triggers **Texas MSB** / NMLS filing for Phase 1–3? Timeline and surety bond?  
3. Recommended **contract structure** with Frost (or other TX bank): FBO language, ODFI roles, liability for returns.  
4. **Multi-state** exposure if App Store distribution is national.  
5. **Referral payments** — any lottery/MLM or money-transmission characterization concerns (single-level only).  
6. **Platform fee** — money transmission or permissible service fee?  
7. Marketing review: “we make payments easy,” balance display, “+ My Bank (optional).”  
8. Insurance: cyber, crime/fidelity, D&O as appropriate.

---

## 10. Contact / business facts (fill before sending)

| Field | Value |
|-------|--------|
| Legal entity name | _[fill in]_ |
| State of formation | _[fill in]_ |
| EIN | _[fill in]_ |
| Principal address (Texas) | _[fill in]_ |
| Authorized contact | _[fill in]_ |
| Website / app name | Czedr |
| Target launch geography | Texas-first; national app distribution possible |

---

*This memorandum summarizes product intent as implemented in the Czedr repository. Counsel should verify all regulatory citations and recommend final structure before any live ACH or cash handling.*
