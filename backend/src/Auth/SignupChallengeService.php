<?php
declare(strict_types=1);

namespace Czedr\Auth;

use Czedr\Database\ConnectionFactory;
use Czedr\Support\Uuid;

/**
 * Picks a random public-domain image (Library of Congress) for signup payload encryption.
 * Image bytes are stored at challenge creation so phone and server use identical data.
 */
final class SignupChallengeService
{
    private const CHALLENGE_TTL_MINUTES = 15;

    public function createChallenge(): array
    {
        $imageUrl = $this->pickLibraryOfCongressImageUrl();
        $imageBytes = $this->fetchChallengeImageBytes($imageUrl);
        $imageB64 = base64_encode($imageBytes);
        $challengeId = Uuid::v4();
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO signup_challenges (id, image_url, image_b64, expires_at)
             VALUES (:id, :url, :b64, DATE_ADD(NOW(), INTERVAL :mins MINUTE))'
        );
        $stmt->execute([
            'id' => $challengeId,
            'url' => $imageUrl,
            'b64' => $imageB64,
            'mins' => self::CHALLENGE_TTL_MINUTES,
        ]);

        return [
            'challenge_id' => $challengeId,
            'image_url' => $imageUrl,
            'image_b64' => $imageB64,
            'crypto_version' => 2,
            'crypto' => 'AES-256-GCM+HKDF-SHA256',
        ];
    }

    public function resolveImageBytes(string $challengeId): string
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT image_url, image_b64 FROM signup_challenges
             WHERE id = :id AND expires_at > NOW() LIMIT 1'
        );
        $stmt->execute(['id' => $challengeId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \InvalidArgumentException('Signup challenge expired or invalid');
        }
        $b64 = $row['image_b64'] ?? null;
        if (is_string($b64) && $b64 !== '') {
            $bytes = base64_decode($b64, true);
            if ($bytes !== false && strlen($bytes) >= 256) {
                return $bytes;
            }
        }
        return $this->fetchImageBytes((string) $row['image_url']);
    }

    public function resolveImageUrl(string $challengeId): string
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT image_url FROM signup_challenges
             WHERE id = :id AND expires_at > NOW() LIMIT 1'
        );
        $stmt->execute(['id' => $challengeId]);
        $url = $stmt->fetchColumn();
        if (!$url) {
            throw new \InvalidArgumentException('Signup challenge expired or invalid');
        }
        return (string) $url;
    }

    public function consumeChallenge(string $challengeId): void
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('DELETE FROM signup_challenges WHERE id = :id');
        $stmt->execute(['id' => $challengeId]);
    }

    private function pickLibraryOfCongressImageUrl(): string
    {
        $candidates = [
            'https://www.loc.gov/pictures/search/?fo=json&sp=1&c=25&cc=true&st=gallery',
            'https://www.loc.gov/pictures/search/?fo=json&sp=2&c=25&cc=true&st=gallery',
            'https://www.loc.gov/pictures/search/?fo=json&sp=3&c=25&cc=true&st=gallery',
        ];
        shuffle($candidates);
        foreach ($candidates as $searchUrl) {
            $json = $this->httpGet($searchUrl);
            if ($json === null) {
                continue;
            }
            $data = json_decode($json, true);
            $results = $data['results'] ?? [];
            if (!is_array($results) || $results === []) {
                continue;
            }
            shuffle($results);
            foreach ($results as $item) {
                $url = $this->extractImageUrl($item);
                if ($url !== null) {
                    return $url;
                }
            }
        }

        return 'https://tile.loc.gov/image-services/iiif/service/pnp/ppmsca/25600/25600r.jpg/full/!640,640/0/default.jpg';
    }

    /** @param array<string, mixed> $item */
    private function extractImageUrl(array $item): ?string
    {
        $candidates = [
            $item['image_url'] ?? null,
            $item['display_url'] ?? null,
        ];
        if (isset($item['image']) && is_array($item['image'])) {
            $candidates[] = $item['image']['full'] ?? null;
            $candidates[] = $item['image']['url'] ?? null;
        }
        foreach ($candidates as $url) {
            if (is_string($url) && str_starts_with($url, 'http')) {
                return $url;
            }
        }
        return null;
    }

    private function httpGet(string $url): ?string
    {
        $ctx = stream_context_create([
            'http' => [
                'timeout' => 8,
                'header' => "User-Agent: CzedrSignup/1.0\r\n",
            ],
            'ssl' => [
                'verify_peer' => true,
                'verify_peer_name' => true,
            ],
        ]);
        $body = @file_get_contents($url, false, $ctx);
        return is_string($body) && $body !== '' ? $body : null;
    }

    private function fetchChallengeImageBytes(string $imageUrl): string
    {
        try {
            return $this->fetchImageBytes($imageUrl);
        } catch (\Throwable) {
            $fallback = 'https://tile.loc.gov/image-services/iiif/service/pnp/ppmsca/25600/25600r.jpg/full/!640,640/0/default.jpg';
            if ($imageUrl !== $fallback) {
                return $this->fetchImageBytes($fallback);
            }
            throw new \RuntimeException('Could not download challenge image');
        }
    }

    public function fetchImageBytes(string $imageUrl): string
    {
        $parsed = parse_url($imageUrl);
        if (!is_array($parsed) || empty($parsed['scheme'])) {
            throw new \InvalidArgumentException('Invalid challenge image URL');
        }
        $scheme = strtolower((string) $parsed['scheme']);
        if (!in_array($scheme, ['http', 'https'], true)) {
            throw new \InvalidArgumentException('Invalid challenge image URL');
        }
        $host = strtolower((string) ($parsed['host'] ?? ''));
        if ($host === '' || ($host !== 'loc.gov' && !str_ends_with($host, '.loc.gov'))) {
            throw new \InvalidArgumentException('Challenge images must be served from loc.gov');
        }
        $body = $this->httpGet($imageUrl);
        if ($body === null || strlen($body) < 256) {
            throw new \RuntimeException('Could not download challenge image');
        }
        return $body;
    }
}
