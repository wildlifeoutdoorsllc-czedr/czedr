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

        return self::connect('app', $db, 'VAULT_USER_SATURN', 'VAULT_PASS_SATURN');
    }

    private static function connect(string $key, string $dbName, ?string $userEnv = null, ?string $passEnv = null): PDO
    {
        $cacheKey = $key . ':' . $dbName;
        if (isset(self::$pool[$cacheKey])) {
            return self::$pool[$cacheKey];
        }

        $cfg = self::base();
        $user = ($userEnv && Env::get($userEnv)) ? Env::get($userEnv) : $cfg['user'];
        $pass = ($passEnv && Env::get($passEnv) !== null) ? Env::get($passEnv) : $cfg['pass'];

        $resolvedDb = $dbName === 'saturn' ? ($cfg['databases']['app'] ?? 'saturn') : $dbName;

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $cfg['host'],
            (int) $cfg['port'],
            $resolvedDb,
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
