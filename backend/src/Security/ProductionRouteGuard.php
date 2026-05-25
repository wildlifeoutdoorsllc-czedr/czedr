<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Http\JsonResponse;
use Czedr\Support\Env;

/** Blocks dev-only or high-risk routes when APP_ENV is production. */
final class ProductionRouteGuard
{
    public static function requirePlainAuthAllowed(): void
    {
        if (self::allowPlainAuth()) {
            return;
        }
        JsonResponse::error(
            'Plaintext auth is disabled. Use /v1/auth/login-secure and /v1/auth/register-secure.',
            404
        );
        exit;
    }

    public static function requireLegacyApiAllowed(): void
    {
        if (self::allowLegacyApi()) {
            return;
        }
        JsonResponse::error('Legacy API routes are disabled on this server.', 404);
        exit;
    }

    public static function allowPlainAuth(): bool
    {
        if (Env::isLocal()) {
            return true;
        }

        return Env::get('CZEDR_ALLOW_PLAIN_AUTH', '0') === '1';
    }

    public static function allowLegacyApi(): bool
    {
        if (Env::isLocal()) {
            return true;
        }

        return Env::get('CZEDR_ALLOW_LEGACY_API', '0') === '1';
    }

    public static function allowPublicDevPages(): bool
    {
        return Env::isLocal();
    }
}
