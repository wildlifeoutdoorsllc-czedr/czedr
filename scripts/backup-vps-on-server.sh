#!/bin/bash
# Full Czedr VPS emergency backup — run on server as root.
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="${1:-/var/backups/czedr/emergency-${STAMP}}"
mkdir -p "$DEST"

echo "==> Czedr VPS backup -> ${DEST}"

mysqldump -u root --single-transaction --routines --triggers saturn \
  | gzip -c >"${DEST}/saturn.sql.gz"

cp -a /root/.czedr-deploy-secrets "${DEST}/czedr-deploy-secrets" 2>/dev/null || true
cp -a /var/www/czedr/.env "${DEST}/dot-env" 2>/dev/null || true
cp -a /var/www/czedr/config/database.local.php "${DEST}/database.local.php" 2>/dev/null || true
cp -a /etc/caddy/Caddyfile "${DEST}/Caddyfile" 2>/dev/null || true

tar -czf "${DEST}/czedr-app.tgz" \
  --exclude='backend/storage/profiles/*.jpg' \
  -C /var/www czedr/backend czedr/config czedr/database czedr/scripts czedr/marketing czedr/.env.production.example 2>/dev/null \
  || tar -czf "${DEST}/czedr-app.tgz" -C /var/www czedr

if [[ -d /var/www/czedr/backend/storage ]]; then
  tar -czf "${DEST}/czedr-storage.tgz" -C /var/www/czedr/backend storage 2>/dev/null || true
fi

{
  echo "backup_at=${STAMP}"
  echo "hostname=$(hostname -f 2>/dev/null || hostname)"
  echo "users=$(mysql -u root -N -e 'SELECT COUNT(*) FROM saturn.users' 2>/dev/null || echo '?')"
  uname -a
} >"${DEST}/README.txt"

chmod -R 700 "$DEST"
echo "OK:${DEST}"
