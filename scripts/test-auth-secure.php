<?php
declare(strict_types=1);

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Auth\SignupChallengeService;
use Czedr\Security\ImageDerivedCryptor;

$base = 'http://127.0.0.1:8080';

function api(string $method, string $path, ?array $body = null, ?string $bearer = null): array
{
    global $base;
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($bearer) {
        $headers[] = 'Authorization: Bearer ' . $bearer;
    }
    $ch = curl_init($base . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode((string) $raw, true);
    if ($code >= 400 || ($json['Status'] ?? '') !== 'true') {
        throw new RuntimeException("HTTP {$code}: {$raw}");
    }
    return $json['Data'];
}

function encryptPayload(array $payload, string $challengeId, string $imageUrl): string
{
    $svc = new SignupChallengeService();
    $imageBytes = $svc->fetchImageBytes($imageUrl);
    $json = json_encode($payload, JSON_THROW_ON_ERROR);
    $key = ImageDerivedCryptor::deriveKeyString($imageBytes, $challengeId);
    $keyPadded = str_pad(substr($key, 0, 32), 32, "\0");
    $cipher = openssl_encrypt($json, 'AES-256-ECB', $keyPadded, OPENSSL_RAW_DATA);
    return base64_encode($cipher);
}

function securePost(string $path, array $payload, ?string $bearer = null): array
{
    $challenge = api('GET', '/v1/auth/signup-challenge');
    $enc = encryptPayload($payload, $challenge['challenge_id'], $challenge['image_url']);
    return api('POST', $path, [
        'challenge_id' => $challenge['challenge_id'],
        'enc_data' => $enc,
    ], $bearer);
}

$email = 'authsec_' . bin2hex(random_bytes(3)) . '@czedr.local';
$password = 'SecurePass123!';
$pin = '4321';

echo "Register (plaintext) for test user...\n";
$reg = api('POST', '/v1/auth/register', [
    'email' => $email,
    'password' => $password,
]);
$token = $reg['auth_token'];
echo "  czedr_id: " . ($reg['user']['czedr_id'] ?? '') . "\n";

echo "Login secure...\n";
$login = securePost('/v1/auth/login-secure', [
    'user_email' => $email,
    'user_pwd' => $password,
]);
$token = $login['auth_code'] ?? $token;
echo "  user_pin flag: " . ($login['user_pin'] ?? '?') . "\n";

echo "Set PIN secure...\n";
securePost('/v1/auth/pin/set-secure', ['user_pin' => $pin], $token);

echo "Verify PIN secure...\n";
$verify = securePost('/v1/auth/pin/verify-secure', ['user_pin' => $pin], $token);
echo "  result: " . ($verify['result'] ?? 'ok') . "\n";

echo "Update PIN secure...\n";
securePost('/v1/auth/pin/update-secure', ['old_pin' => $pin, 'new_pin' => '5678'], $token);

echo "Verify new PIN...\n";
securePost('/v1/auth/pin/verify-secure', ['user_pin' => '5678'], $token);

echo "Secure auth (login + PIN) test passed.\n";
