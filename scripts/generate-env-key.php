<?php
declare(strict_types=1);

// Ledger-only API: no application code consumes MASTER_KEY_BASE64. This script is retained so
// older docs/commands still succeed; it ensures .env exists from the example.
$envPath = dirname(__DIR__) . '/.env';
$example = dirname(__DIR__) . '/.env.example';

if (!is_file($envPath) && is_file($example)) {
    copy($example, $envPath);
    echo "Created .env from .env.example\n";
}

echo "Czedr ledger-only: no encryption master key is required. Tune APP_ENV and database settings in .env as needed.\n";
