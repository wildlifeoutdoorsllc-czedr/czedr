<?php
declare(strict_types=1);

namespace Czedr\Moov;

/**
 * Thin Moov REST client. Implement request paths when sandbox keys are available.
 * @see docs/MOOV-ACH-FUNDING.md
 */
final class MoovHttpClient
{
    /**
     * @param array<string, mixed> $body
     * @return array<string, mixed>
     */
    public function post(string $path, array $body): array
    {
        MoovConfig::assertConfigured();
        $url = MoovConfig::baseUrl() . $path;
        $json = json_encode($body, JSON_THROW_ON_ERROR);
        $ch = curl_init($url);
        if ($ch === false) {
            throw new \RuntimeException('Moov HTTP init failed');
        }
        $secret = MoovConfig::secretKey();
        $public = MoovConfig::publicKey();
        $auth = $public !== '' ? $public . ':' . $secret : $secret;
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $json,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Accept: application/json',
                'Authorization: Basic ' . base64_encode($auth),
            ],
            CURLOPT_TIMEOUT => 30,
        ]);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);
        if ($raw === false) {
            throw new \RuntimeException('Moov request failed: ' . $err);
        }
        /** @var array<string, mixed>|null $decoded */
        $decoded = json_decode($raw, true);
        if ($code >= 400) {
            $msg = is_array($decoded) ? (string) ($decoded['error'] ?? $decoded['message'] ?? $raw) : $raw;
            throw new \RuntimeException('Moov API error (' . $code . '): ' . $msg);
        }

        return is_array($decoded) ? $decoded : [];
    }

    /** Placeholder until Drops / bank-link API is wired. */
    public function createBankLinkSession(string $moovAccountId): array
    {
        throw new \RuntimeException(
            'Moov bank link not implemented yet. See docs/MOOV-ACH-FUNDING.md and Moov Drops docs.'
        );
    }

    /** Placeholder until transfer API is wired. */
    public function createAchDebit(string $moovAccountId, string $bankAccountId, int $amountCents, string $description): array
    {
        throw new \RuntimeException(
            'Moov ACH debit not implemented yet. See docs/MOOV-ACH-FUNDING.md.'
        );
    }
}
