<?php
declare(strict_types=1);

/**
 * Credit a member account from SYSTEM (ops / local testing).
 *
 * Usage:
 *   php scripts/admin-fund-user.php user@example.com 1000
 *   php scripts/admin-fund-user.php user@example.com 1000 --memo "Test credit"
 *
 * On VPS:
 *   php /var/www/czedr/scripts/admin-fund-user.php user@example.com 1000
 */

$root = dirname(__DIR__);
require $root . '/backend/bootstrap.php';

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Ledger\LedgerService;

$email = isset($argv[1]) ? trim((string) $argv[1]) : '';
$amountDollars = isset($argv[2]) ? (float) $argv[2] : 0.0;
$memo = isset($argv[3]) && trim((string) $argv[3]) !== '' ? trim((string) $argv[3]) : 'Admin test fund';

if ($email === '' || $amountDollars <= 0) {
    fwrite(STDERR, "Usage: php scripts/admin-fund-user.php <email> <dollars> [memo]\n");
    exit(1);
}

$cents = (int) round($amountDollars * 100);
if ($cents <= 0) {
    fwrite(STDERR, "Amount must be positive.\n");
    exit(1);
}

$pdo = ConnectionFactory::saturn();
$stmt = $pdo->prepare('SELECT id, czedr_id, email FROM users WHERE email = :email LIMIT 1');
$stmt->execute(['email' => $email]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
    fwrite(STDERR, "No user found for email: {$email}\n");
    exit(1);
}

$userId = (string) $user['id'];
$czedrId = (string) $user['czedr_id'];

$audit = new AuditService();
$ledger = new LedgerService($audit);
$ledger->ensureAccount($userId);

$before = $ledger->getBalanceCents($userId);
$key = 'admin-fund-' . substr(hash('sha256', $email . $cents . date('Y-m-d')), 0, 16);

$txn = $ledger->credit($userId, $cents, $key, $memo, null, 'admin-fund-user.php');
$after = $ledger->getBalanceCents($userId);

echo "Credited {$email} ({$czedrId})\n";
echo '  Before: $' . number_format($before / 100, 2) . "\n";
echo '  Added:  $' . number_format($cents / 100, 2) . "\n";
echo '  After:  $' . number_format($after / 100, 2) . "\n";
echo '  Txn:    ' . ($txn['id'] ?? '?') . "\n";
