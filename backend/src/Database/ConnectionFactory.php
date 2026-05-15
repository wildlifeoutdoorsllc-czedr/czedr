<?php
declare(strict_types=1);

namespace Czedr\Database;

use Czedr\Support\Env;
use PDO;

final class ConnectionFactory
{
    private static ?array $baseConfig = null;

    /** @var array<string, PDO> */
    private static array $pool = [];

    public static function saturn(): PDO
    {
        $cfg = self::base();
        $db = $cfg['databases']['app'] ?? 'saturn';
        return self::planet('app', $db, 'VAULT_USER_SATURN', 'VAULT_PASS_SATURN');
    }

    /**
     * @param 'holder_name'|'account_type'|'routing'|'account'|'mandate' $field
     */
    public static function vault(string $field): PDO
    {
        $map = [
            'holder_name' => ['mercury', 'VAULT_USER_MERCURY', 'VAULT_PASS_MERCURY'],
            'account_type' => ['venus', 'VAULT_USER_VENUS', 'VAULT_PASS_VENUS'],
            'routing' => ['earth', 'VAULT_USER_EARTH', 'VAULT_PASS_EARTH'],
            'account' => ['mars', 'VAULT_USER_MARS', 'VAULT_PASS_MARS'],
            'mandate' => ['jupiter', 'VAULT_USER_JUPITER', 'VAULT_PASS_JUPITER'],
        ];
        if (!isset($map[$field])) {
            throw new \InvalidArgumentException("Unknown vault field: {$field}");
        }
        [$db, $userEnv, $passEnv] = $map[$field];
        return self::planet($db, $db, $userEnv, $passEnv);
    }

    private static function planet(string $key, string $dbName, ?string $userEnv = null, ?string $passEnv = null): PDO
    {
        $cacheKey = $key . ':' . $dbName;
        if (isset(self::$pool[$cacheKey])) {
            return self::$pool[$cacheKey];
        }

        $cfg = self::base();
        $user = ($userEnv && Env::get($userEnv)) ? Env::get($userEnv) : $cfg['user'];
        $pass = ($passEnv && Env::get($passEnv) !== null) ? Env::get($passEnv) : $cfg['pass'];

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $cfg['host'],
            (int) $cfg['port'],
            $dbName === 'saturn' ? ($cfg['databases']['app'] ?? 'saturn') : $dbName,
            $cfg['charset']
        );

        $pdo = new PDO($dsn, $user, $pass, $cfg['options']);
        self::$pool[$cacheKey] = $pdo;
        return $pdo;
    }

    private static function base(): array
    {
        if (self::$baseConfig === null) {
            $path = CZEDR_ROOT . '/config/database.local.php';
            if (!is_file($path)) {
                throw new \RuntimeException('Missing config/database.local.php');
            }
            self::$baseConfig = require $path;
        }
        return self::$baseConfig;
    }
}
