#!/usr/bin/env php
<?php
declare(strict_types=1);

/**
 * Test outbound email: php scripts/test-mail.php you@example.com
 */
require_once dirname(__DIR__) . '/backend/bootstrap.php';

use Czedr\Mail\MailService;

$to = $argv[1] ?? '';
if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Usage: php scripts/test-mail.php recipient@example.com\n");
    exit(1);
}

$mail = new MailService();
if (!$mail->isConfigured()) {
    fwrite(STDERR, "MAIL_* not configured. Set MAIL_ENABLED=1 in .env (see docs/EMAIL-SETUP.md).\n");
    exit(1);
}

$mail->send(
    $to,
    'CZEDR test email',
    "This is a test message from the Czedr server at " . date('c') . ".\n",
    '<p>This is a <strong>test</strong> message from the Czedr server.</p>'
);

echo "OK: test email sent to {$to}\n";
