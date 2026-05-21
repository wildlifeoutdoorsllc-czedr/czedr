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
    private const REFERRAL_CORPORATE_MEMO = 'Referral payout (platform fee)';
    private const SERVICE_FEE_MEMO = 'Czedr service fee';

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
     * that amount plus the platform fee from {@see self::transferFeeCents()} (fee credited to CORPORATE;
     * eligible referral rewards are paid from CORPORATE, net remainder stays in CORPORATE).
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
        if (PlatformAccounts::isPlatformCzedrId($toCzedrId)) {
            throw new \InvalidArgumentException('Invalid recipient Czedr ID');
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
     * Referrer reward (USD cents) per eligible party when a P2P payment completes: the sender's referrer
     * (if the sender signed up with a referrer) and the recipient's referrer (if the recipient signed up
     * with a referrer). Up to two rewards per transfer. Set CZEDR_REFERRAL_REWARD_CENTS=0 to disable.
     */
    public static function referralRewardCents(): int
    {
        $raw = Env::get('CZEDR_REFERRAL_REWARD_CENTS', '17');
        return max(0, (int) $raw);
    }

    /**
     * Read-only: corporate ledger (`czedr_id` CORPORATE) — fees in, referral payouts out, net balance.
     *
     * @return array<string, mixed>
     */
    public function getCorporateLedgerReport(): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = :cid LIMIT 1');
        $stmt->execute(['cid' => PlatformAccounts::CORPORATE]);
        $userId = $stmt->fetchColumn();
        if (!$userId) {
            return [
                'czedr_id' => PlatformAccounts::CORPORATE,
                'corporate_user_exists' => false,
                'balance_cents' => 0,
                'fees_collected_cents' => 0,
                'fees_collected_count' => 0,
                'referrals_paid_cents' => 0,
                'referrals_paid_count' => 0,
                'net_after_referrals_cents' => 0,
                'currency' => 'USD',
                'transfer_fee_cents' => self::transferFeeCents(),
                'referral_reward_cents' => self::referralRewardCents(),
            ];
        }
        $uid = (string) $userId;
        $balance = $this->getBalanceCents($uid);

        $feeAgg = $pdo->prepare(
            'SELECT COALESCE(SUM(amount_cents), 0), COUNT(*)
             FROM ledger_transactions
             WHERE to_user_id = :uid AND memo = :memo'
        );
        $feeAgg->execute(['uid' => $uid, 'memo' => self::SERVICE_FEE_MEMO]);
        $feeRow = $feeAgg->fetch(PDO::FETCH_NUM);
        $feesCollected = (int) ($feeRow[0] ?? 0);
        $feeCount = (int) ($feeRow[1] ?? 0);

        $refAgg = $pdo->prepare(
            'SELECT COALESCE(SUM(amount_cents), 0), COUNT(*)
             FROM ledger_transactions
             WHERE from_user_id = :uid AND memo = :memo'
        );
        $refAgg->execute(['uid' => $uid, 'memo' => self::REFERRAL_CORPORATE_MEMO]);
        $refRow = $refAgg->fetch(PDO::FETCH_NUM);
        $referralsPaid = (int) ($refRow[0] ?? 0);
        $refCount = (int) ($refRow[1] ?? 0);

        return [
            'czedr_id' => PlatformAccounts::CORPORATE,
            'corporate_user_exists' => true,
            'balance_cents' => $balance,
            'fees_collected_cents' => $feesCollected,
            'fees_collected_count' => $feeCount,
            'referrals_paid_cents' => $referralsPaid,
            'referrals_paid_count' => $refCount,
            'net_after_referrals_cents' => $feesCollected - $referralsPaid,
            'currency' => 'USD',
            'transfer_fee_cents' => self::transferFeeCents(),
            'referral_reward_cents' => self::referralRewardCents(),
        ];
    }

    /**
     * @deprecated Use {@see getCorporateLedgerReport()}; kept for existing admin clients.
     *
     * @return array<string, mixed>
     */
    public function getRevenueLedgerReport(): array
    {
        $corp = $this->getCorporateLedgerReport();
        $corp['legacy_endpoint'] = true;
        $corp['note'] = 'Fees settle to CORPORATE; revenue-ledger returns corporate totals.';

        return $corp;
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

        $referralPayouts = [];
        $paidReferralCents = 0;

        $pdo->beginTransaction();
        try {
            $corporateUserId = $feeCents > 0 ? $this->corporateUserId($pdo) : null;

            $referralCandidates = [];
            if ($referralRewardCents > 0) {
                $senderReferrer = $this->resolveReferredByReferrer($pdo, $fromUserId);
                if ($senderReferrer !== null) {
                    $referralCandidates[] = ['referrer_id' => $senderReferrer, 'role' => 'sender'];
                }
                $recipientReferrer = $this->resolveReferredByReferrer($pdo, $toUserId);
                if ($recipientReferrer !== null) {
                    $referralCandidates[] = ['referrer_id' => $recipientReferrer, 'role' => 'recipient'];
                }
            }

            $lockIds = [$fromUserId, $toUserId];
            if ($corporateUserId !== null) {
                $lockIds[] = $corporateUserId;
            }
            foreach ($referralCandidates as $candidate) {
                $lockIds[] = $candidate['referrer_id'];
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
            if ($feeCents > 0 && $corporateUserId !== null) {
                $feeTxnId = $this->executeLedgerMovement(
                    $pdo,
                    $fromUserId,
                    $corporateUserId,
                    $feeCents,
                    $this->feeIdempotencyKey($idempotencyKey),
                    self::SERVICE_FEE_MEMO,
                );
            }

            foreach ($referralCandidates as $candidate) {
                $payout = $this->payReferralRewardInTx(
                    $pdo,
                    $corporateUserId,
                    $feeCents,
                    $referralRewardCents,
                    $mainTxnId,
                    $candidate['referrer_id'],
                    $candidate['role'],
                );
                if ($payout !== null) {
                    $referralPayouts[] = $payout;
                    $paidReferralCents += $referralRewardCents;
                }
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
            'referral_payout_count' => count($referralPayouts),
        ]);

        foreach ($referralPayouts as $payout) {
            $this->audit->log($payout['referrer_id'], 'ledger.referral_reward', 'ledger_transaction', $payout['transaction_id'], $ip, $userAgent, [
                'party_role' => $payout['role'],
                'payer_user_id' => $fromUserId,
                'payee_user_id' => $toUserId,
                'payment_transaction_id' => $mainTxnId,
                'amount_cents' => $referralRewardCents,
            ]);
        }

        $fetch = $pdo->prepare('SELECT * FROM ledger_transactions WHERE id = :id');
        $fetch->execute(['id' => $mainTxnId]);
        $row = $fetch->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException('Ledger transaction missing after commit');
        }

        return $this->attachFeeMeta($row, $feeCents, $feeTxnId, $paidReferralCents, $referralPayouts);
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
        $keys = [
            $this->referralRewardIdempotencyKey($mainTxnId, 'sender'),
            $this->referralRewardIdempotencyKey($mainTxnId, 'recipient'),
            $this->referralRewardIdempotencyKeyLegacy($mainTxnId),
        ];
        $placeholders = implode(',', array_fill(0, count($keys), '?'));
        $st = $pdo->prepare(
            "SELECT id, amount_cents, idempotency_key FROM ledger_transactions WHERE idempotency_key IN ({$placeholders})"
        );
        $st->execute($keys);
        $payouts = [];
        $total = 0;
        while ($refRow = $st->fetch(PDO::FETCH_ASSOC)) {
            $cents = (int) $refRow['amount_cents'];
            $total += $cents;
            $payouts[] = [
                'transaction_id' => (string) $refRow['id'],
                'amount_cents' => $cents,
            ];
        }
        if ($total > 0) {
            $mainRow['referral_reward_cents'] = $total;
            $mainRow['referral_payout_count'] = count($payouts);
            if (count($payouts) === 1) {
                $mainRow['referral_transaction_id'] = $payouts[0]['transaction_id'];
            }
            $mainRow['referral_payouts'] = $payouts;
        }

        return $mainRow;
    }

    /**
     * @param list<array{referrer_id: string, role: string, transaction_id: string, source: string}> $referralPayouts
     * @param array<string, mixed> $mainRow
     * @return array<string, mixed>
     */
    private function attachFeeMeta(array $mainRow, int $feeCents, ?string $feeTxnId, int $paidReferralCents = 0, array $referralPayouts = []): array
    {
        $mainRow['fee_cents'] = $feeCents;
        $mainRow['fee_paid_by'] = 'sender';
        $mainRow['total_debit_cents'] = (int) $mainRow['amount_cents'] + $feeCents;
        if ($feeTxnId !== null) {
            $mainRow['fee_transaction_id'] = $feeTxnId;
            $mainRow['corporate_czedr_id'] = PlatformAccounts::CORPORATE;
        }
        if ($paidReferralCents > 0) {
            $mainRow['referral_reward_cents'] = $paidReferralCents;
            $mainRow['referral_payout_count'] = count($referralPayouts);
            $mainRow['corporate_net_cents'] = max(0, $feeCents - $paidReferralCents);
            $mainRow['referral_payouts'] = $referralPayouts;
            if (count($referralPayouts) === 1) {
                $mainRow['referral_transaction_id'] = $referralPayouts[0]['transaction_id'];
            }
        } elseif ($feeCents > 0) {
            $mainRow['corporate_net_cents'] = $feeCents;
        }

        return $mainRow;
    }

    private function resolveReferredByReferrer(PDO $pdo, string $userId): ?string
    {
        $stmt = $pdo->prepare('SELECT referred_by_user_id FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $rb = $stmt->fetchColumn();
        if (!$rb || (string) $rb === $userId) {
            return null;
        }
        $referrerId = (string) $rb;

        return $this->isEligibleReferrer($pdo, $referrerId) ? $referrerId : null;
    }

    /**
     * @return array{referrer_id: string, role: string, transaction_id: string, source: string}|null
     */
    private function payReferralRewardInTx(
        PDO $pdo,
        ?string $corporateUserId,
        int $feeCents,
        int $referralRewardCents,
        string $mainTxnId,
        string $referrerUserId,
        string $role,
    ): ?array {
        $refKey = $this->referralRewardIdempotencyKey($mainTxnId, $role);
        $check = $pdo->prepare('SELECT id FROM ledger_transactions WHERE idempotency_key = :k LIMIT 1');
        $check->execute(['k' => $refKey]);
        $existing = $check->fetchColumn();
        if ($existing) {
            return [
                'referrer_id' => $referrerUserId,
                'role' => $role,
                'transaction_id' => (string) $existing,
                'source' => 'existing',
            ];
        }

        $txnId = null;
        $source = 'system';
        if ($corporateUserId !== null && $feeCents >= $referralRewardCents) {
            $corpBal = $this->lockedBalance($pdo, $corporateUserId);
            if ($corpBal >= $referralRewardCents) {
                $txnId = $this->executeLedgerMovement(
                    $pdo,
                    $corporateUserId,
                    $referrerUserId,
                    $referralRewardCents,
                    $refKey,
                    self::REFERRAL_CORPORATE_MEMO,
                );
                $source = 'corporate';
            }
        }
        if ($txnId === null) {
            $txnId = $this->executeSystemMintInTx(
                $pdo,
                $referrerUserId,
                $referralRewardCents,
                $refKey,
                self::REFERRAL_REWARD_MEMO,
            );
            if ($txnId === null) {
                return null;
            }
            $source = 'system';
        }

        return [
            'referrer_id' => $referrerUserId,
            'role' => $role,
            'transaction_id' => $txnId,
            'source' => $source,
        ];
    }

    private function feeIdempotencyKey(string $baseKey): string
    {
        return hash('sha256', 'czedr-fee-v1|' . $baseKey);
    }

    private function referralRewardIdempotencyKey(string $mainTxnId, string $role): string
    {
        return hash('sha256', 'czedr-referral-v2|' . $mainTxnId . '|' . $role);
    }

    /** @deprecated v1 key for transfers before dual-party referrals */
    private function referralRewardIdempotencyKeyLegacy(string $mainTxnId): string
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

        return !PlatformAccounts::isPlatformCzedrId($cid);
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

    private function corporateUserId(PDO $pdo): string
    {
        return $this->ensurePlatformUserId($pdo, PlatformAccounts::CORPORATE, 'corporate@czedr.internal');
    }

    private function ensurePlatformUserId(PDO $pdo, string $czedrId, string $email): string
    {
        static $cache = [];
        if (isset($cache[$czedrId])) {
            return $cache[$czedrId];
        }
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = :cid LIMIT 1');
        $stmt->execute(['cid' => $czedrId]);
        $row = $stmt->fetchColumn();
        if ($row) {
            $cache[$czedrId] = (string) $row;

            return $cache[$czedrId];
        }
        $id = Uuid::v4();
        $pdo->prepare(
            'INSERT INTO users (id, czedr_id, email, password_hash, status)
             VALUES (:id, :cid, :email, :hash, \'active\')'
        )->execute([
            'id' => $id,
            'cid' => $czedrId,
            'email' => $email,
            'hash' => password_hash(bin2hex(random_bytes(16)), PASSWORD_ARGON2ID),
        ]);
        $this->ensureAccount($id);
        $cache[$czedrId] = $id;

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
