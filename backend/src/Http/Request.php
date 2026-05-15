<?php
declare(strict_types=1);

namespace Czedr\Http;

final class Request
{
    public function __construct(
        public readonly string $method,
        public readonly string $path,
        /** @var array<string, string> */
        public readonly array $headers,
        /** @var array<string, mixed> */
        public readonly array $body,
        public readonly ?string $rawBody,
        public readonly ?string $ip,
        public readonly ?string $userAgent,
    ) {
    }

    public static function fromGlobals(): self
    {
        $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $uri = $_SERVER['REQUEST_URI'] ?? '/';
        $path = parse_url($uri, PHP_URL_PATH) ?: '/';
        $raw = file_get_contents('php://input') ?: '';
        $body = [];
        $contentType = $_SERVER['CONTENT_TYPE'] ?? $_SERVER['HTTP_CONTENT_TYPE'] ?? '';
        if (str_contains($contentType, 'application/json') && $raw !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                $body = $decoded;
            }
        } elseif ($method === 'POST' && $raw === '') {
            $body = $_POST;
        }

        $headers = [];
        foreach ($_SERVER as $k => $v) {
            if (str_starts_with($k, 'HTTP_')) {
                $name = str_replace('_', '-', substr($k, 5));
                $headers[$name] = (string) $v;
            }
        }

        return new self(
            $method,
            $path,
            $headers,
            $body,
            $raw !== '' ? $raw : null,
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null,
        );
    }

    public function bearerToken(): ?string
    {
        $auth = $this->headers['AUTHORIZATION'] ?? '';
        if (preg_match('/^Bearer\s+(\S+)$/i', $auth, $m)) {
            return $m[1];
        }
        return null;
    }
}
