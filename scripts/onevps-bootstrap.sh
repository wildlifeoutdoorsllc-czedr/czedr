#!/bin/bash
# Czedr OneVPS first-time bootstrap — run ON THE SERVER as root after SSH login.
# Usage: bash onevps-bootstrap.sh
# Does NOT upload your app code — run deploy-on-server.sh after copying repo to /var/www/czedr

set -euo pipefail

echo "==> Czedr OneVPS bootstrap (Ubuntu 24)"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y ufw fail2ban git curl unzip mariadb-server \
  php-fpm php-cli php-mysql php-mbstring php-curl php-xml php-zip

# Swap (2GB VPS)
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Firewall — OneVPS SSH is often 22122 (adjust if you moved sshd)
SSH_PORT="${SSH_PORT:-22122}"
ufw allow "${SSH_PORT}/tcp" || true
ufw allow OpenSSH || true
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# MariaDB tune for 2GB
mkdir -p /etc/mysql/mariadb.conf.d
cat > /etc/mysql/mariadb.conf.d/99-czedr.cnf <<'CNF'
[mysqld]
innodb_buffer_pool_size = 256M
max_connections = 50
CNF
systemctl enable mariadb
systemctl restart mariadb

# Caddy
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy

mkdir -p /var/www/czedr
chown -R www-data:www-data /var/www/czedr

# Caddyfile placeholder — edit domain after DNS works
cat > /etc/caddy/Caddyfile <<'CADDY'
api.czedr.com {
    reverse_proxy 127.0.0.1:8080
}
CADDY

# PHP API systemd unit (needs code in /var/www/czedr)
cat > /etc/systemd/system/czedr-api.service <<'UNIT'
[Unit]
Description=Czedr PHP API
After=network.target mariadb.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/czedr/backend/public
Environment=CZEDR_ROOT=/var/www/czedr
ExecStart=/usr/bin/php -S 127.0.0.1:8080 -t /var/www/czedr/backend/public
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload

echo ""
echo "Bootstrap done."
echo "Next:"
echo "  1) Copy Czedr code to /var/www/czedr (git clone or scp from your PC)"
echo "  2) Configure .env and config/database.local.php"
echo "  3) mysql: create saturn DB + app_saturn user"
echo "  4) php /var/www/czedr/scripts/run-migrations.php"
echo "  5) systemctl enable --now czedr-api && systemctl reload caddy"
echo "  6) curl https://api.czedr.com/v1/health"
