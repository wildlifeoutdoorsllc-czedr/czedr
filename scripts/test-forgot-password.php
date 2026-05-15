<?php
declare(strict_types=1);

$base = 'http://127.0.0.1:8080';

function api(string $path, array $body): array
{
    global $base;
    $ch = curl_init($base . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
        CURLOPT_POSTFIELDS => json_encode($body, JSON_THROW_ON_ERROR),
    ]);
    $raw = curl_exec($ch);
    $json = json_decode((string) $raw, true);
    if (($json['Status'] ?? '') !== 'true') {
        throw new RuntimeException((string) $raw);
    }
    return $json['Data'];
}

echo "Request reset for alice@test.czedr...\n";
$req = api('/v1/auth/forgot-password', ['user_email' => 'alice@test.czedr']);
$token = $req['reset_token'] ?? '';
echo "  token: " . ($token !== '' ? substr($token, 0, 12) . '...' : '(none)') . "\n";

if ($token === '') {
    throw new RuntimeException('Expected reset_token in local env');
}

echo "Reset password...\n";
api('/v1/auth/reset-password', [
    'reset_token' => $token,
    'password' => 'NewTestPass456!',
]);

echo "Login with new password...\n";
$login = api('/v1/auth/login', [
    'user_email' => 'alice@test.czedr',
    'user_pwd' => 'NewTestPass456!',
]);
echo "  czedr_id: " . ($login['czedr_id'] ?? '') . "\n";
echo "Forgot password flow OK.\n";
