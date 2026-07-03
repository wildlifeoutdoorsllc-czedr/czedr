#!/bin/bash
# Install outbound email tools on Czedr VPS and merge MAIL_* into .env when secrets exist.
# Run on server as root: bash /var/www/czedr/scripts/setup-vps-email.sh
set -euo pipefail

ROOT="${CZEDR_DEPLOY_ROOT:-/var/www/czedr}"
SECRETS="/root/.czedr-mail-secrets"
EXAMPLE="${ROOT}/scripts/czedr-mail-secrets.example"

echo "==> Czedr email setup"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates msmtp msmtp-mta mailutils >/dev/null

if [[ ! -f "$SECRETS" ]]; then
  echo ""
  echo "No $SECRETS yet."
  echo "Copy the example, edit with your mailbox password, then re-run this script:"
  echo "  cp $EXAMPLE $SECRETS"
  echo "  chmod 600 $SECRETS"
  echo "  nano $SECRETS"
  echo ""
  if [[ -f "$EXAMPLE" ]]; then
    cp "$EXAMPLE" "${SECRETS}.example-installed"
  fi
  exit 0
fi

chmod 600 "$SECRETS"
# shellcheck disable=SC1090
source "$SECRETS"

ENV_FILE="${ROOT}/.env"
touch "$ENV_FILE"
merge_var() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
  else
    echo "${key}=${val}" >>"$ENV_FILE"
  fi
}

merge_var MAIL_ENABLED "${MAIL_ENABLED:-1}"
merge_var MAIL_HOST "${MAIL_HOST}"
merge_var MAIL_PORT "${MAIL_PORT:-587}"
merge_var MAIL_USER "${MAIL_USER}"
merge_var MAIL_PASS "${MAIL_PASS}"
merge_var MAIL_FROM "${MAIL_FROM:-$MAIL_USER}"
merge_var MAIL_FROM_NAME "${MAIL_FROM_NAME:-CZEDR}"
merge_var MAIL_ENCRYPTION "${MAIL_ENCRYPTION:-tls}"

chmod 640 "$ENV_FILE"
chown root:www-data "$ENV_FILE" 2>/dev/null || true

echo "==> MAIL_* merged into ${ENV_FILE}"
systemctl restart czedr-api 2>/dev/null || true

if [[ -f "${ROOT}/scripts/test-mail.php" ]]; then
  echo "==> Sending test email (if configured)..."
  php "${ROOT}/scripts/test-mail.php" "${MAIL_USER:-$MAIL_FROM}" || true
fi

echo "Done."
