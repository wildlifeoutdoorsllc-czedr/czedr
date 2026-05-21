<?php
declare(strict_types=1);

namespace Czedr\Funding;

use Czedr\Support\Env;

/** Encrypts routing/account numbers at rest; never log plaintext. */
final class BankVaultCryptor
{
    private const INFO = 'czedr-bank-vault-v1';

    /**
     * @param array{routing_number: string, account_number: string} $account
     */
    public static function seal(array $account): string
    {
        $json = json_encode($account, JSON_THROW_ON_ERROR);
        $key = self::key();
        $iv = random_bytes(12);
        $tag = '';
        $cipher = openssl_encrypt($json, 'aes-256-gcm', $key, OPENSSL_RAW_DATA, $iv, $tag, self::INFO, 16);
        if ($cipher === false) {
            throw new \RuntimeException('Bank vault encryption failed');
        }

        return $iv . $tag . $cipher;
    }

    /**
     * @return array{routing_number: string, account_number: string}
     */
    public static function open(string $blob): array
    {
        if (strlen($blob) < 28) {
            throw new \InvalidArgumentException('Invalid bank vault blob');
        }
        $iv = substr($blob, 0, 12);
        $tag = substr($blob, 12, 16);
        $cipher = substr($blob, 28);
        $json = openssl_decrypt($cipher, 'aes-256-gcm', self::key(), OPENSSL_RAW_DATA, $iv, $tag, self::INFO);
        if ($json === false) {
            throw new \InvalidArgumentException('Invalid bank vault blob');
        }
        /** @var array{routing_number: string, account_number: string} $data */
        $data = json_decode($json, true, 512, JSON_THROW_ON_ERROR);

        return $data;
    }

    private static function key(): string
    {
        $pepper = Env::get('CZEDR_CRYPTO_PEPPER', '') ?? '';
        if ($pepper === '') {
            if (Env::isLocal()) {
                $pepper = 'local-dev-only-change-in-production';
            } else {
                throw new \RuntimeException('CZEDR_CRYPTO_PEPPER is required for bank vault encryption');
            }
        }

        return hash('sha256', self::INFO . '|' . $pepper, true);
    }
}
