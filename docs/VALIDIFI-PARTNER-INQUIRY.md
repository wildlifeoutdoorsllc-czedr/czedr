# ValidiFI — partner inquiry email (draft for Michael)

**Use this:** Copy the **Ready to send** section below. Fill in only **email**, **phone**, and **legal entity name** if you want it on the letterhead.

**Not legal advice.** Run final wording past your counsel before signing any contract.

---

## Ready to send (tailored for Czedr today)

**Subject:** `Czedr — partnership inquiry: NACHA account validation + KYC (no bank-login aggregation)`

---

Hello ValidiFI partnerships / sales team,

My name is **Michael**, **Founder** of **Czedr** (https://czedr.com). Czedr is a **Texas-based** mobile payments startup building a **peer-to-peer wallet** where members pay each other with an **in-app balance** and a simple **Czedr ID**—no linked bank required for payments inside the app.

We are in **TestFlight beta** on iOS (live production API at https://api.czedr.com), with a **small controlled pilot** today and a **public beta** planned over the next several months. We are **not** processing consumer ACH cash-in/out at scale yet; that rail is intentionally **behind a feature flag** while we finalize our **Texas bank partnership** (we already bank with **Frost Bank**) and our **money-transmission / MSB legal structure** with outside counsel.

We are evaluating ValidiFI as a **technology partner** for **onboarding**, **bank account validation**, and practical support for **NACHA** (including WEB debit account validation) and **KYC/CIP**—**before** we turn ACH on for deposit and withdrawal. Our product commitment is **no Plaid-style bank logins**: we want **micro-deposit verification** and/or **non-credentialed** validation wherever possible, not asking members for online banking passwords.

### How Czedr works (short)

- **Ledger-first:** P2P works on our internal ledger; bank link is **optional** for cash in/out only.
- **No Plaid / no online banking passwords:** We do **not** want members to enter bank usernames and passwords. We prefer **micro-deposit verification** and/or **non-credentialed** account validation where possible.
- **ACH (planned):** Micro-deposit credits for verification; later ACH debits (add money) and ACH credits (withdraw) via **NACHA file** origination with our bank partner—not card acquiring.
- **Geography:** Texas-oriented company; app may be available nationally via app stores. Counsel review in progress.

### Why we are contacting ValidiFI

We understand ValidiFI is a **NACHA Preferred Partner** and participates in **Phixius**, with APIs for account validation, ownership, fraud signals, and identity/KYC-related services. We would like to understand whether ValidiFI fits Czedr’s model **without** requiring credentialed bank aggregation.

### Questions for your team

**Product fit**

1. Can we use ValidiFI for **account validation and ownership** for **WEB debit** / ACH origination while **not** offering your **CONNECT** bank-login (credentialled) flow to end users?
2. Which products map best to our approach: **non-credentialed** validation (routing + account), **real-time micro-deposits**, and/or **Phixius** network validation?
3. Do you support a **ledger-first wallet** where bank link is optional and P2P does not touch ACH?

**NACHA**

4. How do your solutions help with **Nacha WEB Debit Rule** account validation and the **2026 fraud-monitoring** expectations? What is required from us operationally vs. what your API automates?
5. What **coverage** and **latency** should we expect for US DDA accounts (approve/decline, account status, ownership confidence scores)?
6. Can you provide **documentation** on recommended flow: validate at link time vs. validate again at each debit?

**KYC / identity**

7. Which **KYC/CIP** capabilities do you offer (e.g., identity verification, watchlist/OFAC, device/phone/email risk)? Are these separate SKUs or bundled in Omni?
8. What **PII** do you store vs. tokenize, and what are our obligations under your MSA (GLBA, subprocessors, data retention)?
9. Can onboarding combine **email/password signup** with stepped-up verification only when a user links a bank or requests higher limits?

**Integration & operations**

10. **REST API** integration timeline for a small engineering team—typical go-live for validation-only vs. full onboarding?
11. **Pricing** model (per inquiry, per active user, monthly minimums) for a **pilot** (~hundreds to low thousands of users) and at **scale**.
12. **Sandbox / test environment** and sample responses for micro-deposit and non-credentialed paths.

**Compliance (high level—we rely on counsel for legal conclusions)**

13. Does ValidiFI provide **compliance documentation** our bank or counsel can review (SOC 2, model validation, NACHA partner materials)?
14. Clarify the division of responsibility: what ValidiFI covers vs. what remains **our** obligation as the program operator (BSA/AML program, FinCEN MSB, state licensing, Reg E, etc.).

### What we are *not* looking for

- Card acquiring or card network processing  
- Replacing our **settlement bank** or **ACH file origination** (we plan NACHA files + bank SFTP/portal)  
- A consumer-facing flow that asks for **online banking passwords**

### Next step

We would welcome a **30-minute call** with your fintech / wallet specialist to review fit, pricing, and a recommended **phased rollout** (pilot: validation + KYC at bank link; phase 2: ongoing fraud monitoring).

Please suggest times or send a **NDA + standard pricing overview** if required before technical deep dive.

Thank you,

**Michael**  
Founder — **Czedr**  
**[your email]** | **[your phone]**  
https://czedr.com · https://api.czedr.com  

*(Optional letterhead line: operating as **[Your LLC / Corp legal name — e.g. Wildlife Outdoors LLC]** if you want that on the email.)*

---

## Full template (with bracket placeholders)

Use this version if you prefer to customize the opening yourself.

**Subject:** `Czedr — partnership inquiry: NACHA account validation + KYC (no bank-login aggregation)`

Hello ValidiFI partnerships / sales team,

My name is **[Michael Last Name]**, **[Founder / CEO]** of **Czedr** (czedr.com). We are building a **mobile peer-to-peer payments app** where members hold an **in-app USD balance** and pay each other by **Czedr ID** without needing a linked bank for P2P.

We are evaluating partners to help with **customer onboarding**, **bank account validation**, and support for **NACHA** and **KYC/CIP** expectations before we turn on **ACH deposit and withdrawal** with a **Texas depository bank** (we have an existing banking relationship and are working with counsel on MSB / money-transmission structure).

*(…same sections as “Ready to send” above: How Czedr works, Why ValidiFI, Questions, What we are not looking for, Next step…)*

---

## Optional attachment

| Document | Path in repo |
|----------|----------------|
| Treasury / ACH one-pager for banks | `docs/CZEDR-TREASURY-BANK-PITCH.md` |
| Attorney brief (confidential—only if counsel approves) | `docs/CZEDR-ATTORNEY-BRIEF.md` |
| Micro-deposit technical design | `docs/BANK-LINK-MICRODEPOSITS.md` |

---

## After they reply — checklist for you

- [ ] Share reply with **Texas payments attorney** before signing  
- [ ] Confirm **no bank-login** path is contractually allowed for your use case  
- [ ] Compare quote to **DIY micro-deposits + bank** only  
- [ ] Ask engineering for API sandbox estimate (1–2 week spike)  
- [ ] Do **not** enable live ACH until bank + counsel + validation vendor (if any) are aligned  

---

## Contacts (public — verify on validifi.com)

- Website: https://validifi.com  
- Compliance / NACHA page: https://validifi.com/compliance/  
- NACHA partner listing: https://www.nacha.org/content/validifi  
- API docs (Omni): https://apidocs.ribbit.ai/ (ValidiFI / Ribbit branding—confirm current URL with sales)
