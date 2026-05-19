<?php
declare(strict_types=1);

namespace Czedr\Auth;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Ledger\LedgerService;
use Czedr\Security\ReservedCzedrIds;
use Czedr\Support\Env;
use Czedr\Support\Uuid;
use PDO;

final class AuthService
{
    private const TOKEN_BYTES = 32;
    private const SESSION_DAYS = 30;
    private const PIN_MAX_FAILURES = 5;
    private const PIN_LOCKOUT_MINUTES = 30;

    public function __construct(
        private readonly AuditService $audit,
        private readonly LedgerService $ledger,
    ) {
    }

    /** @param array<string, mixed> $body */
    public static function optionalReferrerFromSignupBody(array $body): ?string
    {
        foreach (['referrer_czedr_id', 'referred_by_czedr_id', 'referrer_payooze_id'] as $key) {
            if (!empty($body[$key])) {
                return (string) $body[$key];
            }
        }

        return null;
    }

    /**
     * @return array{user: array<string, mixed>, auth_token: string}
     */
    public function register(
        string $email,
        string $password,
        ?string $czedrId,
        ?string $referrerCzedrId,
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
        $czedrId = strtoupper(trim($czedrId));
        ReservedCzedrIds::assertAvailable($czedrId);

        $referrerUserId = $this->resolveReferrerUserId($referrerCzedrId);
        if ($referrerUserId !== null && $czedrId === strtoupper(trim((string) $referrerCzedrId))) {
            throw new \InvalidArgumentException('Referrer cannot be the same as your Czedr ID');
        }

        $hash = password_hash($password, PASSWORD_ARGON2ID);

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO users (id, czedr_id, email, password_hash, referred_by_user_id) VALUES (:id, :cid, :email, :hash, :ref)'
        );
        try {
            $stmt->execute([
                'id' => $userId,
                'cid' => $czedrId,
                'email' => $email,
                'hash' => $hash,
                'ref' => $referrerUserId,
            ]);
        } catch (\PDOException $e) {
            if ($e->getCode() === '23000') {
                throw new \InvalidArgumentException('Email or Czedr ID already exists');
            }
            throw $e;
        }

        $this->ledger->ensureAccount($userId);
        if (Env::isLocal()) {
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
        $meta = [];
        if ($referrerUserId !== null) {
            $meta['referred_by_user_id'] = $referrerUserId;
        }
        $this->audit->log($userId, 'auth.register', 'user', $userId, $ip, $userAgent, $meta);

        return [
            'user' => $this->findUserById($userId),
            'auth_token' => $token,
        ];
    }

    /** @return non-empty-string|null */
    private function resolveReferrerUserId(?string $referrerCzedrId): ?string
    {
        if ($referrerCzedrId === null || trim($referrerCzedrId) === '') {
            return null;
        }
        $cid = strtoupper(trim($referrerCzedrId));
        if (in_array($cid, ['SYSTEM', 'REVENUE'], true)) {
            throw new \InvalidArgumentException('Invalid referrer Czedr ID');
        }

        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT id FROM users WHERE czedr_id = :cid AND status = \'active\' LIMIT 1');
        $stmt->execute(['cid' => $cid]);
        $id = $stmt->fetchColumn();
        if (!$id) {
            throw new \InvalidArgumentException('Referrer Czedr ID not found');
        }

