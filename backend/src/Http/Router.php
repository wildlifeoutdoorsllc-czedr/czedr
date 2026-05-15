<?php
declare(strict_types=1);

namespace Czedr\Http;

final class Router
{
    /** @var array<string, array<string, callable>> */
    private array $routes = [];

    public function post(string $path, callable $handler): void
    {
        $this->routes['POST'][$path] = $handler;
    }

    public function get(string $path, callable $handler): void
    {
        $this->routes['GET'][$path] = $handler;
    }

    public function dispatch(Request $request): void
    {
        $path = $request->path;
        if ($path !== '/' && str_ends_with($path, '/')) {
            $path = rtrim($path, '/');
        }
        $handler = $this->routes[$request->method][$path] ?? null;
        if (!$handler && $request->method === 'GET' && str_starts_with($request->path, '/v1/media/profile/')) {
            $handler = $this->routes['GET']['__profile_media'] ?? null;
        }
        if (!$handler) {
            JsonResponse::error('Not found', 404);
            return;
        }
        try {
            $handler($request);
        } catch (\InvalidArgumentException $e) {
            JsonResponse::error($e->getMessage(), 400);
        } catch (\RuntimeException $e) {
            JsonResponse::error($e->getMessage(), 500);
        }
    }
}
