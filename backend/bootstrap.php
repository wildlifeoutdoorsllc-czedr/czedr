<?php
declare(strict_types=1);

define('CZEDR_ROOT', dirname(__DIR__));

require_once CZEDR_ROOT . '/backend/src/Autoload.php';
\Czedr\Autoload::register(CZEDR_ROOT . '/backend/src');

\Czedr\Support\Env::load(CZEDR_ROOT . '/.env');

if (\Czedr\Support\Env::isLocal() && \Czedr\Support\Env::get('APP_DEBUG', 'false') === 'true') {
    error_reporting(E_ALL);
    ini_set('display_errors', '1');
}
