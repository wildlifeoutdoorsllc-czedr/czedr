# Finish Gmail App Password (czedrapp@gmail.com)

Password reset emails need a **Google App Password** on the server. Your normal Gmail sign-in password will **not** work for SMTP.

---

## Easiest way (no editor)

1. Create the app password in Google (Part 1 below).
2. Double-click **`SET-GMAIL-APP-PASSWORD.cmd`** in the Czedr folder.
3. Paste the password when asked — the script saves it and sends a test email.

**Optional (nano on line 10):** `OPEN-MAIL-PASSWORD-LINE.cmd` — only if you want to edit by hand.

---

## Part 1 — In your browser (Google)

1. Sign in to **czedrapp@gmail.com**.
2. Turn on **2-Step Verification** for that account (required).
   - [Google 2-Step Verification](https://myaccount.google.com/signinoptions/two-step-verification)
3. Create an app password:
   - [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
4. App name: **Czedr VPS** → **Create**.
5. Copy the **16-character** password (often shown as four groups of four letters, e.g. `abcd efgh ijkl mnop`).
   - You can paste it **with or without spaces** on the server.

---

## Part 2 — On the server (SSH)

Connect: double-click **`CONNECT-TO-VPS.cmd`**, then run:

```bash
nano /root/.czedr-mail-secrets
```

Find this line:

```text
MAIL_PASS=PASTE_16_CHAR_APP_PASSWORD_HERE
```

Replace only the part after `=` with your app password. Example:

```text
MAIL_PASS=abcdefghijklmnop
```

Save and exit:

- **Ctrl+O** → Enter (save)
- **Ctrl+X** (exit)

---

## Part 3 — Apply and test

Still on the server:

```bash
bash /var/www/czedr/scripts/setup-vps-email.sh
php /var/www/czedr/scripts/test-mail.php czedrapp@gmail.com
```

You want:

```text
OK: test email sent to czedrapp@gmail.com
```

Check the **czedrapp@gmail.com** inbox (and Spam) for “CZEDR test email”.

---

## If something fails

| Problem | Fix |
|---------|-----|
| “App passwords” page missing | Turn on 2-Step Verification first |
| `Permission denied` / auth failed | Wrong app password — create a new app password and update `MAIL_PASS` |
| `MAIL_* not configured` | Run `bash /var/www/czedr/scripts/setup-vps-email.sh` again after editing secrets |
| No email in inbox | Check Spam; wait 2–3 minutes |

Never commit `/root/.czedr-mail-secrets` or paste the app password in chat.
