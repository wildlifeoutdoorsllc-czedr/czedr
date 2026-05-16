<?php
declare(strict_types=1);

namespace Czedr\Ledger;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Support\Env;
use Czedr\Support\Uuid;
use PDO;

/**
 * Internal ledger only — no external bank settlement.
 */
final class LedgerService
{
    private const REFERRAL_REWARD_MEMO = 'Referral reward (referee payment)';

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
     * P2P transfer: recipient receives the full payment amount in cents. The sender is debited
     * that amount plus the platform fee from {@see self::transferFeeCents()} (fee credited to REVENUE).
     *
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
        return $this->applyPeerTransfer(
            $fromUserId,
            $toUser,
            $amountCents,
            $idempotencyKey,
            $memo,
            $ip,
            $userAgent,
        );
    }

    /**
     * Platform fee per P2P transfer (USD cents). Set CZEDR_TRANSFER_FEE_CENTS=0 to disable.
     */
    public static function transferFeeCents(): int
    {
        $raw = Env::get('CZEDR_TRANSFER_FEE_CENTS', '129');
        return max(0, (int) $raw);
    }

    /**
     * Referrer reward (USD cents) minted to the referee's single-level referrer when the referee sends a P2P payment.
     * Set CZEDR_REFERRAL_REWARD_CENTS=0 to disable. Default 17 ($0.17).
     */
    public static function referralRewardCents(): int
    {
        $raw = Env::get('CZEDR_REFERRAL_REWARD_CENTS', '17');
        return max(0, (int) $raw);
    }

    /**
     * Read-only: platform fee balance for `czedr_id` REVENUE. Does not create that user or ledger rows.
     *
     * @return array<string, mixed>
     */
    public function getRevenueLedgerReport(): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = :cid LIMIT 1');
        $stmt->execute(['cid' => 'REVENUE']);
        $userId = $stmt->fetchColumn();
        if (!$userId) {
            return [
                'czedr_id' => 'REVENUE',
                'revenue_user_exists' => false,
                'balance_cents' => 0,
                'credits_to_revenue_count' => 0,
                'currency' => 'USD',
                'transfer_fee_cents' => self::transferFeeCents(),
            ];
        }
        $uid = (string) $userId;
        $balance = $this->getBalanceCents($uid);
        $cnt = $pdo->prepare('SELECT COUNT(*) FROM ledger_transactions WHERE to_user_id = :uid');
        $cnt->execute(['uid' => $uid]);

        return [
            'czedr_id' => 'REVENUE',
            'revenue_user_exists' => true,
            'balance_cents' => $balance,
            'credits_to_revenue_count' => (int) $cnt->fetchColumn(),
            'currency' => 'USD',
            'transfer_fee_cents' => self::transferFeeCents(),
        ];
    }

    /**
     * Referral rewards are SYSTEM→user ledger credits; they are included in {@see getBalanceCents()}.
     *
     * @return array<string, mixed>
     */
    public function referralEarningsForUser(string $userId, int $recentLimit = 25): array
    {
        $pdo = ConnectionFactory::saturn();
        $memo = self::REFERRAL_REWARD_MEMO;
        $sumStmt = $pdo->prepare(
            'SELECT COALESCE(SUM(t.amount_cents), 0), COUNT(*)
             FROM ledger_transactions t
             INNER JOIN users uf ON uf.id = t.from_user_id AND uf.czedr_id = :sys
             WHERE t.to_user_id = :uid AND t.memo = :memo'
        );
        $sumStmt->execute(['sys' => 'SYSTEM', 'uid' => $userId, 'memo' => $memo]);
        $agg = $sumStmt->fetch(PDO::FETCH_NUM);
        $totalCents = (int) ($agg[0] ?? 0);
        $payCount = (int) ($agg[1] ?? 0);

        $lim = max(1, min($recentLimit, 100));
        $recentStmt = $pdo->prepare(
            'SELECT t.id, t.amount_cents, t.created_at, t.memo
             FROM ledger_transactions t
             INNER JOIN users uf ON uf.id = t.from_user_id AND uf.czedr_id = :sys
             WHERE t.to_user_id = :uid AND t.memo = :memo
             ORDER BY t.created_at DESC
             LIMIT :lim'
        );
        $recentStmt->bindValue('sys', 'SYSTEM');
        $recentStmt->bindValue('uid', $userId);
        $recentStmt->bindValue('memo', $memo);
        $recentStmt->bindValue('lim', $lim, PDO::PARAM_INT);
        $recentStmt->execute();

        return [
            'referral_earnings_total_cents' => $totalCents,
            'referral_payment_count' => $payCount,
            'currency' => 'USD',
            'credited_to_ledger_balance' => true,
            'recent_credits' => $recentStmt->fetchAll(PDO::FETCH_ASSOC),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function applyPeerTransfer(
        string $fromUserId,
        string $toUserId,
        int $amountCents,
        string $idempotencyKey,
        string $memo,
        ?string $ip,
        ?string $userAgent,
    ): array {
        $feeCents = self::transferFeeCents();
        $referralRewardCents = self::referralRewardCents();
        $pdo = ConnectionFactory::saturn();

        $existing = $pdo->prepare('SELECT * FROM ledger_transactions WHERE idempotency_key = :key LIMIT 1');
        $existing->execute(['key' => $idempotencyKey]);
        $dup = $existing->fetch(PDO::FETCH_ASSOC);
        if ($dup) {
            return $this->attachFeeMetaFromDb($pdo, $dup);
        }

        $referrerForReward = null;
        $referralTxnId = null;
        $paidReferralCents = 0;

        $pdo->beginTransaction();
        try {
            $revenueUserId = $feeCents > 0 ? $this->revenueUserId($pdo) : null;

            if ($referralRewardCents > 0) {
                $refStmt = $pdo->prepare('SELECT referred_by_user_id FROM users WHERE id = :id FOR UPDATE');
                $refStmt->execute(['id' => $fromUserId]);
                $rb = $refStmt->fetchColumn();
                if ($rb && (string) $rb !== $fromUserId && $this->isEligibleReferrer($pdo, (string) $rb)) {
                    $referrerForReward = (string) $rb;
                }
            }

            $lockIds = [$fromUserId, $toUserId];
            if ($revenueUserId !== null) {
                $lockIds[] = $revenueUserId;
            }
            if ($referrerForReward !== null) {
                $lockIds[] = $referrerForReward;
            }
            $this->lockAccountsForUpdate($pdo, $lockIds);

            $fromBal = $this->lockedBalance($pdo, $fromUserId);
            $totalDebit = $amountCents + $feeCents;
            if ($fromBal < $totalDebit) {
                throw new \InvalidArgumentException('Insufficient balance');
            }

            $mainTxnId = $this->executeLedgerMovement(
                $pdo,
                $fromUserId,
                $toUserId,
                $amountCents,
                $idempotencyKey,
                substr($memo, 0, 255),
            );

            $feeTxnId = null;
            if ($feeCents > 0 && $revenueUserId !== null) {
                $feeTxnId = $this->executeLedgerMovement(
                    $pdo,
                    $fromUserId,
                    $revenueUserId,
                    $feeCents,
                    $this->feeIdempotencyKey($idempotencyKey),
                    'Czedr service fee',
                );
            }

            if ($referrerForReward !== null && $referralRewardCents > 0) {
                $refKey = $this->referralRewardIdempotencyKey($mainTxnId);
                $referralTxnId = $this->executeSystemMintInTx(
                    $pdo,
                    $referrerForReward,
                    $referralRewardCents,
                    $refKey,
                    self::REFERRAL_REWARD_MEMO,
                );
                $paidReferralCents = $referralRewardCents;
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $this->audit->log($fromUserId, 'ledger.transfer', 'ledger_transaction', $mainTxnId, $ip, $userAgent, [
            'amount_cents' => $amountCents,
            'fee_cents' => $feeCents,
            'to_user_id' => $toUserId,
            'fee_transaction_id' => $feeTxnId,
            'referral_reward_cents' => $paidReferralCents,
            'referral_transaction_id' => $referralTxnId,
        ]);

        if ($referralTxnId !== null && $referrerForReward !== null) {
            $this->audit->log($referrerForReward, 'ledger.referral_reward', 'ledger_transaction', $referralTxnId, $ip, $userAgent, [
                'referee_user_id' => $fromUserId,
                'payment_transaction_id' => $mainTxnId,
                'amount_cents' => $paidReferralCents,
            ]);
        }

        $fetch = $pdo->prepare('SELECT * FROM ledger_transactions WHERE id = :id');
        $fetch->execute(['id' => $mainTxnId]);
        $row = $fetch->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException('Ledger transaction missing after commit');
        }

        return $this->attachFeeMeta($row, $feeCents, $feeTxnId, $paidReferralCents, $referralTxnId);
    }

    /**
     * @param array<string, mixed> $mainRow
     * @return array<string, mixed>
     */
    private function attachFeeMetaFromDb(PDO $pdo, array $mainRow): array
    {
        $feeKey = $this->feeIdempotencyKey((string) $mainRow['idempotency_key']);
        $st = $pdo->prepare('SELECT id, amount_cents FROM ledger_transactions WHERE idempotency_key = :k LIMIT 1');
        $st->execute(['k' => $feeKey]);
        $feeRow = $st->fetch(PDO::FETCH_ASSOC);
        $feeCents = $feeRow ? (int) $feeRow['amount_cents'] : 0;
        $feeTxnId = $feeRow ? (string) $feeRow['id'] : null;

        $withFee = $this->attachFeeMeta($mainRow, $feeCents, $feeTxnId);

        return $this->mergeReferralMetaFromDb($pdo, (string) $mainRow['id'], $withFee);
    }

    /**
     * @param array<string, mixed> $mainRow
     * @return array<string, mixed>
     */
    private function mergeReferralMetaFromDb(PDO $pdo, string $mainTxnId, array $mainRow): array
    {
        $rk = $this->referralRewardIdempotencyKey($mainTxnId);
        $st = $pdo->prepare('SELECT id, amount_cents FROM ledger_transactions WHERE idempotency_key = :k LIMIT 1');
        $st->execute(['k' => $rk]);
        $refRow = $st->fetch(PDO::FETCH_ASSOC);
        if ($refRow) {
            $mainRow['referral_reward_cents'] = (int) $refRow['amount_cents'];
            $mainRow['referral_transaction_id'] = (string) $refRow['id'];
        }

        return $mainRow;
    }

    /**
     * @param array<string, mixed> $mainRow
     * @return array<string, mixed>
     */
    private function attachFeeMeta(array $mainRow, int $feeCents, ?string $feeTxnId, int $referralRewardCents = 0, ?string $referralTxnId = null): array
    {
        $mainRow['fee_cents'] = $feeCents;
        $mainRow['fee_paid_by'] = 'sender';
        $mainRow['total_debit_cents'] = (int) $mainRow['amount_cents'] + $feeCents;
        if ($feeTxnId !== null) {
            $mainRow['fee_transaction_id'] = $feeTxnId;
        }
        if ($referralRewardCents > 0) {
            $mainRow['referral_reward_cents'] = $referralRewardCents;
        }
        if ($referralTxnId !== null) {
            $mainRow['referral_transaction_id'] = $referralTxnId;
        }

        return $mainRow;
    }

    private function feeIdempotencyKey(string $baseKey): string
    {
        return hash('sha256', 'czedr-fee-v1|' . $baseKey);
    }

    private function referralRewardIdempotencyKey(string $mainTxnId): string
    {
        return hash('sha256', 'czedr-referral-v1|' . $mainTxnId);
    }

    private function isEligibleReferrer(PDO $pdo, string $userId): bool
    {
        $stmt = $pdo->prepare('SELECT czedr_id, status FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row || ($row['status'] ?? '') !== 'active') {
            return false;
        }
        $cid = strtoupper(trim((string) ($row['czedr_id'] ?? '')));

        return !in_array($cid, ['SYSTEM', 'REVENUE'], true);
    }

    /**
     * Mint from SYSTEM to user (credit only), same pattern as welcome credits. Caller must hold transaction + locks.
     */
    private function executeSystemMintInTx(PDO $pdo, string $toUserId, int $amountCents, string $idempotencyKey, string $memo): ?string
    {
        if ($amountCents <= 0) {
            return null;
        }
        $check = $pdo->prepare('SELECT id FROM ledger_transactions WHERE idempotency_key = :k LIMIT 1');
        $check->execute(['k' => $idempotencyKey]);
        $existing = $check->fetchColumn();
        if ($existing) {
            return (string) $existing;
        }

        $sys = $this->systemUserId($pdo);
        $txnId = Uuid::v4();
        $pdo->prepare(
            'INSERT INTO ledger_transactions (id, idempotency_key, from_user_id, to_user_id, amount_cents, status, memo, completed_at)
             VALUES (:id, :key, :from, :to, :amt, \'completed\', :memo, NOW())'
        )->execute([
            'id' => $txnId,
            'key' => $idempotencyKey,
            'from' => $sys,
            'to' => $toUserId,
            'amt' => $amountCents,
            'memo' => substr($memo, 0, 255),
        ]);

        $toAcct = $this->accountId($pdo, $toUserId);
        $pdo->prepare('UPDATE ledger_accounts SET balance_cents = balance_cents + :amt WHERE id = :id')
            ->execute(['amt' => $amountCents, 'id' => $toAcct]);
        $this->entry($pdo, $txnId, $toAcct, 'credit', $amountCents);

        return $txnId;
    }

    private function executeLedgerMovement(
        PDO $pdo,
        string $fromUserId,
        string $toUserId,
        int $amountCents,
        string $idempotencyKey,
        string $memo,
    ): string {
        $txnId = Uuid::v4();
        $pdo->prepare(
            'INSERT INTO ledger_transactions (id, idempotency_key, from_user_id, to_user_id, amount_cents, status, memo, completed_at)
             VALUES (:id, :key, :from, :to, :amt, \'completed\', :memo, NOW())'
        )->execute([
            'id' => $txnId,
            'key' => $idempotencyKey,
            'from' => $fromUserId,
            'to' => $toUserId,
            'amt' => $amountCents,
            'memo' => substr($memo, 0, 255),
        ]);

        $fromAcct = $this->accountId($pdo, $fromUserId);
        $toAcct = $this->accountId($pdo, $toUserId);

        $pdo->prepare('UPDATE ledger_accounts SET balance_cents = balance_cents - :amt WHERE id = :id')
            ->execute(['amt' => $amountCents, 'id' => $fromAcct]);
        $this->entry($pdo, $txnId, $fromAcct, 'debit', $amountCents);

        $pdo->prepare('UPDATE ledger_accounts SET balance_cents = balance_cents + :amt WHERE id = :id')
            ->execute(['amt' => $amountCents, 'id' => $toAcct]);
        $this->entry($pdo, $txnId, $toAcct, 'credit', $amountCents);

        return $txnId;
    }

    private function revenueUserId(PDO $pdo): string
    {
        static $id = null;
        if ($id !== null) {
            return $id;
        }
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = \'REVENUE\' LIMIT 1');
        $stmt->execute();
        $row = $stmt->fetchColumn();
        if ($row) {
            $id = (string) $row;

            return $id;
        }
        $id = Uuid::v4();
        $pdo->prepare(
            'INSERT INTO users (id, czedr_id, email, password_hash, status)
             VALUES (:id, \'REVENUE\', \'revenue@czedr.internal\', :hash, \'active\')'
        )->execute(['id' => $id, 'hash' => password_hash(bin2hex(random_bytes(16)), PASSWORD_ARGON2ID)]);
        $this->ensureAccount($id);

        return $id;
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

            $this->lockAccountsForUpdate($pdo, [$fromUserId, $toUserId]);

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

    /**
     * @param list<string> $userIds
     */
    private function lockAccountsForUpdate(PDO $pdo, array $userIds): void
    {
        $ids = array_values(array_unique($userIds));
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
