<?php
declare(strict_types=1);

namespace Czedr;

use Czedr\Audit\AuditService;
use Czedr\Auth\AuthService;
use Czedr\Auth\PasswordResetService;
use Czedr\Auth\SignupChallengeService;
use Czedr\Http\JsonResponse;
use Czedr\Http\Request;
use Czedr\Http\Router;
use Czedr\Invoice\InvoiceService;
use Czedr\Legacy\LegacyCompat;
use Czedr\Ledger\LedgerService;
use Czedr\Media\ProfileMediaService;
use Czedr\Security\ImageDerivedCryptor;
use Czedr\Support\Env;

final class App
{
    private const LEDGER_ONLY_EXTERNAL_MONEY_MSG = 'Czedr is ledger-only: there is no card or ACH processing. Money moves only between Czedr balances.';

    private Router $router;
    private AuditService $audit;
    private AuthService $auth;
    private LedgerService $ledger;
    private InvoiceService $invoices;
    private ProfileMediaService $profileMedia;
    private SignupChallengeService $signupChallenges;
    private PasswordResetService $passwordReset;

    public function __construct()
    {
        $this->audit = new AuditService();
        $this->ledger = new LedgerService($this->audit);
        $this->invoices = new InvoiceService($this->audit);
        $this->profileMedia = new ProfileMediaService();
        $this->signupChallenges = new SignupChallengeService();
        $this->passwordReset = new PasswordResetService($this->audit);
        $this->auth = new AuthService($this->audit, $this->ledger);
        $this->router = new Router();
        $this->registerRoutes();
    }

