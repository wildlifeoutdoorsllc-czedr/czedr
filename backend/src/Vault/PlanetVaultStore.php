<?php
declare(strict_types=1);

namespace Czedr\Vault;

use Czedr\Database\ConnectionFactory;
use Czedr\Security\FieldEncryptor;
use PDO;

/**
 * Writes/reads one encrypted field on exactly one planet database.
 */
final class PlanetVaultStore
{
    public function __construct(
        private readonly string $fieldKey,
        private readonly FieldEncryptor $encryptor,
    ) {
    }

    public function write(string $vaultToken, string $userId, string $plaintext): void
    {
        $aad = $this->aad($vaultToken, $userId);
        $enc = $this->encryptor->encrypt($plaintext, $aad);
        $pdo = ConnectionFactory::vault($this->fieldKey);
        $stmt = $pdo->prepare(
            'INSERT INTO vault_fields (vault_token, user_id, ciphertext, iv, tag, key_version)
             VALUES (:token, :user_id, :cipher, :iv, :tag, :kv)
             ON DUPLICATE KEY UPDATE ciphertext = VALUES(ciphertext), iv = VALUES(iv),
             tag = VALUES(tag), key_version = VALUES(key_version)'
        );
        $stmt->execute([
            'token' => $vaultToken,
            'user_id' => $userId,
            'cipher' => $enc['ciphertext'],
            'iv' => $enc['iv'],
            'tag' => $enc['tag'],
            'kv' => $enc['key_version'],
        ]);
    }

    public function read(string $vaultToken, string $userId): string
    {
        $pdo = ConnectionFactory::vault($this->fieldKey);
        $stmt = $pdo->prepare(
            'SELECT ciphertext, iv, tag FROM vault_fields WHERE vault_token = :token AND user_id = :user_id LIMIT 1'
        );
        $stmt->execute(['token' => $vaultToken, 'user_id' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException("Vault field missing: {$this->fieldKey}");
        }
        return $this->encryptor->decrypt(
            $row['ciphertext'],
            $row['iv'],
            $row['tag'],
            $this->aad($vaultToken, $userId)
        );
    }

    public function delete(string $vaultToken, string $userId): void
    {
        $pdo = ConnectionFactory::vault($this->fieldKey);
        $stmt = $pdo->prepare('DELETE FROM vault_fields WHERE vault_token = :token AND user_id = :user_id');
        $stmt->execute(['token' => $vaultToken, 'user_id' => $userId]);
    }

    private function aad(string $vaultToken, string $userId): string
    {
        return $this->fieldKey . '|' . $vaultToken . '|' . $userId;
    }
}
