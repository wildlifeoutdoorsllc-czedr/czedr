<?php

/**
 * PDO helper for Czedr planet databases (MySQL 8.x compatible).
 */
class Database
{
    private static ?array $config = null;

    private static function config(): array
    {
        if (self::$config === null) {
            $path = __DIR__ . '/database.local.php';
            if (!is_file($path)) {
                throw new RuntimeException('Missing config/database.local.php');
            }
            self::$config = require $path;
        }
        return self::$config;
    }

    public static function pdo(string $databaseKey): PDO
    {
        $cfg = self::config();
        $dbName = $cfg['databases'][$databaseKey] ?? null;
        if ($dbName === null) {
            throw new InvalidArgumentException("Unknown database key: {$databaseKey}");
        }

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $cfg['host'],
            (int) $cfg['port'],
            $dbName,
            $cfg['charset']
        );

        return new PDO($dsn, $cfg['user'], $cfg['pass'], $cfg['options']);
    }

    public static function mysqli(string $databaseKey): mysqli
    {
        $cfg = self::config();
        $dbName = $cfg['databases'][$databaseKey] ?? null;
        if ($dbName === null) {
            throw new InvalidArgumentException("Unknown database key: {$databaseKey}");
        }

        $mysqli = new mysqli(
            $cfg['host'],
            $cfg['user'],
            $cfg['pass'],
            $dbName,
            (int) $cfg['port']
        );

        if ($mysqli->connect_errno) {
            throw new RuntimeException('mysqli connect failed: ' . $mysqli->connect_error);
        }

        if (!$mysqli->set_charset($cfg['charset'])) {
            throw new RuntimeException('set_charset failed: ' . $mysqli->error);
        }

        return $mysqli;
    }
}
