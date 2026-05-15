<?php
declare(strict_types=1);

namespace Czedr\Ledger;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Support\Uuid;
use PDO;

/**
 * Internal ledger only — no external bank settlement.
 */
final class LedgerService
{
    public function __construct(private readonly AuditService $audit)
    {
    }

    public function ensureAccount(string $userId): void
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT IGNORE INTO ledger_accounts (id, user_id) VALUES (:id, :uid)'
        );
        $stmt->execute(['id' => Uuid::v4(), 'uid' => $userId]);
    }

    public function getBalanceCents(string $userId): int
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT balance_cents FROM ledger_accounts WHERE user_id = :uid LIMIT 1');
        $stmt->execute(['uid' => $userId]);
        $v = $stmt->fetchColumn();
        return $v !== false ? (int) $v : 0;
    }

    /**
     * @return array<string, mixed>
     */
    public function credit(string $userId, int $amountCents, string $idempotencyKey, string $memo, ?string $ip, ?string $userAgent): array
    {
        if ($amountCents <= 0) {
            throw new \InvalidArgumentException('Amount must be positive');
        }
        return $this->applySystemTransfer(null, $userId, $amountCents, $idempotencyKey, $memo, 'ledger.credit', $ip, $userAgent);
    }

    /**
     * @return array<string, mixed>
     */
    public function transfer(
        string $fromUserId,
        string $toCzedrId,
        int $amountCents,
        string $idempotencyKey,
        string $memo,
        ?string $ip,
        ?string $userAgent,
    ): array {
        if ($amountCents <= 0) {
            throw new \InvalidArgumentException('Amount must be positive');
        }
        $toUser = $this->userIdByCzedrId($toCzedrId);
        if ($toUser === $fromUserId) {
            throw new \InvalidArgumentException('Cannot transfer to yourself');
        }
        return $this->applySystemTransfer($fromUserId, $toUser, $amountCents, $idempotencyKey, $memo, 'ledger.transfer', $ip, $userAgent);
    }

    /** @return list<array<string, mixed>> */
    public function history(string $userId, int $limit = 50): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT t.id, t.amount_cents, t.currency, t.status, t.memo, t.created_at,
                    uf.czedr_id AS from_czedr_id, ut.czedr_id AS to_czedr_id
             FROM ledger_transactions t
             JOIN users uf ON uf.id = t.from_user_id
             JOIN users ut ON ut.id = t.to_user_id
             WHERE t.from_user_id = :uid OR t.to_user_id = :uid2
             ORDER BY t.created_at DESC LIMIT :lim'
        );
        $stmt->bindValue('uid', $userId);
        $stmt->bindValue('uid2', $userId);
        $stmt->bindValue('lim', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * @return array<string, mixed>
     */
    private function applySystemTransfer(
        ?string $fromUserId,
        string $toUserId,
        int $amountCents,
        string $idempotencyKey,
        string $memo,
        string $auditAction,
        ?string $ip,
        ?string $userAgent,
    ): array {
        $pdo = ConnectionFactory::saturn();
        $existing = $pdo->prepare('SELECT * FROM ledger_transactions WHERE idempotency_key = :key LIMIT 1');
        $existing->execute(['key' => $idempotencyKey]);
        $dup = $existing->fetch(PDO::FETCH_ASSOC);
        if ($dup) {
            return $dup;
        }

        $pdo->beginTransaction();
        try {
            if ($fromUserId === null) {
                // System credit — mint to receiver only (demo / load balance)
                $fromUserId = $this->systemUserId($pdo);
            }

            $this->lockAccounts($pdo, $fromUserId, $toUserId);

            $fromBal = $this->lockedBalance($pdo, $fromUserId);
            if ($fromUserId !== $this->systemUserId($pdo) && $fromBal < $amountCents) {
                throw new \InvalidArgumentException('Insufficient balance');
            }

            $txnId = Uuid::v4();
            $ins = $pdo->prepare(
                'INSERT INTO ledger_transactions (id, idempotency_key, from_user_id, to_user_id, amount_cents, status, memo, completed_at)
                 VALUES (:id, :key, :from, :to, :amt, \'completed\', :memo, NOW())'
            );
            $ins->execute([
                'id' => $txnId,
                'key' => $idempotencyKey,
                'from' => $fromUserId,
                'to' => $toUserId,
                'amt' => $amountCents,
                'memo' => substr($memo, 0, 255),
            ]);

            $fromAcct = $this->accountId($pdo, $fromUserId);
            $toAcct = $this->accountId($pdo, $toUserId);

            if ($fromUserId !== $this->systemUserId($pdo)) {
                $pdo->prepare('UPDATE ledger_accounts SET balance_cents = balance_cents - :amt WHERE id = :id')
                    ->execute(['amt' => $amountCents, 'id' => $fromAcct]);
                $this->entry($pdo, $txnId, $fromAcct, 'debit', $amountCents);
            }

            $pdo->prepare('UPDATE ledger_accounts SET balance_cents = balance_cents + :amt WHERE id = :id')
                ->execute(['amt' => $amountCents, 'id' => $toAcct]);
            $this->entry($pdo, $txnId, $toAcct, 'credit', $amountCents);

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $this->audit->log($fromUserId, $auditAction, 'ledger_transaction', $txnId, $ip, $userAgent, [
            'amount_cents' => $amountCents,
            'to_user_id' => $toUserId,
        ]);

        $fetch = $pdo->prepare('SELECT * FROM ledger_transactions WHERE id = :id');
        $fetch->execute(['id' => $txnId]);
        return $fetch->fetch(PDO::FETCH_ASSOC);
    }

    private function systemUserId(PDO $pdo): string
    {
        static $id = null;
        if ($id !== null) {
            return $id;
        }
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = \'SYSTEM\' LIMIT 1');
        $stmt->execute();
        $row = $stmt->fetchColumn();
        if ($row) {
            $id = (string) $row;
            return $id;
        }
        $id = Uuid::v4();
        $pdo->prepare(
            'INSERT INTO users (id, czedr_id, email, password_hash, status)
             VALUES (:id, \'SYSTEM\', \'system@czedr.local\', :hash, \'active\')'
        )->execute(['id' => $id, 'hash' => password_hash(bin2hex(random_bytes(16)), PASSWORD_ARGON2ID)]);
        $this->ensureAccount($id);
        return $id;
    }

    private function userIdByCzedrId(string $czedrId): string
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = :cid AND status = \'active\' LIMIT 1');
        $stmt->execute(['cid' => strtoupper(trim($czedrId))]);
        $id = $stmt->fetchColumn();
        if (!$id) {
            throw new \InvalidArgumentException('Recipient Czedr ID not found');
        }
        return (string) $id;
    }

    private function lockAccounts(PDO $pdo, string $a, string $b): void
    {
        $ids = [$a, $b];
        sort($ids);
        foreach ($ids as $uid) {
            $pdo->prepare('SELECT id FROM ledger_accounts WHERE user_id = :uid FOR UPDATE')
                ->execute(['uid' => $uid]);
        }
    }

    private function lockedBalance(PDO $pdo, string $userId): int
    {
        $stmt = $pdo->prepare('SELECT balance_cents FROM ledger_accounts WHERE user_id = :uid');
        $stmt->execute(['uid' => $userId]);
        return (int) $stmt->fetchColumn();
    }

    private function accountId(PDO $pdo, string $userId): string
    {
        $stmt = $pdo->prepare('SELECT id FROM ledger_accounts WHERE user_id = :uid');
        $stmt->execute(['uid' => $userId]);
        $id = $stmt->fetchColumn();
        if (!$id) {
            throw new \RuntimeException('Ledger account missing');
        }
        return (string) $id;
    }

    private function entry(PDO $pdo, string $txnId, string $accountId, string $type, int $amount): void
    {
        $pdo->prepare(
            'INSERT INTO ledger_entries (id, transaction_id, account_id, entry_type, amount_cents)
             VALUES (:id, :txn, :acct, :type, :amt)'
        )->execute([
            'id' => Uuid::v4(),
            'txn' => $txnId,
            'acct' => $accountId,
            'type' => $type,
            'amt' => $amount,
        ]);
    }
}
