<?php
declare(strict_types=1);

namespace Czedr\Audit;

use Czedr\Database\ConnectionFactory;
use Czedr\Support\Uuid;

final class AuditService
{
    public function log(
        ?string $actorUserId,
        string $action,
        string $resourceType,
        ?string $resourceId,
        ?string $ip,
        ?string $userAgent,
        array $meta = [],
    ): void {
        $pdo = ConnectionFactory::saturn();
        $stmt = $pdo->prepare(
            'INSERT INTO audit_events (id, actor_user_id, action, resource_type, resource_id, ip_address, user_agent, meta_json)
             VALUES (:id, :actor, :action, :rtype, :rid, :ip, :ua, :meta)'
        );
        $stmt->execute([
            'id' => Uuid::v4(),
            'actor' => $actorUserId,
            'action' => $action,
            'rtype' => $resourceType,
            'rid' => $resourceId,
            'ip' => $ip,
            'ua' => $userAgent !== null ? substr($userAgent, 0, 512) : null,
            'meta' => $meta === [] ? null : json_encode($meta, JSON_THROW_ON_ERROR),
        ]);
    }
}
