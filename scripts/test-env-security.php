<?php
declare(strict_types=1);

/**
 * Unit checks: APP_ENV defaults must be production-safe (no implicit "local").
 * Run: php scripts/test-env-security.php
 */

require_once dirname(__DIR__) . '/backend/src/Autoload.php';
\Czedr\Autoload::register(dirname(__DIR__) . '/backend/src');

putenv('APP_ENV');
putenv('CZEDR_ALLOW_LEDGER_LOAD');
unset($_ENV['APP_ENV'], $_ENV['CZEDR_ALLOW_LEDGER_LOAD']);

if (\Czedr\Support\Env::isLocal()) {
    fwrite(STDERR, "FAIL: isLocal should be false when APP_ENV is unset\n");
    exit(1);
}
if (\Czedr\Support\Env::allowSelfServiceLedgerLoad()) {
    fwrite(STDERR, "FAIL: allowSelfServiceLedgerLoad should be false when APP_ENV unset and flag unset\n");
    exit(1);
}

$_ENV['APP_ENV'] = 'local';
putenv('APP_ENV=local');
if (!\Czedr\Support\Env::isLocal()) {
    fwrite(STDERR, "FAIL: isLocal should be true for APP_ENV=local\n");
    exit(1);
}
if (!\Czedr\Support\Env::allowSelfServiceLedgerLoad()) {
    fwrite(STDERR, "FAIL: allowSelfServiceLedgerLoad should be true for APP_ENV=local\n");
    exit(1);
}

$_ENV['APP_ENV'] = 'production';
putenv('APP_ENV=production');
$_ENV['CZEDR_ALLOW_LEDGER_LOAD'] = '1';
putenv('CZEDR_ALLOW_LEDGER_LOAD=1');
if (\Czedr\Support\Env::isLocal()) {
    fwrite(STDERR, "FAIL: isLocal should be false for production\n");
    exit(1);
}
if (!\Czedr\Support\Env::allowSelfServiceLedgerLoad()) {
    fwrite(STDERR, "FAIL: allowSelfServiceLedgerLoad should honor CZEDR_ALLOW_LEDGER_LOAD=1\n");
    exit(1);
}

echo "Env security checks OK.\n";
