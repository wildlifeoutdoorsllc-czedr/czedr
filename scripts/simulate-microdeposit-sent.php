<?php
declare(strict_types=1);

/**
 * Dev helper: mark a bank link awaiting_confirm after micro-deposits were sent.
 * Usage: php scripts/simulate-microdeposit-sent.php --bank-link-id=<uuid>
 */

$root = dirname(__DIR__);
require $root . '/backend/bootstrap.php';

use Czedr\Database\ConnectionFactory;
use Czedr\Funding\MicroDepositBankLinkService;
use Czedr\Support\Env;

Env::load($root . '/.env');

$bankLinkId = '';
foreach ($argv as $arg) {
    if (str_starts_with($arg, '--bank-link-id=')) {
        $bankLinkId = substr($arg, strlen('--bank-link-id='));
    }
}
if ($bankLinkId === '') {
    fwrite(STDERR, "Usage: php scripts/simulate-microdeposit-sent.php --bank-link-id=<uuid>\n");
    exit(1);
}

if (!Env::isLocal()) {
    fwrite(STDERR, "Only for APP_ENV=local\n");
    exit(1);
}

$svc = new MicroDepositBankLinkService();
$svc->markMicroDepositsSent($bankLinkId);

$pdo = ConnectionFactory::saturn();
$st = $pdo->prepare('SELECT status, micro_cents_a, micro_cents_b FROM moov_bank_links WHERE id = :id');
$st->execute(['id' => $bankLinkId]);
$row = $st->fetch(PDO::FETCH_ASSOC);
if (!$row) {
    fwrite(STDERR, "Bank link not found\n");
    exit(1);
}

echo "status={$row['status']} micro_cents_a={$row['micro_cents_a']} micro_cents_b={$row['micro_cents_b']}\n";
echo "Confirm via POST /v1/funding/bank-link/confirm with those cent amounts.\n";
