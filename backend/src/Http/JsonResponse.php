<?php
declare(strict_types=1);

namespace Czedr\Http;

final class JsonResponse
{
    public static function send(int $status, array $payload): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: DENY');
        header('Referrer-Policy: no-referrer');
        echo json_encode($payload, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES);
    }

    public static function ok(array $data): void
    {
        self::send(200, ['Status' => 'true', 'Data' => $data]);
    }

    public static function error(string $message, int $status = 400): void
    {
        self::send($status, ['Status' => 'false', 'Data' => [['result' => $message]]]);
    }

    /** @param list<array<string, mixed>> $rows */
    public static function okList(array $rows, int $totalRows): void
    {
        self::send(200, ['Status' => 'true', 'Data' => $rows, 'Total_rows' => $totalRows]);
    }
}
