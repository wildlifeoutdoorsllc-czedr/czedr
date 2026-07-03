#!/bin/bash
# Read one line from stdin (Google App Password) and set MAIL_PASS in /root/.czedr-mail-secrets
# Called from Windows: scripts/set-gmail-app-password.ps1
set -euo pipefail

SECRETS="/root/.czedr-mail-secrets"
ROOT="${CZEDR_DEPLOY_ROOT:-/var/www/czedr}"

if [[ ! -f "$SECRETS" ]]; then
  if [[ -f "$ROOT/scripts/czedr-mail-secrets.gmail.example" ]]; then
    cp "$ROOT/scripts/czedr-mail-secrets.gmail.example" "$SECRETS"
  elif [[ -f "$ROOT/scripts/czedr-mail-secrets.example" ]]; then
    cp "$ROOT/scripts/czedr-mail-secrets.example" "$SECRETS"
  else
    echo "Missing secrets file and template under $ROOT/scripts/" >&2
    exit 1
  fi
  chmod 600 "$SECRETS"
fi

IFS= read -r pass || true
pass="${pass//$'\r'/}"
pass="${pass// /}"

if [[ ${#pass} -lt 16 ]]; then
  echo "Password too short (Google app passwords are 16 characters). Got ${#pass}." >&2
  exit 1
fi

if [[ ! "$pass" =~ ^[a-zA-Z0-9]+$ ]]; then
  echo "Unexpected characters. Paste only the 16-letter Google App Password." >&2
  exit 1
fi

if ! grep -q '^MAIL_PASS=' "$SECRETS"; then
  echo "MAIL_PASS= line not found in $SECRETS" >&2
  exit 1
fi

sed -i "s/^MAIL_PASS=.*/MAIL_PASS=${pass}/" "$SECRETS"
chmod 600 "$SECRETS"
echo "OK: MAIL_PASS saved on server (line with MAIL_PASS=)."
