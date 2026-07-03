# Deploy Czedr on OneVPS (Ubuntu 24, 2 GB RAM)

Target: **api.czedr.com** → `91.220.203.91` (OneVPS hostname `VM5413717769735819.onevps.cloud`).

Related: `docs/DEPLOY-HTTPS.md`, `docs/PRODUCTION-SECURITY-CHECKLIST.md`, `.env.production.example`.

---

## SSH login (OneVPS)

OneVPS uses a **non-standard SSH port**, not 22.

| Field | Value |
|-------|--------|
| Host | `91.220.203.91` |
| Port | **`22122`** |
| User | `root` |
| Password | From OneVPS welcome email / panel (paste from Notepad — nothing shows as you type) |

**Windows PowerShell:**

```powershell
ssh -p 22122 root@91.220.203.91
```

Type `yes` on first connect, then paste the password.

**PuTTY:** Host `91.220.203.91`, Port **`22122`**, Connection type SSH. Guide: [OneVPS PuTTY blog](https://blog.onevps.com/how-to-connect-to-linux-from-windows-using-putty/).

After login, open **80/443** for the website/API (`ufw allow 80/tcp` etc.); SSH stays on **22122**.

---

## DNS (do this first)

At your registrar or **Cloudflare** (recommended):

| Type | Name | Value | Notes |
|------|------|--------|--------|
| A | `api` | `91.220.203.91` | Czedr API — proxy through Cloudflare (orange cloud) |
| A | `@` | `91.220.203.91` | Marketing site on same VPS (optional) |
| A | `www` | `91.220.203.91` | Optional |

SSL: use **Caddy** on the server (Let’s Encrypt) or **Cloudflare Full (strict)** with origin cert.

---

## 2 GB RAM notes

- Enough for **API + MariaDB** at low/medium traffic.
- Add **2 GB swap** (below).
- Do **not** run Ollama or heavy services on this box.
- Keep `pm.max_children` low for PHP-FPM (5–8).

---

## 1. SSH and harden

```bash
# From your PC: ssh -p 22122 root@91.220.203.91

apt update && apt upgrade -y
apt install -y ufw fail2ban git curl unzip

# Optional: non-root deploy user
adduser --disabled-password --gecos "" czedr
usermod -aG sudo czedr

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Swap (helps on 2 GB)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

Use **SSH keys** and disable password login when ready.

---

## 2. Install stack

```bash
apt install -y mariadb-server nginx php-fpm php-cli php-mysql php-mbstring php-curl php-xml php-zip
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy
```

---

## 3. Database

```bash
mysql -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS saturn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'app_saturn'@'localhost' IDENTIFIED BY 'REPLACE_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON saturn.* TO 'app_saturn'@'localhost';
FLUSH PRIVILEGES;
SQL
```

Tune MariaDB for 2 GB (`/etc/mysql/mariadb.conf.d/50-server.cnf`):

```ini
innodb_buffer_pool_size = 256M
max_connections = 50
```

```bash
systemctl restart mariadb
```

---

## 4. Deploy code

```bash
mkdir -p /var/www/czedr
cd /var/www/czedr

# Option A: git clone (if repo is accessible from server)
# git clone https://github.com/wildlifeoutdoorsllc-czedr/czedr.git .

# Option B: rsync from your PC (PowerShell on Windows):
# scp -r D:\CZEDR\* root@91.220.203.91:/var/www/czedr/

chown -R www-data:www-data /var/www/czedr
```

On the server:

```bash
cd /var/www/czedr
cp .env.production.example .env
cp config/database.local.php.example config/database.local.php
nano .env
nano config/database.local.php
```

Set at minimum in `.env`:

```env
APP_ENV=production
APP_DEBUG=false
APP_PUBLIC_URL=https://api.czedr.com
CZEDR_RATE_LIMIT=1
CZEDR_CRYPTO_PEPPER=<openssl rand -base64 32>
VAULT_USER_SATURN=app_saturn
VAULT_PASS_SATURN=<same password as MySQL user>
CZEDR_AUTO_MIGRATE=0
MOOV_ENABLED=0
```

Generate pepper:

```bash
openssl rand -base64 32
```

Run migrations:

```bash
cd /var/www/czedr
php scripts/run-migrations.php
```

---

## 5. PHP-FPM + internal listener

Caddy will proxy to PHP on port **8080** (matches local dev).

Create `/etc/systemd/system/czedr-api.service`:

```ini
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
```

```bash
systemctl daemon-reload
systemctl enable --now czedr-api
```

---

## 6. Caddy (HTTPS)

`/etc/caddy/Caddyfile`:

```caddyfile
api.czedr.com {
    reverse_proxy 127.0.0.1:8080
}

# Optional marketing placeholder
czedr.com, www.czedr.com {
    root * /var/www/czedr/marketing
    file_server
    try_files {path} /index.html
}
```

```bash
systemctl reload caddy
```

**Before reload:** ensure DNS for `api.czedr.com` points to this server so Let’s Encrypt can issue a cert.

---

## 7. Cloudflare (recommended)

1. Add zone **czedr.com** to Cloudflare.
2. Proxy **api** (orange cloud).
3. SSL mode: **Full (strict)** once Caddy has a valid cert.
4. Enable **Bot Fight Mode** and rate limits on `/v1/auth/*` (see `docs/EDGE-WAF-DDOS.md`).

---

## 8. Verify

```bash
curl -sS https://api.czedr.com/v1/health
# Expect: "Status":"true"

curl -sS http://api.czedr.com/v1/health
# Expect: 403 HTTPS required (production)
```

---

## 9. iOS / Android

1. GitHub Actions variable: `CZEDR_API_BASE=https://api.czedr.com`
2. Ship a new TestFlight / Android build.
3. Confirm app uses secure auth endpoints in production.

---

## 10. Smoke checklist

- [ ] `.env` has `APP_ENV=production`, no `CZEDR_ALLOW_HTTP`, no `CZEDR_ALLOW_LEDGER_LOAD`
- [ ] `CZEDR_CRYPTO_PEPPER` set
- [ ] MySQL not exposed on `0.0.0.0:3306`
- [ ] `ufw` only 22/80/443
- [ ] Backups: OneVPS snapshots or `mysqldump` cron
- [ ] `docs/PRODUCTION-SECURITY-CHECKLIST.md` P0 items

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| SSH timeout from PC | Use port **22122**: `ssh -p 22122 root@91.220.203.91` (not port 22) |
| Caddy no certificate | DNS not propagated; check `dig api.czedr.com` |
| 502 from Caddy | `systemctl status czedr-api` — PHP listener down |
| DB connection error | `config/database.local.php` + `VAULT_*` in `.env` |
