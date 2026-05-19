<?php
declare(strict_types=1);

namespace Czedr\Cards;

use Czedr\Database\ConnectionFactory;
use Czedr\Media\ProfileMediaService;
use Czedr\Security\SecurePayloadCryptor;
use Czedr\Support\Uuid;
use PDO;

/**
 * Linked payment cards: metadata on server, PAN/CVV only inside image-bound ciphertext (never stored).
 */
final class CardLinkService
{
    public function __construct(private readonly ProfileMediaService $profileMedia)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function linkSecure(string $userId, string $imageB64, string $encData): array
    {
        $imageBytes = base64_decode($imageB64, true);
        if ($imageBytes === false || strlen($imageBytes) < 32) {
            throw new \InvalidArgumentException('Invalid card image');
        }
        if (!SecurePayloadCryptor::isV2Payload($encData)) {
            throw new \InvalidArgumentException('Unsupported encryption; update the app');
        }

        $json = SecurePayloadCryptor::decryptCardBase64($encData, $imageBytes, $userId);
        /** @var array<string, mixed> $fields */
        $fields = json_decode($json, true, 512, JSON_THROW_ON_ERROR);

        $displayName = trim((string) ($fields['name'] ?? ''));
        if ($displayName === '') {
            throw new \InvalidArgumentException('Card name is required');
        }

        $pan = preg_replace('/\D+/', '', (string) ($fields['card_no'] ?? '')) ?? '';
        if (strlen($pan) < 13 || strlen($pan) > 19) {
            throw new \InvalidArgumentException('Invalid card number');
        }

        $cvv = preg_replace('/\D+/', '', (string) ($fields['cvv'] ?? '')) ?? '';
        if (strlen($cvv) < 3 || strlen($cvv) > 4) {
            throw new \InvalidArgumentException('Invalid security code');
        }
        unset($cvv);

        $expLabel = trim((string) ($fields['date'] ?? ''));
        if ($expLabel === '') {
            throw new \InvalidArgumentException('Expiry date is required');
        }

        $brand = strtolower(trim((string) ($fields['type'] ?? 'visa')));
        if ($brand === '') {
            $brand = 'visa';
        }

        $wantDefault = in_array((string) ($fields['default'] ?? '0'), ['1', 'true', 'yes'], true);
        $lastFour = substr($pan, -4);
        unset($pan);

        $cardId = trim((string) ($fields['id'] ?? ''));
        $pdo = ConnectionFactory::saturn();
        if ($cardId !== '' && !$this->userOwnsCard($pdo, $userId, $cardId)) {
            throw new \InvalidArgumentException('Card not found');
        }
        if ($cardId === '') {
            $cardId = Uuid::v4();
        }

        $imageFilename = $this->profileMedia->saveCardForUser($userId, $cardId, $imageBytes);

        if ($wantDefault) {
            $pdo->prepare('UPDATE linked_cards SET is_default = 0 WHERE user_id = :uid')
                ->execute(['uid' => $userId]);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO linked_cards (id, user_id, display_name, last_four, exp_label, card_brand, is_default, image_filename)
             VALUES (:id, :uid, :name, :last4, :exp, :brand, :def, :img)
             ON DUPLICATE KEY UPDATE
               display_name = VALUES(display_name),
               last_four = VALUES(last_four),
               exp_label = VALUES(exp_label),
               card_brand = VALUES(card_brand),
               is_default = VALUES(is_default),
               image_filename = VALUES(image_filename),
               updated_at = CURRENT_TIMESTAMP'
        );
        $stmt->execute([
            'id' => $cardId,
            'uid' => $userId,
            'name' => mb_substr($displayName, 0, 128),
            'last4' => $lastFour,
            'exp' => mb_substr($expLabel, 0, 16),
            'brand' => mb_substr($brand, 0, 32),
            'def' => $wantDefault ? 1 : 0,
            'img' => $imageFilename,
        ]);

        return $this->rowToApi($this->fetchOne($pdo, $userId, $cardId));
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function listForUser(string $userId): array
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id, display_name, last_four, exp_label, card_brand, is_default, image_filename
             FROM linked_cards WHERE user_id = :uid ORDER BY is_default DESC, created_at ASC'
        );
        $stmt->execute(['uid' => $userId]);
        $rows = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $rows[] = $this->rowToApi($row);
        }

        return $rows;
    }

    public function delete(string $userId, string $cardId): bool
    {
        $pdo = ConnectionFactory::saturn();
        if (!$this->userOwnsCard($pdo, $userId, $cardId)) {
            return false;
        }
        $stmt = $pdo->prepare('DELETE FROM linked_cards WHERE id = :id AND user_id = :uid LIMIT 1');
        $stmt->execute(['id' => $cardId, 'uid' => $userId]);

        return $stmt->rowCount() > 0;
    }

    private function userOwnsCard(PDO $pdo, string $userId, string $cardId): bool
    {
        $stmt = $pdo->prepare('SELECT 1 FROM linked_cards WHERE id = :id AND user_id = :uid LIMIT 1');
        $stmt->execute(['id' => $cardId, 'uid' => $userId]);

        return (bool) $stmt->fetchColumn();
    }

    /**
     * @return array<string, mixed>
     */
    private function fetchOne(PDO $pdo, string $userId, string $cardId): array
    {
        $stmt = $pdo->prepare(
            'SELECT id, display_name, last_four, exp_label, card_brand, is_default, image_filename
             FROM linked_cards WHERE id = :id AND user_id = :uid LIMIT 1'
        );
        $stmt->execute(['id' => $cardId, 'uid' => $userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            throw new \RuntimeException('Card save failed');
        }

        return $row;
    }

    /**
     * @param array<string, mixed> $row
     * @return array<string, mixed>
     */
    private function rowToApi(array $row): array
    {
        $exp = (string) ($row['exp_label'] ?? '');
        $parts = preg_split('#\s*/\s*#', $exp) ?: [];
        $month = isset($parts[0]) ? str_pad(preg_replace('/\D/', '', $parts[0]) ?? '', 2, '0', STR_PAD_LEFT) : '01';
        $yearRaw = isset($parts[1]) ? preg_replace('/\D/', '', $parts[1]) ?? '' : '';
        if (strlen($yearRaw) === 2) {
            $year = '20' . $yearRaw;
        } else {
            $year = strlen($yearRaw) >= 4 ? substr($yearRaw, 0, 4) : '2030';
        }

        return [
            'id' => (string) $row['id'],
            'display_name' => (string) $row['display_name'],
            'last4' => (string) $row['last_four'],
            'exp_label' => $exp,
            'exp_month' => $month,
            'exp_year' => $year,
            'card_brand' => (string) ($row['card_brand'] ?? 'visa'),
            'card_default' => ((int) ($row['is_default'] ?? 0)) === 1 ? '1' : '0',
            'image_filename' => (string) ($row['image_filename'] ?? ''),
        ];
    }
}
