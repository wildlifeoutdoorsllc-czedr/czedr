<?php
declare(strict_types=1);

/**
 * Smoke test for ProductionRouteGuard behavior.
 * Run with API up. Uses APP_ENV from .env — temporarily set APP_ENV=production to test blocks.
 */

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Support\Env;

$base = getenv('CZEDR_TEST_BASE') ?: 'http://127.0.0.1:8080';
$isProd = !Env::isLocal();

function req(string $method, string $path, ?array $body = null): array
{
    global $base;
    $ch = curl_init($base . $path);
    $headers = ['Accept: application/json'];
    if ($body !== null) {
        $headers[] = 'Content-Type: application/json';
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
    ]);
    $raw = (string) curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return ['code' => $code, 'raw' => $raw];
}

echo "APP_ENV=" . (Env::isLocal() ? 'local' : 'production') . " base={$base}\n";

$r = req('GET', '/sandbox');
echo $isProd
    ? ($r['code'] === 404 ? "[OK] /sandbox blocked\n" : "[FAIL] /sandbox expected 404 got {$r['code']}\n")
    : ($r['code'] === 200 ? "[OK] /sandbox allowed in local\n" : "[INFO] /sandbox code {$r['code']}\n");

$r = req('POST', '/v1/auth/login', ['email' => 'x@test.czedr', 'password' => 'LongPassword1!']);
echo $isProd
    ? ($r['code'] === 404 ? "[OK] plain login blocked\n" : "[FAIL] plain login expected 404 got {$r['code']}\n")
    : "[SKIP] plain login block only tested when APP_ENV=production\n";

$r = req('POST', '/login', ['user_email' => 'x@test.czedr', 'user_pwd' => 'x']);
echo $isProd
    ? ($r['code'] === 404 ? "[OK] legacy /login not registered\n" : "[INFO] legacy /login code {$r['code']}\n")
    : "[SKIP] legacy routes only disabled in production\n";

echo "Done.\n";
