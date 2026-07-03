# Plaid — security opinion (for Czedr product decisions)

**Not legal advice.** Engineering perspective for Michael and counsel.

---

## What Plaid is

[Plaid](https://plaid.com) is a **financial data connectivity** company. Many apps use it so users can “link” a bank by signing into their bank inside a Plaid-hosted flow. Plaid then provides account/routing info, balances, and sometimes ACH initiation partners.

---

## Security strengths (why companies use it)

| Area | Plaid’s typical approach |
|------|---------------------------|
| **You don’t store bank passwords** | User enters credentials in Plaid’s UI; your servers ideally never see the bank password |
| **Mature vendor** | Large compliance program (SOC 2, etc.), dedicated security team |
| **Reduced scraping** | Less home-grown bank scraping (which is fragile and risky) |
| **Tokenized access** | Ongoing access via Plaid tokens rather than raw passwords in your DB |

For a startup that **cannot** run micro-deposits, NACHA files, and fraud ops, Plaid is often the **practical** way to link banks.

---

## Security weaknesses and real-world risks

| Risk | What it means for users and you |
|------|----------------------------------|
| **Concentration / supply chain** | One breach or outage at Plaid affects many apps |
| **Users still type bank passwords somewhere** | Phishing can mimic “Connect with Plaid”; users are trained to enter bank creds in third-party widgets |
| **Over-collection** | Apps may request more data than needed (transactions, identity) — expands blast radius if token stolen |
| **Account takeover via linked app** | If attacker gets **your** app account + Plaid link, they may move money depending on product design |
| **Regulatory & contractual** | You depend on Plaid’s terms, subprocessors, and incident notices |
| **Not a substitute for app security** | TLS, session security, PIN, rate limits still required on **your** API |

Plaid does **not** eliminate identity theft or account takeover on **your** platform.

---

## Comparison to Czedr’s chosen model (micro-deposits)

| Topic | Plaid-style aggregation | Czedr micro-deposits (current design) |
|-------|-------------------------|--------------------------------------|
| Bank password to third party | Yes (Plaid) | **No** |
| Proof of account ownership | Instant (if creds work) | 1–3 days (ACH micro credits) |
| User friction | Lower | Higher |
| Vendor dependency | High (Plaid) | Lower (your bank + ACH files / Moov optional) |
| Credential phishing target | “Plaid” + your brand | Your brand only (routing/account entry) |
| Data at rest in Czedr | Tokens + metadata | Encrypted routing/account vault |
| Fit for ledger-first P2P | Common | Matches “bank optional” story |

**Czedr’s docs explicitly reject Plaid/Yodlee** to avoid routing **online banking passwords** through aggregators (`docs/BANK-LINK-MICRODEPOSITS.md`). That is a **defensible privacy and trust** position, not “Plaid is always insecure.”

---

## Opinion (summary)

1. **Plaid is not “insecure”** in the sense of a sketchy library — it is a major, regulated fintech infrastructure vendor used by thousands of apps.
2. **Plaid is the wrong fit for Czedr’s stated policy** — you chose proof-of-ownership without bank logins; keep that unless business needs force a change.
3. **Biggest risks to your users today** are not “Plaid vs no Plaid” — they are **production deployment**, **HTTPS**, **stolen app sessions**, **4-digit PIN**, **credential stuffing**, and **server misconfiguration** (see `docs/CZEDR-SECURITY-VS-IDENTITY-THEFT.md`).
4. **If you ever add Plaid later** — treat it as a major compliance decision: vendor due diligence, data minimization (scopes), incident plan, and updated privacy policy.

---

## When Plaid might make sense later

- You need **instant** bank linking and cannot operate micro-deposits + ACH ops.
- Your bank partner requires aggregator connectivity.
- You accept subprocessors and pass **Plaid’s** trust model to users.

Until then, **micro-deposits + Moov/file ACH** (as documented) align with your security story.

---

*End.*
