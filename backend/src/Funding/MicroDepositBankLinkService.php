<?php
declare(strict_types=1);

namespace Czedr\Funding;

use Czedr\Database\ConnectionFactory;
use Czedr\Support\Env;
use Czedr\Support\Uuid;
use PDO;

final class MicroDepositBankLinkService
{
    private const MAX_CONFIRM_ATTEMPTS = 5;

    public static function linkMethod(): string
    {
        return strtolower(Env::get('CZEDR_BANK_LINK_METHOD', 'microdeposit') ?? 'microdeposit');
    }

    public static function assertMicroDepositOnly(): void
    {
        if (self::linkMethod() !== 'microdeposit') {
            throw new \RuntimeException('Only microdeposit bank linking is supported');
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function startLink(
        string $userId,
        string $routingNumber,
        string $accountNumber,
        string $accountType,
        string $accountHolderName,
    ): array {
        self::assertMicroDepositOnly();
        $routing = preg_replace('/\D/', '', $routingNumber) ?? '';
        $account = preg_replace('/\D/', '', $accountNumber) ?? '';
        if (!self::isValidAbaRouting($routing)) {
            throw new \InvalidArgumentException('Invalid routing number');
        }
        if (strlen($account) < 4 || strlen($account) > 17) {
            throw new \InvalidArgumentException('Invalid account number');
        }
        $type = strtolower($accountType);
        if (!in_array($type, ['checking', 'savings'], true)) {
            throw new \InvalidArgumentException('account_type must be checking or savings');
        }
        $name = trim($accountHolderName);
        if ($name === '') {
            throw new \InvalidArgumentException('account_holder_name is required');
        }

        [$centsA, $centsB] = self::microAmounts();
        $vault = BankVaultCryptor::seal([
            'routing_number' => $routing,
            'account_number' => $account,
        ]);

        $pdo = ConnectionFactory::saturn();
        $id = Uuid::v4();
        $lastFour = substr($account, -4);
        $pdo->prepare(
            'INSERT INTO moov_bank_links (
                id, user_id, link_method, moov_bank_account_id, bank_name, last_four,
                account_type, account_holder_name, routing_last4, account_vault,
                micro_cents_a, micro_cents_b, is_default, status
             ) VALUES (
                :id, :uid, \'microdeposit\', NULL, NULL, :last4,
                :atype, :name, :rlast4, :vault,
                :ma, :mb, 1, \'pending_micro_send\'
             )'
        )->execute([
            'id' => $id,
            'uid' => $userId,
            'last4' => $lastFour,
            'atype' => $type,
            'name' => substr($name, 0, 128),
            'rlast4' => substr($routing, -4),
            'vault' => $vault,
            'ma' => $centsA,
            'mb' => $centsB,
        ]);

        $status = 'pending_micro_send';
        $message = 'Two small deposits will appear on your bank statement in 1–3 business days. '
            . 'You will never be asked for your online banking password.';
        if (self::skipMicroDepositWait()) {
            $this->markMicroDepositsSent($id);
            $status = 'awaiting_confirm';
            $message = 'Dev mode: confirm the two amounts below (see funding status or your records). '
                . 'No bank login required.';
        }

        // TODO: production — enqueue two ACH credits from FBO via file rail (OpenACH / achgateway).
        $out = [
            'bank_link_id' => $id,
            'status' => $status,
            'last4' => $lastFour,
            'link_method' => 'microdeposit',
            'message' => $message,
        ];
        if ($status === 'awaiting_confirm' && self::skipMicroDepositWait()) {
            $out['micro_cents_a'] = $centsA;
            $out['micro_cents_b'] = $centsB;
        }

        return $out;
    }

    private static function skipMicroDepositWait(): bool
    {
        if (!\Czedr\Support\Env::isLocal()) {
            return false;
        }

        return (\Czedr\Support\Env::get('CZEDR_MICRO_DEPOSIT_SKIP_WAIT', '1') ?? '1') === '1';
    }

    /**
     * @return array<string, mixed>
     */
    public function confirmMicroDeposits(
        string $userId,
        string $bankLinkId,
        int $amount1Cents,
        int $amount2Cents,
    ): array {
        self::assertMicroDepositOnly();
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, user_id, status, micro_cents_a, micro_cents_b, confirm_attempts
             FROM moov_bank_links WHERE id = :id LIMIT 1'
        );
        $stmt->execute(['id' => $bankLinkId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row || (string) $row['user_id'] !== $userId) {
            throw new \InvalidArgumentException('Bank link not found');
        }
        $status = (string) $row['status'];
        if ($status === 'verified') {
            return ['bank_link_id' => $bankLinkId, 'status' => 'verified'];
        }
        if (!in_array($status, ['pending_micro_send', 'awaiting_confirm'], true)) {
            throw new \InvalidArgumentException('This bank link cannot be confirmed');
        }

        $expected = [(int) $row['micro_cents_a'], (int) $row['micro_cents_b']];
        $given = [$amount1Cents, $amount2Cents];
        sort($expected);
        sort($given);
        if ($expected !== $given) {
            $attempts = (int) $row['confirm_attempts'] + 1;
            $newStatus = $attempts >= self::MAX_CONFIRM_ATTEMPTS ? 'failed' : $status;
            $pdo->prepare('UPDATE moov_bank_links SET confirm_attempts = :a, status = :st WHERE id = :id')
                ->execute(['a' => $attempts, 'st' => $newStatus, 'id' => $bankLinkId]);
            throw new \InvalidArgumentException('Amounts do not match. Check your bank statement and try again.');
        }

        $pdo->prepare(
            'UPDATE moov_bank_links SET status = \'verified\', verified_at = NOW(), confirm_attempts = 0 WHERE id = :id'
        )->execute(['id' => $bankLinkId]);

        return ['bank_link_id' => $bankLinkId, 'status' => 'verified'];
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function listBanks(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, last_four, account_type, account_holder_name, is_default, status, micro_sent_at, verified_at
             FROM moov_bank_links WHERE user_id = :uid
             ORDER BY is_default DESC, created_at ASC'
        );
        $stmt->execute(['uid' => $userId]);
        $out = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $out[] = [
                'id' => (string) $row['id'],
                'last4' => (string) ($row['last_four'] ?? ''),
                'account_type' => (string) ($row['account_type'] ?? 'checking'),
                'account_holder_name' => (string) ($row['account_holder_name'] ?? ''),
                'is_default' => ((int) ($row['is_default'] ?? 0)) === 1,
                'status' => (string) $row['status'],
                'link_method' => 'microdeposit',
            ];
        }

        return $out;
    }

