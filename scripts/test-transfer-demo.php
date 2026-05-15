<?php
declare(strict_types=1);

/**
 * Two-user internal ledger transfer demo (no bank).
 * Run with API server: php scripts/test-transfer-demo.php
 */

$base = 'http://127.0.0.1:8080';

function api(string $method, string $path, ?array $body = null, ?string $token = null): array
{
    global $base;
    $ch = curl_init($base . $path);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) {
        $headers[] = 'Authorization: Bearer ' . $token;
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body, JSON_THROW_ON_ERROR));
    }
    $raw = curl_exec($ch);
    if ($raw === false) {
        throw new RuntimeException('curl: ' . curl_error($ch));
    }
    $json = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
    if (($json['Status'] ?? '') !== 'true') {
        throw new RuntimeException($raw);
    }
    return $json['Data'];
}

echo "=== Czedr two-user transfer demo ===\n\n";

$emailA = 'alice_' . bin2hex(random_bytes(3)) . '@czedr.local';
$emailB = 'bob_' . bin2hex(random_bytes(3)) . '@czedr.local';
$pass = 'SecurePass123!';

echo "Register Alice...\n";
$alice = api('POST', '/v1/auth/register', ['email' => $emailA, 'password' => $pass]);
$tokenA = $alice['auth_token'];
$czedrA = $alice['user']['czedr_id'];
echo "  Czedr ID: {$czedrA}\n";

echo "Register Bob...\n";
$bob = api('POST', '/v1/auth/register', ['email' => $emailB, 'password' => $pass]);
$tokenB = $bob['auth_token'];
$czedrB = $bob['user']['czedr_id'];
echo "  Czedr ID: {$czedrB}\n";

echo "Load Alice balance \$100.00...\n";
api('POST', '/v1/ledger/load', [
    'amount_cents' => 10000,
    'idempotency_key' => 'demo-load-' . bin2hex(random_bytes(4)),
    'memo' => 'Demo load',
], $tokenA);

$bal = api('GET', '/v1/ledger/balance', null, $tokenA);
echo "  Alice balance: " . ($bal['balance_cents'] / 100) . " USD\n";

echo "Alice pays Bob \$25.50...\n";
$txn = api('POST', '/v1/transfers', [
    'to_czedr_id' => $czedrB,
    'amount_cents' => 2550,
    'idempotency_key' => 'demo-txn-' . bin2hex(random_bytes(4)),
    'memo' => 'Demo payment',
], $tokenA);
echo "  Transaction: {$txn['id']} status={$txn['status']}\n";

$balA = api('GET', '/v1/ledger/balance', null, $tokenA);
$balB = api('GET', '/v1/ledger/balance', null, $tokenB);
echo "\nFinal balances:\n";
echo "  Alice: " . ($balA['balance_cents'] / 100) . " USD\n";
echo "  Bob:   " . ($balB['balance_cents'] / 100) . " USD\n";
echo "\nDemo complete. Use these IDs in the iOS Make Payment screen.\n";
echo "  Alice: {$czedrA} ({$emailA})\n";
echo "  Bob:   {$czedrB} ({$emailB})\n";
echo "  Password (both): {$pass}\n";
