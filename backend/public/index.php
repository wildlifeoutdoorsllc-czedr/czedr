<?php
declare(strict_types=1);

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$staticPublic = [
    '/status' => __DIR__ . '/status.html',
    '/status.html' => __DIR__ . '/status.html',
    '/reset-password' => __DIR__ . '/reset-password.html',
    '/reset-password.html' => __DIR__ . '/reset-password.html',
];
$staticDev = [
    '/sandbox' => __DIR__ . '/sandbox.html',
    '/sandbox.html' => __DIR__ . '/sandbox.html',
    '/corporate' => __DIR__ . '/corporate-portal.html',
    '/corporate-portal' => __DIR__ . '/corporate-portal.html',
    '/corporate-portal.html' => __DIR__ . '/corporate-portal.html',
];
if (isset($staticPublic[$path]) && is_readable($staticPublic[$path])) {
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-cache');
    header('X-Frame-Options: DENY');
    readfile($staticPublic[$path]);
    return;
}
if (isset($staticDev[$path]) && is_readable($staticDev[$path])) {
    require_once dirname(__DIR__) . '/bootstrap.php';
    if (!\Czedr\Security\ProductionRouteGuard::allowPublicDevPages()) {
        // Old reset emails pointed at /sandbox — serve the production reset page instead.
        if ($path === '/sandbox' || $path === '/sandbox.html') {
            $resetPage = __DIR__ . '/reset-password.html';
            if (is_readable($resetPage)) {
                header('Content-Type: text/html; charset=utf-8');
                header('Cache-Control: no-cache');
                header('X-Frame-Options: DENY');
                readfile($resetPage);
                return;
            }
        }
        http_response_code(404);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['Status' => 'false', 'Data' => [['result' => 'Not found']]]);
        return;
    }
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-cache');
    header('X-Frame-Options: DENY');
    readfile($staticDev[$path]);
    return;
}

require_once dirname(__DIR__) . '/bootstrap.php';

if (\Czedr\Support\Env::get('CZEDR_AUTO_MIGRATE', '0') === '1') {
    try {
        $applied = \Czedr\Database\MigrationRunner::runPending();
        if ($applied > 0) {
            error_log("Czedr: applied {$applied} database migration(s).");
        }
    } catch (Throwable $e) {
        error_log('Czedr MigrationRunner: ' . $e->getMessage());
        Czedr\Http\JsonResponse::error(
            \Czedr\Support\Env::get('APP_DEBUG', 'false') === 'true' ? $e->getMessage() : 'Service unavailable',
            503
        );
        exit;
    }
}

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
