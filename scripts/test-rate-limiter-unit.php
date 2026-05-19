<?php
require dirname(__DIR__) . '/backend/bootstrap.php';

$rl = new \Czedr\Security\RateLimiter();
$pdo = \Czedr\Database\ConnectionFactory::saturn();
$pdo->exec("DELETE FROM rate_limit_buckets WHERE bucket = 'test:unit'");

for ($i = 1; $i <= 11; $i++) {
    try {
        $rl->check('test:unit', 10, 900);
        $rl->hit('test:unit', 10, 900);
    } catch (\Czedr\Security\RateLimitExceededException) {
        if ($i === 11) {
            echo "RateLimiter unit test OK (blocked on attempt 11).\n";
            exit(0);
        }
        fwrite(STDERR, "Blocked too early on attempt $i\n");
        exit(1);
    }
}
fwrite(STDERR, "Never blocked after 11 hits\n");
exit(1);
