<?php
declare(strict_types=1);

namespace Czedr\Auth;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Ledger\LedgerService;
use Czedr\Support\Env;
use Czedr\Support\Uuid;
use PDO;

final class AuthService
{
    private const TOKEN_BYTES = 32;
    private const SESSION_DAYS = 30;

    public function __construct(
        private readonly AuditService $audit,
        private readonly LedgerService $ledger,
    ) {
    }

    /**
     * @return array{user: array<string, mixed>, auth_token: string}
     */
    public function register(
        string $email,
        string $password,
        ?string $czedrId,
        ?string $ip,
        ?string $userAgent,
    ): array {
        $email = strtolower(trim($email));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException('Invalid email');
        }
        if (strlen($password) < 10) {
            throw new \InvalidArgumentException('Password must be at least 10 characters');
        }

        $userId = Uuid::v4();
        $czedrId = $czedrId ?: $this->generateCzedrId();
        $hash = password_hash($password, PASSWORD_ARGON2ID);

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO users (id, czedr_id, email, password_hash) VALUES (:id, :cid, :email, :hash)'
        );
        try {
            $stmt->execute(['id' => $userId, 'cid' => $czedrId, 'email' => $email, 'hash' => $hash]);
        } catch (\PDOException $e) {
            if ($e->getCode() === '23000') {
                throw new \InvalidArgumentException('Email or Czedr ID already exists');
            }
            throw $e;
        }

        $this->ledger->ensureAccount($userId);
        if (Env::get('APP_ENV', 'local') === 'local') {
            $this->ledger->credit(
                $userId,
                10000,
                'welcome-' . $userId,
                'Welcome balance (local dev only)',
                $ip,
                $userAgent
            );
        }
        $token = $this->createSession($userId);
        $this->audit->log($userId, 'auth.register', 'user', $userId, $ip, $userAgent, []);

        return [
            'user' => $this->findUserById($userId),
            'auth_token' => $token,
        ];
    }

    /**
     * @return array{user: array<string, mixed>, auth_token: string}
     */
    public function login(string $email, string $password, ?string $ip, ?string $userAgent): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email AND status = \'active\' LIMIT 1');
        $stmt->execute(['email' => strtolower(trim($email))]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$user || !password_verify($password, $user['password_hash'])) {
            $this->audit->log(null, 'auth.login_failed', 'user', null, $ip, $userAgent, ['email' => $email]);
            throw new \InvalidArgumentException('Invalid credentials');
        }
        $token = $this->createSession($user['id']);
        $this->audit->log($user['id'], 'auth.login', 'user', $user['id'], $ip, $userAgent, []);
        unset($user['password_hash'], $user['pin_hash']);

        return ['user' => $this->publicUserRow($user), 'auth_token' => $token];
    }

    public function logout(string $tokenHash): void
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('UPDATE auth_sessions SET revoked_at = NOW() WHERE token_hash = :hash');
        $stmt->execute(['hash' => $tokenHash]);
    }

    public function resolveUserId(string $bearerToken): ?string
    {
        $hash = hash('sha256', $bearerToken);
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT user_id FROM auth_sessions
             WHERE token_hash = :hash AND revoked_at IS NULL AND expires_at > NOW() LIMIT 1'
        );
        $stmt->execute(['hash' => $hash]);
        $uid = $stmt->fetchColumn();
        return $uid !== false ? (string) $uid : null;
    }

    public static function hashToken(string $token): string
    {
        return hash('sha256', $token);
    }

    public function hasPinSet(string $userId): bool
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT pin_hash FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $hash = $stmt->fetchColumn();
        return is_string($hash) && $hash !== '';
    }

    /** Legacy flag: "1" if PIN configured, "0" otherwise. */
    public function userPinFlag(string $userId): string
    {
        return $this->hasPinSet($userId) ? '1' : '0';
    }

    public function verifyPin(string $userId, string $pin): void
    {
        $pin = $this->normalizePin($pin);
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT pin_hash FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $hash = $stmt->fetchColumn();
        if (!is_string($hash) || $hash === '' || !password_verify($pin, $hash)) {
            throw new \InvalidArgumentException('The entered PIN number is not correct.');
        }
    }

    /** Payments and invoices require a configured PIN (matches product security model). */
    public function requirePinForPayment(string $userId, string $pin): void
    {
        if (!$this->hasPinSet($userId)) {
            throw new \InvalidArgumentException('You must set a 4-digit PIN before sending money');
        }
        $this->verifyPin($userId, $pin);
    }

    public function setPin(string $userId, string $pin): void
    {
        $pin = $this->normalizePin($pin);
        $hash = password_hash($pin, PASSWORD_ARGON2ID);
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('UPDATE users SET pin_hash = :hash WHERE id = :id');
        $stmt->execute(['hash' => $hash, 'id' => $userId]);
        $this->audit->log($userId, 'auth.pin_set', 'user', $userId, null, null, []);
    }

    public function changePin(string $userId, string $oldPin, string $newPin): void
    {
        $this->verifyPin($userId, $oldPin);
        $newPin = $this->normalizePin($newPin);
        if ($newPin === $this->normalizePin($oldPin)) {
            throw new \InvalidArgumentException('New PIN must be different');
        }
        $hash = password_hash($newPin, PASSWORD_ARGON2ID);
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('UPDATE users SET pin_hash = :hash WHERE id = :id');
        $stmt->execute(['hash' => $hash, 'id' => $userId]);
        $this->audit->log($userId, 'auth.pin_change', 'user', $userId, null, null, []);
    }

    private function normalizePin(string $pin): string
    {
        $pin = preg_replace('/\D/', '', $pin) ?? '';
        if (strlen($pin) !== 4) {
            throw new \InvalidArgumentException('PIN must be 4 digits');
        }
        return $pin;
    }

    private function createSession(string $userId): string
    {
        $token = rtrim(strtr(base64_encode(random_bytes(self::TOKEN_BYTES)), '+/', '-_'), '=');
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO auth_sessions (id, user_id, token_hash, expires_at)
             VALUES (:id, :uid, :hash, DATE_ADD(NOW(), INTERVAL :days DAY))'
        );
        $stmt->execute([
            'id' => Uuid::v4(),
            'uid' => $userId,
            'hash' => self::hashToken($token),
            'days' => self::SESSION_DAYS,
        ]);
        return $token;
    }

    /** @return array<string, mixed> */
    private function findUserById(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, czedr_id, email, status, created_at FROM users WHERE id = :id LIMIT 1'
        );
        $stmt->execute(['id' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException('User not found');
        }
        return $this->publicUserRow($row);
    }

    /** @param array<string, mixed> $row */
    private function publicUserRow(array $row): array
    {
        if (!isset($row['czedr_id']) && isset($row['payooze_id'])) {
            $row['czedr_id'] = $row['payooze_id'];
        }
        unset($row['payooze_id'], $row['password_hash'], $row['pin_hash']);

        return $row;
    }

    private function generateCzedrId(): string
    {
        return 'CZ' . strtoupper(bin2hex(random_bytes(4)));
    }
}
