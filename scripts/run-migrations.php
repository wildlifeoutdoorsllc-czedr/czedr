<?php
declare(strict_types=1);

/**
 * Apply pending database migrations (tracks schema_migrations in saturn).
 *
 * Usage: php scripts/run-migrations.php
 * Requires: config/database.local.php, working MySQL, .env optional
 */

require_once dirname(__DIR__) . '/backend/bootstrap.php';

$n = \Czedr\Database\MigrationRunner::runPending();

if (PHP_SAPI === 'cli') {
    echo $n === 0 ? "Migrations: already up to date.\n" : "Migrations: applied {$n} file(s).\n";
}
