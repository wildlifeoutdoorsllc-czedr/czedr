<?php
declare(strict_types=1);

namespace Czedr\Moov;

use Czedr\Support\Env;

final class MoovConfig
{
    public static function isEnabled(): bool
    {
        return Env::get('MOOV_ENABLED', '0') === '1';
    }

    public static function assertConfigured(): void
    {
        if (!self::isEnabled()) {
            throw new \RuntimeException('ACH funding is not enabled');
        }
        foreach (['MOOV_SECRET_KEY', 'MOOV_PLATFORM_ACCOUNT_ID', 'MOOV_WALLET_ID'] as $key) {
            if (Env::get($key) === null || Env::get($key) === '') {
                throw new \RuntimeException('ACH funding is not fully configured');
            }
        }
    }

    public static function baseUrl(): string
    {
        return rtrim(Env::get('MOOV_BASE_URL', 'https://api.moov.io') ?? 'https://api.moov.io', '/');
    }

    public static function secretKey(): string
    {
        return Env::require('MOOV_SECRET_KEY');
    }

    public static function publicKey(): string
    {
        return Env::get('MOOV_PUBLIC_KEY', '') ?? '';
    }

    public static function platformAccountId(): string
    {
        return Env::require('MOOV_PLATFORM_ACCOUNT_ID');
    }

    public static function walletId(): string
    {
        return Env::require('MOOV_WALLET_ID');
    }

    public static function webhookSecret(): string
    {
        return Env::get('MOOV_WEBHOOK_SECRET', '') ?? '';
    }

    public static function minDepositCents(): int
    {
        return max(100, (int) (Env::get('CZEDR_ACH_MIN_CENTS', '100') ?? '100'));
    }

    public static function maxDepositCents(): int
    {
        return min(1_000_000_00, (int) (Env::get('CZEDR_ACH_MAX_CENTS', '500000') ?? '500000'));
    }
}
