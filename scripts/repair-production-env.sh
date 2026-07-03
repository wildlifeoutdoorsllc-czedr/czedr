#!/bin/bash
# Repair production .env on OneVPS (dedupe keys, apply secrets, iOS migration flags).
set -euo pipefail
SECRETS="/root/.czedr-deploy-secrets"
ENV="/var/www/czedr/.env"
DOMAIN="${CZEDR_API_DOMAIN:-api.czedr.com}"

if [[ ! -f "$SECRETS" ]]; then
  echo "Missing $SECRETS"
  exit 1
fi
# shellcheck disable=SC1090
source "$SECRETS"

umask 077
cat >"$ENV" <<EOF
APP_ENV=production
APP_DEBUG=false
APP_PUBLIC_URL=https://${DOMAIN}
CZEDR_RATE_LIMIT=1
CZEDR_CRYPTO_PEPPER=${CZEDR_CRYPTO_PEPPER}
VAULT_USER_SATURN=app_saturn
VAULT_PASS_SATURN=${DB_PASS}
CZEDR_AUTO_MIGRATE=0
MOOV_ENABLED=0
CZEDR_BANK_LINK_METHOD=microdeposit
CZEDR_TRANSFER_FEE_CENTS=129
CZEDR_REFERRAL_REWARD_CENTS=17
# Temporary until iOS/Android use *-secure auth over HTTPS (see docs/MIGRATION-TO-VPS.md)
CZEDR_ALLOW_PLAIN_AUTH=1
EOF
chmod 640 "$ENV"
chown www-data:www-data "$ENV" 2>/dev/null || true
systemctl restart czedr-api
echo "Repaired $ENV and restarted czedr-api"
