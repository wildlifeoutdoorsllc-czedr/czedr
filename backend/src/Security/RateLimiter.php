<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Database\ConnectionFactory;
use Czedr\Support\Env;
use PDO;

final class RateLimiter
{
    private const DEFAULT_MESSAGE = 'Too many attempts. Please try again later.';

    public function isEnabled(): bool
    {
        return Env::get('CZEDR_RATE_LIMIT', '1') !== '0';
    }

    public function check(string $bucket, int $maxHits, int $windowSeconds, string $message = self::DEFAULT_MESSAGE): void
    {
        if (!$this->isEnabled() || $bucket === '') {
            return;
        }
        $pdo = ConnectionFactory::saturn();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare(
                'SELECT hits, TIMESTAMPDIFF(SECOND, window_start, NOW()) AS elapsed
                 FROM rate_limit_buckets WHERE bucket = :b FOR UPDATE'
            );
            $stmt->execute(['b' => $bucket]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($row) {
                $elapsed = (int) ($row['elapsed'] ?? 0);
                if ($elapsed < $windowSeconds && (int) $row['hits'] >= $maxHits) {
                    throw new RateLimitExceededException($message);
                }
            }
            $pdo->commit();
        } catch (RateLimitExceededException $e) {
            $pdo->rollBack();
            throw $e;
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public function hit(string $bucket, int $maxHits, int $windowSeconds): void
    {
        if (!$this->isEnabled() || $bucket === '') {
            return;
        }
        $pdo = ConnectionFactory::saturn();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare(
                'SELECT hits, TIMESTAMPDIFF(SECOND, window_start, NOW()) AS elapsed
                 FROM rate_limit_buckets WHERE bucket = :b FOR UPDATE'
            );
            $stmt->execute(['b' => $bucket]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) {
                $ins = $pdo->prepare(
                    'INSERT INTO rate_limit_buckets (bucket, hits, window_start) VALUES (:b, 1, NOW())'
                );
                $ins->execute(['b' => $bucket]);
            } elseif ((int) ($row['elapsed'] ?? 0) >= $windowSeconds) {
                $upd = $pdo->prepare(
                    'UPDATE rate_limit_buckets SET hits = 1, window_start = NOW() WHERE bucket = :b'
                );
                $upd->execute(['b' => $bucket]);
            } else {
                $upd = $pdo->prepare(
                    'UPDATE rate_limit_buckets SET hits = hits + 1 WHERE bucket = :b'
                );
                $upd->execute(['b' => $bucket]);
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    public static function clientIp(?string $ip): string
    {
        $ip = trim((string) $ip);
        if ($ip === '') {
            return 'unknown';
        }

        return $ip;
    }

    public static function emailBucket(string $email): string
    {
        return 'email:' . hash('sha256', strtolower(trim($email)));
    }
}