    public function run(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
            http_response_code(204);
            return;
        }
        $this->router->dispatch(Request::fromGlobals());
    }

    private function registerRoutes(): void
    {
        $this->router->get('/v1/health', function (Request $r) {
            JsonResponse::ok([
                'service' => 'czedr-api',
                'ledger' => 'internal_only',
                'settlement' => 'internal_ledger_only',
                'bank_or_ach' => false,
                'transfer_fee_cents' => LedgerService::transferFeeCents(),
                'referral_reward_cents' => LedgerService::referralRewardCents(),
            ]);
        });

        $this->router->get('/v1/admin/revenue-ledger', function (Request $r) {
            $secret = Env::get('CZEDR_ADMIN_REPORT_TOKEN');
            if ($secret === null || $secret === '') {
                JsonResponse::error('Not found', 404);
                return;
            }
            $provided = (string) ($r->headers['X-CZEDR-ADMIN-TOKEN'] ?? '');
            if ($provided === '') {
                $provided = (string) ($r->bearerToken() ?? '');
            }
            if ($provided === '' || !hash_equals($secret, $provided)) {
                JsonResponse::error('Unauthorized', 401);
                return;
            }
            JsonResponse::ok($this->ledger->getRevenueLedgerReport());
        });

        $this->router->get('/v1/dev/setup', function (Request $r) {
            if (!Env::isLocal()) {
                JsonResponse::error('Not found', 404);
                return;
            }
            $host = $_SERVER['HTTP_HOST'] ?? '127.0.0.1:8080';
            $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
            $base = $scheme . '://' . $host;
            JsonResponse::ok([
                'sandbox_url' => $base . '/sandbox',
                'api_base' => $base,
                'health_url' => $base . '/v1/health',
                'product' => 'internal_ledger_only_no_card_or_ach',
                'iphone_without_mac' => [
                    'test_in_safari' => 'Open sandbox_url on your iPhone (same Wi‑Fi as this PC).',
                    'native_app' => 'Apple requires building on macOS or a cloud CI service (Codemagic, GitHub Actions + TestFlight).',
                    'no_email_config' => 'iOS cannot install settings from an emailed file; the native app bakes URLs in at build time.',
                ],
                'lan_hint' => 'On iPhone use your PC Wi‑Fi IP, e.g. http://192.168.x.x:8080 — run scripts\\start-iphone-sandbox.ps1',
            ]);
        });

        $this->router->get('/v1/auth/signup-challenge', function (Request $r) {
            JsonResponse::ok($this->signupChallenges->createChallenge());
        });

        $this->router->post('/v1/auth/register', function (Request $r) {
            $out = $this->auth->register(
                (string) ($r->body['email'] ?? ''),
                (string) ($r->body['password'] ?? ''),
                isset($r->body['czedr_id']) ? (string) $r->body['czedr_id']
                    : (isset($r->body['payooze_id']) ? (string) $r->body['payooze_id'] : null),
                AuthService::optionalReferrerFromSignupBody($r->body),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($out);
        });

        $this->router->post('/v1/auth/register-secure', function (Request $r) {
            $challengeId = (string) ($r->body['challenge_id'] ?? '');
            $encData = (string) ($r->body['enc_data'] ?? '');
            if ($challengeId === '' || $encData === '') {
                throw new \InvalidArgumentException('challenge_id and enc_data are required');
            }
            $imageBytes = $this->signupChallenges->resolveImageBytes($challengeId);
            $json = ImageDerivedCryptor::decryptBase64Payload($encData, $imageBytes, $challengeId);
            $payload = json_decode($json, true);
            if (!is_array($payload)) {
                throw new \InvalidArgumentException('Invalid signup payload');
            }
            $out = $this->auth->register(
                (string) ($payload['email'] ?? $payload['user_email'] ?? ''),
                (string) ($payload['password'] ?? $payload['user_pwd'] ?? ''),
                isset($payload['czedr_id']) ? (string) $payload['czedr_id'] : null,
                AuthService::optionalReferrerFromSignupBody($payload),
                $r->ip,
                $r->userAgent
            );
            $this->signupChallenges->consumeChallenge($challengeId);
            JsonResponse::ok($out);
        });

        $this->router->post('/v1/auth/login', function (Request $r) {
            $out = $this->auth->login(
                (string) ($r->body['user_email'] ?? $r->body['email'] ?? ''),
                (string) ($r->body['user_pwd'] ?? $r->body['password'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($this->loginResponsePayload($out));
        });

        $this->router->post('/v1/auth/login-secure', function (Request $r) {
            $payload = $this->decryptSecureBody($r);
            $out = $this->auth->login(
                (string) ($payload['user_email'] ?? $payload['email'] ?? ''),
                (string) ($payload['user_pwd'] ?? $payload['password'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($this->loginResponsePayload($out));
        });

        $this->router->post('/v1/auth/pin/verify-secure', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $payload = $this->decryptSecureBody($r);
            $pin = (string) ($payload['user_pin'] ?? $payload['pin'] ?? '');
            $this->auth->verifyPin($uid, $pin);
            JsonResponse::ok(['verified' => true, 'result' => 'userpin matched']);
        }));

        $this->router->post('/v1/auth/pin/update-secure', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $payload = $this->decryptSecureBody($r);
            $oldPin = (string) ($payload['old_pin'] ?? $payload['user_pin_old'] ?? '');
            $newPin = (string) ($payload['new_pin'] ?? $payload['user_pin'] ?? '');
            if ($oldPin === '' || $newPin === '') {
                throw new \InvalidArgumentException('old_pin and new_pin are required');
            }
            $this->auth->changePin($uid, $oldPin, $newPin);
            JsonResponse::ok(['updated' => true]);
        }));

        $this->router->post('/v1/auth/pin/set', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $pin = (string) ($r->body['user_pin'] ?? $r->body['pin'] ?? '');
            if ($this->auth->hasPinSet($uid)) {
                throw new \InvalidArgumentException('PIN already set');
            }
            $this->auth->setPin($uid, $pin);
            JsonResponse::ok(['set' => true, 'user_pin' => '1']);
        }));

        $this->router->post('/v1/auth/pin/set-secure', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $payload = $this->decryptSecureBody($r);
            $pin = (string) ($payload['user_pin'] ?? $payload['pin'] ?? '');
            if ($this->auth->hasPinSet($uid)) {
                throw new \InvalidArgumentException('PIN already set');
            }
            $this->auth->setPin($uid, $pin);
            JsonResponse::ok(['set' => true, 'user_pin' => '1']);
        }));

        $this->router->post('/v1/auth/logout', function (Request $r) {
            $token = $r->bearerToken();
            if ($token) {
                $this->auth->logout(AuthService::hashToken($token));
            }
            JsonResponse::ok(['logged_out' => true]);
        });

        $this->router->post('/v1/auth/forgot-password', function (Request $r) {
            $out = $this->passwordReset->requestReset(
                (string) ($r->body['user_email'] ?? $r->body['email'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($out);
        });

        $this->router->post('/v1/auth/reset-password', function (Request $r) {
            $this->passwordReset->resetPassword(
                (string) ($r->body['reset_token'] ?? $r->body['token'] ?? ''),
                (string) ($r->body['password'] ?? $r->body['user_pwd'] ?? $r->body['new_password'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok(['message' => 'Password has been reset. You can sign in now.']);
        });

        $this->router->get('/v1/ledger/balance', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok([
                'balance_cents' => $this->ledger->getBalanceCents($uid),
                'currency' => 'USD',
                'transfer_fee_cents' => LedgerService::transferFeeCents(),
                'referral_reward_cents' => LedgerService::referralRewardCents(),
            ]);
        }));

        $this->router->get('/v1/referrals/earnings', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $lim = (int) ($_GET['recent_limit'] ?? $r->body['recent_limit'] ?? 25);
            JsonResponse::ok($this->ledger->referralEarningsForUser($uid, $lim));
        }));

        $this->router->post('/v1/ledger/load', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            if (!Env::allowSelfServiceLedgerLoad()) {
                JsonResponse::error('Self-service account load is disabled', 403);
                return;
            }
            $txn = $this->ledger->credit(
                $uid,
                (int) ($r->body['amount_cents'] ?? 0),
                (string) ($r->body['idempotency_key'] ?? bin2hex(random_bytes(8))),
                (string) ($r->body['memo'] ?? 'Account load'),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($txn);
        }));

        $this->router->get('/v1/users/validate', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $czedrId = (string) ($_GET['czedr_id'] ?? $r->body['czedr_id'] ?? '');
            JsonResponse::ok($this->auth->recipientLookupForViewer($uid, $czedrId));
        }));

        $this->router->post('/v1/transfers', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->auth->requirePinForPayment($uid, (string) ($r->body['user_pin'] ?? $r->body['pin'] ?? ''));
            $recipient = self::bodyCzedrId($r, 'to_czedr_id', 'to_payooze_id');
            $txn = $this->ledger->transfer(
                $uid,
                $recipient,
                (int) ($r->body['amount_cents'] ?? 0),
                (string) ($r->body['idempotency_key'] ?? bin2hex(random_bytes(8))),
                (string) ($r->body['memo'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($txn);
        }));

        $this->router->get('/v1/transfers/history', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok(['transactions' => $this->ledger->history($uid)]);
        }));

        $this->router->post('/v1/invoices', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->auth->requirePinForPayment($uid, (string) ($r->body['user_pin'] ?? $r->body['pin'] ?? ''));
            $recipient = self::bodyCzedrId($r, 'to_czedr_id', 'rec_czedr_id', 'rec_payooze_id');
            $amount = (float) ($r->body['amount'] ?? 0);
            $out = $this->invoices->create(
                $uid,
                $recipient,
                $amount,
                (string) ($r->body['desc'] ?? $r->body['description'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($out);
        }));

        $this->router->get('/v1/invoices/received', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $start = (int) ($_GET['offset'] ?? $r->body['offset'] ?? 1);
            $limit = (int) ($_GET['limit'] ?? $r->body['limit'] ?? 10);
            $list = $this->invoices->listReceived($uid, max(0, $start - 1), $limit);
            JsonResponse::okList($list['rows'], $list['total']);
        }));

        $this->router->get('/v1/invoices/sent', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $start = (int) ($_GET['offset'] ?? $r->body['offset'] ?? 1);
            $limit = (int) ($_GET['limit'] ?? $r->body['limit'] ?? 10);
            $list = $this->invoices->listSent($uid, max(0, $start - 1), $limit);
            JsonResponse::okList($list['rows'], $list['total']);
        }));

        $this->router->post('/v1/bank-accounts', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::error(self::LEDGER_ONLY_EXTERNAL_MONEY_MSG, 501);
        }));

        $this->router->get('/v1/bank-accounts', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok([
                'accounts' => [],
                'ledger_only' => true,
                'message' => self::LEDGER_ONLY_EXTERNAL_MONEY_MSG,
            ]);
        }));

        $this->router->post('/v1/bank-accounts/delete', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok(['deleted' => true, 'ledger_only' => true]);
        }));

        $this->router->post('/v1/ach/export', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::error(self::LEDGER_ONLY_EXTERNAL_MONEY_MSG, 501);
        }));

        $this->router->post('/v1/profile/avatar', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $raw = $r->rawBody ?? '';
            if ($raw === '' && isset($r->body['image_base64'])) {
                $raw = base64_decode((string) $r->body['image_base64'], true) ?: '';
            }
            if ($raw === '' && !empty($_FILES['user_pic']['tmp_name'])) {
                $raw = (string) file_get_contents((string) $_FILES['user_pic']['tmp_name']);
            }
            if ($raw === '' && !empty($_FILES['enc_pic']['tmp_name'])) {
                $raw = (string) file_get_contents((string) $_FILES['enc_pic']['tmp_name']);
            }
            $filename = $this->profileMedia->saveForUser($uid, $raw);
            JsonResponse::ok(['profile_pic' => $filename, 'profile_pic ' => $filename]);
        }));

        $this->router->get('__profile_media', function (Request $r) {
            $file = basename((string) substr($r->path, strlen('/v1/media/profile/')));
            $binary = $this->profileMedia->read($file);
            if ($binary === null) {
                JsonResponse::error('Not found', 404);
                return;
            }
            header('Content-Type: image/jpeg');
            header('Cache-Control: private, max-age=3600');
            echo $binary;
        });

        $this->router->post('/v1/notifications/dispatch', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            JsonResponse::ok(['dispatched' => true, 'msg' => (string) ($r->body['msg'] ?? '')]);
        }));

        $this->router->post('/v1/legacy/card/decrypt', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok(['result' => self::LEDGER_ONLY_EXTERNAL_MONEY_MSG]);
        }));

        $this->router->post('/v1/legacy/card/update', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok(['updated' => true]);
        }));

        (new LegacyCompat(
            $this->auth,
            $this->passwordReset,
            $this->ledger,
            $this->invoices,
            fn (Request $r, callable $fn) => $this->withAuth($r, $fn),
            fn (array $out) => $this->loginResponsePayload($out),
        ))->register($this->router);

        $this->router->post('/v1/legacy/card/image', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $raw = $r->rawBody ?? '';
            if ($raw === '' && !empty($_FILES['enc_pic']['tmp_name'])) {
                $raw = (string) file_get_contents((string) $_FILES['enc_pic']['tmp_name']);
            }
            if ($raw !== '') {
                $this->profileMedia->saveForUser('card-' . $uid, $raw);
            }
            JsonResponse::ok(['uploaded' => true]);
        }));
    }

    /** @param non-empty-string ...$keys */
    private static function bodyCzedrId(Request $r, string ...$keys): string
    {
        foreach ($keys as $key) {
            if (!empty($r->body[$key])) {
                return (string) $r->body[$key];
            }
        }
        return '';
    }

    private function withAuth(Request $request, callable $fn): void
    {
        $token = $request->bearerToken();
        if (!$token && !empty($request->body['auth_code'])) {
            $token = (string) $request->body['auth_code'];
        }
        if (!$token) {
            JsonResponse::error('authcode expired', 401);
            return;
        }
        $userId = $this->auth->resolveUserId($token);
        if (!$userId) {
            JsonResponse::error('authcode expired', 401);
            return;
        }
        $fn($userId);
    }

    /** @return array<string, mixed> */
    private function loginResponsePayload(array $out): array
    {
        $user = $out['user'];
        $userId = (string) ($user['id'] ?? '');
        $czedrId = (string) ($user['czedr_id'] ?? '');

        return [
            'auth_code' => $out['auth_token'],
            'user' => $user,
            'id' => $czedrId,
            'czedr_id' => $czedrId,
            'email' => $user['email'] ?? '',
            'email ' => $user['email'] ?? '',
            'user_pin' => $this->auth->userPinFlag($userId),
            'profile_pic ' => '',
        ];
    }

    /** @return array<string, mixed> */
    private function decryptSecureBody(Request $r): array
    {
        $challengeId = (string) ($r->body['challenge_id'] ?? '');
        $encData = (string) ($r->body['enc_data'] ?? '');
        if ($challengeId === '' || $encData === '') {
            throw new \InvalidArgumentException('challenge_id and enc_data are required');
        }
        $imageBytes = $this->signupChallenges->resolveImageBytes($challengeId);
        $json = ImageDerivedCryptor::decryptBase64Payload($encData, $imageBytes, $challengeId);
        $payload = json_decode($json, true);
        if (!is_array($payload)) {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }
        $this->signupChallenges->consumeChallenge($challengeId);

        return $payload;
    }
}
