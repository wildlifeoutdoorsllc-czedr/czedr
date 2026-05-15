<?php
declare(strict_types=1);

/**
 * Create (or refresh login for) two demo accounts for sandbox / API testing.
 * Run: php scripts/seed-test-accounts.php
 * Requires API at http://127.0.0.1:8080 and APP_ENV=local in .env for $100 welcome balance.
 */

$base = getenv('CZEDR_API_BASE') ?: 'http://127.0.0.1:8080';

function api(string $method, string $path, ?array $body = null): array
{
    global $base;
    $ch = curl_init($base . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body, JSON_THROW_ON_ERROR));
    }
    $raw = (string) curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw, true);
    return ['code' => $code, 'json' => $json, 'raw' => $raw];
}

function registerOrLogin(string $email, string $password): array
{
    $reg = api('POST', '/v1/auth/register', ['email' => $email, 'password' => $password]);
    if (($reg['json']['Status'] ?? '') === 'true') {
        return ['action' => 'created', 'data' => $reg['json']['Data']];
    }
    $login = api('POST', '/v1/auth/login', ['user_email' => $email, 'user_pwd' => $password]);
    if (($login['json']['Status'] ?? '') === 'true') {
        return ['action' => 'existing', 'data' => $login['json']['Data']];
    }
    throw new RuntimeException("Could not register or login {$email}: " . $login['raw']);
}

$accounts = [
    [
        'label' => 'Alice (payer)',
        'email' => 'alice@test.czedr',
        'password' => 'TestPass1234!',
    ],
    [
        'label' => 'Bob (receiver)',
        'email' => 'bob@test.czedr',
        'password' => 'TestPass1234!',
    ],
];

echo "Czedr test accounts\n";
echo "API: {$base}\n";
echo str_repeat('=', 50) . "\n\n";

$health = api('GET', '/v1/health');
if (($health['json']['Status'] ?? '') !== 'true') {
    fwrite(STDERR, "API not reachable at {$base}. Start: scripts\\start-iphone-sandbox.ps1\n");
    exit(1);
}

$rows = [];
foreach ($accounts as $spec) {
    $out = registerOrLogin($spec['email'], $spec['password']);
    $d = $out['data'];
    $user = $d['user'] ?? $d;
    $czedrId = $user['czedr_id'] ?? $d['czedr_id'] ?? '';
    $token = $d['auth_token'] ?? $d['auth_code'] ?? '';

    $balCents = 0;
    if ($token !== '') {
        $ch = curl_init($base . '/v1/ledger/balance');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Accept: application/json',
                'Authorization: Bearer ' . $token,
            ],
        ]);
        $balRaw = curl_exec($ch);
        curl_close($ch);
        $balJson = json_decode((string) $balRaw, true);
        $balCents = (int) ($balJson['Data']['balance_cents'] ?? 0);
    }

    $rows[] = [
        'label' => $spec['label'],
        'email' => $spec['email'],
        'password' => $spec['password'],
        'czedr_id' => $czedrId,
        'action' => $out['action'],
        'balance' => $balCents / 100,
    ];
}

foreach ($rows as $r) {
    echo "{$r['label']}\n";
    echo "  Email:     {$r['email']}\n";
    echo "  Password:  {$r['password']}\n";
    echo "  Czedr ID:  {$r['czedr_id']}\n";
    echo "  Balance:   \${$r['balance']} USD\n";
    echo "  Status:    {$r['action']}\n\n";
}

echo "iPhone sandbox: open /sandbox → Sign in with Alice or Bob.\n";
echo "Pay Bob from Alice: Money tab → Pay Czedr ID → {$rows[1]['czedr_id']}\n";
