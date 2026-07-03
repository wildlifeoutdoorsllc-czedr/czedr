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
use Czedr\Cards\CardLinkService;
use Czedr\Media\ProfileMediaService;
use Czedr\Funding\FundingStatusService;
use Czedr\Funding\MicroDepositBankLinkService;
use Czedr\Moov\MoovAchService;
use Czedr\Moov\MoovConfig;
use Czedr\Moov\MoovHttpClient;
use Czedr\Moov\MoovWebhookVerifier;
use Czedr\Payments\PaymentQr;
use Czedr\Security\HttpsGate;
use Czedr\Security\PayloadCryptor;
use Czedr\Security\ProductionRouteGuard;
use Czedr\Security\RateLimitExceededException;
use Czedr\Security\RateLimiter;
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
    private CardLinkService $cardLinks;
    private MoovAchService $moovAch;
    private MicroDepositBankLinkService $microDepositBankLink;
    private FundingStatusService $fundingStatus;
    private SignupChallengeService $signupChallenges;
    private PasswordResetService $passwordReset;
    private RateLimiter $rateLimiter;

    public function __construct()
    {
        $this->rateLimiter = new RateLimiter();
        $this->audit = new AuditService();
        $this->ledger = new LedgerService($this->audit);
        $this->invoices = new InvoiceService($this->audit);
        $this->profileMedia = new ProfileMediaService();
        $this->cardLinks = new CardLinkService($this->profileMedia);
        $this->moovAch = new MoovAchService(new MoovHttpClient(), $this->ledger);
        $this->microDepositBankLink = new MicroDepositBankLinkService();
        $this->fundingStatus = new FundingStatusService($this->microDepositBankLink);
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
        HttpsGate::enforce();
        $request = Request::fromGlobals();
        try {
            $this->applyIngressRateLimits($request);
            $this->router->dispatch($request);
        } catch (RateLimitExceededException $e) {
            JsonResponse::error($e->getMessage(), 429);
        }
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

        $this->router->get('/v1/admin/corporate-ledger', function (Request $r) {
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
            JsonResponse::ok($this->ledger->getCorporateLedgerReport());
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
            $this->rateLimiter->check(
                'challenge:ip:' . RateLimiter::clientIp($r->ip),
                30,
                3600
            );
            $this->rateLimiter->hit(
                'challenge:ip:' . RateLimiter::clientIp($r->ip),
                30,
                3600
            );
            JsonResponse::ok($this->signupChallenges->createChallenge());
        });

        $this->router->post('/v1/auth/register', function (Request $r) {
            ProductionRouteGuard::requirePlainAuthAllowed();
            $this->guardRegisterAttempt($r);
            $out = $this->auth->register(
                (string) ($r->body['email'] ?? ''),
                (string) ($r->body['password'] ?? ''),
                isset($r->body['czedr_id']) ? (string) $r->body['czedr_id'] : null,
                AuthService::optionalReferrerFromSignupBody($r->body),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok($this->loginResponsePayload($out));
        });

        $this->router->post('/v1/auth/register-secure', function (Request $r) {
            $challengeId = (string) ($r->body['challenge_id'] ?? '');
            $encData = (string) ($r->body['enc_data'] ?? '');
            if ($challengeId === '' || $encData === '') {
                throw new \InvalidArgumentException('challenge_id and enc_data are required');
            }
            $imageBytes = $this->signupChallenges->resolveImageBytes($challengeId);
            $cryptoVersion = (int) ($r->body['crypto_version'] ?? 0);
            $json = PayloadCryptor::decrypt($encData, $imageBytes, $challengeId, $cryptoVersion);
            $payload = json_decode($json, true);
            if (!is_array($payload)) {
                throw new \InvalidArgumentException('Invalid signup payload');
            }
            $this->guardRegisterAttempt($r);
            $out = $this->auth->register(
                (string) ($payload['email'] ?? $payload['user_email'] ?? ''),
                (string) ($payload['password'] ?? $payload['user_pwd'] ?? ''),
                isset($payload['czedr_id']) ? (string) $payload['czedr_id'] : null,
                AuthService::optionalReferrerFromSignupBody($payload),
                $r->ip,
                $r->userAgent
            );
            $this->signupChallenges->consumeChallenge($challengeId);
            JsonResponse::ok($this->loginResponsePayload($out));
        });

        $this->router->post('/v1/auth/login', function (Request $r) {
            ProductionRouteGuard::requirePlainAuthAllowed();
            $this->handleLogin(
                $r,
                (string) ($r->body['user_email'] ?? $r->body['email'] ?? ''),
                (string) ($r->body['user_pwd'] ?? $r->body['password'] ?? '')
            );
        });

        $this->router->post('/v1/auth/login-secure', function (Request $r) {
            $payload = $this->decryptSecureBody($r);
            $this->handleLogin(
                $r,
                (string) ($payload['user_email'] ?? $payload['email'] ?? ''),
                (string) ($payload['user_pwd'] ?? $payload['password'] ?? '')
            );
        });

        $this->router->post('/v1/auth/pin/verify-secure', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->guardPinAttempt($uid);
            $payload = $this->decryptSecureBody($r);
            $pin = (string) ($payload['user_pin'] ?? $payload['pin'] ?? '');
            try {
                $this->auth->verifyPin($uid, $pin);
            } catch (\InvalidArgumentException $e) {
                if (str_contains($e->getMessage(), 'PIN')) {
                    $this->rateLimiter->hit('pin:uid:' . $uid, 5, 900);
                }
                throw $e;
            }
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

        $this->router->post('/v1/auth/pin/update', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $oldPin = (string) ($r->body['old_pin'] ?? $r->body['user_pin_old'] ?? '');
            $newPin = (string) ($r->body['new_pin'] ?? $r->body['user_pin'] ?? '');
            if ($oldPin === '' || $newPin === '') {
                throw new \InvalidArgumentException('old_pin and new_pin are required');
            }
            $this->auth->changePin($uid, $oldPin, $newPin);
            JsonResponse::ok(['updated' => true, 'user_pin' => '1']);
        }));

        $this->router->post('/v1/auth/logout', function (Request $r) {
            $token = $r->bearerToken();
            if ($token) {
                $this->auth->logout(AuthService::hashToken($token));
            }
            JsonResponse::ok(['logged_out' => true]);
        });

        $this->router->post('/v1/auth/forgot-password', function (Request $r) {
            $email = (string) ($r->body['user_email'] ?? $r->body['email'] ?? '');
            $this->rateLimiter->check(
                'forgot:ip:' . RateLimiter::clientIp($r->ip),
                3,
                3600
            );
            $this->rateLimiter->check(
                'forgot:' . RateLimiter::emailBucket($email),
                3,
                3600
            );
            $this->rateLimiter->hit('forgot:ip:' . RateLimiter::clientIp($r->ip), 3, 3600);
            $this->rateLimiter->hit('forgot:' . RateLimiter::emailBucket($email), 3, 3600);
            $out = $this->passwordReset->requestReset(
                $email,
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

        $this->registerFundingRoutes();

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

        $this->router->get('/v1/me', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            $user = $this->auth->userProfile($uid);
            $czedrId = (string) ($user['czedr_id'] ?? '');
            JsonResponse::ok(array_merge(
                $user,
                PaymentQr::metaForCzedrId($czedrId),
                ['user_pin' => $this->auth->userPinFlag($uid)]
            ));
        }));

        $this->router->post('/v1/transfers', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->auth->requirePinForPayment($uid, (string) ($r->body['user_pin'] ?? $r->body['pin'] ?? ''));
            $recipient = self::bodyCzedrId($r, 'to_czedr_id');
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
            $recipient = self::bodyCzedrId($r, 'to_czedr_id', 'rec_czedr_id');
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

        $this->router->get('/v1/cards', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            JsonResponse::ok(['cards' => $this->cardLinks->listForUser($uid)]);
        }));

        $this->router->post('/v1/cards/link-secure', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $imageB64 = (string) ($r->body['image_b64'] ?? '');
            $encData = (string) ($r->body['enc_data'] ?? '');
            if ($imageB64 === '' || $encData === '') {
                JsonResponse::error('image_b64 and enc_data are required', 400);
                return;
            }
            try {
                $card = $this->cardLinks->linkSecure($uid, $imageB64, $encData);
                JsonResponse::ok(['card' => $card, 'Status' => 'true']);
            } catch (\InvalidArgumentException $e) {
                JsonResponse::error($e->getMessage(), 400);
            } catch (\Throwable $e) {
                JsonResponse::error('Could not link card', 500);
            }
        }));

        $this->router->post('/v1/cards/delete', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $cardId = (string) ($r->body['card_id'] ?? $r->body['id'] ?? '');
            if ($cardId === '') {
                JsonResponse::error('card_id is required', 400);
                return;
            }
            if (!$this->cardLinks->delete($uid, $cardId)) {
                JsonResponse::error('Card not found', 404);
                return;
            }
            JsonResponse::ok(['deleted' => true, 'Status' => 'true']);
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
            $token = $r->bearerToken();
            if (!$token && isset($_GET['auth_code']) && is_string($_GET['auth_code'])) {
                $token = $_GET['auth_code'];
            }
            if (!$token && !empty($r->body['auth_code'])) {
                $token = (string) $r->body['auth_code'];
            }
            if (!$token) {
                JsonResponse::error('Unauthorized', 401);
                return;
            }
            $userId = $this->auth->resolveUserId($token);
            if (!$userId) {
                JsonResponse::error('Unauthorized', 401);
                return;
            }
            $file = basename((string) substr($r->path, strlen('/v1/media/profile/')));
            if (!$this->profileMedia->userMayRead($userId, $file)) {
                JsonResponse::error('Not found', 404);
                return;
            }
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

        $this->router->post('/v1/legacy/card/decrypt', fn (Request $r) => $this->legacyCardLink($r));

        $this->router->post('/v1/legacy/card/update', fn (Request $r) => $this->legacyCardLink($r));

        if (ProductionRouteGuard::allowLegacyApi()) {
            (new LegacyCompat(
                $this->auth,
                $this->passwordReset,
                $this->ledger,
                $this->invoices,
                fn (Request $r, callable $fn) => $this->withAuth($r, $fn),
                fn (array $out) => $this->loginResponsePayload($out),
                $this->rateLimiter,
            ))->register($this->router);
        }

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

    private function registerFundingRoutes(): void
    {
        $this->router->get('/v1/funding/status', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            $this->bankLinkJson(fn () => $this->fundingStatus->statusForUser($uid));
        }));

        $this->router->post('/v1/funding/bank-link/start', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->bankLinkJson(fn () => $this->microDepositBankLink->startLink(
                $uid,
                (string) ($r->body['routing_number'] ?? ''),
                (string) ($r->body['account_number'] ?? ''),
                (string) ($r->body['account_type'] ?? 'checking'),
                (string) ($r->body['account_holder_name'] ?? ''),
            ));
        }));

        $this->router->post('/v1/funding/bank-link/confirm', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->bankLinkJson(fn () => $this->microDepositBankLink->confirmMicroDeposits(
                $uid,
                (string) ($r->body['bank_link_id'] ?? ''),
                (int) ($r->body['amount_1_cents'] ?? 0),
                (int) ($r->body['amount_2_cents'] ?? 0),
            ));
        }));

        $this->router->get('/v1/funding/banks', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            $this->bankLinkJson(fn () => [
                'bank_link_method' => MicroDepositBankLinkService::linkMethod(),
                'banks' => $this->microDepositBankLink->listBanks($uid),
            ]);
        }));

        $this->router->post('/v1/funding/moov/onboarding', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            $this->achRailJson(function () use ($uid) {
                $user = $this->auth->userProfile($uid);

                return $this->moovAch->ensureMoovAccount(
                    $uid,
                    (string) ($user['email'] ?? ''),
                    (string) ($user['czedr_id'] ?? '')
                );
            });
        }));

        $this->router->post('/v1/funding/moov/bank-link', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            $this->bankLinkJson(function () use ($uid) {
                $user = $this->auth->userProfile($uid);

                return $this->moovAch->startBankLink(
                    $uid,
                    (string) ($user['email'] ?? ''),
                    (string) ($user['czedr_id'] ?? '')
                );
            });
        }));

        $this->router->get('/v1/funding/moov/banks', fn (Request $r) => $this->withAuth($r, function (string $uid) {
            $this->bankLinkJson(fn () => ['banks' => $this->microDepositBankLink->listBanks($uid)]);
        }));

        $this->router->post('/v1/funding/moov/deposit', fn (Request $r) => $this->withAuth($r, function (string $uid) use ($r) {
            $this->achRailJson(function () use ($uid, $r) {
                return $this->moovAch->initiateDeposit(
                    $uid,
                    (int) ($r->body['amount_cents'] ?? 0),
                    (string) ($r->body['idempotency_key'] ?? ''),
                    isset($r->body['bank_account_id']) ? (string) $r->body['bank_account_id'] : null,
                    $r->ip,
                    $r->userAgent
                );
            });
        }));

        $this->router->post('/v1/webhooks/moov', function (Request $r) {
            $raw = $r->rawBody ?? '';
            if ($raw === '') {
                JsonResponse::error('Empty body', 400);
                return;
            }
            $headers = [];
            foreach ($_SERVER as $key => $value) {
                if (str_starts_with($key, 'HTTP_')) {
                    $name = str_replace('_', '-', substr($key, 5));
                    $headers[$name] = is_string($value) ? $value : '';
                }
            }
            if (!MoovWebhookVerifier::verify($raw, $headers)) {
                JsonResponse::error('Invalid signature', 401);
                return;
            }
            /** @var array<string, mixed> $payload */
            $payload = json_decode($raw, true) ?: [];
            $event = (string) ($payload['type'] ?? $payload['event'] ?? '');
            if (str_contains(strtolower($event), 'transfer')) {
                $this->moovAch->handleTransferWebhook($payload);
            }
            JsonResponse::ok(['received' => true]);
        });
    }

    /** Bank link + status — always available (micro-deposit, no credential aggregators). */
    /** @param callable(): array<string, mixed> $fn */
    private function bankLinkJson(callable $fn): void
    {
        try {
            JsonResponse::ok($fn());
        } catch (\InvalidArgumentException $e) {
            JsonResponse::error($e->getMessage(), 400);
        } catch (\RuntimeException $e) {
            JsonResponse::error($e->getMessage(), 503);
        }
    }

    /** ACH cash in/out — only when rail is configured (optional; P2P does not need this). */
    /** @param callable(): array<string, mixed> $fn */
    private function achRailJson(callable $fn): void
    {
        if (!MoovConfig::isEnabled()) {
            JsonResponse::error(
                'ACH cash in/out is not enabled on this server. You can still pay and receive on Czedr using your balance.',
                503
            );
            return;
        }
        $this->bankLinkJson($fn);
    }

    private function legacyCardLink(Request $request): void
    {
        $this->withAuth($request, function (string $uid) use ($request) {
            $imageB64 = (string) ($request->body['image_b64'] ?? $_GET['image_b64'] ?? '');
            $encData = (string) ($request->body['enc_data'] ?? $_GET['enc_data'] ?? '');
            if ($imageB64 === '' || $encData === '') {
                JsonResponse::error('image_b64 and enc_data are required', 400);
                return;
            }
            try {
                $card = $this->cardLinks->linkSecure($uid, $imageB64, $encData);
                JsonResponse::ok(['Status' => 'true', 'card' => $card]);
            } catch (\InvalidArgumentException $e) {
                JsonResponse::error($e->getMessage(), 400);
            } catch (\Throwable $e) {
                JsonResponse::error('Could not link card', 500);
            }
        });
    }

    private function withAuth(Request $request, callable $fn): void
    {
        $token = $request->bearerToken();
        if (!$token && Env::isLocal() && !empty($request->body['auth_code'])) {
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

        return array_merge(
            [
                'auth_code' => $out['auth_token'],
                'user' => $user,
                'id' => $czedrId,
                'czedr_id' => $czedrId,
                'email' => $user['email'] ?? '',
                'email ' => $user['email'] ?? '',
                'user_pin' => $this->auth->userPinFlag($userId),
                'profile_pic ' => '',
            ],
            PaymentQr::metaForCzedrId($czedrId)
        );
    }

    private function applyIngressRateLimits(Request $r): void
    {
        if ($r->method !== 'POST') {
            return;
        }
        $ip = RateLimiter::clientIp($r->ip);
        if ($r->path === '/v1/auth/login' || $r->path === '/v1/auth/login-secure') {
            $this->rateLimiter->check('login:ip:' . $ip, 10, 900);
        }
    }

    private function guardRegisterAttempt(Request $r): void
    {
        $ip = RateLimiter::clientIp($r->ip);
        $this->rateLimiter->check('register:ip:' . $ip, 5, 3600);
        $this->rateLimiter->hit('register:ip:' . $ip, 5, 3600);
    }

    private function guardPinAttempt(string $userId): void
    {
        $this->rateLimiter->check('pin:uid:' . $userId, 5, 900);
    }

    private function handleLogin(Request $r, string $email, string $password): void
    {
        $ip = RateLimiter::clientIp($r->ip);
        $emailKey = RateLimiter::emailBucket($email);
        $this->rateLimiter->check('login:ip:' . $ip, 10, 900);
        $this->rateLimiter->check('login:' . $emailKey, 10, 900);
        try {
            $out = $this->auth->login($email, $password, $r->ip, $r->userAgent);
        } catch (\InvalidArgumentException $e) {
            if ($e->getMessage() === 'Invalid credentials') {
                $this->rateLimiter->hit('login:ip:' . $ip, 10, 900);
                $this->rateLimiter->hit('login:' . $emailKey, 10, 900);
            }
            throw $e;
        }
        JsonResponse::ok($this->loginResponsePayload($out));
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
        $cryptoVersion = (int) ($r->body['crypto_version'] ?? 0);
        $json = PayloadCryptor::decrypt($encData, $imageBytes, $challengeId, $cryptoVersion);
        $payload = json_decode($json, true);
        if (!is_array($payload)) {
            throw new \InvalidArgumentException('Invalid encrypted payload');
        }
        $this->signupChallenges->consumeChallenge($challengeId);

        return $payload;
    }
}
