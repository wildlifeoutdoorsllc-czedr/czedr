<?php
declare(strict_types=1);

namespace Czedr\Security;

use Czedr\Ledger\PlatformAccounts;

/** Platform and system ledger identities — never assignable at registration. */
final class ReservedCzedrIds
{
    /** @return list<string> */
    private static function reserved(): array
    {
        return PlatformAccounts::reservedCzedrIds();
    }

    public static function assertAvailable(?string $czedrId): void
    {
        if ($czedrId === null || trim($czedrId) === '') {
            return;
        }
        $normalized = strtoupper(trim($czedrId));
        if (in_array($normalized, self::reserved(), true)) {
            throw new \InvalidArgumentException('This Czedr ID is not available');
        }
    }
}
