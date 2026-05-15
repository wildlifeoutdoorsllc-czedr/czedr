<?php
declare(strict_types=1);

namespace Czedr\Vault;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Security\FieldEncryptor;
use Czedr\Support\Uuid;
use PDO;

/**
 * Splits bank account data across planet DBs; only this service reassembles for authorized flows.
 */
final class BankAccountVault
{
    private PlanetVaultStore $holderName;
    private PlanetVaultStore $accountType;
    private PlanetVaultStore $routing;
    private PlanetVaultStore $account;
    private PlanetVaultStore $mandate;

    public function __construct(
        private readonly FieldEncryptor $encryptor,
        private readonly AuditService $audit,
    ) {
        $this->holderName = new PlanetVaultStore('holder_name', $encryptor);
        $this->accountType = new PlanetVaultStore('account_type', $encryptor);
        $this->routing = new PlanetVaultStore('routing', $encryptor);
        $this->account = new PlanetVaultStore('account', $encryptor);
        $this->mandate = new PlanetVaultStore('mandate', $encryptor);
    }

    /**
     * @param array{holder_name: string, routing: string, account: string, account_type: 'checking'|'savings', mandate?: array<string, mixed>} $data
     * @return array{id: string, vault_token: string, last4: string, account_type: string, display_name: string}
     */
    public function create(string $userId, array $data, ?string $ip, ?string $userAgent): array
    {
        $this->validateBankInput($data);
        $vaultToken = Uuid::v4();
        $refId = Uuid::v4();
        $last4 = substr($data['account'], -4);
        $mandateJson = json_encode($data['mandate'] ?? [
            'authorized_at' => gmdate('c'),
            'purpose' => 'internal_ledger_and_optional_ach_export',
        ], JSON_THROW_ON_ERROR);

        // Split writes — each planet DB receives only one field
        $this->holderName->write($vaultToken, $userId, $data['holder_name']);
        $this->accountType->write($vaultToken, $userId, $data['account_type']);
        $this->routing->write($vaultToken, $userId, $data['routing']);
        $this->account->write($vaultToken, $userId, $data['account']);
        $this->mandate->write($vaultToken, $userId, $mandateJson);

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO bank_account_refs (id, user_id, vault_token, display_name, last4, account_type, is_default)
             VALUES (:id, :user_id, :token, :name, :last4, :type, 0)'
        );
        $stmt->execute([
            'id' => $refId,
            'user_id' => $userId,
            'token' => $vaultToken,
            'name' => $data['holder_name'],
            'last4' => $last4,
            'type' => $data['account_type'],
        ]);

        $this->audit->log($userId, 'bank_account.created', 'bank_account', $refId, $ip, $userAgent, [
            'last4' => $last4,
            'vault_token_prefix' => substr($vaultToken, 0, 8),
        ]);

        return [
            'id' => $refId,
            'vault_token' => $vaultToken,
            'last4' => $last4,
            'account_type' => $data['account_type'],
            'display_name' => $data['holder_name'],
        ];
    }

    /** @return list<array<string, mixed>> */
    public function listMasked(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, display_name, last4, account_type, is_default, verification_status, created_at
             FROM bank_account_refs WHERE user_id = :uid ORDER BY created_at DESC'
        );
        $stmt->execute(['uid' => $userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Reassemble full bank details — audit every read; use only for ACH export admin flow.
     * @return array{holder_name: string, routing: string, account: string, account_type: string, mandate: array<string, mixed>}
     */
    public function readSensitive(string $userId, string $vaultToken, string $purpose, ?string $ip, ?string $userAgent): array
    {
        $this->assertRefOwnership($userId, $vaultToken);
        $this->audit->log($userId, 'vault.read_sensitive', 'vault_token', $vaultToken, $ip, $userAgent, [
            'purpose' => $purpose,
        ]);

        $mandate = json_decode(
            $this->mandate->read($vaultToken, $userId),
            true,
            512,
            JSON_THROW_ON_ERROR
        );

        return [
            'holder_name' => $this->holderName->read($vaultToken, $userId),
            'routing' => $this->routing->read($vaultToken, $userId),
            'account' => $this->account->read($vaultToken, $userId),
            'account_type' => $this->accountType->read($vaultToken, $userId),
            'mandate' => $mandate,
        ];
    }

    public function delete(string $userId, string $bankAccountId, ?string $ip, ?string $userAgent): void
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT vault_token FROM bank_account_refs WHERE id = :id AND user_id = :uid LIMIT 1'
        );
        $stmt->execute(['id' => $bankAccountId, 'uid' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException('Bank account not found');
        }
        $token = $row['vault_token'];
        $this->holderName->delete($token, $userId);
        $this->accountType->delete($token, $userId);
        $this->routing->delete($token, $userId);
        $this->account->delete($token, $userId);
        $this->mandate->delete($token, $userId);
        $del = $pdo->prepare('DELETE FROM bank_account_refs WHERE id = :id AND user_id = :uid');
        $del->execute(['id' => $bankAccountId, 'uid' => $userId]);
        $this->audit->log($userId, 'bank_account.deleted', 'bank_account', $bankAccountId, $ip, $userAgent, []);
    }

    private function assertRefOwnership(string $userId, string $vaultToken): void
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT 1 FROM bank_account_refs WHERE user_id = :uid AND vault_token = :token LIMIT 1'
        );
        $stmt->execute(['uid' => $userId, 'token' => $vaultToken]);
        if (!$stmt->fetchColumn()) {
            throw new \RuntimeException('Vault token not found for user');
        }
    }

    private function validateBankInput(array $data): void
    {
        if (empty($data['holder_name']) || strlen($data['holder_name']) > 128) {
            throw new \InvalidArgumentException('Invalid holder_name');
        }
        if (!preg_match('/^\d{9}$/', (string) ($data['routing'] ?? ''))) {
            throw new \InvalidArgumentException('Routing number must be 9 digits');
        }
        if (!preg_match('/^\d{4,17}$/', (string) ($data['account'] ?? ''))) {
            throw new \InvalidArgumentException('Account number must be 4-17 digits');
        }
        if (!in_array($data['account_type'] ?? '', ['checking', 'savings'], true)) {
            throw new \InvalidArgumentException('account_type must be checking or savings');
        }
    }
}
