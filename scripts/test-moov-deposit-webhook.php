<?php
declare(strict_types=1);

/**
 * Local helper: mark an ach_deposits row completed and credit the ledger.
 *
 * Usage: php scripts/test-moov-deposit-webhook.php --deposit-id=<uuid>
 */

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Ledger\AuditService;
use Czedr\Ledger\LedgerService;
use Czedr\Moov\MoovAchService;
use Czedr\Moov\MoovHttpClient;

$depositId = '';
foreach ($argv as $arg) {
    if (str_starts_with($arg, '--deposit-id=')) {
        $depositId = substr($arg, strlen('--deposit-id='));
    }
}
if ($depositId === '') {
    fwrite(STDERR, "Usage: php scripts/test-moov-deposit-webhook.php --deposit-id=<uuid>\n");
    exit(1);
}

$service = new MoovAchService(new MoovHttpClient(), new LedgerService(new AuditService()));
$result = $service->simulateDepositCompleted($depositId);
echo json_encode($result, JSON_PRETTY_PRINT) . "\n";
