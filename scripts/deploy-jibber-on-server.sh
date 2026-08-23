#!/bin/bash
# Deploy Jibber Talk on OneVPS — run as root after Czedr code is available.
# Usage: bash scripts/deploy-jibber-on-server.sh
# Expects repo checkout at /var/www/czedr (or set CZEDR_DEPLOY_ROOT).
set -euo pipefail

CZEDR_ROOT="${CZEDR_DEPLOY_ROOT:-/var/www/czedr}"
JIBBER_ROOT="${JIBBER_DEPLOY_ROOT:-/var/www/jibber-talk}"
DOMAIN="${JIBBER_DOMAIN:-jibber.czedr.com}"
PORT="${JIBBER_PORT:-8791}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/deploy-jibber-on-server.sh"
  exit 1
fi

if [[ ! -d "$CZEDR_ROOT/jibber-talk" ]]; then
  echo "Missing $CZEDR_ROOT/jibber-talk — upload/deploy the Czedr repo first."
  exit 1
fi

echo "==> Syncing Jibber Talk to $JIBBER_ROOT"
mkdir -p "$JIBBER_ROOT"
rsync -a --delete \
  --exclude 'data/' \
  --exclude '.env' \
  --exclude '__pycache__/' \
  --exclude '.venv/' \
  "$CZEDR_ROOT/jibber-talk/" "$JIBBER_ROOT/"

cd "$JIBBER_ROOT"
python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r requirements.txt

if [[ ! -f .env ]]; then
  umask 077
  KEY="$(openssl rand -hex 24)"
  cat >.env <<EOF
JIBBER_API_KEY=${KEY}
JIBBER_HOST=127.0.0.1
JIBBER_PORT=${PORT}
EOF
  chmod 600 .env
  echo "==> Wrote .env (API key saved). Back up /var/www/jibber-talk/.env"
fi

mkdir -p data
chown -R www-data:www-data "$JIBBER_ROOT" 2>/dev/null || true

cat >/etc/systemd/system/jibber-talk.service <<EOF
[Unit]
Description=Jibber Talk progress board
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=${JIBBER_ROOT}
EnvironmentFile=${JIBBER_ROOT}/.env
ExecStart=${JIBBER_ROOT}/.venv/bin/uvicorn jibber.main:app --host 127.0.0.1 --port ${PORT}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now jibber-talk.service

if command -v caddy >/dev/null 2>&1; then
  CADDY_SNIPPET="/etc/caddy/Caddyfile.jibber"
  cat >"$CADDY_SNIPPET" <<EOF
${DOMAIN} {
        encode gzip
        reverse_proxy 127.0.0.1:${PORT}
}
EOF
  if ! grep -q "Caddyfile.jibber" /etc/caddy/Caddyfile 2>/dev/null; then
    echo "import Caddyfile.jibber" >> /etc/caddy/Caddyfile
  fi
  caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
  echo "==> Caddy: https://${DOMAIN}  (DNS A record must point to this VPS)"
else
  echo "==> Caddy not installed; service listens on 127.0.0.1:${PORT}"
fi

echo "==> Health:"
curl -fsS "http://127.0.0.1:${PORT}/v1/health" || true
echo
echo "Done. Open https://${DOMAIN}/ when DNS is ready."
