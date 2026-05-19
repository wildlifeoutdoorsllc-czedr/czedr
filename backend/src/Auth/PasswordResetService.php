<?php
declare(strict_types=1);

namespace Czedr\Auth;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Support\Env;
use Czedr\Support\Uuid;
use PDO;

final class PasswordResetService
{
    private const TOKEN_BYTES = 32;
    private const EXPIRY_MINUTES = 60;

    public function __construct(private readonly AuditService $audit)
    {
    }

    /**
     * @return array{message: string, reset_token?: string, reset_url?: string, expires_in_minutes?: int}
     */
    public function requestReset(string $email, ?string $ip, ?string $userAgent): array
    {
        $email = strtolower(trim($email));
        if (!$this->isValidEmail($email)) {
            throw new \InvalidArgumentException('Please enter a valid email address');
        }

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id FROM users WHERE email = :email AND status = \'active\' LIMIT 1'
        );
        $stmt->execute(['email' => $email]);
        $userId = $stmt->fetchColumn();

        $message = 'If an account exists for this email, password reset instructions have been sent.';

        if ($userId === false) {
            $this->audit->log(null, 'auth.forgot_password_unknown', 'user', null, $ip, $userAgent, ['email' => $email]);
            return ['message' => $message];
        }

        $userId = (string) $userId;
        $token = $this->generateToken();
        $tokenHash = hash('sha256', $token);

        $pdo->prepare(
            'UPDATE password_reset_tokens SET used_at = NOW()
             WHERE user_id = :uid AND used_at IS NULL'
        )->execute(['uid' => $userId]);

        $stmt = $pdo->prepare(
            'INSERT INTO password_reset_tokens (id, user_id, token_hash, expires_at)
             VALUES (:id, :uid, :hash, DATE_ADD(NOW(), INTERVAL :mins MINUTE))'
        );
        $stmt->execute([
            'id' => Uuid::v4(),
            'uid' => $userId,
            'hash' => $tokenHash,
            'mins' => self::EXPIRY_MINUTES,
        ]);

        $this->audit->log($userId, 'auth.forgot_password', 'user', $userId, $ip, $userAgent, []);
        $this->deliverResetToken($email, $token);

        $out = ['message' => $message, 'expires_in_minutes' => self::EXPIRY_MINUTES];

        if (Env::isLocal()) {
            $base = rtrim(Env::get('APP_PUBLIC_URL', 'http://127.0.0.1:8080') ?? 'http://127.0.0.1:8080', '/');
            $out['reset_token'] = $token;
            $out['reset_url'] = $base . '/sandbox#reset=' . urlencode($token);
        }

        return $out;
    }

    public function resetPassword(string $token, string $newPassword, ?string $ip, ?string $userAgent): void
    {
        if (strlen($newPassword) < 10) {
            throw new \InvalidArgumentException('Password must be at least 10 characters');
        }

        $token = trim($token);
        if ($token === '') {
            throw new \InvalidArgumentException('Reset token is required');
        }

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT t.id, t.user_id FROM password_reset_tokens t
             WHERE t.token_hash = :hash AND t.used_at IS NULL AND t.expires_at > NOW()
             LIMIT 1'
        );
        $stmt->execute(['hash' => hash('sha256', $token)]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            throw new \InvalidArgumentException('This reset link is invalid or has expired');
        }

        $userId = (string) $row['user_id'];
        $hash = password_hash($newPassword, PASSWORD_ARGON2ID);

        $pdo->prepare('UPDATE users SET password_hash = :hash WHERE id = :id')
            ->execute(['hash' => $hash, 'id' => $userId]);

        $pdo->prepare('UPDATE password_reset_tokens SET used_at = NOW() WHERE id = :id')
            ->execute(['id' => $row['id']]);

        $pdo->prepare(
            'UPDATE auth_sessions SET revoked_at = NOW() WHERE user_id = :uid AND revoked_at IS NULL'
        )->execute(['uid' => $userId]);

        $this->audit->log($userId, 'auth.password_reset', 'user', $userId, $ip, $userAgent, []);
    }

    private function generateToken(): string
    {
        return rtrim(strtr(base64_encode(random_bytes(self::TOKEN_BYTES)), '+/', '-_'), '=');
    }

    private function isValidEmail(string $email): bool
    {
        if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return true;
        }
        return (bool) preg_match('/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$/i', $email);
    }

    private function deliverResetToken(string $email, string $token): void
    {
        $logDir = dirname(__DIR__, 3) . '/storage/logs';
        if (!is_dir($logDir)) {
            mkdir($logDir, 0755, true);
        }
        if (Env::isLocal()) {
            $line = sprintf(
                "[%s] password reset for %s token=%s\n",
                date('c'),
                $email,
                $token
            );
        } else {
            $line = sprintf(
                "[%s] password reset requested for %s token_hash=%s\n",
                date('c'),
                $email,
                hash('sha256', $token)
            );
        }
        file_put_contents($logDir . '/password-reset.log', $line, FILE_APPEND | LOCK_EX);

        // Production: integrate SMTP / SendGrid / SES using MAIL_* env vars.
        if (!Env::isLocal()) {
            return;
        }
    }
}
