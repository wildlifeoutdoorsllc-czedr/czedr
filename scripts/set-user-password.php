<?php
declare(strict_types=1);

/**
 * Ops: set a member password (Argon2id). Revokes active sessions.
 * Usage: php scripts/set-user-password.php user@example.com 'NewPass1234!'
 */

require_once dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Database\ConnectionFactory;

$email = strtolower(trim($argv[1] ?? ''));
$password = (string) ($argv[2] ?? '');

if ($email === '' || $password === '') {
    fwrite(STDERR, "Usage: php scripts/set-user-password.php <email> <password>\n");
    exit(1);
}
if (strlen($password) < 10) {
    fwrite(STDERR, "Password must be at least 10 characters.\n");
    exit(1);
}

$pdo = ConnectionFactory::saturn();
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email AND status = \'active\' LIMIT 1');
$stmt->execute(['email' => $email]);
$userId = $stmt->fetchColumn();
if ($userId === false) {
    fwrite(STDERR, "No active user for {$email}\n");
    exit(1);
}

$userId = (string) $userId;
$hash = password_hash($password, PASSWORD_ARGON2ID);
if (!password_verify($password, $hash)) {
    fwrite(STDERR, "Hash self-check failed.\n");
    exit(1);
}

$pdo->prepare('UPDATE users SET password_hash = :hash WHERE id = :id')->execute(['hash' => $hash, 'id' => $userId]);
$pdo->prepare('UPDATE auth_sessions SET revoked_at = NOW() WHERE user_id = :uid AND revoked_at IS NULL')
    ->execute(['uid' => $userId]);

echo "OK: password updated for {$email}\n";

$base = rtrim(getenv('APP_PUBLIC_URL') ?: 'https://api.czedr.com', '/');
$ch = curl_init($base . '/v1/auth/login');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
    CURLOPT_POSTFIELDS => json_encode(['email' => $email, 'password' => $password], JSON_THROW_ON_ERROR),
]);
$raw = (string) curl_exec($ch);
$code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
echo "Login probe HTTP {$code}: {$raw}\n";
