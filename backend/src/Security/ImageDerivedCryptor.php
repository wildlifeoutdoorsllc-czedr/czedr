<?php
declare(strict_types=1);

namespace Czedr\Security;

/**
 * Derives an AES-256 key from image bytes + challenge id (matches iOS signup crypto).
 */
final class ImageDerivedCryptor
{
    /** Same algorithm as legacy card screen: base64(image)[0:16] + md5(challenge)[0:16] */
    public static function deriveKeyString(string $imageBytes, string $challengeId): string
    {
        $b64 = base64_encode($imageBytes);
        $base16 = substr($b64, 0, 16);
        $md5 = md5($challengeId);
        $chal16 = substr($md5, 0, 16);

        return $base16 . $chal16;
    }

    public static function decryptBase64Payload(string $encBase64, string $imageBytes, string $challengeId): string
    {
        $cipher = base64_decode($encBase64, true);
        if ($cipher === false || $cipher === '') {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }
        $key = self::deriveKeyString($imageBytes, $challengeId);
        $plain = self::aes256Decrypt($cipher, $key);
        if ($plain === '') {
            throw new \InvalidArgumentException('Decryption failed');
        }
        return $plain;
    }

    private static function aes256Decrypt(string $cipher, string $keyString): string
    {
        $key = str_pad(substr($keyString, 0, 32), 32, "\0");
        $plain = openssl_decrypt(
            $cipher,
            'AES-256-ECB',
            $key,
            OPENSSL_RAW_DATA
        );
        if ($plain === false) {
            return '';
        }
        return $plain;
    }
}