        return (string) $id;
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
        if (in_array((string) ($user['czedr_id'] ?? ''), ['SYSTEM', 'REVENUE'], true)) {
            $this->audit->log(null, 'auth.login_failed', 'user', null, $ip, $userAgent, ['email' => $email, 'reason' => 'internal_ledger_user']);
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
        $this->assertPinNotLocked($userId);
        $pin = $this->normalizePin($pin);
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare('SELECT pin_hash FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $hash = $stmt->fetchColumn();
        if (!is_string($hash) || $hash === '' || !password_verify($pin, $hash)) {
            $this->recordPinFailure($userId);
            throw new \InvalidArgumentException('The entered PIN number is not correct.');
        }
        $this->clearPinFailures($userId);
    }

    public function assertPinNotLocked(string $userId): void
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT 1 FROM users WHERE id = :id AND pin_locked_until IS NOT NULL AND pin_locked_until > NOW() LIMIT 1'
        );
        $stmt->execute(['id' => $userId]);
        if ($stmt->fetchColumn()) {
            throw new \InvalidArgumentException(
                'PIN is temporarily locked after too many failed attempts. Try again later.'
            );
        }
    }

    private function recordPinFailure(string $userId): void
    {
        $pdo = ConnectionFactory::saturn();
        $pdo->prepare(
            'UPDATE users SET pin_failed_attempts = pin_failed_attempts + 1 WHERE id = :id'
        )->execute(['id' => $userId]);
        $stmt = $pdo->prepare(
            'SELECT pin_failed_attempts FROM users WHERE id = :id LIMIT 1'
        );
        $stmt->execute(['id' => $userId]);
        $failures = (int) $stmt->fetchColumn();
        if ($failures >= self::PIN_MAX_FAILURES) {
            $pdo->prepare(
                'UPDATE users SET pin_locked_until = DATE_ADD(NOW(), INTERVAL :mins MINUTE) WHERE id = :id'
            )->execute(['id' => $userId, 'mins' => self::PIN_LOCKOUT_MINUTES]);
            $this->audit->log($userId, 'auth.pin_locked', 'user', $userId, null, null, [
                'failures' => $failures,
                'minutes' => self::PIN_LOCKOUT_MINUTES,
            ]);
        }
    }

    private function clearPinFailures(string $userId): void
    {
        $pdo = ConnectionFactory::saturn();
        $pdo->prepare(
            'UPDATE users SET pin_failed_attempts = 0, pin_locked_until = NULL WHERE id = :id'
        )->execute(['id' => $userId]);
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
    public function userProfile(string $userId): array
    {
        return $this->findUserById($userId);
    }

    /** @return array<string, mixed> */
    private function findUserById(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $cols = self::usersTableHasRoleColumn($pdo)
            ? 'id, czedr_id, email, status, role, created_at'
            : 'id, czedr_id, email, status, created_at';
        $stmt = $pdo->prepare("SELECT {$cols} FROM users WHERE id = :id LIMIT 1");
        $stmt->execute(['id' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException('User not found');
        }
        if (!isset($row['role'])) {
            $row['role'] = 'member';
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

    public function isStaff(string $userId): bool
    {
        $pdo = ConnectionFactory::saturn();
        if (!self::usersTableHasRoleColumn($pdo)) {
            return false;
        }
        $stmt = $pdo->prepare('SELECT role FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
        $role = $stmt->fetchColumn();

        return $role === 'staff';
    }

    private static function usersTableHasRoleColumn(PDO $pdo): bool
    {
        static $has = null;
        if ($has !== null) {
            return $has;
        }
        $stmt = $pdo->query(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role'"
        );
        $has = $stmt !== false && (int) $stmt->fetchColumn() > 0;

        return $has;
    }

    /**
     * Recipient validation: regular members get a masked label; `staff` users see the recipient email.
     *
     * @return array{czedr_id: string, display_name: string, result: string}
     */
    public function recipientLookupForViewer(string $viewerUserId, string $targetCzedrId): array
    {
        $staff = $this->isStaff($viewerUserId);
        $cidKey = strtoupper(trim($targetCzedrId));
        if ($cidKey === '' || in_array($cidKey, ['SYSTEM', 'REVENUE'], true)) {
            throw new \InvalidArgumentException('Invalid Czedr Id');
        }
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT czedr_id, email FROM users WHERE czedr_id = :cid AND status = \'active\' LIMIT 1'
        );
        $stmt->execute(['cid' => $cidKey]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \InvalidArgumentException('Invalid Czedr Id');
        }
        $email = (string) $row['email'];
        $cid = (string) $row['czedr_id'];
        $friendly = self::friendlyNameFromEmail($email);
        $label = $staff
            ? sprintf('%s (%s)', $friendly, $email)
            : sprintf('%s · %s', $friendly, $cid);

        return [
            'czedr_id' => $cid,
            'display_name' => $label,
            'recipient_name' => $friendly,
            'result' => $label,
        ];
    }

    /**
     * Derive a short display name from an email local part (e.g. bob@test.czedr → Bob).
     */
    public static function friendlyNameFromEmail(string $email): string
    {
        $email = trim($email);
        $local = $email;
        if (str_contains($email, '@')) {
            $local = (string) explode('@', $email, 2)[0];
        }
        $parts = preg_split('/[._+-]+/', $local) ?: [$local];
        $words = [];
        foreach ($parts as $part) {
            $part = trim($part);
            if ($part === '') {
                continue;
            }
            $words[] = ucfirst(strtolower($part));
        }

        return $words !== [] ? implode(' ', $words) : $email;
    }

    public static function maskedRecipientLabel(string $czedrId): string
    {
        $czedrId = strtoupper(trim($czedrId));
        $tail = strlen($czedrId) >= 4 ? substr($czedrId, -4) : $czedrId;

        return 'Czedr member · …' . $tail;
    }

    private function generateCzedrId(): string
    {
        return 'CZ' . strtoupper(bin2hex(random_bytes(4)));
    }
}