    /** Mark link ready for member confirmation (after ACH credits sent). */
    public function markMicroDepositsSent(string $bankLinkId): void
    {
        $pdo = ConnectionFactory::saturn();
        $pdo->prepare(
            'UPDATE moov_bank_links SET status = \'awaiting_confirm\', micro_sent_at = NOW()
             WHERE id = :id AND status = \'pending_micro_send\''
        )->execute(['id' => $bankLinkId]);
    }

    public static function isValidAbaRouting(string $routing): bool
    {
        if (strlen($routing) !== 9 || !ctype_digit($routing)) {
            return false;
        }
        $digits = array_map('intval', str_split($routing));
        $sum = 3 * ($digits[0] + $digits[3] + $digits[6])
            + 7 * ($digits[1] + $digits[4] + $digits[7])
            + ($digits[2] + $digits[5] + $digits[8]);

        return $sum % 10 === 0;
    }

    /** @return array{0: int, 1: int} */
    private static function microAmounts(): array
    {
        $a = (int) (Env::get('CZEDR_MICRO_DEPOSIT_CENTS_A', '') ?: 0);
        $b = (int) (Env::get('CZEDR_MICRO_DEPOSIT_CENTS_B', '') ?: 0);
        if ($a > 0 && $b > 0 && $a !== $b && $a <= 99 && $b <= 99) {
            return [$a, $b];
        }
        do {
            $a = random_int(1, 99);
            $b = random_int(1, 99);
        } while ($a === $b);

        return [$a, $b];
    }
}
