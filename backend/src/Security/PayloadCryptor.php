<?php
declare(strict_types=1);

namespace Czedr\Security;

/** Routes secure payloads to v2 (GCM) or legacy v1 (ECB). */
final class PayloadCryptor
{
    public static function decrypt(string $encBase64, string $imageBytes, string $challengeId, int $cryptoVersion = 0): string
    {
        if ($cryptoVersion === 2 || SecurePayloadCryptor::isV2Payload($encBase64)) {
            return SecurePayloadCryptor::decryptBase64Payload($encBase64, $imageBytes, $challengeId);
        }

        return ImageDerivedCryptor::decryptBase64Payload($encBase64, $imageBytes, $challengeId);
    }
}
