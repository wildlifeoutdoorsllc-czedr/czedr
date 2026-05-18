<?php
declare(strict_types=1);

/**
 * Credit $100 to Alice and Bob test accounts and print balances + REVENUE fee ledger.
 * Run: php scripts/fund-test-accounts.php
 * Requires API at http://127.0.0.1:8080 and APP_ENV=local (or CZEDR_ALLOW_LEDGER_LOAD=1).
 */

$root = dirname(__DIR__);
$base = getenv('CZEDR_API_BASE') ?: 'http://127.0.0.1:8080';

/** @return array<string, string> */
function loadDotEnv(string $path): array
{
    $vars = [];
    if (!is_readable($path)) {
        return $vars;
    }
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }
        [$k, $v] = explode('=', $line, 2);
        $vars[trim($k)] = trim($v, " \t\"'");
    }

    return $vars;
}
$password = 'TestPass1234!';
$loadCents = 10000;

function api(string $method, string $path, ?array $body = null, ?string $token = null): array
{
    global $base;
    $ch = curl_init($base . $path);
    $headers = ['Accept: application/json', 'Content-Type: application/json'];
    if ($token !== null && $token !== '') {
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
    $raw = (string) curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw, true);

    return ['code' => $code, 'json' => $json, 'raw' => $raw];
}

function login(string $email, string $password): string
{
    $login = api('POST', '/v1/auth/login', [
        'user_email' => $email,
        'user_pwd' => $password,
        'email' => $email,
        'password' => $password,
    ]);
    if (($login['json']['Status'] ?? '') !== 'true') {
        throw new RuntimeException("Login failed for {$email}: " . $login['raw']);
    }
    $data = $login['json']['Data'] ?? [];
    $token = $data['auth_code'] ?? $data['auth_token'] ?? '';
    if ($token === '') {
        throw new RuntimeException("No auth token for {$email}");
    }

    return $token;
}

function balanceCents(string $token): int
{
    $bal = api('GET', '/v1/ledger/balance', null, $token);
    if (($bal['json']['Status'] ?? '') !== 'true') {
        throw new RuntimeException('Balance failed: ' . $bal['raw']);
    }

    return (int) ($bal['json']['Data']['balance_cents'] ?? 0);
}

function loadAccount(string $email, string $password, int $cents): void
{
    $token = login($email, $password);
    $before = balanceCents($token);
    $key = 'fund-' . substr(md5($email . microtime(true)), 0, 12);
    $load = api('POST', '/v1/ledger/load', [
        'amount_cents' => $cents,
        'idempotency_key' => $key,
        'memo' => 'Test fund $100',
    ], $token);
    if (($load['json']['Status'] ?? '') !== 'true') {
        throw new RuntimeException("Ledger load failed for {$email}: " . $load['raw']);
    }
    $after = balanceCents($token);
    $czedrId = $load['json']['Data']['czedr_id'] ?? '';
    echo sprintf(
        "  %s (%s): $%s -> $%s (added $%s)\n",
        $email,
        $czedrId,
        number_format($before / 100, 2),
        number_format($after / 100, 2),
        number_format($cents / 100, 2)
    );
}

echo "Czedr fund test accounts\nAPI: {$base}\n" . str_repeat('=', 50) . "\n\n";

$health = api('GET', '/v1/health');
if (($health['json']['Status'] ?? '') !== 'true') {
    fwrite(STDERR, "API not reachable. Run START-IPHONE-TESTING.cmd first.\n");
    exit(1);
}

$env = loadDotEnv($root . '/.env');
$feeCents = (int) ($env['CZEDR_TRANSFER_FEE_CENTS'] ?? 129);
echo "Platform transfer fee: $" . number_format($feeCents / 100, 2) . " (credited to REVENUE on each send)\n\n";

echo "Loading \$100 per account...\n";
loadAccount('alice@test.czedr', $password, $loadCents);
loadAccount('bob@test.czedr', $password, $loadCents);

echo "\nREVENUE (Czedr fee) ledger:\n";
$adminToken = $env['CZEDR_ADMIN_REPORT_TOKEN'] ?? '';
if ($adminToken !== '') {
    $ch = curl_init($base . '/v1/admin/revenue-ledger');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Accept: application/json',
            'Authorization: Bearer ' . $adminToken,
        ],
    ]);
    $revRaw = (string) curl_exec($ch);
    curl_close($ch);
    $revJson = json_decode($revRaw, true);
    $revData = $revJson['Data'] ?? [];
    $revBal = (int) ($revData['balance_cents'] ?? 0);
    echo '  REVENUE balance: $' . number_format($revBal / 100, 2) . "\n";
} else {
    echo "  (Set CZEDR_ADMIN_REPORT_TOKEN in .env to print REVENUE balance here.)\n";
    echo "  After Alice pays Bob, REVENUE should increase by \$" . number_format($feeCents / 100, 2) . ".\n";
}

echo "\nValidate Bob from Alice's session (recipient display name):\n";
$aliceToken = login('alice@test.czedr', $password);
$val = api('GET', '/v1/users/validate?czedr_id=CZ93EE0AF0', null, $aliceToken);
if (($val['json']['Status'] ?? '') === 'true') {
    $d = $val['json']['Data'] ?? [];
    echo '  display_name: ' . ($d['display_name'] ?? '?') . "\n";
} else {
    echo '  validate failed: ' . $val['raw'] . "\n";
}

echo "\nDone. Send a payment from Alice to Bob, then re-run this script to see REVENUE increase by \$"
    . number_format($feeCents / 100, 2) . ".\n";
