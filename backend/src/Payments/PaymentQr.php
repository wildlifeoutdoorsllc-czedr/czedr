<?php

declare(strict_types=1);

namespace Czedr\Payments;

/** Canonical payment QR payload shared by iOS, Android, and web. */
final class PaymentQr
{
    public const VERSION = 1;

    public const URL_PREFIX = 'https://czedr.com/pay/';

    public static function payloadForCzedrId(string $czedrId): string
    {
        $id = strtoupper(trim($czedrId));

        return self::URL_PREFIX . $id;
    }

    /** @return array{payment_qr_payload: string, payment_qr_version: int} */
    public static function metaForCzedrId(string $czedrId): array
    {
        return [
            'payment_qr_payload' => self::payloadForCzedrId($czedrId),
            'payment_qr_version' => self::VERSION,
        ];
    }
}
