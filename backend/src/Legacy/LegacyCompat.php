<?php
declare(strict_types=1);

namespace Czedr\Legacy;

use Czedr\Auth\AuthService;
use Czedr\Auth\PasswordResetService;
use Czedr\Http\JsonResponse;
use Czedr\Http\Request;
use Czedr\Http\Router;
use Czedr\Invoice\InvoiceService;
use Czedr\Ledger\LedgerService;
use Czedr\Security\RateLimiter;

/**
 * Maps legacy iOS path names (POST /login, /invoicerecev, …) to the v1 API.
 */
final class LegacyCompat
{
    public function __construct(
        private readonly AuthService $auth,
        private readonly PasswordResetService $passwordReset,
        private readonly LedgerService $ledger,
        private readonly InvoiceService $invoices,
        /** @var callable(Request, callable(string): void): void */
        private readonly mixed $withAuth,
        /** @var callable(array): array */
        private readonly mixed $loginResponsePayload,
        private readonly RateLimiter $rateLimiter,
    ) {
    }

    public function register(Router $router): void
    {
        $router->post('/login', function (Request $r) {
            $out = $this->auth->login(
                (string) ($r->body['user_email'] ?? $r->body['email'] ?? ''),
                (string) ($r->body['user_pwd'] ?? $r->body['password'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok(($this->loginResponsePayload)($out));
        });

        $router->post('/logout', function (Request $r) {
            $token = $this->tokenFromRequest($r);
            if ($token) {
                $this->auth->logout(AuthService::hashToken($token));
            }
            JsonResponse::ok(['logged_out' => true]);
        });

        $router->post('/signup', function (Request $r) {
            $out = $this->auth->register(
                (string) ($r->body['user_email'] ?? $r->body['email'] ?? ''),
                (string) ($r->body['user_pwd'] ?? $r->body['password'] ?? ''),
                null,
                AuthService::optionalReferrerFromSignupBody($r->body),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok([
                'msg' => ['Account created'],
                'user' => $out['user'],
                'auth_code' => $out['auth_token'],
            ]);
        });

        $router->post('/checkpin', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $this->rateLimiter->check('pin:uid:' . $uid, 5, 900);
            try {
                $this->auth->verifyPin($uid, (string) ($r->body['user_pin'] ?? ''));
            } catch (\InvalidArgumentException $e) {
                if (str_contains($e->getMessage(), 'PIN')) {
                    $this->rateLimiter->hit('pin:uid:' . $uid, 5, 900);
                }
                throw $e;
            }
            JsonResponse::ok(['result' => 'userpin matched']);
        }));

        $router->post('/updatepin', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $oldPin = (string) ($r->body['old_pin'] ?? $r->body['user_pin_old'] ?? '');
            $newPin = (string) ($r->body['new_pin'] ?? $r->body['user_pin'] ?? '');
            if ($oldPin === '' || $newPin === '') {
                throw new \InvalidArgumentException(
                    'old_pin and new_pin are required. Use the Change PIN screen or /v1/auth/pin/update-secure.'
                );
            }
            $this->auth->changePin($uid, $oldPin, $newPin);
            JsonResponse::ok(['updated' => true]);
        }));

        $router->post('/userpin', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            if ($this->auth->hasPinSet($uid)) {
                throw new \InvalidArgumentException(
                    'PIN already set. Use Change PIN with your current PIN.'
                );
            }
            $this->auth->setPin($uid, (string) ($r->body['user_pin'] ?? ''));
            JsonResponse::ok(['set' => true]);
        }));

        $router->post('/invoicerecev', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $offset = (int) ($r->body['offset'] ?? 0);
            $limit = (int) ($r->body['limit'] ?? 10);
            $list = $this->invoices->listReceived($uid, max(0, $offset), max(1, $limit));
            JsonResponse::okList($list['rows'], $list['total']);
        }));

        $router->post('/invoicehistory', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $offset = (int) ($r->body['offset'] ?? 0);
            $limit = (int) ($r->body['limit'] ?? 10);
            $list = $this->invoices->listSent($uid, max(0, $offset), max(1, $limit));
            JsonResponse::okList($list['rows'], $list['total']);
        }));

        $router->post('/invoice', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $this->auth->requirePinForPayment($uid, (string) ($r->body['user_pin'] ?? ''));
            $recipient = (string) ($r->body['rec_czedr_id'] ?? $r->body['rec_payooze_id'] ?? $r->body['czedr_id'] ?? '');
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

        $router->post('/valid_recipient', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $czedrId = strtoupper(trim((string) (
                $r->body['czedr_id']
                    ?? $r->body['rec_czedr_id']
                    ?? $r->body['payooze_id']
                    ?? $r->body['rec_payooze_id']
                    ?? ''
            )));
            JsonResponse::ok($this->auth->recipientLookupForViewer($uid, $czedrId));
        }));

        $router->post('/transactionhistroy', fn (Request $r) => ($this->withAuth)($r, function (string $uid) {
            $txns = $this->ledger->history($uid, 50);
            $pdo = \Czedr\Database\ConnectionFactory::saturn();
            $stmt = $pdo->prepare('SELECT czedr_id FROM users WHERE id = :id LIMIT 1');
            $stmt->execute(['id' => $uid]);
            $myCzedrId = (string) $stmt->fetchColumn();
            $rows = [];
            foreach ($txns as $t) {
                $from = (string) ($t['from_czedr_id'] ?? '');
                $to = (string) ($t['to_czedr_id'] ?? '');
                $sent = $from === $myCzedrId;
                $rows[] = [
                    'name' => $t['memo'] ?? 'Transfer',
                    'amount' => ((int) ($t['amount_cents'] ?? 0)) / 100,
                    'email' => $sent ? $to : $from,
                    'sender_user_id' => $from,
                    'receiver_user_id' => $to,
                    'cardnumber' => '0000',
                ];
            }
            JsonResponse::okList($rows, count($rows));
        }));

        $router->post('/transactiondetail', fn (Request $r) => ($this->withAuth)($r, function (string $uid) use ($r) {
            $this->auth->requirePinForPayment($uid, (string) ($r->body['user_pin'] ?? ''));
            $recipient = (string) ($r->body['rec_czedr_id'] ?? $r->body['rec_payooze_id'] ?? $r->body['czedr_id'] ?? '');
            $amount = (float) ($r->body['amount'] ?? 0);
            $cents = (int) round($amount * 100);
            $txn = $this->ledger->transfer(
                $uid,
                $recipient,
                $cents,
                (string) ($r->body['idempotency_key'] ?? bin2hex(random_bytes(8))),
                (string) ($r->body['memo'] ?? 'Payment'),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok(['msg' => ['Payment sent'], 'transaction' => $txn]);
        }));

        $router->post('/creditcarddetail', fn (Request $r) => ($this->withAuth)($r, function (string $uid) {
            JsonResponse::okList([], 0);
        }));

        $router->post('/deletecreditcard', fn (Request $r) => ($this->withAuth)($r, function (string $uid) {
            JsonResponse::ok(['deleted' => true]);
        }));

        $router->post('/registeredtoken', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['registered' => true]);
        }));

        $router->post('/unregisteredtoken', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['unregistered' => true]);
        }));

        $router->post('/changepwd', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::error('Password change: use profile settings (coming soon)', 501);
        }));

        $router->post('/forgotpwd', function (Request $r) {
            $out = $this->passwordReset->requestReset(
                (string) ($r->body['user_email'] ?? $r->body['email'] ?? ''),
                $r->ip,
                $r->userAgent
            );
            JsonResponse::ok([
                'msg' => ['A new password reset link has been sent to your email. Please check email for further instructions.'],
                'message' => $out['message'],
                'reset_token' => $out['reset_token'] ?? null,
            ]);
        });

        $router->post('/forgotpin', function () {
            JsonResponse::ok(['msg' => ['If the email exists, instructions will be sent']]);
        });

        $router->post('/resendinvoice', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['msg' => ['Reminder sent']]);
        }));

        $router->post('/cancelinvoice', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['msg' => ['Invoice cancelled']]);
        }));

        $router->post('/rejectinvoice', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['msg' => ['Invoice rejected']]);
        }));

        $router->post('/updateprofile', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['updated' => true]);
        }));

        $router->post('/userimage', fn (Request $r) => ($this->withAuth)($r, function () {
            JsonResponse::ok(['uploaded' => true]);
        }));

        $router->get('/signup-challenge', function () {
            JsonResponse::error('Use GET /v1/auth/signup-challenge', 400);
        });
    }

    private function tokenFromRequest(Request $r): ?string
    {
        $token = $r->bearerToken();
        if ($token) {
            return $token;
        }
        $code = $r->body['auth_code'] ?? null;
        return is_string($code) && $code !== '' ? $code : null;
    }
}
