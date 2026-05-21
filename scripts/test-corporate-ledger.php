<?php
declare(strict_types=1);

/**
 * Verifies CORPORATE ledger: fee in, referral out from corporate when referee pays.
 * Requires APP_ENV=local, API on http://127.0.0.1:8080, CZEDR_ADMIN_REPORT_TOKEN in .env.
 */

$root = dirname(__DIR__);
require $root . '/backend/vendor/autoload.php';

use Czedr\Ledger\LedgerService;
use Czedr\Support\Env;

Env::load($root . '/.env');

$base = 'http://127.0.0.1:8080';
$adminToken = Env::get('CZEDR_ADMIN_REPORT_TOKEN', '');
if ($adminToken === '') {
    fwrite(STDERR, "Set CZEDR_ADMIN_REPORT_TOKEN in .env to run this test.\n");
    exit(1);
}

function api(string $method, string $path, ?array $body, ?string $token): array
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
        throw new RuntimeException(curl_error($ch));
    }
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
    if ($code >= 400 || ($json['Status'] ?? '') !== 'true') {
        throw new RuntimeException("HTTP {$code}: {$raw}");
    }
    return $json['Data'];
}

$fee = LedgerService::transferFeeCents();
$reward = LedgerService::referralRewardCents();
echo "Configured fee={$fee}c referral={$reward}c\n";

$referrerEmail = 'corp_ref_' . bin2hex(random_bytes(3)) . '@czedr.local';
$refereeEmail = 'corp_refee_' . bin2hex(random_bytes(3)) . '@czedr.local';

echo "Register referrer...\n";
$refReg = api('POST', '/v1/auth/register', [
    'email' => $referrerEmail,
    'password' => 'SecurePass123!',
], null);
$referrerId = $refReg['user']['czedr_id'];
$referrerTok = $refReg['auth_token'];
api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $referrerTok);
api('POST', '/v1/ledger/load', [
    'amount_cents' => 50000,
    'idempotency_key' => 'corp-ref-load-' . bin2hex(random_bytes(4)),
], $referrerTok);

echo "Register referee with referrer {$referrerId}...\n";
$reeReg = api('POST', '/v1/auth/register', [
    'email' => $refereeEmail,
    'password' => 'SecurePass123!',
    'referrer_czedr_id' => $referrerId,
], null);
$recipientId = $reeReg['user']['czedr_id'];
$reeTok = $reeReg['auth_token'];
api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $reeTok);
api('POST', '/v1/ledger/load', [
    'amount_cents' => 50000,
    'idempotency_key' => 'corp-ree-load-' . bin2hex(random_bytes(4)),
], $reeTok);

echo "Referee pays recipient (triggers fee + referral)...\n";
$xfer = api('POST', '/v1/transfers', [
    'to_czedr_id' => $referrerId,
    'amount_cents' => 1000,
    'memo' => 'Corporate ledger test',
    'user_pin' => '1234',
], $reeTok);

if (($xfer['fee_cents'] ?? 0) !== $fee) {
    throw new RuntimeException('Unexpected fee_cents on transfer response');
}
$expectedNet = $fee - $reward;
if (($xfer['corporate_net_cents'] ?? -1) !== $expectedNet) {
    throw new RuntimeException("Expected corporate_net_cents={$expectedNet}, got " . json_encode($xfer['corporate_net_cents'] ?? null));
}

echo "Admin corporate ledger...\n";
$ch = curl_init($base . '/v1/admin/corporate-ledger');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Accept: application/json',
        'X-Czedr-Admin-Token: ' . $adminToken,
    ],
]);
$raw = curl_exec($ch);
curl_close($ch);
$corp = json_decode($raw, true, 512, JSON_THROW_ON_ERROR)['Data'] ?? [];
print_r($corp);

if (($corp['czedr_id'] ?? '') !== 'CORPORATE') {
    throw new RuntimeException('Expected czedr_id CORPORATE');
}
if (($corp['fees_collected_cents'] ?? 0) < $fee) {
    throw new RuntimeException('fees_collected_cents too low');
}
if (($corp['referrals_paid_cents'] ?? 0) < $reward) {
    throw new RuntimeException('referrals_paid_cents too low');
}
if (($corp['balance_cents'] ?? -1) < $expectedNet) {
    throw new RuntimeException('balance_cents should be at least net fee minus referral');
}

