# Deploy Czedr API with HTTPS (Phase 1)

Use this when moving from home Wi‑Fi HTTP testing to a public or staging API.

## Recommended stack

| Piece | Choice |
|-------|--------|
| TLS termination | **Caddy** (auto Let’s Encrypt) or cloud load balancer |
| App | PHP-FPM or `php -S` behind reverse proxy |
| DNS | `api.yourdomain.com` → your server |
| App env | `APP_ENV=production` |
| TestFlight | GitHub variable `CZEDR_API_BASE=https://api.yourdomain.com` |

## Caddy example

```caddyfile
api.yourdomain.com {
    reverse_proxy 127.0.0.1:8080
}
```

Caddy sets `X-Forwarded-Proto: https`. The API accepts that when `APP_ENV` is not `local`.

## Environment

```env
APP_ENV=production
APP_DEBUG=false
CZEDR_RATE_LIMIT=1
# Do not set CZEDR_ALLOW_HTTP in production unless you know you need it.
```

## Verify

```bash
curl -sS https://api.yourdomain.com/v1/health
```

Response should include `"Status":"true"`. Plain `http://` to the same host should return **403** with `"HTTPS is required"`.

## iPhone / TestFlight

1. Set `CZEDR_API_BASE` to `https://api.yourdomain.com` in GitHub Actions variables.
2. Run **iOS TestFlight** workflow for a new build.
3. Install build; sign-in uses TLS end-to-end.

Local home testing can keep `APP_ENV=local` and `http://192.168.x.x:8080` — HTTPS enforcement is skipped automatically.
