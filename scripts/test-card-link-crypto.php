<?php
declare(strict_types=1);

require dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Security\SecurePayloadCryptor;

$image = random_bytes(8192);
$userId = 'user-' . bin2hex(random_bytes(8));
$payload = json_encode([
    'name' => 'Test Card',
    'card_no' => '4111111111111111',
    'cvv' => '123',
    'date' => '12/30',
    'type' => 'visa',
    'default' => '0',
], JSON_THROW_ON_ERROR);

$enc = SecurePayloadCryptor::encryptCardJson($payload, $image, $userId);
$plain = SecurePayloadCryptor::decryptCardBase64($enc, $image, $userId);

if ($plain !== $payload) {
    fwrite(STDERR, "Card-link crypto roundtrip mismatch\n");
    exit(1);
}

echo "Card-link AES-256-GCM + HKDF roundtrip OK.\n";
