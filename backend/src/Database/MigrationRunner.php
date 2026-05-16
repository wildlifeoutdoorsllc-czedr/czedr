<?php
declare(strict_types=1);

namespace Czedr\Database;

use PDO;

/**
 * Applies numbered SQL files from database/migrations once each, tracked in schema_migrations.
 * Migrations should be idempotent where possible (safe if run twice before tracking exists).
 */
final class MigrationRunner
{
    private const META_TABLE = 'schema_migrations';

    /** @return int Number of migration files newly applied */
    public static function runPending(): int
    {
        $pdo = ConnectionFactory::saturn();
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::MYSQL_ATTR_MULTI_STATEMENTS, true);

        self::ensureMetaTable($pdo);

        $applied = self::appliedFilenames($pdo);
        $files = self::migrationFiles();
        $count = 0;

        foreach ($files as $path) {
            $base = basename($path);
            if (isset($applied[$base])) {
                continue;
            }
            $sql = file_get_contents($path);
            if ($sql === false || trim($sql) === '') {
                throw new \RuntimeException("Empty migration: {$base}");
            }
            try {
                $pdo->exec($sql);
            } catch (\Throwable $e) {
                throw new \RuntimeException("Migration failed: {$base} — " . $e->getMessage(), 0, $e);
            }
            $ins = $pdo->prepare(
                'INSERT INTO `' . self::META_TABLE . '` (filename) VALUES (:f)'
            );
            $ins->execute(['f' => $base]);
            $count++;
        }

        return $count;
    }

    private static function ensureMetaTable(PDO $pdo): void
    {
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS `' . self::META_TABLE . '` (
                filename VARCHAR(191) NOT NULL PRIMARY KEY,
                applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
        );
    }

    /** @return array<string, true> */
    private static function appliedFilenames(PDO $pdo): array
    {
        $stmt = $pdo->query('SELECT filename FROM `' . self::META_TABLE . '`');
        if ($stmt === false) {
            return [];
        }
        $out = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $out[(string) $row['filename']] = true;
        }

        return $out;
    }

    /** @return list<string> absolute paths */
    private static function migrationFiles(): array
    {
        $dir = CZEDR_ROOT . '/database/migrations';
        if (!is_dir($dir)) {
            return [];
        }
        $paths = glob($dir . '/[0-9][0-9][0-9]_*.sql') ?: [];
        sort($paths, SORT_STRING);

        return $paths;
    }
}
