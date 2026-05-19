<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Http\JsonResponse;
use Czedr\Support\Env;

/** Blocks cleartext API use in production (TLS or trusted proxy header required). */
final class HttpsGate
{
    public static function enforce(): void
    {
        if (Env::isLocal() || Env::get('CZEDR_ALLOW_HTTP', '0') === '1') {
            return;
        }
        if (self::requestIsHttps()) {
            return;
        }
        JsonResponse::error('HTTPS is required for this API', 403);
        exit;
    }

    public static function requestIsHttps(): bool
    {
        if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
            return true;
        }
        $forwarded = strtolower((string) ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? ''));
        if ($forwarded === 'https') {
            return true;
        }
        $fronted = strtolower((string) ($_SERVER['HTTP_FRONT_END_HTTPS'] ?? ''));

        return $fronted === 'on';
    }
}
