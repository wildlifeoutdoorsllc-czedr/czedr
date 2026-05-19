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
        return $this->writeJpeg($userId . '.jpg', $binary);
    }

    public function saveCardForUser(string $userId, string $cardId, string $binary): string
    {
        $safeId = preg_replace('/[^a-zA-Z0-9\-]/', '', $cardId) ?? '';
        if ($safeId === '') {
            throw new \InvalidArgumentException('Invalid card id');
        }

        return $this->writeJpeg('card-' . $userId . '-' . $safeId . '.jpg', $binary);
    }

    private function writeJpeg(string $filename, string $binary): string
    {
        if ($binary === '') {
            throw new \InvalidArgumentException('Empty image data');
        }
        $safe = basename($filename);
        $path = $this->storageDir() . '/' . $safe;
        if (file_put_contents($path, $binary) === false) {
            throw new \RuntimeException('Could not save image');
        }

        return $safe;
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
        if ($safe === $userId . '.jpg' || $safe === 'card-' . $userId . '.jpg') {
            return true;
        }
        $prefix = 'card-' . $userId . '-';
        if (str_starts_with($safe, $prefix) && str_ends_with($safe, '.jpg')) {
            return true;
        }

        return false;
    }
}
