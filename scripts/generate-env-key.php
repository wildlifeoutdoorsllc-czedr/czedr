<?php
declare(strict_types=1);

$key = random_bytes(32);
$encoded = base64_encode($key);
$envPath = dirname(__DIR__) . '/.env';
$example = dirname(__DIR__) . '/.env.example';

if (!is_file($envPath) && is_file($example)) {
    copy($example, $envPath);
}

$content = is_file($envPath) ? file_get_contents($envPath) : '';
if (preg_match('/^MASTER_KEY_BASE64=(\S+)/m', $content, $m) && $m[1] !== '') {
    echo "MASTER_KEY_BASE64 already set in .env\n";
    exit(0);
}

$line = 'MASTER_KEY_BASE64=' . $encoded;
if (preg_match('/^MASTER_KEY_BASE64=.*$/m', $content)) {
    $content = preg_replace('/^MASTER_KEY_BASE64=.*$/m', $line, $content);
} else {
    $content .= "\n" . $line . "\n";
}
file_put_contents($envPath, $content);
echo "Generated MASTER_KEY_BASE64 in .env (keep secret; never commit)\n";
