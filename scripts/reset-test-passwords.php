<?php
declare(strict_types=1);

/**
 * Reset Alice/Bob to documented test password (fixes forgot-password test drift).
 * Run: php scripts/reset-test-passwords.php
 */

require_once dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Database\ConnectionFactory;

$password = 'TestPass1234!';
$emails = ['alice@test.czedr', 'bob@test.czedr'];
$hash = password_hash($password, PASSWORD_ARGON2ID);

$pdo = ConnectionFactory::saturn();
$stmt = $pdo->prepare(
    'UPDATE users SET password_hash = :hash WHERE email = :email AND status = \'active\''
);

foreach ($emails as $email) {
    $stmt->execute(['hash' => $hash, 'email' => $email]);
    $n = $stmt->rowCount();
    echo $n > 0 ? "[OK] Reset password for {$email}\n" : "[SKIP] No active user: {$email}\n";
}

echo "\nVerify login via API...\n";
$base = getenv('CZEDR_API_BASE') ?: 'http://127.0.0.1:8080';
foreach ($emails as $email) {
    $ch = curl_init($base . '/v1/auth/login');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
        CURLOPT_POSTFIELDS => json_encode(['user_email' => $email, 'user_pwd' => $password], JSON_THROW_ON_ERROR),
    ]);
    $raw = (string) curl_exec($ch);
    curl_close($ch);
    $json = json_decode($raw, true);
    if (($json['Status'] ?? '') === 'true') {
        $id = $json['Data']['czedr_id'] ?? $json['Data']['user']['czedr_id'] ?? '?';
        echo "[OK] Login {$email} → {$id}\n";
    } else {
        echo "[FAIL] Login {$email}: {$raw}\n";
        exit(1);
    }
}

echo "Done. Password for both: {$password}\n";
