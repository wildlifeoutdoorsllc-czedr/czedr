# Czedr QR payments

## What members see

### Profile — “My payment QR”

- Shows a QR code for `https://czedr.com/pay/CZxxxxxxxx`
- Copy/share by showing the screen; friends can also **type or paste** the Czedr ID

### Make Payment

- **QR scan** opens the camera to read a recipient’s code
- **VALIDATE** still works for typed IDs
- **Paste ID from clipboard** for IDs sent in text messages
- Flow after recipient is set: **amount → description → PIN → pay** (unchanged)

## QR payload format

```text
https://czedr.com/pay/CZ08CB8143
```

Parser also accepts:

- Plain `CZ08CB8143`
- `czedr://pay?czedr_id=CZ08CB8143` (future deep links)

## API contract

Authenticated responses include:

| Field | Type | Description |
|-------|------|-------------|
| `payment_qr_payload` | string | Canonical URL encoded in the QR |
| `payment_qr_version` | int | Currently `1` |

Present on:

- `POST /v1/auth/login` and `POST /v1/auth/register` (login-shaped response)
- `GET /v1/me` (profile refresh)

Apps should render the QR locally from `payment_qr_payload` (fast, offline on Profile). If the field is missing, fall back to `https://czedr.com/pay/{czedr_id}`.

## Security

- Scan only fills the **recipient ID**; app still calls **`/v1/users/validate`** and requires **PIN** to pay
- No balance or secrets in the QR

## Code

| Area | Files |
|------|--------|
| API | `backend/src/Payments/PaymentQr.php`, `backend/src/App.php` (`/v1/me`) |
| iOS | `CzedrQrCode.swift`, `CzedrPaymentQrView.swift` (uses `/v1/me` payload via `AppSession`) |
| Android | `android/.../qr/CzedrQrCode.kt`, `ui/PaymentQrCard.kt`, `ui/CzedrScreens.kt` |

## Later

- Same scan on **Send Invoice**
- Optional `czedr.com/pay/CZ…` web landing page
- Server-generated PNG (`GET /v1/me/payment-qr.png`) only if client rendering fails on all platforms
