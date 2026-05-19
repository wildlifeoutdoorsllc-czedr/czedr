<?php
declare(strict_types=1);

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Security\SecurePayloadCryptor;

$image = random_bytes(4096);
$challengeId = 'test-challenge-' . bin2hex(random_bytes(8));
$payload = json_encode(['email' => 'gcm@test.czedr', 'password' => 'TestPass1234!'], JSON_THROW_ON_ERROR);

$enc = SecurePayloadCryptor::encryptJson($payload, $image, $challengeId);
$plain = SecurePayloadCryptor::decryptBase64Payload($enc, $image, $challengeId);

if ($plain !== $payload) {
    fwrite(STDERR, "Roundtrip mismatch\n");
    exit(1);
}

echo "AES-256-GCM + HKDF roundtrip OK.\n";
