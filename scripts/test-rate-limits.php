<?php
declare(strict_types=1);

/**
 * Verifies auth rate limits return HTTP 429 after repeated failures.
 * Run: php scripts/test-rate-limits.php
 * Requires API on http://127.0.0.1:8080 and APP_ENV=local.
 */

$base = getenv('CZEDR_API_BASE') ?: 'http://127.0.0.1:8080';

function post(string $path, array $body): array
{
    global $base;
    $ch = curl_init($base . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
        CURLOPT_POSTFIELDS => json_encode($body),
    ]);
    $raw = (string) curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw, true);

    return ['code' => $code, 'raw' => $raw, 'json' => $json];
}

echo "Login rate limit (expect 429 on attempt 11)...\n";
$got429 = false;
$email = 'ratelimit_' . bin2hex(random_bytes(4)) . '@example.com';
for ($i = 1; $i <= 12; $i++) {
    $res = post('/v1/auth/login', [
        'email' => $email,
        'password' => 'WrongPass123!',
    ]);
    if ($res['code'] === 429) {
        echo "  attempt {$i}: HTTP 429 OK\n";
        $got429 = true;
        break;
    }
    if ($i <= 10 && $res['code'] !== 400) {
        throw new RuntimeException("Expected 400 on attempt {$i}, got {$res['code']}: {$res['raw']}");
    }
    if ($i > 10) {
        echo "  attempt {$i}: HTTP {$res['code']}\n";
    }
}
if (!$got429) {
    throw new RuntimeException('Rate limit did not trigger after 12 login attempts');
}

echo "Reserved Czedr ID block...\n";
$reg = post('/v1/auth/register', [
    'email' => 'reserved_' . bin2hex(random_bytes(3)) . '@czedr.local',
    'password' => 'TestPass1234!',
    'czedr_id' => 'REVENUE',
]);
if ($reg['code'] !== 400) {
    throw new RuntimeException('Expected 400 for REVENUE czedr_id, got ' . $reg['code']);
}
$msg = $reg['json']['Data'][0]['result'] ?? '';
if (!str_contains((string) $msg, 'not available')) {
    throw new RuntimeException('Unexpected message: ' . $msg);
}
echo "  REVENUE blocked OK\n";

echo "Rate limit tests passed.\n";
