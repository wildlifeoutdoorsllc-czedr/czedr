<?php
declare(strict_types=1);

namespace Czedr\Moov;

final class MoovWebhookVerifier
{
    /**
     * Verify Moov webhook signature when MOOV_WEBHOOK_SECRET is set.
     * @see https://docs.moov.io/guides/webhooks/set-up-webhooks/
     */
    public static function verify(string $rawBody, array $headers): bool
    {
        $secret = MoovConfig::webhookSecret();
        if ($secret === '') {
            return MoovConfig::isEnabled() === false || \Czedr\Support\Env::isLocal();
        }

        $signature = self::header($headers, 'X-Signature') ?? self::header($headers, 'x-signature') ?? '';
        $timestamp = self::header($headers, 'X-Timestamp') ?? self::header($headers, 'x-timestamp') ?? '';
        $nonce = self::header($headers, 'X-Nonce') ?? self::header($headers, 'x-nonce') ?? '';
        if ($signature === '' || $timestamp === '' || $nonce === '') {
            return false;
        }

        $signed = $timestamp . '|' . $nonce . '|' . $rawBody;
        $expected = hash_hmac('sha512', $signed, $secret);

        return hash_equals($expected, $signature) || hash_equals($expected, trim($signature));
    }

    /**
     * @param array<string, string|list<string>> $headers
     */
    private static function header(array $headers, string $name): ?string
    {
        foreach ($headers as $key => $value) {
            if (strcasecmp((string) $key, $name) !== 0) {
                continue;
            }
            if (is_array($value)) {
                return (string) ($value[0] ?? '');
            }

            return (string) $value;
        }

        return null;
    }
}
