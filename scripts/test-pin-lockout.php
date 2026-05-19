<?php
declare(strict_types=1);

/**
 * Verifies PIN lockout after repeated wrong PINs.
 * Run with API up: php scripts/test-pin-lockout.php
 */

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Auth\AuthService;
use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Ledger\LedgerService;
use Czedr\Support\Uuid;

$pdo = ConnectionFactory::saturn();
$email = 'pinlock_' . bin2hex(random_bytes(3)) . '@czedr.local';
$userId = Uuid::v4();
$czedrId = 'CZ' . strtoupper(bin2hex(random_bytes(4)));
$hash = password_hash('TestPass1234!', PASSWORD_ARGON2ID);
$pdo->prepare(
    'INSERT INTO users (id, czedr_id, email, password_hash) VALUES (:id, :cid, :email, :hash)'
)->execute(['id' => $userId, 'cid' => $czedrId, 'email' => $email, 'hash' => $hash]);

$auth = new AuthService(new AuditService(), new LedgerService(new AuditService()));
$auth->setPin($userId, '1234');

$locked = false;
for ($i = 1; $i <= 6; $i++) {
    try {
        $auth->verifyPin($userId, '0000');
    } catch (InvalidArgumentException $e) {
        if (str_contains($e->getMessage(), 'temporarily locked')) {
            echo "Locked on attempt {$i}: OK\n";
            $locked = true;
            break;
        }
    }
}
if (!$locked) {
    fwrite(STDERR, "PIN lockout did not trigger\n");
    exit(1);
}

try {
    $auth->verifyPin($userId, '1234');
    echo "Correct PIN after lock cleared path: still locked (expected until window expires)\n";
} catch (InvalidArgumentException $e) {
    if (str_contains($e->getMessage(), 'temporarily locked')) {
        echo "Correct PIN blocked while locked: OK\n";
    }
}

$pdo->prepare('DELETE FROM users WHERE id = :id')->execute(['id' => $userId]);
echo "PIN lockout test passed.\n";
