#!/bin/bash
# Import saturn dump on OneVPS (called from migrate-local-to-vps.ps1).
set -euo pipefail
DUMP="${1:-/tmp/czedr-saturn-migrate.sql}"
systemctl stop czedr-api || true
mysql -u root -e "DROP DATABASE IF EXISTS saturn; CREATE DATABASE saturn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root saturn <"$DUMP"
# shellcheck disable=SC1091
source /root/.czedr-deploy-secrets
mysql -u root -e "GRANT ALL PRIVILEGES ON saturn.* TO 'app_saturn'@'localhost'; FLUSH PRIVILEGES;"
chown -R www-data:www-data /var/www/czedr/backend/storage 2>/dev/null || true
systemctl start czedr-api
USERS=$(mysql -u root -N -e "SELECT COUNT(*) FROM saturn.users")
echo "Imported users: ${USERS}"
curl -fsS "https://api.czedr.com/v1/health"
echo ""
