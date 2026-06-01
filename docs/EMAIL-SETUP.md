# Czedr — email on the VPS

Outbound email is used for **password reset** and can be extended for other alerts. The API sends mail over **SMTP** using `MAIL_*` settings in `.env`.

## Gmail (czedrapp@gmail.com)

Step-by-step app password checklist: **`docs/GMAIL-APP-PASSWORD.md`**

---

## What you need

1. A real mailbox or SMTP service for your domain, e.g.:
   - **GoDaddy Email** — `noreply@czedr.com` or `support@czedr.com`
   - **SendGrid**, **Brevo**, **Amazon SES** — transactional SMTP
2. SMTP host, port, username, and password from that provider.

## One-time server setup

SSH to the VPS, then:

```bash
cd /var/www/czedr
bash scripts/setup-vps-email.sh
```

First run installs `msmtp` (system mail tools). It will tell you to create secrets:

```bash
cp scripts/czedr-mail-secrets.example /root/.czedr-mail-secrets
chmod 600 /root/.czedr-mail-secrets
nano /root/.czedr-mail-secrets   # paste real MAIL_PASS
bash scripts/setup-vps-email.sh   # merges into .env and sends a test
```

From your PC after a code deploy:

```text
scripts\ssh-onevps.cmd
```

## GoDaddy mailbox (typical)

| Setting | Value |
|---------|--------|
| SMTP host | `smtpout.secureserver.net` |
| Port | `587` (TLS) or `465` (SSL — set `MAIL_ENCRYPTION=ssl`) |
| User | Full address, e.g. `noreply@czedr.com` |
| Password | That mailbox’s password |

Create the mailbox in GoDaddy → **Email & Office** → add `noreply@czedr.com`.

## .env variables

| Variable | Example |
|----------|---------|
| `MAIL_ENABLED` | `1` |
| `MAIL_HOST` | `smtpout.secureserver.net` |
| `MAIL_PORT` | `587` |
| `MAIL_ENCRYPTION` | `tls` or `ssl` |
| `MAIL_USER` | `noreply@czedr.com` |
| `MAIL_PASS` | mailbox password |
| `MAIL_FROM` | `noreply@czedr.com` |
| `MAIL_FROM_NAME` | `CZEDR` |

`APP_PUBLIC_URL` should be `https://api.czedr.com` so reset links in email are correct.

## Test from the server

```bash
cd /var/www/czedr
php scripts/test-mail.php yourname@gmail.com
```

## Test password reset

Use **Forgot password?** on the iOS sign-in screen (build **119+**), or:

```bash
curl -sS -X POST https://api.czedr.com/v1/auth/forgot-password \
  -H 'Content-Type: application/json' \
  -d '{"email":"alice@test.czedr"}'
```

Check the inbox (and spam). Local dev still logs tokens to `storage/logs/password-reset.log` when SMTP is off.

## Security

- Keep `/root/.czedr-mail-secrets` mode **600** — never commit it to git.
- Use a dedicated `noreply@` address, not your personal inbox password in shared files.
