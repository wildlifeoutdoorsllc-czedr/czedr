<?php
declare(strict_types=1);

/** One-off ops: check user + verify password hash. Usage on VPS:
 *  php scripts/vps-check-user-login.php email@example.com [password-to-test]
 */

require_once dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Database\ConnectionFactory;

$email = strtolower(trim($argv[1] ?? ''));
$testPass = $argv[2] ?? '';

if ($email === '') {
    fwrite(STDERR, "Usage: php scripts/vps-check-user-login.php <email> [password-to-test]\n");
    exit(1);
}

$pdo = ConnectionFactory::saturn();
$stmt = $pdo->prepare('SELECT id, czedr_id, email, password_hash, status, updated_at FROM users WHERE email = :email LIMIT 1');
$stmt->execute(['email' => $email]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$row) {
    echo "NO_USER\n";
    exit(0);
}

echo 'email=' . $row['email'] . "\n";
echo 'czedr_id=' . $row['czedr_id'] . "\n";
echo 'status=' . $row['status'] . "\n";
echo 'hash_prefix=' . substr((string) $row['password_hash'], 0, 30) . "\n";
echo 'updated_at=' . ($row['updated_at'] ?? '') . "\n";

$stmt = $pdo->prepare(
    'SELECT COUNT(*) FROM password_reset_tokens WHERE user_id = :uid AND used_at IS NOT NULL'
);
$stmt->execute(['uid' => $row['id']]);
echo 'used_reset_tokens=' . $stmt->fetchColumn() . "\n";

if ($testPass !== '') {
    $ok = password_verify($testPass, (string) $row['password_hash']);
    echo 'password_verify=' . ($ok ? 'true' : 'false') . "\n";
}
