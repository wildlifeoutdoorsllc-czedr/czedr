#!/bin/bash
# Finish Czedr deploy on OneVPS — run as root after code is in /var/www/czedr
set -euo pipefail

ROOT="${CZEDR_DEPLOY_ROOT:-/var/www/czedr}"
SECRETS="/root/.czedr-deploy-secrets"
DOMAIN="${CZEDR_API_DOMAIN:-api.czedr.com}"
SSH_PORT="${SSH_PORT:-22122}"

cd "$ROOT"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/deploy-on-server.sh"
  exit 1
fi

if [[ ! -f backend/bootstrap.php ]]; then
  echo "Missing app code in $ROOT (backend/bootstrap.php not found)."
  echo "Upload from your PC first: scripts\\deploy-onevps.ps1"
  exit 1
fi

run_bootstrap() {
  if command -v caddy >/dev/null 2>&1 && systemctl is-active --quiet mariadb 2>/dev/null; then
    return 0
  fi
  echo "==> Installing stack (bootstrap)..."
  export SSH_PORT
  bash "$ROOT/scripts/onevps-bootstrap.sh"
}

run_bootstrap

if [[ ! -f "$SECRETS" ]]; then
  DB_PASS="$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)"
  PEPPER="$(openssl rand -base64 32)"
  umask 077
  cat >"$SECRETS" <<EOF
DB_PASS=${DB_PASS}
CZEDR_CRYPTO_PEPPER=${PEPPER}
EOF
  chmod 600 "$SECRETS"
  echo "==> Saved secrets in $SECRETS (back this up securely)."
fi
# shellcheck disable=SC1090
source "$SECRETS"

if [[ ! -f .env.production.example ]]; then
  echo "Missing .env.production.example in $ROOT"
  exit 1
fi

if [[ ! -f .env ]] || grep -q 'REPLACE_WITH_OPENSSL' .env 2>/dev/null || ! grep -q '^VAULT_PASS_SATURN=' .env 2>/dev/null || [[ $(grep -c '^CZEDR_CRYPTO_PEPPER=' .env 2>/dev/null || echo 0) -gt 1 ]]; then
  echo "==> Writing .env"
  umask 077
  cat >.env <<EOF
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
CZEDR_ALLOW_PLAIN_AUTH=1
EOF
  chmod 640 .env
fi

if [[ ! -f config/database.local.php ]] || grep -q "'user' => 'root'" config/database.local.php 2>/dev/null; then
  echo "==> Writing config/database.local.php"
  DB_PASS_ESC="${DB_PASS//\'/\\\'}"
  cat >config/database.local.php <<PHP
<?php
return [
    'host' => '127.0.0.1',
    'port' => 3306,
    'user' => 'app_saturn',
    'pass' => '${DB_PASS_ESC}',
    'charset' => 'utf8mb4',
    'databases' => [
        'app' => 'saturn',
    ],
    'options' => [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ],
];
PHP
fi

echo "==> MariaDB database and user"
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS saturn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'app_saturn'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER 'app_saturn'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON saturn.* TO 'app_saturn'@'localhost';
FLUSH PRIVILEGES;
SQL

chown -R www-data:www-data "$ROOT"
chmod 640 .env 2>/dev/null || true
chmod 640 config/database.local.php 2>/dev/null || true

echo "==> Base schema (saturn.sql)"
SCHEMA_FRESH=0
if ! mysql -u root -N -e "SELECT 1 FROM information_schema.tables WHERE table_schema='saturn' AND table_name='users' LIMIT 1" | grep -q 1; then
  mysql -u root <"$ROOT/database/schemas/saturn.sql"
  SCHEMA_FRESH=1
fi

if [[ "$SCHEMA_FRESH" -eq 1 ]]; then
  echo "==> Marking migrations already included in saturn.sql"
  for f in "$ROOT"/database/migrations/00[3-9]_*.sql "$ROOT"/database/migrations/01[01]_*.sql; do
    [[ -f "$f" ]] || continue
    mysql -u root saturn -e "INSERT IGNORE INTO schema_migrations (filename) VALUES ('$(basename "$f")')"
  done
fi

echo "==> Migrations"
php "$ROOT/scripts/run-migrations.php"

echo "==> Caddy + API service"
cat >/etc/caddy/Caddyfile <<CADDY
${DOMAIN} {
    reverse_proxy 127.0.0.1:8080
}

czedr.com, www.czedr.com {
    root * /var/www/czedr/marketing
    file_server
    try_files {path} /index.html
}
CADDY

systemctl daemon-reload
systemctl enable mariadb czedr-api caddy
systemctl restart czedr-api
systemctl reload caddy || systemctl restart caddy

echo ""
echo "==> Waiting for HTTPS (up to 90s)..."
for i in $(seq 1 18); do
  if curl -fsS "https://${DOMAIN}/v1/health" >/dev/null 2>&1; then
    echo "OK: https://${DOMAIN}/v1/health"
    curl -sS "https://${DOMAIN}/v1/health" | head -c 400
    echo ""
    exit 0
  fi
  sleep 5
done

echo "Deploy finished but HTTPS health check timed out."
echo "Check: systemctl status czedr-api caddy"
echo "Check DNS: dig +short ${DOMAIN}"
echo "Try: curl -v https://${DOMAIN}/v1/health"
exit 1
