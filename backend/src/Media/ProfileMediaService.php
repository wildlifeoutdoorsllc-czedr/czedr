<?php
declare(strict_types=1);

namespace Czedr\Media;

final class ProfileMediaService
{
    private function storageDir(): string
    {
        $dir = dirname(__DIR__, 2) . '/storage/profiles';
        if (!is_dir($dir)) {
            mkdir($dir, 0750, true);
        }
        return $dir;
    }

    public function saveForUser(string $userId, string $binary): string
    {
        if ($binary === '') {
            throw new \InvalidArgumentException('Empty image data');
        }
        $filename = $userId . '.jpg';
        $path = $this->storageDir() . '/' . $filename;
        if (file_put_contents($path, $binary) === false) {
            throw new \RuntimeException('Could not save profile image');
        }
        return $filename;
    }

    public function read(string $filename): ?string
    {
        $safe = basename($filename);
        $path = $this->storageDir() . '/' . $safe;
        if (!is_file($path)) {
            return null;
        }
        $data = file_get_contents($path);
        return $data === false ? null : $data;
    }

    /** Profile avatar or card image owned by the authenticated user only. */
    public function userMayRead(string $userId, string $filename): bool
    {
        $safe = basename($filename);
        $allowed = [
            $userId . '.jpg',
            'card-' . $userId . '.jpg',
        ];

        return in_array($safe, $allowed, true);
    }
}