echo "Dual-referral transfer (sender + recipient each referred)...\n";
$aliceEmail = 'corp_alice_' . bin2hex(random_bytes(3)) . '@czedr.local';
$bobEmail = 'corp_bob_' . bin2hex(random_bytes(3)) . '@czedr.local';
$payerEmail = 'corp_pay_' . bin2hex(random_bytes(3)) . '@czedr.local';
$payeeEmail = 'corp_ee_' . bin2hex(random_bytes(3)) . '@czedr.local';

$aliceReg = api('POST', '/v1/auth/register', [
    'email' => $aliceEmail,
    'password' => 'SecurePass123!',
], null);
$aliceId = $aliceReg['user']['czedr_id'];
$aliceTok = $aliceReg['auth_token'];
api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $aliceTok);
api('POST', '/v1/ledger/load', [
    'amount_cents' => 50000,
    'idempotency_key' => 'corp-alice-load-' . bin2hex(random_bytes(4)),
], $aliceTok);

$bobReg = api('POST', '/v1/auth/register', [
    'email' => $bobEmail,
    'password' => 'SecurePass123!',
], null);
$bobId = $bobReg['user']['czedr_id'];
$bobTok = $bobReg['auth_token'];
api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $bobTok);
api('POST', '/v1/ledger/load', [
    'amount_cents' => 50000,
    'idempotency_key' => 'corp-bob-load-' . bin2hex(random_bytes(4)),
], $bobTok);

$payerReg = api('POST', '/v1/auth/register', [
    'email' => $payerEmail,
    'password' => 'SecurePass123!',
    'referrer_czedr_id' => $aliceId,
], null);
$payerId = $payerReg['user']['czedr_id'];
$payerTok = $payerReg['auth_token'];
api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $payerTok);
api('POST', '/v1/ledger/load', [
    'amount_cents' => 50000,
    'idempotency_key' => 'corp-payer-load-' . bin2hex(random_bytes(4)),
], $payerTok);

$payeeReg = api('POST', '/v1/auth/register', [
    'email' => $payeeEmail,
    'password' => 'SecurePass123!',
    'referrer_czedr_id' => $bobId,
], null);
$payeeId = $payeeReg['user']['czedr_id'];
$payeeTok = $payeeReg['auth_token'];
api('POST', '/v1/auth/pin/set', ['user_pin' => '1234'], $payeeTok);

$dualXfer = api('POST', '/v1/transfers', [
    'to_czedr_id' => $payeeId,
    'amount_cents' => 1000,
    'memo' => 'Dual referral test',
    'user_pin' => '1234',
], $payerTok);

$expectedDualReferral = $reward * 2;
if (($dualXfer['referral_reward_cents'] ?? 0) !== $expectedDualReferral) {
    throw new RuntimeException(
        "Expected referral_reward_cents={$expectedDualReferral}, got " . json_encode($dualXfer['referral_reward_cents'] ?? null)
    );
}
$expectedDualNet = $fee - $expectedDualReferral;
if (($dualXfer['corporate_net_cents'] ?? -1) !== $expectedDualNet) {
    throw new RuntimeException(
        "Expected corporate_net_cents={$expectedDualNet}, got " . json_encode($dualXfer['corporate_net_cents'] ?? null)
    );
}
if (($dualXfer['referral_payout_count'] ?? 0) !== 2) {
    throw new RuntimeException('Expected referral_payout_count=2');
}

echo "Register without referrer (optional field)...\n";
$soloReg = api('POST', '/v1/auth/register', [
    'email' => 'corp_solo_' . bin2hex(random_bytes(3)) . '@czedr.local',
    'password' => 'SecurePass123!',
], null);
if (!empty($soloReg['user']['referred_by_user_id'] ?? null)) {
    throw new RuntimeException('Solo signup should not have referred_by_user_id');
}

echo "Corporate ledger test passed.\n";
