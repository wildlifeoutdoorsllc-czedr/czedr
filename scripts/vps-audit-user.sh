#!/bin/bash
# List recent audit_events for a user email (run on VPS as root).
# Usage: bash /var/www/czedr/scripts/vps-audit-user.sh rita@test.czedr
set -euo pipefail

EMAIL="${1:-}"
if [[ -z "$EMAIL" ]]; then
  echo "Usage: $0 user@example.com" >&2
  exit 1
fi

if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
  echo "Invalid email format." >&2
  exit 1
fi

mysql -u root saturn -e "
SELECT ae.action, ae.created_at
FROM audit_events ae
INNER JOIN users u ON u.id = ae.user_id
WHERE u.email = '$(printf '%s' "$EMAIL" | sed "s/'/''/g")'
ORDER BY ae.created_at DESC
LIMIT 50;
"
