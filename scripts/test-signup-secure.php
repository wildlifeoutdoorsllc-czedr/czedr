<?php
declare(strict_types=1);

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Auth\SignupChallengeService;
use Czedr\Security\SecurePayloadCryptor;

$base = 'http://127.0.0.1:8080';

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

echo "Signup challenge...\n";
$challenge = api('GET', '/v1/auth/signup-challenge');
$challengeId = $challenge['challenge_id'];
$imageUrl = $challenge['image_url'] ?? '';
echo "  challenge_id: {$challengeId}\n";
echo "  image_url: {$imageUrl}\n";

$svc = new SignupChallengeService();
if (!empty($challenge['image_b64'])) {
    $imageBytes = base64_decode((string) $challenge['image_b64'], true);
    if ($imageBytes === false || strlen($imageBytes) < 256) {
        throw new RuntimeException('Invalid image_b64 in challenge');
    }
} else {
    $imageBytes = $svc->fetchImageBytes($imageUrl);
}
$payload = json_encode([
    'email' => 'secure_' . bin2hex(random_bytes(3)) . '@czedr.local',
    'password' => 'SecurePass123!',
    'user_name' => 'Secure User',
    'mobile_no' => '5550100',
], JSON_THROW_ON_ERROR);

$enc = SecurePayloadCryptor::encryptJson($payload, $imageBytes, $challengeId);
$cryptoVersion = (int) ($challenge['crypto_version'] ?? 2);

echo "Register secure (crypto v{$cryptoVersion})...\n";
$reg = api('POST', '/v1/auth/register-secure', [
    'challenge_id' => $challengeId,
    'enc_data' => $enc,
    'crypto_version' => $cryptoVersion,
]);
echo "  czedr_id: " . ($reg['user']['czedr_id'] ?? '') . "\n";
echo "Secure signup test passed.\n";
