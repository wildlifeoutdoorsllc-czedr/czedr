<?php
declare(strict_types=1);

namespace Czedr\Funding;

use Czedr\Moov\MoovConfig;

/**
 * Ledger-first money model: P2P never requires a bank. ACH in/out is optional and separate.
 */
final class FundingStatusService
{
    public function __construct(
        private readonly MicroDepositBankLinkService $bankLinks,
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function statusForUser(string $userId): array
    {
        $banks = $this->bankLinks->listBanks($userId);
        $verified = 0;
        $pending = 0;
        foreach ($banks as $b) {
            $st = (string) ($b['status'] ?? '');
            if ($st === 'verified' || $st === 'active') {
                $verified++;
            } elseif (in_array($st, ['pending_micro_send', 'awaiting_confirm'], true)) {
                $pending++;
            }
        }

        return [
            'money_model' => 'ledger_first',
            'bank_optional' => true,
            'bank_login_required' => false,
            'bank_link_method' => MicroDepositBankLinkService::linkMethod(),
            'p2p_without_bank' => true,
            'ach_deposit_available' => MoovConfig::isEnabled(),
            'ach_withdraw_available' => MoovConfig::isEnabled() && self::withdrawalsEnabled(),
            'banks' => $banks,
            'banks_linked' => count($banks),
            'banks_verified' => $verified,
            'banks_pending_verification' => $pending,
            'has_verified_bank' => $verified > 0,
            'min_deposit_cents' => MoovConfig::minDepositCents(),
            'max_deposit_cents' => MoovConfig::maxDepositCents(),
            'user_message' => self::userMessage($verified, $pending),
        ];
    }

    private static function withdrawalsEnabled(): bool
    {
        return (\Czedr\Support\Env::get('CZEDR_ACH_WITHDRAW_ENABLED', '0') ?? '0') === '1';
    }

    private static function userMessage(int $verified, int $pending): string
    {
        if ($verified > 0) {
            return 'Your bank is linked. Payments between Czedr members still use your in-app balance only.';
        }
        if ($pending > 0) {
            return 'Confirm the two small deposits on your bank statement to finish linking. No bank password required.';
        }

        return 'Use Czedr without a bank. Link one only if you want to move cash in or out later—we never ask for your online banking password.';
    }
}
