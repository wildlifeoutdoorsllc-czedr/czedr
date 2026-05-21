<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Ledger\PlatformAccounts;

/** Platform and system ledger identities — never assignable at registration. */
final class ReservedCzedrIds
{
    /** @var list<string> */
    public const RESERVED = PlatformAccounts::reservedCzedrIds();

    public static function assertAvailable(?string $czedrId): void
    {
        if ($czedrId === null || trim($czedrId) === '') {
            return;
        }
        $normalized = strtoupper(trim($czedrId));
        if (in_array($normalized, self::RESERVED, true)) {
            throw new \InvalidArgumentException('This Czedr ID is not available');
        }
    }
}
