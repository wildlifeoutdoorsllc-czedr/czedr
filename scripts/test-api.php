<?php
declare(strict_types=1);

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
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
    if ($code >= 400 || ($json['Status'] ?? '') !== 'true') {
        throw new RuntimeException("HTTP {$code}: " . $raw);
    }
    return $json['Data'];
}

function apiExpectError(string $method, string $path, ?array $body, ?string $token, int $expectCode): void
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
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($code !== $expectCode) {
        throw new RuntimeException("Expected HTTP {$expectCode}, got {$code}: {$raw}");
    }
}

echo "Health...\n";
$health = api('GET', '/v1/health');
print_r($health);
if (($health['bank_or_ach'] ?? true) !== false) {
    throw new RuntimeException('health should include bank_or_ach: false');
}

$email = 'test_' . bin2hex(random_bytes(4)) . '@czedr.local';
echo "Register {$email}...\n";
$reg = api('POST', '/v1/auth/register', [
    'email' => $email,
    'password' => 'SecurePass123!',
]);
$token = $reg['auth_token'];

api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $token);

echo "Load balance...\n";
api('POST', '/v1/ledger/load', [
    'amount_cents' => 10000,
    'idempotency_key' => 'load-' . bin2hex(random_bytes(4)),
    'memo' => 'Initial load',
], $token);

echo "Bank account POST rejected (ledger-only)...\n";
apiExpectError('POST', '/v1/bank-accounts', [
    'holder_name' => 'Test User',
    'routing' => '021000021',
    'account' => '1234567890',
    'account_type' => 'checking',
], $token, 501);

echo "List bank accounts (empty)...\n";
$accounts = api('GET', '/v1/bank-accounts', null, $token);
if (($accounts['accounts'] ?? null) !== []) {
    throw new RuntimeException('bank-accounts list should be empty');
}

echo "Balance...\n";
$bal = api('GET', '/v1/ledger/balance', null, $token);
print_r($bal);

echo "Referral earnings (authenticated)...\n";
$earn = api('GET', '/v1/referrals/earnings?recent_limit=5', null, $token);
if (!isset($earn['referral_earnings_total_cents'], $earn['credited_to_ledger_balance'])) {
    throw new RuntimeException('referrals/earnings response shape unexpected');
}

$email2 = 'test_' . bin2hex(random_bytes(4)) . '@czedr.local';
echo "Register recipient {$email2}...\n";
$reg2 = api('POST', '/v1/auth/register', [
    'email' => $email2,
    'password' => 'SecurePass123!',
]);
$recipientId = $reg2['user']['czedr_id'];

echo "Validate recipient (members see masked label, not email)...\n";
$val = api('GET', '/v1/users/validate?czedr_id=' . rawurlencode($recipientId), null, $token);
if (($val['display_name'] ?? '') === $email2 || str_contains((string) ($val['display_name'] ?? ''), '@')) {
    throw new RuntimeException('validate should not expose recipient email to normal members');
}

echo "Create invoice to {$recipientId}...\n";
api('POST', '/v1/invoices', [
    'to_czedr_id' => $recipientId,
    'amount' => '12.50',
    'desc' => 'Test invoice',
    'user_pin' => '1234',
], $token);

echo "List sent invoices...\n";
$sent = api('GET', '/v1/invoices/sent?offset=1&limit=10', null, $token);
echo '  sent count: ' . count($sent) . "\n";

echo "List received invoices (recipient)...\n";
$recvToken = $reg2['auth_token'];
$recv = api('GET', '/v1/invoices/received?offset=1&limit=10', null, $recvToken);
echo '  received count: ' . count($recv) . "\n";

echo "All API tests passed.\n";
