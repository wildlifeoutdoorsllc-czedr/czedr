<?php
declare(strict_types=1);

namespace Czedr\Auth;

use Czedr\Database\ConnectionFactory;
use Czedr\Support\Uuid;

/**
 * Picks a random public-domain image (Library of Congress) for signup payload encryption.
 */
final class SignupChallengeService
{
    private const CHALLENGE_TTL_MINUTES = 15;

    public function createChallenge(): array
    {
        $imageUrl = $this->pickLibraryOfCongressImageUrl();
        $challengeId = Uuid::v4();
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO signup_challenges (id, image_url, expires_at)
             VALUES (:id, :url, DATE_ADD(NOW(), INTERVAL :mins MINUTE))'
        );
        $stmt->execute([
            'id' => $challengeId,
            'url' => $imageUrl,
            'mins' => self::CHALLENGE_TTL_MINUTES,
        ]);

        return [
            'challenge_id' => $challengeId,
            'image_url' => $imageUrl,
        ];
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

        // Fallback: LoC static public-domain sample (no API key required)
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

    public function fetchImageBytes(string $imageUrl): string
    {
        $body = $this->httpGet($imageUrl);
        if ($body === null || strlen($body) < 256) {
            throw new \RuntimeException('Could not download challenge image');
        }
        return $body;
    }
}
