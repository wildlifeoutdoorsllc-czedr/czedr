# Ledger-first, bank-optional

Czedr is designed to **minimize bank bottlenecks** while staying within U.S. money-movement rules.

## What never requires a bank

| Feature | Bank needed? |
|---------|----------------|
| Sign up / sign in | No |
| P2P payments (Make Payment) | No — internal ledger only |
| Send Invoice | No |
| Referral rewards | No |
| Platform fee ($1.29) | No — debited from sender balance |

Members can use Czedr **indefinitely** with balance funded by other members, promos, or admin loads (sandbox).

## What optionally uses a bank (later)

| Feature | When |
|---------|------|
| **+ My Bank** (micro-deposit link) | Only if member wants ACH cash **in** or **out** |
| ACH deposit | After link **verified** + ACH rail enabled on server |
| ACH withdraw | Same; `CZEDR_ACH_WITHDRAW_ENABLED=1` when implemented |

No Plaid, Yodlee, or **bank passwords** — see `docs/BANK-LINK-MICRODEPOSITS.md`.

## API behavior

- `GET /v1/funding/status` — **always** returns `ledger_first` + bank list (never 503).
- `POST /v1/funding/bank-link/*` — always available for micro-deposit linking.
- `POST /v1/funding/moov/deposit` — **503** until `MOOV_ENABLED=1` (cash-in rail optional).

## Reducing wait times (legal)

| Bottleneck | Mitigation |
|------------|------------|
| Micro-deposit 1–3 days | Same-day ACH credits when bank supports; local dev `CZEDR_MICRO_DEPOSIT_SKIP_WAIT=1` |
| ACH settlement | Credit ledger only on **settled** webhook (required) |
| Bank partnership | One FBO + file-based origination (OpenACH / achgateway), not per-txn SaaS |
| Member confusion | App copy: “Pay on Czedr without linking a bank” |

## iOS

**Profile → + My Bank** — link or confirm micro-deposits. Not required for home or payments.

## Outreach documents

| Audience | Document |
|----------|----------|
| Attorney (Texas MSB, FBO, disclosures) | `docs/CZEDR-ATTORNEY-BRIEF.md` — includes §11 counsel placeholders and DFW candidate list |
| Banks / CUs (Frost, ACH origination pitch) | `docs/CZEDR-TREASURY-BANK-PITCH.md` |
