# Czedr QR payments (iOS)

## What members see

### Profile — “My payment QR”

- Shows a QR code for `https://czedr.com/pay/CZxxxxxxxx`
- Copy/share by showing the screen; friends can also **type or paste** the Czedr ID

### Make Payment

- **QR icon** (next to VALIDATE) opens the camera to scan a recipient’s code
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

## Security

- Scan only fills the **recipient ID**; app still calls **`/v1/users/validate`** and requires **PIN** to pay
- No balance or secrets in the QR

## Code

| File | Role |
|------|------|
| `ios/CzedrSwift/CzedrQrCode.swift` | Generate + parse |
| `ios/CzedrSwift/CzedrQrScanner.swift` | Camera sheet |
| `ios/CzedrSwift/CzedrSwiftRootView.swift` | Profile + Make Payment UI |

## Later (phase 3+)

- Same scan icon on **Send Invoice**
- Optional `czedr.com/pay/CZ…` web landing page
- Android parity
