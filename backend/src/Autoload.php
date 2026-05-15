<?php
declare(strict_types=1);

namespace Czedr;

final class Autoload
{
    public static function register(string $baseDir): void
    {
        spl_autoload_register(static function (string $class) use ($baseDir): void {
            if (!str_starts_with($class, 'Czedr\\')) {
                return;
            }
            $relative = str_replace('\\', DIRECTORY_SEPARATOR, substr($class, 6)) . '.php';
            $path = $baseDir . DIRECTORY_SEPARATOR . $relative;
            if (is_file($path)) {
                require_once $path;
            }
        });
    }
}
