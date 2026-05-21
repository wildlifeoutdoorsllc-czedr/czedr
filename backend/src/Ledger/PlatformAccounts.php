<?php
declare(strict_types=1);

namespace Czedr\Ledger;

/** Internal ledger identities (not assignable to members). */
final class PlatformAccounts
{
    public const SYSTEM = 'SYSTEM';
    /** Legacy fee sink — fees now route to {@see CORPORATE}. */
    public const REVENUE = 'REVENUE';
    /** Corporate account: collects transfer fees, pays referrals, keeps net. */
    public const CORPORATE = 'CORPORATE';

    /** @return list<string> */
    public static function reservedCzedrIds(): array
    {
        return [self::SYSTEM, self::REVENUE, self::CORPORATE];
    }

    public static function isPlatformCzedrId(string $czedrId): bool
    {
        return in_array(strtoupper(trim($czedrId)), self::reservedCzedrIds(), true);
    }
}
