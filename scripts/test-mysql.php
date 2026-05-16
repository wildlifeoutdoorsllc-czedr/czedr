<?php
/**
 * PHP + MySQL 8.x compatibility check for Czedr.
 * Run: php scripts/test-mysql.php
 */

declare(strict_types=1);

$failed = 0;
$passed = 0;

function ok(string $msg): void
{
    global $passed;
    $passed++;
    echo "[OK] {$msg}\n";
}

function fail(string $msg): void
{
    global $failed;
    $failed++;
    echo "[FAIL] {$msg}\n";
}

echo "=== PHP MySQL compatibility test ===\n";
echo 'PHP: ' . PHP_VERSION . "\n";

foreach (['mysqli', 'pdo_mysql', 'mysqlnd', 'openssl'] as $ext) {
    extension_loaded($ext) ? ok("extension loaded: {$ext}") : fail("missing extension: {$ext}");
}

$pdo = null;
try {
    $pdo = new PDO('mysql:host=127.0.0.1;port=3306', 'root', '');
} catch (Throwable $e) {
    $pdo = null;
}
if ($pdo) {
    $version = (string) $pdo->query('SELECT VERSION()')->fetchColumn();
    if (preg_match('/^(8\.|9\.)/', $version)) {
        ok("MySQL 8.x+ server detected ({$version}) — compatible with PHP mysqlnd");
    } else {
        ok("MySQL server version: {$version}");
    }
}

try {
    $pdo = new PDO(
        'mysql:host=127.0.0.1;port=3306;charset=utf8mb4',
        'root',
        '',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci',
        ]
    );
    $version = $pdo->query('SELECT VERSION()')->fetchColumn();
    ok("PDO connect, server version: {$version}");
} catch (Throwable $e) {
    fail('PDO connect: ' . $e->getMessage());
    $pdo = null;
}

try {
    $mysqli = new mysqli('127.0.0.1', 'root', '', '', 3306);
    if ($mysqli->connect_errno) {
        fail('mysqli connect: ' . $mysqli->connect_error);
    } else {
        $mysqli->set_charset('utf8mb4');
        ok('mysqli connect + utf8mb4 charset');
        $mysqli->close();
    }
} catch (Throwable $e) {
    fail('mysqli: ' . $e->getMessage());
}

if ($pdo) {
    $existing = $pdo->query('SHOW DATABASES')->fetchAll(PDO::FETCH_COLUMN);
    in_array('saturn', $existing, true)
        ? ok('database exists: saturn')
        : fail('database missing: saturn (run scripts/local-mysql-init.sql)');
}

if ($pdo) {
    try {
        $pdo->exec('USE saturn');
        $pdo->exec('DROP TABLE IF EXISTS _php_compat_test');
        $pdo->exec(
            'CREATE TABLE _php_compat_test (
                id INT AUTO_INCREMENT PRIMARY KEY,
                label VARCHAR(64) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
        );
        $stmt = $pdo->prepare('INSERT INTO _php_compat_test (label) VALUES (?)');
        $stmt->execute(['Czedr test — éàü']);
        $id = (int) $pdo->lastInsertId();
        $row = $pdo->query("SELECT label FROM _php_compat_test WHERE id = {$id}")->fetch(PDO::FETCH_ASSOC);
        if ($row && $row['label'] === 'Czedr test — éàü') {
            ok('PDO prepared statement + utf8mb4 insert/select on saturn');
        } else {
            fail('utf8mb4 data mismatch after insert');
        }
        $pdo->exec('DROP TABLE _php_compat_test');
    } catch (Throwable $e) {
        fail('saturn CRUD test: ' . $e->getMessage());
    }
}

$configPath = dirname(__DIR__) . '/config/database.local.php';
if (is_file($configPath)) {
    require_once dirname(__DIR__) . '/config/Database.php';
    try {
        $db = Database::pdo('app');
        $db->query('SELECT 1');
        ok('Database::pdo("app") → saturn');
        $mysqliApp = Database::mysqli('app');
        $mysqliApp->query('SELECT 1');
        $mysqliApp->close();
        ok('Database::mysqli("app") → saturn');
    } catch (Throwable $e) {
        fail('Database helper: ' . $e->getMessage());
    }
}

echo "\n=== Summary: {$passed} passed, {$failed} failed ===\n";
exit($failed > 0 ? 1 : 0);
