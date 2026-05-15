<?php
declare(strict_types=1);

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$static = [
    '/sandbox' => __DIR__ . '/sandbox.html',
    '/sandbox.html' => __DIR__ . '/sandbox.html',
];
if (isset($static[$path]) && is_readable($static[$path])) {
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-cache');
    readfile($static[$path]);
    return;
}

require_once dirname(__DIR__) . '/bootstrap.php';

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET' && !str_contains($_SERVER['CONTENT_TYPE'] ?? '', 'application/json')) {
    // Prefer JSON bodies for all mutations (no secrets in query strings)
    header('Content-Type: application/json; charset=utf-8');
    if (empty($_POST) && in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT', 'PATCH'], true)) {
        // Allow JSON body without form content-type from some clients
    }
}

try {
    (new Czedr\App())->run();
} catch (Throwable $e) {
    Czedr\Http\JsonResponse::error(
        Czedr\Support\Env::get('APP_DEBUG') === 'true' ? $e->getMessage() : 'Server error',
        500
    );
}
