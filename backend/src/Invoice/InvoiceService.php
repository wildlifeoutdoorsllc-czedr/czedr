<?php
declare(strict_types=1);

namespace Czedr\Invoice;

use Czedr\Audit\AuditService;
use Czedr\Database\ConnectionFactory;
use Czedr\Support\Uuid;
use PDO;

final class InvoiceService
{
    public function __construct(private readonly AuditService $audit)
    {
    }

    /** @return array{msg: list<string>, objid: list<string>, type: list<string>} */
    public function create(
        string $fromUserId,
        string $toCzedrId,
        float $amountDollars,
        string $description,
        ?string $ip,
        ?string $userAgent
    ): array {
        if ($amountDollars <= 0) {
            throw new \InvalidArgumentException('Please enter valid amount');
        }
        $toUserId = $this->userIdByCzedrId($toCzedrId);
        if ($toUserId === $fromUserId) {
            throw new \InvalidArgumentException('Please enter valid id');
        }
        $amountCents = (int) round($amountDollars * 100);
        $invoiceId = Uuid::v4();
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO invoices (id, from_user_id, to_user_id, amount_cents, description, status)
             VALUES (:id, :from_id, :to_id, :cents, :desc, \'pending\')'
        );
        $stmt->execute([
            'id' => $invoiceId,
            'from_id' => $fromUserId,
            'to_id' => $toUserId,
            'cents' => $amountCents,
            'desc' => substr(trim($description), 0, 255),
        ]);
        $this->audit->log($fromUserId, 'invoice.create', 'invoice', $invoiceId, $ip, $userAgent, [
            'to_czedr_id' => strtoupper(trim($toCzedrId)),
            'amount_cents' => $amountCents,
        ]);
        return [
            'msg' => ['Invoice sent'],
            'objid' => [$invoiceId],
            'type' => ['sent'],
        ];
    }

    /** @return array{rows: list<array<string, mixed>>, total: int} */
    public function listReceived(string $userId, int $offset, int $limit): array
    {
        return $this->listForUser($userId, 'to_user_id', $offset, $limit, true);
    }

    /** @return array{rows: list<array<string, mixed>>, total: int} */
    public function listSent(string $userId, int $offset, int $limit): array
    {
        return $this->listForUser($userId, 'from_user_id', $offset, $limit, false);
    }

    /** @return array{rows: list<array<string, mixed>>, total: int} */
    private function listForUser(
        string $userId,
        string $column,
        int $offset,
        int $limit,
        bool $received
    ): array {
        $pdo = ConnectionFactory::saturn();
        $allowed = ['from_user_id', 'to_user_id'];
        if (!in_array($column, $allowed, true)) {
            throw new \InvalidArgumentException('Invalid list column');
        }
        $otherCol = $column === 'from_user_id' ? 'to_user_id' : 'from_user_id';
        $countStmt = $pdo->prepare(
            "SELECT COUNT(*) FROM invoices WHERE {$column} = :uid AND status = 'pending'"
        );
        $countStmt->execute(['uid' => $userId]);
        $total = (int) $countStmt->fetchColumn();
        $stmt = $pdo->prepare(
            "SELECT i.id, i.amount_cents, i.description, i.status, i.created_at,
                    u.czedr_id, u.email
             FROM invoices i
             JOIN users u ON u.id = i.{$otherCol}
             WHERE i.{$column} = :uid AND i.status = 'pending'
             ORDER BY i.created_at DESC
             LIMIT :lim OFFSET :off"
        );
        $stmt->bindValue('uid', $userId);
        $stmt->bindValue('lim', max(1, min($limit, 50)), PDO::PARAM_INT);
        $stmt->bindValue('off', max(0, $offset), PDO::PARAM_INT);
        $stmt->execute();
        $rows = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $rows[] = $this->legacyRow($row, $received);
        }
        return ['rows' => $rows, 'total' => $total];
    }

    /** @param array<string, mixed> $row */
    private function legacyRow(array $row, bool $received): array
    {
        $amount = ((int) $row['amount_cents']) / 100.0;
        return [
            'id' => $row['id'],
            'name' => $row['email'],
            'user_email' => $row['email'],
            'user_id' => $row['czedr_id'],
            'amount' => (string) $amount,
            'description' => $row['description'] ?? '',
            'created_date' => $row['created_at'],
            'status' => $row['status'],
            'direction' => $received ? 'received' : 'sent',
        ];
    }

    private function userIdByCzedrId(string $czedrId): string
    {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'SELECT id FROM users WHERE czedr_id = :cid AND status = \'active\' LIMIT 1'
        );
        $stmt->execute(['cid' => strtoupper(trim($czedrId))]);
        $id = $stmt->fetchColumn();
        if (!$id) {
            throw new \InvalidArgumentException('Invalid Czedr Id');
        }
        return (string) $id;
    }
}
