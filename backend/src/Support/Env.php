<?php
declare(strict_types=1);

namespace Czedr\Support;

final class Env
{
    public static function load(string $path): void
    {
        if (!is_file($path)) {
            return;
        }
        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }
            if (!str_contains($line, '=')) {
                continue;
            }
            [$key, $value] = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value, " \t\"'");
            if ($key !== '' && getenv($key) === false) {
                putenv("{$key}={$value}");
                $_ENV[$key] = $value;
            }
        }
    }

    public static function get(string $key, ?string $default = null): ?string
    {
        $v = $_ENV[$key] ?? getenv($key);
        if ($v === false || $v === '') {
            return $default;
        }
        return (string) $v;
    }

    public static function require(string $key): string
    {
        $v = self::get($key);
        if ($v === null || $v === '') {
            throw new \RuntimeException("Missing required environment variable: {$key}");
        }
        return $v;
    }

    /** True only when APP_ENV is explicitly set to "local" (never when unset — defaults to production). */
    public static function isLocal(): bool
    {
        return self::get('APP_ENV', 'production') === 'local';
    }

    /**
     * Self-service ledger credits (POST /v1/ledger/load). Allowed in local dev, or when
     * CZEDR_ALLOW_LEDGER_LOAD=1 (e.g. staging). Disabled in production by default.
     */
    public static function allowSelfServiceLedgerLoad(): bool
    {
        if (self::get('CZEDR_ALLOW_LEDGER_LOAD', '0') === '1') {
            return true;
        }

        return self::isLocal();
    }
}
