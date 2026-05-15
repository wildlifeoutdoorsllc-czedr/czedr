<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Support\Env;

/**
 * AES-256-GCM envelope encryption for vault fields (per-record random IV).
 */
final class FieldEncryptor
{
    private const CIPHER = 'aes-256-gcm';
    private const IV_LEN = 12;
    private const TAG_LEN = 16;

    public function __construct(
        private readonly string $masterKey,
        private readonly int $keyVersion = 1,
    ) {
        if (strlen($this->masterKey) !== 32) {
            throw new \InvalidArgumentException('Master key must be 32 bytes');
        }
    }

    public static function fromEnv(): self
    {
        $b64 = Env::require('MASTER_KEY_BASE64');
        $key = base64_decode($b64, true);
        if ($key === false || strlen($key) !== 32) {
            throw new \RuntimeException('MASTER_KEY_BASE64 must decode to 32 bytes');
        }
        return new self($key);
    }

  /** @return array{ciphertext: string, iv: string, tag: string, key_version: int} */
    public function encrypt(string $plaintext, string $aad = ''): array
    {
        $iv = random_bytes(self::IV_LEN);
        $tag = '';
        $ciphertext = openssl_encrypt(
            $plaintext,
            self::CIPHER,
            $this->masterKey,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
            $aad,
            self::TAG_LEN
        );
        if ($ciphertext === false) {
            throw new \RuntimeException('Encryption failed');
        }
        return [
            'ciphertext' => $ciphertext,
            'iv' => $iv,
            'tag' => $tag,
            'key_version' => $this->keyVersion,
        ];
    }

    public function decrypt(string $ciphertext, string $iv, string $tag, string $aad = ''): string
    {
        $plain = openssl_decrypt(
            $ciphertext,
            self::CIPHER,
            $this->masterKey,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
            $aad
        );
        if ($plain === false) {
            throw new \RuntimeException('Decryption failed');
        }
        return $plain;
    }
}
