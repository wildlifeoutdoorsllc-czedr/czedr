<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Support\Env;

/**
 * NIST-aligned image-bound payload encryption (v2).
 * AES-256-GCM with 12-byte random IV, 16-byte auth tag, HKDF-SHA256 key derivation.
 */
final class SecurePayloadCryptor
{
    public const VERSION = 0x02;
    private const IV_LEN = 12;
    private const TAG_LEN = 16;
    private const KEY_LEN = 32;
    private const HKDF_INFO = 'czedr-secure-v2';
    private const HKDF_CARD_INFO = 'czedr-card-link-v2';

    public static function deriveKey(string $imageBytes, string $challengeId): string
    {
        $info = self::HKDF_INFO;
        $pepper = Env::get('CZEDR_CRYPTO_PEPPER', '') ?? '';
        if ($pepper !== '') {
            $info .= '|' . $pepper;
        }

        return hash_hkdf('sha256', $imageBytes, self::KEY_LEN, $challengeId, $info);
    }

    /** User-chosen card photo + account id (HKDF salt). */
    public static function deriveKeyForCardLink(string $imageBytes, string $userId): string
    {
        $info = self::HKDF_CARD_INFO;
        $pepper = Env::get('CZEDR_CRYPTO_PEPPER', '') ?? '';
        if ($pepper !== '') {
            $info .= '|' . $pepper;
        }

        return hash_hkdf('sha256', $imageBytes, self::KEY_LEN, $userId, $info);
    }

    public static function encryptCardJson(string $json, string $imageBytes, string $userId): string
    {
        return self::encryptWithKey($json, self::deriveKeyForCardLink($imageBytes, $userId));
    }

    public static function decryptCardBase64(string $encBase64, string $imageBytes, string $userId): string
    {
        $raw = base64_decode($encBase64, true);
        if ($raw === false || $raw === '') {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }

        return self::decryptBinaryWithKey($raw, self::deriveKeyForCardLink($imageBytes, $userId));
    }

    public static function encryptJson(string $json, string $imageBytes, string $challengeId): string
    {
        return self::encryptWithKey($json, self::deriveKey($imageBytes, $challengeId));
    }

    private static function encryptWithKey(string $json, string $key): string
    {
        $iv = random_bytes(self::IV_LEN);
        $tag = '';
        $cipher = openssl_encrypt(
            $json,
            'aes-256-gcm',
            $key,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
            '',
            self::TAG_LEN
        );
        if ($cipher === false || strlen($tag) !== self::TAG_LEN) {
            throw new \RuntimeException('Encryption failed');
        }

        return base64_encode(chr(self::VERSION) . $iv . $tag . $cipher);
    }

    public static function decryptBase64Payload(string $encBase64, string $imageBytes, string $challengeId): string
    {
        $raw = base64_decode($encBase64, true);
        if ($raw === false || $raw === '') {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }

        return self::decryptBinary($raw, $imageBytes, $challengeId);
    }

    public static function decryptBinary(string $raw, string $imageBytes, string $challengeId): string
    {
        if (strlen($raw) < 1 + self::IV_LEN + self::TAG_LEN + 1) {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }
        if (ord($raw[0]) !== self::VERSION) {
            throw new \InvalidArgumentException('Unsupported crypto version');
        }
        $iv = substr($raw, 1, self::IV_LEN);
        $tag = substr($raw, 1 + self::IV_LEN, self::TAG_LEN);
        $cipher = substr($raw, 1 + self::IV_LEN + self::TAG_LEN);
        return self::decryptBinaryWithKey($raw, self::deriveKey($imageBytes, $challengeId));
    }

    private static function decryptBinaryWithKey(string $raw, string $key): string
    {
        if (strlen($raw) < 1 + self::IV_LEN + self::TAG_LEN + 1) {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }
        if (ord($raw[0]) !== self::VERSION) {
            throw new \InvalidArgumentException('Unsupported crypto version');
        }
        $iv = substr($raw, 1, self::IV_LEN);
        $tag = substr($raw, 1 + self::IV_LEN, self::TAG_LEN);
        $cipher = substr($raw, 1 + self::IV_LEN + self::TAG_LEN);
        $plain = openssl_decrypt(
            $cipher,
            'aes-256-gcm',
            $key,
            OPENSSL_RAW_DATA,
            $iv,
            $tag
        );
        if ($plain === false || $plain === '') {
            throw new \InvalidArgumentException('Decryption failed');
        }

        return $plain;
    }

    public static function isV2Payload(string $encBase64): bool
    {
        $raw = base64_decode($encBase64, true);
        if ($raw === false || $raw === '') {
            return false;
        }

        return ord($raw[0]) === self::VERSION;
    }
}
