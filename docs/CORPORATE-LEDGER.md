# Corporate ledger account (`CORPORATE`)

Internal platform account that holds **net** revenue after referral payouts on each P2P transfer.

## Flow (per payment)

1. Sender pays recipient the **full payment amount**.
2. Sender also pays the **platform fee** (`CZEDR_TRANSFER_FEE_CENTS`, default **$1.29**).
3. The fee is credited to **`CORPORATE`** (`czedr_id` **CORPORATE**).
4. Up to **two** referral rewards per transfer (default **$0.17** each), paid **from CORPORATE** when balance allows:
   - Sender’s referrer (if the sender signed up with a referrer).
   - Recipient’s referrer (if the recipient signed up with a referrer).
5. **Net** left in CORPORATE = fee − total referrals (e.g. $1.29 − $0.34 = **$0.95** when both sides qualify).

If fees are disabled (`CZEDR_TRANSFER_FEE_CENTS=0`) but referrals are enabled, referral rewards still mint from **SYSTEM** (same as before).

## Reserved ID

`CORPORATE` cannot be registered by members (like `SYSTEM` and `REVENUE`).

## Access control

- **`CORPORATE`** is a reserved platform Czedr ID — members cannot register it or send P2P payments to it.
- There is **no app login** for CORPORATE. Only **you** should hold the server secret **`CZEDR_ADMIN_REPORT_TOKEN`** (long random value in production `.env`).
- If the token is unset, admin routes return **404** (hidden).

## Admin portal (you only)

1. Set `CZEDR_ADMIN_REPORT_TOKEN` in `.env` on the API server.
2. Open **`/corporate-portal`** on your API host (e.g. `https://api.yourdomain.com/corporate-portal`).
3. Paste your admin token once; it stays in **session storage** on that browser only.
4. The portal shows balance, fees collected, referrals paid, and net — read-only.

## Admin API

```http
GET /v1/admin/corporate-ledger
X-Czedr-Admin-Token: <token>
```

Response fields:

| Field | Meaning |
|-------|---------|
| `balance_cents` | Current CORPORATE ledger balance |
| `fees_collected_cents` | Total service fees received |
| `referrals_paid_cents` | Total referral payouts from CORPORATE |
| `net_after_referrals_cents` | fees_collected − referrals_paid |
| `transfer_fee_cents` | Configured fee per transfer |
| `referral_reward_cents` | Configured referral per qualifying payment |

`GET /v1/admin/revenue-ledger` returns the same corporate totals (legacy alias).

## Test

```powershell
cd C:\Michaels Apps\czedr\scripts
.\start-php-server.ps1
php ..\scripts\test-corporate-ledger.php
```
