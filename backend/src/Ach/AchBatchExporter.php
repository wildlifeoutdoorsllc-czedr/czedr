<?php
declare(strict_types=1);

namespace Czedr\Ach;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Support\Env;
use Czedr\Support\Uuid;
use Czedr\Vault\BankAccountVault;

/**
 * Builds ACH export files for manual/offline use — does NOT transmit to any bank.
 */
final class AchBatchExporter
{
    public function __construct(
        private readonly BankAccountVault $vault,
        private readonly AuditService $audit,
    ) {
    }

    /**
     * @param list<array{vault_token: string, amount_cents: int}> $entries
     * @return array<string, mixed>
     */
    public function exportBatch(
        string $actorUserId,
        array $entries,
        string $note,
        ?string $ip,
        ?string $userAgent,
    ): array {
        if ($entries === []) {
            throw new \InvalidArgumentException('No ACH entries provided');
        }

        $batchId = Uuid::v4();
        $total = 0;
        $moovEntries = [];

        foreach ($entries as $i => $entry) {
            $sensitive = $this->vault->readSensitive(
                $actorUserId,
                $entry['vault_token'],
                'ach_export_batch',
                $ip,
                $userAgent
            );
            $amount = (int) $entry['amount_cents'];
            $total += $amount;
            $moovEntries[] = [
                'id' => (string) ($i + 1),
                'amount' => $amount,
                'routingNumber' => $sensitive['routing'],
                'accountNumber' => $sensitive['account'],
                'accountType' => $sensitive['account_type'],
                'name' => $sensitive['holder_name'],
            ];
        }

        $dir = CZEDR_ROOT . '/storage/ach_exports';
        if (!is_dir($dir) && !mkdir($dir, 0700, true) && !is_dir($dir)) {
            throw new \RuntimeException('Cannot create ACH export directory');
        }

        $payload = [
            'batch_id' => $batchId,
            'created_at' => gmdate('c'),
            'disclaimer' => 'EXPORT ONLY — not submitted to any financial institution',
            'entries' => $moovEntries,
        ];

        $jsonPath = $dir . '/' . $batchId . '.json';
        file_put_contents($jsonPath, json_encode($payload, JSON_PRETTY_PRINT | JSON_THROW_ON_ERROR));

        $nachaPath = $this->tryMoovExport($payload) ?? $this->writePlaceholderNacha($batchId, $dir, count($entries), $total);

        $pdo = ConnectionFactory::saturn();
        $pdo->prepare(
            'INSERT INTO ach_export_batches (id, created_by_user_id, status, entry_count, total_amount_cents, file_path, note, exported_at)
             VALUES (:id, :uid, \'exported\', :cnt, :total, :path, :note, NOW())'
        )->execute([
            'id' => $batchId,
            'uid' => $actorUserId,
            'cnt' => count($entries),
            'total' => $total,
            'path' => $nachaPath,
            'note' => substr($note, 0, 255),
        ]);

        $this->audit->log($actorUserId, 'ach.batch_exported', 'ach_export_batch', $batchId, $ip, $userAgent, [
            'entry_count' => count($entries),
            'total_amount_cents' => $total,
        ]);

        return [
            'batch_id' => $batchId,
            'entry_count' => count($entries),
            'total_amount_cents' => $total,
            'json_file' => basename($jsonPath),
            'nacha_file' => basename($nachaPath),
            'message' => 'Export saved locally only. No funds moved.',
        ];
    }

    private function tryMoovExport(array $payload): ?string
    {
        $url = Env::get('MOOV_ACH_URL');
        if (!$url) {
            return null;
        }
        // Optional Moov ACH HTTP API when running moov/ach via Docker
        $ctx = stream_context_create([
            'http' => [
                'method' => 'POST',
                'header' => "Content-Type: application/json\r\n",
                'content' => json_encode($payload, JSON_THROW_ON_ERROR),
                'timeout' => 10,
                'ignore_errors' => true,
            ],
        ]);
        $response = @file_get_contents(rtrim($url, '/'), false, $ctx);
        if ($response === false) {
            return null;
        }
        $out = CZEDR_ROOT . '/storage/ach_exports/' . $payload['batch_id'] . '.ach';
        file_put_contents($out, $response);
        return $out;
    }

    private function writePlaceholderNacha(string $batchId, string $dir, int $count, int $totalCents): string
    {
        $path = $dir . '/' . $batchId . '.ach.txt';
        $lines = [
            'NACHA PLACEHOLDER — replace with Moov ACH or ODFI file before any real submission',
            'BATCH ' . $batchId,
            'ENTRY COUNT ' . $count,
            'TOTAL CENTS ' . $totalCents,
            'GENERATED ' . gmdate('c'),
        ];
        file_put_contents($path, implode(PHP_EOL, $lines) . PHP_EOL);
        return $path;
    }
}
