<?php
declare(strict_types=1);

namespace Czedr\Moov;

use Czedr\Database\ConnectionFactory;
use Czedr\Ledger\LedgerService;
use Czedr\Support\Uuid;
use PDO;

final class MoovAchService
{
    public function __construct(
        private readonly MoovHttpClient $moov,
        private readonly LedgerService $ledger,
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function statusForUser(string $userId): array
    {
        $enabled = MoovConfig::isEnabled();
        $ready = false;
        if ($enabled) {
            try {
                MoovConfig::assertConfigured();
                $ready = true;
            } catch (\RuntimeException) {
                $ready = false;
            }
        }

        return [
            'enabled' => $enabled,
            'moov_ready' => $ready,
            'min_deposit_cents' => MoovConfig::minDepositCents(),
            'max_deposit_cents' => MoovConfig::maxDepositCents(),
            'banks' => $enabled ? $this->listBanks($userId) : [],
            'pending_deposits' => $enabled ? $this->listPendingDeposits($userId) : [],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function ensureMoovAccount(string $userId, string $email, string $displayName): array
    {
        MoovConfig::assertConfigured();
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT moov_account_id, status FROM moov_accounts WHERE user_id = :uid LIMIT 1');
        $stmt->execute(['uid' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row) {
            return [
                'moov_account_id' => (string) $row['moov_account_id'],
                'status' => (string) $row['status'],
            ];
        }

        // TODO: MoovHttpClient::post('/accounts', ...) with profile + metadata czedr_user_id
        throw new \RuntimeException(
            'Moov account creation not implemented yet. Configure sandbox keys and complete MoovHttpClient.'
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function startBankLink(string $userId, string $email, string $displayName): array
    {
        throw new \RuntimeException(
            'Hosted bank login is disabled. Use POST /v1/funding/bank-link/start with routing and account '
            . 'numbers, then confirm two micro-deposits. See docs/BANK-LINK-MICRODEPOSITS.md.'
        );
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function listBanks(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, moov_bank_account_id, bank_name, last_four, is_default, status
             FROM moov_bank_links WHERE user_id = :uid AND status IN (\'verified\', \'active\', \'pending\')
             ORDER BY is_default DESC, created_at ASC'
        );
        $stmt->execute(['uid' => $userId]);
        $out = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $out[] = [
                'id' => (string) $row['id'],
                'moov_bank_account_id' => (string) $row['moov_bank_account_id'],
                'bank_name' => (string) ($row['bank_name'] ?? ''),
                'last4' => (string) ($row['last_four'] ?? ''),
                'is_default' => ((int) ($row['is_default'] ?? 0)) === 1,
                'status' => (string) $row['status'],
            ];
        }

        return $out;
    }

    /**
     * @return array<string, mixed>
     */
    public function initiateDeposit(
        string $userId,
        int $amountCents,
        string $idempotencyKey,
        ?string $bankLinkId,
        ?string $ip,
        ?string $userAgent,
    ): array {
        MoovConfig::assertConfigured();
        if ($amountCents < MoovConfig::minDepositCents() || $amountCents > MoovConfig::maxDepositCents()) {
            throw new \InvalidArgumentException('Amount out of allowed range');
        }
        if ($idempotencyKey === '') {
            throw new \InvalidArgumentException('idempotency_key is required');
        }

        $pdo = ConnectionFactory::saturn();
        $existing = $pdo->prepare('SELECT id, status, moov_transfer_id FROM ach_deposits WHERE idempotency_key = :k LIMIT 1');
        $existing->execute(['k' => $idempotencyKey]);
        $dup = $existing->fetch(PDO::FETCH_ASSOC);
        if ($dup) {
            return [
                'deposit_id' => (string) $dup['id'],
                'status' => (string) $dup['status'],
                'moov_transfer_id' => $dup['moov_transfer_id'],
                'idempotent' => true,
            ];
        }

        $bank = $this->resolveBankLink($pdo, $userId, $bankLinkId);
        $moovAccount = $pdo->prepare('SELECT moov_account_id FROM moov_accounts WHERE user_id = :uid LIMIT 1');
        $moovAccount->execute(['uid' => $userId]);
        $moovAcctId = $moovAccount->fetchColumn();
        if (!$moovAcctId) {
            throw new \InvalidArgumentException('Link a bank account before depositing');
        }

        $depositId = Uuid::v4();
        $transfer = $this->moov->createAchDebit(
            (string) $moovAcctId,
            (string) $bank['moov_bank_account_id'],
            $amountCents,
            'Czedr balance load'
        );
        $transferId = (string) ($transfer['transferID'] ?? $transfer['id'] ?? '');

        $ins = $pdo->prepare(
            'INSERT INTO ach_deposits (id, user_id, moov_bank_link_id, amount_cents, moov_transfer_id, status, idempotency_key)
             VALUES (:id, :uid, :bank, :amt, :tid, \'pending\', :idem)'
        );
        $ins->execute([
            'id' => $depositId,
            'uid' => $userId,
            'bank' => $bank['id'],
            'amt' => $amountCents,
            'tid' => $transferId !== '' ? $transferId : null,
            'idem' => $idempotencyKey,
        ]);

        return [
            'deposit_id' => $depositId,
            'status' => 'pending',
            'moov_transfer_id' => $transferId,
            'amount_cents' => $amountCents,
        ];
    }

    /**
     * Handle Moov transfer.updated webhook (signature should be verified by caller).
     *
     * @param array<string, mixed> $payload
     */
    public function handleTransferWebhook(array $payload): void
    {
        $transferId = (string) ($payload['transferID'] ?? $payload['data']['transferID'] ?? $payload['data']['transferId'] ?? '');
        $status = strtolower((string) ($payload['status'] ?? $payload['data']['status'] ?? ''));
        if ($transferId === '') {
            return;
        }

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, user_id, amount_cents, status FROM ach_deposits WHERE moov_transfer_id = :tid LIMIT 1'
        );
        $stmt->execute(['tid' => $transferId]);
        $deposit = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$deposit) {
            return;
        }
        if ((string) $deposit['status'] === 'completed') {
            return;
        }

        if (in_array($status, ['completed', 'complete', 'succeeded'], true)) {
            $this->completeDeposit(
                (string) $deposit['id'],
                (string) $deposit['user_id'],
                (int) $deposit['amount_cents'],
                $transferId
            );
            return;
        }

        if (in_array($status, ['failed', 'canceled', 'cancelled', 'reversed'], true)) {
            $pdo->prepare(
                'UPDATE ach_deposits SET status = :st, failure_reason = :reason WHERE id = :id'
            )->execute([
                'st' => $status === 'reversed' ? 'reversed' : 'failed',
                'reason' => (string) ($payload['failureReason'] ?? $payload['data']['failureReason'] ?? ''),
                'id' => $deposit['id'],
            ]);
        }
    }

    /** Local / test helper: mark deposit completed and credit ledger. */
    public function simulateDepositCompleted(string $depositId): array
    {
        if (!MoovConfig::isEnabled() && !\Czedr\Support\Env::isLocal()) {
            throw new \RuntimeException('Simulation only allowed in local dev');
        }
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT id, user_id, amount_cents, moov_transfer_id, status FROM ach_deposits WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $depositId]);
        $deposit = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$deposit) {
            throw new \InvalidArgumentException('Deposit not found');
        }

        return $this->completeDeposit(
            (string) $deposit['id'],
            (string) $deposit['user_id'],
            (int) $deposit['amount_cents'],
            (string) ($deposit['moov_transfer_id'] ?? 'sim-' . $depositId)
        );
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function listPendingDeposits(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, amount_cents, status, created_at FROM ach_deposits
             WHERE user_id = :uid AND status = \'pending\' ORDER BY created_at DESC LIMIT 10'
        );
        $stmt->execute(['uid' => $userId]);
        $rows = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $rows[] = [
                'deposit_id' => (string) $row['id'],
                'amount_cents' => (int) $row['amount_cents'],
                'status' => (string) $row['status'],
                'created_at' => (string) $row['created_at'],
            ];
        }

        return $rows;
    }

    /**
     * @return array<string, mixed>
     */
    private function resolveBankLink(PDO $pdo, string $userId, ?string $bankLinkId): array
    {
        if ($bankLinkId !== null && $bankLinkId !== '') {
            $stmt = $pdo->prepare(
                'SELECT id, moov_bank_account_id FROM moov_bank_links
                 WHERE id = :id AND user_id = :uid AND status IN (\'verified\', \'active\') LIMIT 1'
            );
            $stmt->execute(['id' => $bankLinkId, 'uid' => $userId]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($row) {
                return $row;
            }
            throw new \InvalidArgumentException('Bank account not found');
        }

        $stmt = $pdo->prepare(
            'SELECT id, moov_bank_account_id FROM moov_bank_links
             WHERE user_id = :uid AND status IN (\'verified\', \'active\')
             ORDER BY is_default DESC, created_at ASC LIMIT 1'
        );
        $stmt->execute(['uid' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \InvalidArgumentException('Link a bank account before depositing');
        }

        return $row;
    }

    /**
     * @return array<string, mixed>
     */
    private function completeDeposit(string $depositId, string $userId, int $amountCents, string $transferId): array
    {
        $pdo = ConnectionFactory::saturn();
        $pdo->beginTransaction();
        try {
            $check = $pdo->prepare('SELECT status FROM ach_deposits WHERE id = :id FOR UPDATE');
            $check->execute(['id' => $depositId]);
            $st = $check->fetchColumn();
            if ($st === 'completed') {
                $pdo->commit();

                return ['deposit_id' => $depositId, 'status' => 'completed', 'already_completed' => true];
            }

            $txn = $this->ledger->credit(
                $userId,
                $amountCents,
                'moov-ach:' . $transferId,
                'ACH deposit',
                null,
                null
            );

            $txnId = (string) ($txn['id'] ?? $txn['transaction_id'] ?? '');
            $pdo->prepare(
                'UPDATE ach_deposits SET status = \'completed\', ledger_txn_id = :txn, completed_at = NOW() WHERE id = :id'
            )->execute(['txn' => $txnId !== '' ? $txnId : null, 'id' => $depositId]);
            $pdo->commit();

            return [
                'deposit_id' => $depositId,
                'status' => 'completed',
                'ledger_txn_id' => $txnId,
                'balance_cents' => $this->ledger->getBalanceCents($userId),
            ];
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }
}
